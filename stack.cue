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
				args: ["--uri", "$(RABBIT_MQ_URI)", "--queue", "queue", "--rate", "10"]
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
							value:       "20"
							queueName:   "queue"
							mode:        "MessageRate"
							hostFromEnv: "RABBIT_MQ_URI"
						}
					},
				]
			}

		}

	}
}

builders: {
	prod: components: {
		cluster: k8s: name: "prod"
	}
}
