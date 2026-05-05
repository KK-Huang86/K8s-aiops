resource "kubernetes_config_map_v1" "discord_mcp" {
  metadata {
    name      = "discord-mcp"
    namespace = "kagent"
  }
  data = {
    "server.py" = <<-EOT
      import os, json, requests, threading
      from http.server import HTTPServer, BaseHTTPRequestHandler
      from mcp.server.fastmcp import FastMCP
      from mcp.server.transport_security import TransportSecuritySettings

      WEBHOOK    = os.environ.get("DISCORD_WEBHOOK_URL", "")
      KAGENT_URL = os.environ.get("KAGENT_URL", "http://kagent-controller.kagent:8083/api/a2a/kagent/alert-investigator/")

      mcp = FastMCP(
          "discord-notifier",
          host="0.0.0.0",
          port=8085,
          transport_security=TransportSecuritySettings(enable_dns_rebinding_protection=False),
      )

      @mcp.tool()
      def send_discord_message(discord_message: str) -> str:
          """Send an alert analysis report to the Discord notification channel. Use this as the final step after completing investigation."""
          if not WEBHOOK:
              return "error: DISCORD_WEBHOOK_URL not set"
          r = requests.post(WEBHOOK, json={"content": discord_message[:2000]})
          print(f"[discord] {r.status_code}", flush=True)
          return "sent" if r.ok else f"error {r.status_code}"

      def _call_kagent(body):
          try:
              requests.post(KAGENT_URL, json=body, timeout=300)
          except Exception as e:
              print(f"[kagent] {e}", flush=True)

      class TriggerHandler(BaseHTTPRequestHandler):
          def log_message(self, *args): pass
          def do_POST(self):
              length = int(self.headers.get("Content-Length", 0))
              body = json.loads(self.rfile.read(length)) if length else {}
              threading.Thread(target=_call_kagent, args=(body,), daemon=True).start()
              self.send_response(200)
              self.send_header("Content-Type", "application/json")
              self.end_headers()
              self.wfile.write(b'{"status":"triggered"}')

      trigger_server = HTTPServer(("0.0.0.0", 8086), TriggerHandler)
      threading.Thread(target=trigger_server.serve_forever, daemon=True).start()
      print("Trigger server on :8086", flush=True)

      mcp.run(transport="streamable-http")
    EOT
    "start.sh"  = <<-EOT
      #!/bin/sh
      pip install -q "mcp[cli]" requests
      python3 /app/server.py
    EOT
  }
}

resource "kubernetes_deployment_v1" "discord_mcp" {
  metadata {
    name      = "discord-mcp"
    namespace = "kagent"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "discord-mcp" }
    }
    template {
      metadata {
        labels      = { app = "discord-mcp" }
        annotations = { "configmap-hash" = sha256(jsonencode(kubernetes_config_map_v1.discord_mcp.data)) }
      }
      spec {
        container {
          name    = "discord-mcp"
          image   = "python:3.11-slim"
          command = ["sh", "/app/start.sh"]
          env {
            name  = "DISCORD_WEBHOOK_URL"
            value = var.discord_webhook_url
          }
          port {
            container_port = 8085
          }
          volume_mount {
            name       = "script"
            mount_path = "/app"
          }
          resources {
            requests = { cpu = "50m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
          readiness_probe {
            tcp_socket {
              port = 8085
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
        volume {
          name = "script"
          config_map {
            name         = kubernetes_config_map_v1.discord_mcp.metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "discord_mcp" {
  metadata {
    name      = "discord-mcp"
    namespace = "kagent"
  }
  spec {
    selector = { app = "discord-mcp" }
    port {
      name        = "mcp"
      port        = 8085
      target_port = 8085
    }
    port {
      name        = "trigger"
      port        = 8086
      target_port = 8086
    }
  }
}

resource "kubectl_manifest" "discord_mcp_server" {
  yaml_body = <<-YAML
    apiVersion: kagent.dev/v1alpha2
    kind: RemoteMCPServer
    metadata:
      name: discord-mcp
      namespace: kagent
    spec:
      description: "Discord notification MCP server for sending alert reports"
      url: "http://discord-mcp.kagent:8085/mcp"
      protocol: STREAMABLE_HTTP
      timeout: 30s
      sseReadTimeout: 5m0s
      terminateOnClose: true
  YAML

  depends_on = [helm_release.kagent]
}
