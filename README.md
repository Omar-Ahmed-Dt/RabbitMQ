# About: 
I will deploy a RabbitMQ cluster on Kubernetes using Helm and Terraform, and integrat it with KEDA for autoscaling!
## Project Highlights:
- RabbitMQ Deployment: Managed with RabbitMQ Operator Helm chart.
- Application Deployment: Configured to connect to RabbitMQ via environment variables.
- Autoscaling: Implemented KEDA to scale based on RabbitMQ metrics.
- Ingress Setup: Exposed RabbitMQ management UI using an Ingress resource for easy access.
- **Technologies Used:**
RabbitMQ, Kubernetes, KEDA, Helm, Terraform, Ingress

## 1. Create a Kind cluster
```bash
kind create cluster --config kind-config.yaml
```

## 2. Create the RabbitMQ Cluster
a. **Install RabbitMQ Cluster Operator Deployment and Custom Configuration:**
   ```bash
terraform -chdir=build/prod/terraform init && terraform -chdir=build/prod/terraform apply --auto-approve
```
**or**
```bash
cd build/prod/kubernetes/
kubectl create namespace rabbitmq-system
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml
```
b. **Create The RabbitMQ Cluster and Verify Resources**
```bash
kubectl apply -f rabbit-rabbitmqcluster.yml
kubectl get pods -n rabbitmq
kubectl get svc -n rabbitmq
```
![rabbitmq](imgs/rabbitmq_ns.png)

## 3. Create the ServiceAccount 
```bash
kubectl apply -f rabbittest-serviceaccount.yml
```
## 4. Verify the access and look up the service
```bash
a. edit stack.cue file to add dnsutils-deployment: 
package main

import (
        "stakpak.dev/devx/v1"
        "stakpak.dev/devx/v1/traits"
        "stakpak.dev/devx/k8s/services/rabbitmq"
        "stakpak.dev/devx/k8s/services/keda"
        "stakpak.dev/devx/k8s/services/ingressnginx"
)

stack: v1.#Stack & {
        components: {
                cluster: {
                        traits.#KubernetesCluster
                        k8s: version: minor: 26
                }
                common: {
                        traits.#Secret
                        secrets: {
                        }
                        env: {
                                RABBIT_MQ_URI: "amqp://default_user_CEp19JlfPtw3PciCnK5:aJo_RRJZvSK_fwMvuyFAaCUsX2mZ0A8z@rabbit.rabbitmq.svc.cluster.local:5672"
                        }
                }

                ingress: {
                        ingressnginx.#IngressNginxChart
                        k8s: cluster.k8s
                }

                kedaop: {
                        keda.#KEDAChart
                        k8s: cluster.k8s
                }

                rabbitmqop: {
                        rabbitmq.#RabbitMQOperatorChart
                        k8s: cluster.k8s
                }

                rabbit: {
                        traits.#RabbitMQ
                        k8s: {
                                cluster.k8s
                                namespace: "rabbitmq"
                        }
                        rabbitmq: {
                                name:     "rabbitmq"
                                version:  "3.9"
                                replicas: 2
                        }
                }

                rabbittest: {
                        traits.#Workload
                        traits.#Scalable
                        containers: default: {
                                image: "pivotalrabbitmq/perf-test"
                                args: ["--uri", "$(RABBIT_MQ_URI)", "--queue", "queue", "--rate", "10000"]
                                env: {
                                        RABBIT_MQ_URI: common.env.RABBIT_MQ_URI
                                }
                                resources: {
                                        requests: {
                                                cpu:    "4"
                                                memory: "4Gi"
                                        }
                                }
                        }
                        scale: {
                                replicas: {
                                        min: 1
                                        max: 3
                                }
                                triggers: [
                                        {
                                                type: "rabbitmq"
                                                metadata: {
                                                        value:       "1000"
                                                        queueName:   "queue"
                                                        mode:        "MessageRate"
                                                        hostFromEnv: "RABBIT_MQ_URI"
                                                }
                                        },
                                ]
                        }

                }

                dnsutils: {
                        traits.#Workload
                        containers: default: {
                                image: "busybox"
                                command: ["sleep", "3600"]
                        }
                        k8s: {
                                namespace: "default"
                        }
                }

        }
}

builders: {
        prod: components: {
                cluster: k8s: name: "prod"
        }
}


b. run :
kubectl logs <pod name for rabbittest-deployment>
kubectl exec -it dnsutils -- nslookup rabbit.rabbitmq.svc.cluster.local
```
## 5. Inspect RabbitMQ Secrets and Deploy rabbittest-deployment
```bash
kubectl get secret rabbit-default-user -n rabbitmq -o yaml
echo "ZGVmYXVsdF91c2VyID0gZGVmYXVsdF91c2VyX3dtYUE0aDhPRmJEU05LZHoxV0YKZGVmYXVsdF9wYXNzID0gVGJXRzM4UHBXbFBwQUsxM1dKYWhnSjl0SFJLdUxnVTcK" | base64 --decode 
```

## 6. Edit Deployment for Rabbittest to Access the Server:
```bash
    env:
  - name: RABBIT_MQ_URI
    value: amqp://default_user_wmaA4h8OFbDSNKdz1WF:TbWG38PpWlPpAK13WJahgJ9tHRKuLgU7@rabbit.rabbitmq.svc:5672
```
or 
```bash
edit stack.cue file and rebuild: 
a. 
env: {
				RABBIT_MQ_URI: "amqp://default_user_Gf-B3iY5LBj19vEJW3S:WtbmEl2jqfg7Z-LWkqvWX5jlVPey6Qpf@rabbit.rabbitmq.svc:5672"
			}

b. run: 
devx build prod
```

