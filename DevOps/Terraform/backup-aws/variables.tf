variable "aws_region" {
  description = "The aws Region which Infra will be held at"
  type        = string
  default     = "us-east-1"
}

variable "subnet" {
  description = "The aws subent which Infra will be held at"
  type        = string
  default     = "us-east-1a"
}


variable "ami" {
  description = "The resultant ami from packer"
  type        = string
  default     = "ami-0c07d44e910203efc"
}

variable "instance_type" {
  description = "The instance type for the server"
  type        = string
  default     = "c7i-flex.large"
}

variable "instance_root_volume_size" {
  description = "The root volume size for the server"
  type        = number
  default     = 30
}

variable "domain_name" {
  description = "The domain name for start server apigateway"
  type        = string
  default     = "start.ema2a.website"
  
}

variable "certificate_arn" {
  description = "The apigateway domain certificate arn"
  type        = string
  default     = "arn:aws:acm:us-east-1:069089526123:certificate/b3c0ca4b-f450-47ba-b208-8b3a564f7d4b"
}

variable "cloudflare_zone_id" {
  description = "The main zone id for CloudFlare"
  type        = string 
  default     = "6203992685844830f739303f8bbc168e"
}

variable "server_dns_record_name" {
  description = "The Name for the CloudFlare main server subdomain record"
  type        = string 
  default     = "backup"
}

variable "api-gateway_dns_record_name" {
  description = "The Name for CloudFlare api-gateway subdomain record"
  type        = string 
  default     = "start"
}

variable "infisical_identity_id" {
  description = "The infisical identity id"
  type        = string 
  default     = "dd22bb8a-6524-475b-a2ad-5080da6ac999"
}

variable "account_id" {
  description = "The allowed account to use for infisical"
  type        = string
  default     = "069089526123"
}

variable "cloudflare_api_token" {
  description = "The API Token for Cloudflare"
  type        = string
  sensitive   = true 
}

variable "infisical_client_id" {
  description = "The Machine Identity Client ID for Infisical"
  type        = string
  sensitive   = true
}

variable "infisical_client_secret" {
  description = "The Machine Identity Client Secret for Infisical"
  type        = string
  sensitive   = true
}













