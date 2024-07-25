provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "rabbitmqop" {
  name             = "rabbitmqop"
  namespace        = "rabbitmq"
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "rabbitmq-cluster-operator"
  # version          = "3.4.1"
  timeout          = 1200
  atomic           = true
  create_namespace = true

  values = [
    <<EOF
    global:
      imageRegistry: ""
      imagePullSecrets: []
      storageClass: ""
    kubeVersion: ""
    nameOverride: ""
    fullnameOverride: ""
    commonLabels: {}
    commonAnnotations: {}
    clusterDomain: cluster.local
    extraDeploy: []
    diagnosticMode:
      enabled: false
    rabbitmqImage:
      registry: docker.io
      repository: bitnami/rabbitmq
      tag: 3.11.16-debian-11-r3
      digest: ""
      pullSecrets: []
    credentialUpdaterImage:
      registry: docker.io
      repository: bitnami/rmq-default-credential-updater
      tag: 1.0.2-scratch-r21
      digest: ""
      pullSecrets: []
    clusterOperator:
      image:
        registry: docker.io
        repository: bitnami/rabbitmq-cluster-operator
        tag: 2.2.0-scratch-r7
        digest: ""
        pullPolicy: IfNotPresent
        pullSecrets: []
      replicaCount: 1
      topologySpreadConstraints: []
      schedulerName: ""
      terminationGracePeriodSeconds: ""
      livenessProbe:
        enabled: true
        initialDelaySeconds: 5
        periodSeconds: 30
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 5
      readinessProbe:
        enabled: true
        initialDelaySeconds: 5
        periodSeconds: 30
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 5
      startupProbe:
        enabled: false
        initialDelaySeconds: 5
        periodSeconds: 30
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 5
      customLivenessProbe: {}
      customReadinessProbe: {}
      customStartupProbe: {}
      resources:
        limits: {}
        requests: {}
      podSecurityContext:
        enabled: true
        fsGroup: 1001
      containerSecurityContext:
        enabled: true
        runAsUser: 1001
        runAsNonRoot: true
        readOnlyRootFilesystem: true
      command: []
      args: []
      hostAliases: []
      podLabels: {}
      podAnnotations: {}
      podAffinityPreset: ""
      podAntiAffinityPreset: soft
      nodeAffinityPreset: {}
      affinity: {}
      nodeSelector: {}
      tolerations: []
      updateStrategy:
        type: RollingUpdate
      priorityClassName: ""
      lifecycleHooks: {}
      containerPorts:
        metrics: 9782
      extraEnvVars: []
      extraEnvVarsCM: ""
      extraEnvVarsSecret: ""
      extraVolumes: []
      extraVolumeMounts: []
      sidecars: []
      initContainers: []
      rbac:
        create: true
      serviceAccount:
        create: true
        annotations: {}
        extraLabels: {}
        name: ""
        automountServiceAccountToken: true
      metrics:
        service:
          enabled: false
          type: ClusterIP
          port: 80
          nodePorts:
            http: ""
          clusterIP: ""
          extraPorts: []
          loadBalancerIP: ""
          loadBalancerSourceRanges: []
          externalTrafficPolicy: Cluster
          annotations:
            prometheus.io/scrape: "true"
            prometheus.io/port: 80
          sessionAffinity: None
          sessionAffinityConfig: {}
          serviceMonitor:
            enabled: false
            jobLabel: app.kubernetes.io/name
            honorLabels: false
            selector: {}
            scrapeTimeout: ""
            interval: ""
            metricRelabelings: []
            relabelings: []
            labels: {}
    msgTopologyOperator:
      image:
        registry: docker.io
        repository: bitnami/rmq-messaging-topology-operator
        tag: 1.10.3-scratch-r1
        digest: ""
        pullPolicy: IfNotPresent
        pullSecrets: []
      replicaCount: 1
      topologySpreadConstraints: []
      schedulerName: ""
      terminationGracePeriodSeconds: ""
      hostNetwork: false
      dnsPolicy: ClusterFirst
      livenessProbe:
        enabled: true
        initialDelaySeconds: 5
        periodSeconds: 30
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 5
      readinessProbe:
        enabled: true
        initialDelaySeconds: 5
        periodSeconds: 30
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 5
      startupProbe:
        enabled: false
        initialDelaySeconds: 5
        periodSeconds: 30
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 5
      customLivenessProbe: {}
      customReadinessProbe: {}
      customStartupProbe: {}
      existingWebhookCertSecret: ""
      existingWebhookCertCABundle: ""
    EOF
  ]
}
