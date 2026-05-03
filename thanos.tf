resource "kubernetes_secret" "thanos_objstore" {
  metadata {
    name      = "thanos-objstore-secret"
    namespace = "monitoring"
  }

  data = {
    "objstore.yml" = <<-EOT
      type: S3
      config:
        bucket: ${linode_object_storage_bucket.thanos.label}
        endpoint: ${linode_object_storage_bucket.thanos.hostname}
        access_key: ${linode_object_storage_key.thanos.access_key}
        secret_key: ${linode_object_storage_key.thanos.secret_key}
        insecure: false
    EOT
  }

  depends_on = [
    linode_object_storage_bucket.thanos,
    linode_object_storage_key.thanos,
  ]
}

resource "helm_release" "thanos" {
  name             = "thanos"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "thanos"
  namespace        = "monitoring"
  create_namespace = false
  version          = "15.7.19"
  timeout          = 600
  wait             = false

  values = [<<-EOT
    image:
      registry: quay.io
      repository: thanos/thanos
      tag: v0.37.2

    existingObjstoreSecret: thanos-objstore-secret

    query:
      enabled: true
      # 連接 Thanos Sidecar（跑在 Prometheus Pod 裡）
      stores:
        - dnssrv+_grpc._tcp.prometheus-operated.monitoring.svc.cluster.local

    storegateway:
      enabled: true

    compactor:
      enabled: true
      # 各解析度的資料保留時間
      retentionResolutionRaw: 30d
      retentionResolution5m: 90d
      retentionResolution1h: 365d

    # 關閉不需要的元件
    queryFrontend:
      enabled: false
    ruler:
      enabled: false
    receive:
      enabled: false
    bucketweb:
      enabled: false
  EOT
  ]

  depends_on = [kubernetes_secret.thanos_objstore]
}
