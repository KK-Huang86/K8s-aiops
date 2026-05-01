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

  depends_on = [local_file.kubeconfig]
}
