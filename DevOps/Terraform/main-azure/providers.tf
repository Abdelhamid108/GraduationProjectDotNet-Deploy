terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.67.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.8.0"
    } 
   cloudflare = { 
      source = "cloudflare/cloudflare"
      version = "~> 5.0" 
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = "62dc5b60-eeb2-4c57-a565-cb1751b65a43"
  resource_provider_registrations = "none"

  storage_use_azuread             = true 
}

provider "azuread" {}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
