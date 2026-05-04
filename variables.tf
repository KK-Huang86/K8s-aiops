variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "discord_webhook_url" {
  description = "Discord webhook URL"
  type        = string
  sensitive   = true
}