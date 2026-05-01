resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  namespace        = "monitoring"
  create_namespace = false
  version          = "6.6.2"

  values = [<<-EOT
    deploymentMode: SingleBinary

    loki:
      auth_enabled: false
      commonConfig:
        replication_factor: 1
      storage:
        type: filesystem
      schemaConfig:
        configs:
          - from: "2024-01-01"
            store: tsdb
            object_store: filesystem
            schema: v13
            index:
              prefix: loki_index_
              period: 24h

    singleBinary:
      replicas: 1

    # 關閉 SimpleScalable 模式的元件（SingleBinary 不需要）
    backend:
      replicas: 0
    read:
      replicas: 0
    write:
      replicas: 0

    # 關閉需要 memcached 的快取（小型環境不需要）
    chunksCache:
      enabled: false
    resultsCache:
      enabled: false

    gateway:
      enabled: false

    minio:
      enabled: false

    test:
      enabled: false
  EOT
  ]

  depends_on = [helm_release.grafana]
}
