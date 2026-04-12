# ==============================================================================
# 0. LOCAL SECRETS MAP
# ==============================================================================
locals {
  backend_secret_map = {
    "CORRECT_SENTENCE_KEY"                 = "correct-sentence-key"
    "CORRECT_SENTENCE_BACKUP_KEY"          = "correct-sentence-backup-key"
    "GENERATE_AUDIO_KEY"                   = "generate-audio-key"
    "GENERATE_AUDIO_BACKUP_KEY"            = "generate-audio-backup-key"
    "GENERATE_TEXT_FROM_AUDIO_KEY"         = "generate-text-from-audio-key"
    "GENERATE_TEXT_FROM_AUDIO_BACKUP_KEY"  = "generate-text-from-audio-backup-key"
    "HARDWARE_CORRECT_SENTENCE_KEY"        = "hardware-correct-sentence-key"
    "HARDWARE_CORRECT_SENTENCE_BACKUP_KEY" = "hardware-correct-sentence-backup-key"
    "HARDWARE_TTS_KEY"                     = "hardware-tts-key"
    "SECRET_KEY"                           = "secret-key"
    "ISSUER"                               = "issuer"
    "GOOGLE_CLIENT_ID"                     = "google-client-id"
    "GOOGLE_CLIENT_SECRET"                 = "google-client-secret"
    "MAIL_HOST"                            = "mail-host"
    "MAIL_PORT"                            = "mail-port"
    "MAIL_USE_SSL"                         = "mail-use-ssl"
    "MAIL_NAME"                            = "mail-name"
    "MAIL_EMAIL_ID"                        = "mail-email-id"
    "MAIL_PASSWORD"                        = "mail-password"
    "MAIL_USERNAME"                        = "mail-username"
  }
}

data "azuread_client_config" "current" {}
data "azurerm_client_config" "current" {}

# ==============================================================================
# 1. CORE
# ==============================================================================
resource "azurerm_resource_group" "ema2a_rg" {
  location = "westus2"
  name     = "GraduationProject-Ema2a"
}

# ==============================================================================
# 3. STORAGE & DATABASES
# ==============================================================================
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.8"

  name                          = "ema2asgxyz1234" # Must be globally unique, no dashes
  resource_group_name           = azurerm_resource_group.ema2a_rg.name
  location                      = azurerm_resource_group.ema2a_rg.location
  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  account_kind                  = "StorageV2"
  
  shared_access_key_enabled     = true
  public_network_access_enabled = true

  network_rules = {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  containers = {
    blob_container0 = {
      name          = "ema2a-apitest-reports"
      public_access = "None"
    }
  }
}

data "azurerm_storage_account" "storage_keys" {
  name                = module.storage_account.name
  resource_group_name = azurerm_resource_group.ema2a_rg.name
  depends_on          = [module.storage_account]
}

resource "azurerm_storage_share" "images" {
  name               = "ema2a-user-images"
  storage_account_id = module.storage_account.resource_id
  quota              = 100
}

module "sql_server" {
  source  = "Azure/avm-res-sql-server/azurerm"
  version = "0.2.0"
  
  public_network_access_enabled = true
  server_version               = "12.0"

  name                         = "ema2a-sql-server-azure1234" # Must be unique
  location                     = azurerm_resource_group.ema2a_rg.location
  resource_group_name          = azurerm_resource_group.ema2a_rg.name
  administrator_login          = var.database_admin
  administrator_login_password = var.database_admin_pass

  databases = {
    ema2a_db = {
      name     = "ema2a-database"
      sku_name = "Free"
    }
  }
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  
  server_id        = module.sql_server.resource_id 

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

module "cognitive_services" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.11.0"

  # If you still get a 'Conflict/Restore' error, simply change this to "ema2a-speech-services-v2"
  name                = "ema2a-speech-services" 
  kind                = "SpeechServices"
  location            = azurerm_resource_group.ema2a_rg.location
  parent_id           = azurerm_resource_group.ema2a_rg.id
  sku_name            = "F0"
}

# ==============================================================================
# 4. SERVERLESS COMPUTE
# ==============================================================================
resource "azurerm_log_analytics_workspace" "law" {
  name                = "ema2a-law"
  location            = azurerm_resource_group.ema2a_rg.location
  resource_group_name = azurerm_resource_group.ema2a_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "container_app_environment" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.4.0"

  location                                   = azurerm_resource_group.ema2a_rg.location
  name                                       = "ema2a-env"
  resource_group_name                        = azurerm_resource_group.ema2a_rg.name
  zone_redundancy_enabled                    = false
  log_analytics_workspace_customer_id        = azurerm_log_analytics_workspace.law.workspace_id
  log_analytics_workspace_primary_shared_key = azurerm_log_analytics_workspace.law.primary_shared_key
}

