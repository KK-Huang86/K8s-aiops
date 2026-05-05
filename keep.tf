resource "helm_release" "keep" {
  name             = "keep"
  repository       = "https://keephq.github.io/helm-charts"
  chart            = "keep"
  namespace        = "keep"
  create_namespace = true

  wait       = false
  depends_on = [helm_release.ingress_nginx]

  values = [
    yamlencode({
      ingress = {
        enabled   = true
        className = "nginx"
        annotations = {
          "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "3600"
          "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "3600"
          "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "3600"
        }
        hosts = [{ host = local.keep_host }]
      }

      backend = {
        resources = {
          requests = { memory = "256Mi", cpu = "100m" }
          limits   = { memory = "640Mi", cpu = "500m" }
        }
        env = [
          { name = "SECRET_KEY", value = var.keep_secret_key },
          { name = "AUTH_TYPE", value = "NO_AUTH" },
          { name = "PUSHER_APP_ID", value = "1" },
          { name = "PUSHER_APP_KEY", value = "keepappkey" },
          { name = "PUSHER_APP_SECRET", value = "keepappsecret" },
          { name = "PUSHER_HOST", value = "keep-websocket" },
          { name = "PUSHER_PORT", value = "6001" },
        ]
        provision = {
          providers = {
            discord = {
              type = "discord"
              authentication = {
                webhook_url = var.discord_webhook_url
              }
            }

            kagent_trigger = {
              type = "webhook"
              authentication = {
                url = "http://discord-mcp.kagent.svc.cluster.local:8086/trigger"
              }
            }
          }
          workflows = [
            {
              id          = "discord-warning"
              name        = "Discord Warning Alert"
              description = "Send warning alerts to Discord"
              triggers = [
                {
                  type = "alert"
                  filters = [
                    { key = "source", value = "prometheus" },
                    { key = "severity", value = "warning" },
                  ]
                }
              ]
              actions = [
                {
                  name = "notify-discord"
                  provider = {
                    type   = "discord"
                    config = "{{ providers.discord }}"
                    with = {
                      content = "### 🟡 [WARNING] {{ alert.labels.alertname }}\n> 📍 **Node**  `{{ alert.labels.instance }}`\n> 📊 **Detail**  {{ alert.description }}"
                    }
                  }
                }
              ]
            },
            {
              id          = "discord-critical"
              name        = "Discord Critical Alert"
              description = "Send critical alerts to Discord"
              triggers = [
                {
                  type = "alert"
                  filters = [
                    { key = "source", value = "prometheus" },
                    { key = "severity", value = "critical" },
                  ]
                }
              ]
              actions = [
                {
                  name = "notify-discord"
                  provider = {
                    type   = "discord"
                    config = "{{ providers.discord }}"
                    with = {
                      content = "### 🔴 [CRITICAL] {{ alert.labels.alertname }}\n> 📍 **Node**  `{{ alert.labels.instance }}`\n> 📊 **Detail**  {{ alert.description }}"
                    }
                  }
                }
              ]
            },

            {
              id          = "kagent-trigger"
              name        = "kagent Alert Investigation"
              description = "Trigger kagent AI agent to investigate critical alerts"
              triggers = [
                {
                  type = "alert"
                  filters = [
                    { key = "severity", value = "critical" },
                    { key = "status", value = "firing" },
                  ]
                }
              ]
              actions = [
                {
                  name = "trigger_investigation"
                  provider = {
                    type   = "webhook"
                    config = "{{ providers.kagent_trigger }}"
                    with = {
                      fail_on_error = false
                      body = {
                        jsonrpc = "2.0"
                        id      = "{{ alert.id }}"
                        method  = "message/send"
                        params = {
                          message = {
                            role      = "user"
                            messageId = "{{ alert.id }}"
                            parts = [
                              {
                                kind = "text"
                                text = "Alert: {{ alert.name }} | Severity: {{ alert.severity }} | Instance: {{ alert.labels.instance }} | Description: {{ alert.description }}. Please investigate."
                              }
                            ]
                          }
                        }
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      }

      frontend = {
        resources = {
          requests = { memory = "64Mi", cpu = "50m" }
          limits   = { memory = "256Mi", cpu = "200m" }
        }
        env = [
          { name = "AUTH_TYPE", value = "NO_AUTH" },
          { name = "NEXTAUTH_SECRET", value = var.keep_secret_key },
          { name = "NEXTAUTH_URL", value = "http://${local.keep_host}" },
          { name = "NEXTAUTH_URL_INTERNAL", value = "http://keep-frontend:3000" },
          { name = "API_URL", value = "http://keep-backend:8080" },
          { name = "PUSHER_APP_KEY", value = "keepappkey" },
          { name = "PUSHER_HOST", value = local.keep_host },
          { name = "PUSHER_PORT", value = "80" },
        ]
      }

      websocket = {
        resources = {
          requests = { memory = "64Mi", cpu = "50m" }
          limits   = { memory = "128Mi", cpu = "100m" }
        }
        env = [
          { name = "SOKETI_HOST", value = "0.0.0.0" },
          { name = "SOKETI_DEBUG", value = "0" },
          { name = "SOKETI_USER_AUTHENTICATION_TIMEOUT", value = "3000" },
          { name = "SOKETI_DEFAULT_APP_ID", value = "1" },
          { name = "SOKETI_DEFAULT_APP_KEY", value = "keepappkey" },
          { name = "SOKETI_DEFAULT_APP_SECRET", value = "keepappsecret" },
        ]
      }
      database = {
        resources = {
          requests = { memory = "256Mi", cpu = "100m" }
          limits   = { memory = "512Mi", cpu = "300m" }
        }
        extraEnvVars = [
          { name = "MYSQL_INNODB_BUFFER_POOL_SIZE", value = "128M" }
        ]
      }
    })
  ]
}
