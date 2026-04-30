output "cluster_id" {
  value = linode_lke_cluster.cluster.id
}

output "api_endpoints" {
  value = linode_lke_cluster.cluster.api_endpoints
}

output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}
