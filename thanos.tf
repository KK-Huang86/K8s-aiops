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
