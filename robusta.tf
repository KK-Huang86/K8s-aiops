resource "helm_release" "robusta" {
  name             = "robusta"
  repository       = "https://robusta-charts.storage.googleapis.com"
  chart            = "robusta"
  namespace        = "robusta"
  create_namespace = true
  timeout          = 300
  wait             = false

  values = [
    yamlencode({
      clusterName = linode_lke_cluster.cluster.label

      globalConfig = {
        signing_key = var.robusta_signing_key
        account_id  = "00000000-0000-0000-0000-000000000000"
      }

      sinksConfig = [
        {
          discord_sink = {
            name = "discord"
            url  = var.discord_webhook_url
          }
        }
      ]

      # 使用外部已安裝的 Prometheus，不重複安裝
      enablePrometheusStack = false

      # 不使用 PersistentVolume，適合小型環境
      disablePersistentVolume = true
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}
