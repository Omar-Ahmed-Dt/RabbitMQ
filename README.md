# Stakpak Assessment

## Overview
This is a kubernetes cluster setup using [Kind](https://kind.sigs.k8s.io/) and have three core components:
- [Ingress Nginx](https://kubernetes.github.io/ingress-nginx/)
- [KEDA](https://keda.sh/)
- [RabbitMQOperator](https://www.rabbitmq.com/kubernetes/operator/operator-overview)

## Prerequisites
- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Setup
1. Create a Kind cluster
```bash
kind create cluster --config kind-config.yaml
```

2. Install Core Components
```bash
terraform -chdir=build/prod/terraform init && terraform -chdir=build/prod/terraform apply
```

3. Apply Manifests
```bash
kubectl apply -f ./build/prod/kubernetes
```

## Requirements

- Ensure all components are running and healthy
- Modify `rabbittest` deployment args to make it scale to maximum replicas
- Create an Ingress resource to expose rabbitmq management UI

## Notes
- You are free to use any tools or resources to complete the task
- You can modify the existing manifests or create new ones including kind configuration
- `perf-test(rabbittest)` is a performance test tool that can be used to test the RabbitMQ cluster so don't keep it running for long

## Bonus
- Use our own open-source tool [Devx](https://devx.stakpak.dev/) to modify the manifests

## Submission
- Fork this repository and submit a PR with your changes# RabbitMQ
