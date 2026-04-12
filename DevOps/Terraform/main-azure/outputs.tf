output "FRONTEND_DEFAULT_URL" {
  description = "The auto-generated URL for your frontend"
  value       = "https://ema2a-frontend-app.${module.container_app_environment.default_domain}"
}

output "BACKEND_DEFAULT_URL" {
  description = "The auto-generated URL for your backend API"
  value       = "https://ema2a-backend-app.${module.container_app_environment.default_domain}"
}

output "DNS_CUSTOM_DOMAIN_VERIFICATION_ID" {
  description = "Use this ID to create the TXT record in your DNS provider"
  value       = module.container_app_environment.custom_domain_verification_id
  sensitive   = true
}