```bash
kubectl apply -f rabbittest-deployment.yml
```
## 7. Install KEDA, It allows Kubernetes to scale applications based on the number of events needing to be processed
```bash
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace
```
## 8. Create the ScaledObject, It polls the RabbitMQ queue every 30 seconds to check the message rate.
```bash
kubectl apply -f rabbittest-scaledobject.yml
kubectl get scaledobject
kubectl describe scaledobject rabbittest
kubectl get pod
```

## Ensure all components are running and healthy
![pods](imgs/all_pods.png)

## Modify rabbittest deployment args to make it scale to maximum replicas 
### Modified the rate to --rate 1000. This increases the message rate, generating a higher load that should trigger the scaling mechanism to reach the maximum replicas (3 replicas in your ScaledObject).

```bash
args:
   # - java -jar /perf_test/perf-test.jar --uri $(RABBIT_MQ_URI) --queue queue --rate 10
    - java -jar /perf_test/perf-test.jar --uri $(RABBIT_MQ_URI) --queue queue --rate 1000
```
or 
```bash
a. edit stack.cue file and rebuild: 
args: ["--uri", "$(RABBIT_MQ_URI)", "--queue", "queue", "--rate", "100"]

b. run: 
devx build prod
```

```bash
kubectl apply -f rabbittest-deployment.yml
```

## Expose rabbitmq management UI
a. **Create an Ingress resource**
```bash
a1. Add this section to stack.cue file : 
package main

import (
        "stakpak.dev/devx/v1"
        "stakpak.dev/devx/v1/traits"
        "stakpak.dev/devx/k8s/services/rabbitmq"
        "stakpak.dev/devx/k8s/services/keda"
        "stakpak.dev/devx/k8s/services/ingressnginx"
)

stack: v1.#Stack & {
        components: {
                cluster: {
                        traits.#KubernetesCluster
                        k8s: version: minor: 26
                }
                common: {
                        traits.#Secret
                        secrets: {
                        }
                        env: {
                                RABBIT_MQ_URI: "amqp://default_user_CEp19JlfPtw3PciCnK5:aJo_RRJZvSK_fwMvuyFAaCUsX2mZ0A8z@rabbit.rabbitmq.svc.cluster.local:5672"
                        }
                }

                ingress: {
                        ingressnginx.#IngressNginxChart
                        k8s: cluster.k8s
                }

                kedaop: {
                        keda.#KEDAChart
                        k8s: cluster.k8s
                }

                rabbitmqop: {
                        rabbitmq.#RabbitMQOperatorChart
                        k8s: cluster.k8s
                }

                rabbit: {
                        traits.#RabbitMQ
                        k8s: {
                                cluster.k8s
                                namespace: "rabbitmq"
                        }
                        rabbitmq: {
                                name:     "rabbitmq"
                                version:  "3.9"
                                replicas: 2
                        }
                }

                rabbittest: {
                        traits.#Workload
                        traits.#Scalable
                        containers: default: {
                                image: "pivotalrabbitmq/perf-test"
                                args: ["--uri", "$(RABBIT_MQ_URI)", "--queue", "queue", "--rate", "10000"]
                                env: {
                                        RABBIT_MQ_URI: common.env.RABBIT_MQ_URI
                                }
                                resources: {
                                        requests: {
                                                cpu:    "4"
                                                memory: "4Gi"
                                        }
                                }
                        }
                        scale: {
                                replicas: {
                                        min: 1
                                        max: 3
                                }
                                triggers: [
                                        {
                                                type: "rabbitmq"
                                                metadata: {
                                                        value:       "1000"
                                                        queueName:   "queue"
                                                        mode:        "MessageRate"
                                                        hostFromEnv: "RABBIT_MQ_URI"
                                                }
                                        },
                                ]
                        }
                }

                dnsutils: {
                        traits.#Workload
                        containers: default: {
                                image: "busybox"
                                command: ["sleep", "3600"]
                        }
                        k8s: {
                                namespace: "default"
                        }
                }

                rabbitmqIngress: {
                        traits.#Ingress
                        k8s: {
                                namespace: "rabbitmq"
                        }
                        ingress: {
                                metadata: {
                                        name: "rabbitmq-ingress"
                                        annotations: {
                                                "nginx.ingress.kubernetes.io/rewrite-target": "/"
                                        }
                                }
                                spec: {
                                        rules: [{
                                                host: "rabbitmqtesting.com"
                                                http: {
                                                        paths: [{
                                                                path: "/"
                                                                pathType: "Prefix"
                                                                backend: {
                                                                        service: {
                                                                                name: "rabbitmq"
                                                                                port: {
                                                                                        number: 15672
                                                                                }
                                                                        }
                                                                }
                                                        }]
                                                }
                                        }]
                                }
                        }
                }
        }
}

builders: {
        prod: components: {
                cluster: k8s: name: "prod"
        }
}

a2. run: devx build prod
```
b. **Create an Ingress Controller**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```
![ingress](imgs/ingress.png)

c. **Update hosts file**
```bash
echo "127.0.0.1 rabbitmqtesting.com" | sudo tee -a /etc/hosts
kubectl port-forward svc/rabbit -n rabbitmq 15672:15672
```

![pods](imgs/userandpass.png)
![pods](imgs/UI.png)