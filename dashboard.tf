resource "kubernetes_config_map" "k8s_dashboard" {
  metadata {
    name      = "k8s-overview-dashboard"
    namespace = "monitoring"

    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "k8s-overview.json" = jsonencode({
      title       = "K8s Overview"
      uid         = "k8s-overview"
      schemaVersion = 36
      refresh     = "30s"
      time        = { from = "now-1h", to = "now" }

      panels = [
        {
          id    = 1
          title = "Node CPU 使用率 (%)"
          type  = "timeseries"
          gridPos = { x = 0, y = 0, w = 12, h = 8 }
          datasource = { type = "prometheus", uid = "prometheus" }
          targets = [{
            expr         = "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)"
            legendFormat = "{{instance}}"
          }]
          fieldConfig = {
            defaults = {
              unit = "percent"
              min  = 0
              max  = 100
              thresholds = {
                mode = "absolute"
                steps = [
                  { color = "green", value = null },
                  { color = "yellow", value = 70 },
                  { color = "red", value = 90 }
                ]
              }
            }
          }
        },
        {
          id    = 2
          title = "Node 記憶體使用率 (%)"
          type  = "timeseries"
          gridPos = { x = 12, y = 0, w = 12, h = 8 }
          datasource = { type = "prometheus", uid = "prometheus" }
          targets = [{
            expr         = "100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)"
            legendFormat = "{{instance}}"
          }]
          fieldConfig = {
            defaults = {
              unit = "percent"
              min  = 0
              max  = 100
              thresholds = {
                mode = "absolute"
                steps = [
                  { color = "green", value = null },
                  { color = "yellow", value = 70 },
                  { color = "red", value = 90 }
                ]
              }
            }
          }
        },
        {
          id    = 3
          title = "Node 數量"
          type  = "stat"
          gridPos = { x = 0, y = 8, w = 4, h = 4 }
          datasource = { type = "prometheus", uid = "prometheus" }
          targets = [{
            expr        = "count(kube_node_info)"
            legendFormat = "Nodes"
          }]
          fieldConfig = {
            defaults = { color = { mode = "thresholds" }, thresholds = { mode = "absolute", steps = [{ color = "blue", value = null }] } }
          }
        },
        {
          id    = 4
          title = "Running Pods"
          type  = "stat"
          gridPos = { x = 4, y = 8, w = 4, h = 4 }
          datasource = { type = "prometheus", uid = "prometheus" }
          targets = [{
            expr        = "count(kube_pod_info)"
            legendFormat = "Pods"
          }]
          fieldConfig = {
            defaults = { color = { mode = "thresholds" }, thresholds = { mode = "absolute", steps = [{ color = "green", value = null }] } }
          }
        },
        {
          id    = 5
          title = "Node 狀態"
          type  = "stat"
          gridPos = { x = 8, y = 8, w = 4, h = 4 }
          datasource = { type = "prometheus", uid = "prometheus" }
          targets = [{
            expr        = "sum(kube_node_status_condition{condition='Ready', status='true'})"
            legendFormat = "Ready Nodes"
          }]
          fieldConfig = {
            defaults = { color = { mode = "thresholds" }, thresholds = { mode = "absolute", steps = [{ color = "green", value = null }] } }
          }
        },
        {
          id    = 6
          title = "Node 磁碟使用率 (%)"
          type  = "timeseries"
          gridPos = { x = 0, y = 12, w = 24, h = 8 }
          datasource = { type = "prometheus", uid = "prometheus" }
          targets = [{
            expr         = "100 - ((node_filesystem_avail_bytes{mountpoint='/',fstype!='tmpfs'} / node_filesystem_size_bytes{mountpoint='/',fstype!='tmpfs'}) * 100)"
            legendFormat = "{{instance}}"
          }]
          fieldConfig = {
            defaults = {
              unit = "percent"
              min  = 0
              max  = 100
              thresholds = {
                mode = "absolute"
                steps = [
                  { color = "green", value = null },
                  { color = "yellow", value = 70 },
                  { color = "red", value = 90 }
                ]
              }
            }
          }
        }
      ]
    })
  }

  depends_on = [helm_release.grafana]
}
