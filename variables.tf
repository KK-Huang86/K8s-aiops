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

variable "keep_secret_key" {
  description = "Keep JWT secret key"
  type        = string
  sensitive   = true
}

variable "robusta_signing_key" {
  description = "Robusta signing key for cluster authentication"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Google Gemini API key for kagent"
  type        = string
  sensitive   = true
}