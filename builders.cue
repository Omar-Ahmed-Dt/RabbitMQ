package main

import (
	"stakpak.dev/devx/v1/traits"
	"stakpak.dev/devx/v1/transformers/kubernetes"
	keda "stakpak.dev/devx/k8s/services/keda/transformers/kubernetes"
	"stakpak.dev/devx/v2alpha1"
	"stakpak.dev/devx/v1/transformers/terraform/helm"
	"stakpak.dev/devx/v1/transformers/terraform/k8s"
	rabbitmq "stakpak.dev/devx/k8s/services/rabbitmq/transformers/kubernetes"
)

builders: v2alpha1.#Environments & {
	prod: {
		flows: {
			"ignore-k8s-cluster": pipeline: [{traits.#KubernetesCluster}]
			"ignore-secrets": pipeline: [{traits.#Secret}]
			"k8s/resources": pipeline: [
				kubernetes.#AddKubernetesResources,
			]
			"terraform/helm": pipeline: [
				k8s.#AddLocalHelmProvider,
				helm.#AddHelmRelease,
			]
			"k8s/add-deployment": {
				pipeline: [kubernetes.#AddDeployment]
			}
			"k8s/add-labels": pipeline: [kubernetes.#AddLabels & {
				labels: [string]: string
			}]
			"k8s/add-annotations": pipeline: [kubernetes.#AddAnnotations & {
				annotations: [string]: string
			}]
			"k8s/add-scaled": {
				pipeline: [keda.#AddScaledObject]
			}
			"k8s/add-rabbitmq": {
				pipeline: [rabbitmq.#AddCluster]
			}
		}
	}
}
