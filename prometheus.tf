resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "70.4.2"

  set {
    name  = "grafana.enabled"
    value = "false"
  }

  # 讓 Prometheus 接受來自 Alloy 的 remote_write 推送
  set {
    name  = "prometheus.prometheusSpec.enableRemoteWriteReceiver"
    value = "true"
  }

  # Thanos Sidecar：注入到 Prometheus Pod 裡
  set {
    name  = "prometheus.prometheusSpec.thanos.image"
    value = "quay.io/thanos/thanos:v0.37.2"
  }

  set {
    name  = "prometheus.prometheusSpec.thanos.objectStorageConfig.name"
    value = "thanos-objstore-secret"
  }

  set {
    name  = "prometheus.prometheusSpec.thanos.objectStorageConfig.key"
    value = "objstore.yml"
  }

  # Thanos 需要 block duration 固定，才能正確上傳到 S3
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "5h"
  }

  set {
    name  = "prometheus.prometheusSpec.retentionSize"
    value = "1GB"
  }

  depends_on = [
    local_file.kubeconfig,
    kubernetes_secret.thanos_objstore,
  ]
}
