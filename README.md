# Stakpak Assessment

## 1. Create a Kind cluster
```bash
kind create cluster --config kind-config.yaml
```

## 2. Install Core Components
```bash
terraform -chdir=build/prod/terraform init && terraform -chdir=build/prod/terraform apply --auto-approve
```


## 3. Create the RabbitMQ Cluster
a. **Install RabbitMQ Operator:**
   ```bash
cd build/prod/kubernetes/
kubectl create namespace rabbitmq-system
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml
   ```
b. **Verify that the RabbitMQ Operator is running:**
```bash
kubectl get pods -n rabbitmq-system
```
c. **Create The RabbitMQ Cluster and Verify Resources**
```bash
kubectl apply -f rabbit-rabbitmqcluster.yml
kubectl get pods -n rabbitmq
kubectl get svc -n rabbitmq
```
## 4. Create the ServiceAccount 
```bash
kubectl apply -f rabbittest-serviceaccount.yml
```
## 5. Install KEDA 
```bash
kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.7.1/keda-2.7.1.yaml
kubectl get pods -n keda
```
## 6. Create the ScaledObject
```bash
kubectl apply -f rabbittest-scaledobject.yml
```
## 7. Inspect RabbitMQ Secrets and Deploy rabbittest-deployment
```bash
kubectl get secret rabbit-default-user -n rabbitmq -o yaml
echo "ZGVmYXVsdF91c2VyID0gZGVmYXVsdF91c2VyX3dtYUE0aDhPRmJEU05LZHoxV0YKZGVmYXVsdF9wYXNzID0gVGJXRzM4UHBXbFBwQUsxM1dKYWhnSjl0SFJLdUxnVTcK" | base64 --decode 
```
## 8. Edit Deployment for Rabbittest to Access the Server:
```bash
    env:
  - name: RABBIT_MQ_URI
    value: amqp://default_user_wmaA4h8OFbDSNKdz1WF:TbWG38PpWlPpAK13WJahgJ9tHRKuLgU7@rabbit.rabbitmq.svc:5672
```

```bash
    kubectl apply -f rabbittest-deployment.yml
```
## 9. Verify the access and look up the service
```bash
kubectl logs <pod name for rabbittest-deployment>
kubectl exec -it dnsutils -- nslookup rabbit.rabbitmq.svc.cluster.local
```

## Ensure all components are running and healthy
![pods](imgs/all_pods.png)

## To configure the Horizontal Pod Autoscaler (HPA) to scale Rabbittest to a maximum number of replicas
```bash
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: rabbittest-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: rabbittest
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50 
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