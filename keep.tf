resource "kubernetes_namespace" "keep" {
  metadata {
    name = "keep"
  }

  depends_on = [local_file.kubeconfig]
}

resource "helm_release" "keep" {
  name             = "keep"
  repository       = "https://keephq.github.io/helm-charts"
  chart            = "keep"
  namespace        = kubernetes_namespace.keep.metadata[0].name
  create_namespace = false
  timeout          = 300
  wait             = false

  values = [
    yamlencode({
      backend = {
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
            }
          ]
        }
      }

      frontend = {
        env = [
          { name = "AUTH_TYPE", value = "NO_AUTH" },
          { name = "NEXTAUTH_SECRET", value = var.keep_secret_key },
          { name = "NEXTAUTH_URL", value = "http://localhost:3000" },
          { name = "NEXTAUTH_URL_INTERNAL", value = "http://keep-frontend:3000" },
          { name = "API_URL", value = "http://keep-backend:8080" },
          { name = "PUSHER_APP_KEY", value = "keepappkey" },
          { name = "PUSHER_HOST", value = "keep-websocket" },
          { name = "PUSHER_PORT", value = "6001" },
        ]
      }

      websocket = {
        env = [
          { name = "SOKETI_HOST", value = "0.0.0.0" },
          { name = "SOKETI_DEBUG", value = "0" },
          { name = "SOKETI_USER_AUTHENTICATION_TIMEOUT", value = "3000" },
          { name = "SOKETI_DEFAULT_APP_ID", value = "1" },
          { name = "SOKETI_DEFAULT_APP_KEY", value = "keepappkey" },
          { name = "SOKETI_DEFAULT_APP_SECRET", value = "keepappsecret" },
        ]
      }
    })
  ]

  depends_on = [kubernetes_namespace.keep]
}
