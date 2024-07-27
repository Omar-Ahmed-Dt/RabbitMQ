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

```bash
kubectl apply -f rabbittest-deployment.yml
```

## Expose rabbitmq management UI
a. **Create an Ingress resource**
```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rabbitmq-ingress
  namespace: rabbitmq
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: rabbitmqtesting.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rabbitmq
                port:
                  number: 15672
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