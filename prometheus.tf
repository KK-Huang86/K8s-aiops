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

  depends_on = [local_file.kubeconfig]
}