resource "azurerm_container_app_environment_storage" "mount_images" {
  name                         = "images-mount"
  container_app_environment_id = module.container_app_environment.resource_id
  account_name                 = module.storage_account.name
  share_name                   = azurerm_storage_share.images.name

  access_key                   = data.azurerm_storage_account.storage_keys.primary_access_key
  access_mode                  = "ReadWrite"
}

# --- BACKEND APP ---
module "backend_app" {
  source                                = "Azure/avm-res-app-containerapp/azurerm"
  version                               = "0.8.0"
  name                                  = "ema2a-backend-app"
  resource_group_name                   = azurerm_resource_group.ema2a_rg.name
  container_app_environment_resource_id = module.container_app_environment.resource_id
  revision_mode                         = "Single"

  managed_identities = {
    system_assigned = true
  }

  secrets = {
    for env_key, azure_val in local.backend_secret_map : azure_val => {
      name  = azure_val
      value = var.backend_secrets_values[env_key]
    }
  }

  template = {
    containers = [{
      name   = "backend-container"
      image  = "docker.io/abdelhameed208/graduationproject-backend:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env = concat(
        [
          { name = "DEFAULT_CONNECTION", value = "Server=tcp:ema2a-sql-server-azure1234.database.windows.net,1433;Initial Catalog=ema2a-database;User ID=${var.database_admin};Password=${var.database_admin_pass};Encrypt=True;" },
          { name = "ASPNETCORE_URLS", value = "http://+:5001" }
        ],
        [
          for env_key, azure_val in local.backend_secret_map : {
            name        = env_key
            secret_name = azure_val
          }
        ]
      )

      volume_mounts = [{
        name = "images-volume"
        path = "/app/wwwroot/Images"
      }]
    }]
    min_replicas = 0
    max_replicas = 5

    volumes = [{
      name         = "images-volume"
      storage_name = azurerm_container_app_environment_storage.mount_images.name
      storage_type = "AzureFile"
    }]
  }

  ingress = {
    external_enabled = true
    target_port      = 5001
    traffic_weight   = [{ percentage = 100, latest_revision = true }]
  }
}

# --- FRONTEND APP ---
module "frontend_app" {
  source                                = "Azure/avm-res-app-containerapp/azurerm"
  version                               = "0.8.0"
  name                                  = "ema2a-frontend-app"
  resource_group_name                   = azurerm_resource_group.ema2a_rg.name
  container_app_environment_resource_id = module.container_app_environment.resource_id
  revision_mode                         = "Single"

  template = {
    containers = [{
      name   = "frontend-container"
      image  = "docker.io/abdelhameed208/graduationproject-frontend:v1.0-9-c6809db-azure"
      cpu    = 0.25
      memory = "0.5Gi"

      env = [{
        name  = "BACKEND_URL"
        value = "https://ema2a-backend-app.${module.container_app_environment.default_domain}"
      }]
    }]
    min_replicas = 0
    max_replicas = 5
  }

  ingress = {
    external_enabled = true
    target_port      = 8080
    traffic_weight   = [{ percentage = 100, latest_revision = true }]
  }
}

# ==============================================================================
# 5. CLOUDFLARE DNS AUTOMATION (A Record & TXT)
# ==============================================================================
resource "cloudflare_dns_record" "azure_verification" {
  zone_id = var.cloudflare_zone_id
  name    = var.frontend_dns_record_name == "@" ? "asuid" : "asuid.${var.frontend_dns_record_name}"
  type    = "TXT"
  content = module.container_app_environment.custom_domain_verification_id
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "frontend_a_record" {
  zone_id = var.cloudflare_zone_id
  name    = var.frontend_dns_record_name
  type    = "A"
  content = module.container_app_environment.static_ip_address
  ttl     = 1
  proxied = false
}

# ==============================================================================
# 6. AZURE MANAGED CERTIFICATE & DOMAIN BINDING
# ==============================================================================
resource "azurerm_container_app_custom_domain" "frontend_domain" {
  count                    = var.frontend_custom_domain != "" ? 1 : 0
  name                     = var.frontend_custom_domain
  container_app_id         = module.frontend_app.resource_id

  certificate_binding_type = "SniEnabled"

  depends_on = [
    cloudflare_dns_record.azure_verification,
    cloudflare_dns_record.frontend_a_record,
    module.frontend_app
  ]
}
