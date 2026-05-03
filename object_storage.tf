resource "linode_object_storage_bucket" "thanos" {
  label  = "thanos-metrics"
  region = "jp-osa"
}

resource "linode_object_storage_key" "thanos" {
  label = "thanos-metrics-key"

  bucket_access {
    bucket_name = linode_object_storage_bucket.thanos.label
    region      = "jp-osa"
    permissions = "read_write"
  }
}
