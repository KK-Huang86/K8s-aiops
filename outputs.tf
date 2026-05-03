output "cluster_id" {
  value = linode_lke_cluster.cluster.id
}

output "api_endpoints" {
  value = linode_lke_cluster.cluster.api_endpoints
}

output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}

output "thanos_bucket_name" {
  value = linode_object_storage_bucket.thanos.label
}

output "thanos_access_key" {
  value     = linode_object_storage_key.thanos.access_key
  sensitive = true
}

output "thanos_secret_key" {
  value     = linode_object_storage_key.thanos.secret_key
  sensitive = true
}
