resource "kubectl_manifest" "node_alerts" {
  yaml_body = <<-YAML
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: node-resource-alerts
      namespace: monitoring
      labels:
        release: kube-prometheus-stack
    spec:
      groups:
        - name: node.resources
          rules:
            - alert: NodeCPUHigh
              expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "Node CPU 使用率過高"
                description: "節點 {{ $labels.instance }} 的 CPU 使用率已超過 80%，目前為 {{ printf \"%.1f\" $value }}%"
            - alert: NodeCPUCritical
              expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
              for: 5m
              labels:
                severity: critical
              annotations:
                summary: "Node CPU 使用率嚴重過高"
                description: "節點 {{ $labels.instance }} 的 CPU 使用率已超過 90%，目前為 {{ printf \"%.1f\" $value }}%"
            - alert: NodeMemoryHigh
              expr: 100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) > 80
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "Node Memory 使用率過高"
                description: "節點 {{ $labels.instance }} 的 Memory 使用率已超過 80%，目前為 {{ printf \"%.1f\" $value }}%"
            - alert: NodeMemoryCritical
              expr: 100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) > 90
              for: 5m
              labels:
                severity: critical
              annotations:
                summary: "Node Memory 使用率嚴重過高"
                description: "節點 {{ $labels.instance }} 的 Memory 使用率已超過 90%，目前為 {{ printf \"%.1f\" $value }}%"
  YAML

  depends_on = [helm_release.kube_prometheus_stack]
}
