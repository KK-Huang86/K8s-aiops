resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "sidecar.dashboards.enabled"
    value = "true"
  }

  set {
    name  = "sidecar.dashboards.label"
    value = "grafana_dashboard"
  }

  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].uid"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
    value = "true"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[1].name"
    value = "Loki"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[1].type"
    value = "loki"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[1].uid"
    value = "loki"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[1].url"
    value = "http://loki.monitoring.svc.cluster.local:3100"
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
