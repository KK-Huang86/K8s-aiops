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

          // ── Metrics ──────────────────────────────────────────────────

          // 發現標註 prometheus.io/scrape=true 的 pod
          discovery.kubernetes "metrics_pods" {
            role = "pod"
          }

          discovery.relabel "metrics_pods" {
            targets = discovery.kubernetes.metrics_pods.targets

            // 只抓有明確標註要 scrape 的 pod，避免與 kube-prometheus-stack 重複
            rule {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
              action        = "keep"
              regex         = "true"
            }

            // 允許 pod 自訂 metrics path（預設 /metrics）
            rule {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
              action        = "replace"
              target_label  = "__metrics_path__"
              regex         = "(.+)"
            }

            // 允許 pod 自訂 port
            rule {
              source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
              action        = "replace"
              regex         = "([^:]+)(?::\\d+)?;(\\d+)"
              replacement   = "$1:$2"
              target_label  = "__address__"
            }

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
          }

          prometheus.scrape "pods" {
            targets    = discovery.relabel.metrics_pods.output
            forward_to = [prometheus.remote_write.prometheus.receiver]
          }

          // 推送到 Prometheus remote write endpoint
          prometheus.remote_write "prometheus" {
            endpoint {
              url = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/api/v1/write"
            }
          }
  EOT
  ]

  depends_on = [helm_release.loki]
}
