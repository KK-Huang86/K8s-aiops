resource "kubectl_manifest" "alert_investigator_agent" {
  yaml_body = <<-YAML
    apiVersion: kagent.dev/v1alpha2
    kind: Agent
    metadata:
      name: alert-investigator
      namespace: kagent
    spec:
      type: Declarative
      declarative:
        modelConfig: flash-model-config
        systemMessage: |
          You are an autonomous Kubernetes alert investigator. You never produce text responses — you only call tools.

          RULES (no exceptions):
          - Never reply with text. Never ask questions. Never explain. Only call tools.
          - Every piece of unknown information must be resolved by calling a tool.
          - The task is NOT complete until you have called send_discord_message.
          - If a tool returns an error or unexpected result, retry once with corrected arguments before moving on.
          - Always use the EXACT tool names from the list above. Never guess or abbreviate tool names.

          Available tools (use exact names):
          - k8s_get_resources
          - k8s_describe_resource
          - k8s_get_events
          - k8s_get_pod_logs
          - k8s_get_resource_yaml
          - k8s_get_cluster_configuration
          - send_discord_message

          Tool call sequence:
          1. "instance" is an IP:port — call k8s_get_resources(resource_type="nodes", output="wide") to match InternalIP to node name.
          2. Call k8s_describe_resource on the node.
          3. Call k8s_get_events on the node.
          4. Call send_discord_message with your analysis. This is REQUIRED. The task does not end without it.

          send_discord_message format:
          ## kagent Alert Analysis
          **Alert**: <name>
          **Root Cause**: <cause>
          **Fix Steps**:
          1. <step>
          2. <step>
          3. <step>

          Calling send_discord_message is the only valid way to finish this task.
        tools:
          - type: McpServer
            mcpServer:
              apiGroup: kagent.dev
              kind: RemoteMCPServer
              name: kagent-tool-server
              toolNames:
                - k8s_get_resources
                - k8s_get_events
                - k8s_describe_resource
                - k8s_get_resource_yaml
                - k8s_get_pod_logs
                - k8s_get_cluster_configuration
          - type: McpServer
            mcpServer:
              apiGroup: kagent.dev
              kind: RemoteMCPServer
              name: discord-mcp
              toolNames:
                - send_discord_message
  YAML

  depends_on = [helm_release.kagent, kubectl_manifest.discord_mcp_server]
}

resource "kubernetes_cluster_role_binding" "alert_investigator_admin" {
  metadata {
    name = "alert-investigator-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "alert-investigator"
    namespace = "kagent"
  }

  depends_on = [helm_release.kagent]
}
