resource "helm_release" "alloy" {
  name             = "alloy"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "alloy"
  namespace        = "monitoring"
  create_namespace = false
  version          = "0.9.2"

  values = [<<-EOT
    controller:
      type: daemonset

    alloy:
      configMap:
        content: |
          // 發現 cluster 內所有 pod
          discovery.kubernetes "pods" {
            role = "pod"
          }

          // 從 pod metadata 提取 label，讓 Loki 可以用 namespace/pod/container 查詢
          discovery.relabel "pod_logs" {
            targets = discovery.kubernetes.pods.targets

            rule {
              source_labels = ["__meta_kubernetes_namespace"]
              target_label  = "namespace"
            }

            rule {
              source_labels = ["__meta_kubernetes_pod_name"]
              target_label  = "pod"
            }

            rule {
              source_labels = ["__meta_kubernetes_pod_container_name"]
              target_label  = "container"
            }

            rule {
              source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_name"]
              separator     = "/"
              target_label  = "job"
            }
          }

          // 從每個 pod 收集 log
          loki.source.kubernetes "pods" {
            targets    = discovery.relabel.pod_logs.output
            forward_to = [loki.write.loki.receiver]
          }

          // 傳送到 Loki
          loki.write "loki" {
            endpoint {
              url = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
            }
          }
  EOT
  ]

  depends_on = [helm_release.loki]
}
