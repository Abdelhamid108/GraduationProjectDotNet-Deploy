variable "subscription_id" {
  description = "Your Azure Subscription ID"
  type        = string
  default     = "62dc5b60-eeb2-4c57-a565-cb1751b65a43"
}

variable "database_admin" {
  description = "The admin username for the Azure SQL Server"
  type        = string
  default     = "ema2a_admin"
}

variable "database_admin_pass" {
  description = "The admin password for the Azure SQL Server"
  type        = string
  sensitive   = true
}

variable "frontend_custom_domain" {
  description = "Your custom domain (e.g., www.ema2a.com)"
  type        = string
  default     = "test.ema2a.website"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token for DNS editing"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "The Zone ID of your domain from the Cloudflare dashboard"
  type        = string
  default     = "6203992685844830f739303f8bbc168e"
}

variable "frontend_dns_record_name" {
  description = "The subdomain part (e.g., 'www' or '@' for root)"
  type        = string
  default     = "test"
}

variable "backend_secrets_values" {
  description = "A map containing the actual values for the backend secrets"
  type        = map(string)
  sensitive   = true
}
