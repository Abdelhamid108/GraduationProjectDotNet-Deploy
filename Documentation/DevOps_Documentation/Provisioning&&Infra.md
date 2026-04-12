# Infrastructure & Provisioning Documentation — Ema2a Application

> **Project:** Ema2a Graduation Project  
> **Primary Cloud:** Microsoft Azure (Container Apps)  
> **Backup Cloud:** Amazon Web Services (EC2)  
> **IaC Tool:** Terraform  
> **Image Builder:** HashiCorp Packer  
> **Configuration Manager:** Ansible  
> **DNS Provider:** Cloudflare  
> **Secrets Manager (AWS):** Infisical

---

## Table of Contents

1. [Overall Infrastructure Architecture](#1-overall-infrastructure-architecture)
2. [Azure Infrastructure — Terraform (`main-azure/`)](#2-azure-infrastructure--terraform)
   - [providers.tf](#21-providerstf)
   - [variables.tf](#22-variablestf)
   - [main.tf](#23-maintf)
   - [outputs.tf](#24-outputstf)
3. [AWS Backup Infrastructure — Terraform (`backup-aws/`)](#3-aws-backup-infrastructure--terraform)
   - [providers.tf (inline)](#31-providers-embedded-in-maintf)
   - [variables.tf](#32-variablestf)
   - [main.tf](#33-maintf)
   - [Lambda Function (`lambda_src/index.py`)](#34-lambda-function)
4. [VM Image Building — Packer (`ema2a.pkr.hcl`)](#4-vm-image-building--packer)
5. [Server Configuration — Ansible](#5-server-configuration--ansible)
   - [site.yml — Master Playbook](#51-siteyml--master-playbook)
   - [Role: `initialization`](#52-role-initialization)
   - [Role: `Docker_installation`](#53-role-docker_installation)
   - [Role: `github_actions_ssh_setup`](#54-role-github_actions_ssh_setup)
   - [Role: `deploy`](#55-role-deploy)
   - [Systemd Service Template](#56-systemd-service-template-ema2a-appservicejinja2)
6. [Azure vs AWS — Architecture Comparison](#6-azure-vs-aws--architecture-comparison)
7. [End-to-End Provisioning Flow](#7-end-to-end-provisioning-flow)
8. [Required Credentials & Secrets](#8-required-credentials--secrets)
9. [Dependabot — Automated Dependency Updates](#9-dependabot--automated-dependency-updates)

---

## 1. Overall Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  AZURE (Primary — Serverless Container Apps)                            │
│                                                                         │
│  Cloudflare DNS ──► Container App Environment (ema2a-env)              │
│                          │                                              │
│         ┌────────────────┴──────────────────┐                          │
│         │                                   │                          │
│  ema2a-frontend-app                ema2a-backend-app                   │
│  (nginx + React SPA)               (.NET 8 API + ONNX)                 │
│  Port 8080, 0–5 replicas           Port 5001, 0–5 replicas             │
│         │                                   │                          │
│         └─────────┐       ┌─────────────────┘                          │
│                   │       │                                             │
│          Azure SQL Server (ema2a-sql-server-azure1234)                 │
│          Database: ema2a-database (Free tier)                          │
│                                                                         │
│  Storage Account (ema2a-sgxyz1234)                                     │
│  ├── Blob Container: ema2a-apitest-reports (CI Test Artifacts)         │
│  └── File Share: ema2a-user-images (Mounted to backend /wwwroot)       │
│                                                                         │
│  Azure Speech Services (ema2a-speech-services)                         │
│  Log Analytics Workspace (ema2a-law)                                   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  AWS (Backup — Single EC2 + Lambda Wake-on-Request)                     │
│                                                                         │
│  Cloudflare DNS ──► backup.ema2a.website (A record, proxied)           │
│                          │                                              │
│                  EC2 Instance (c7i-flex.large, us-east-1)              │
│                  Custom AMI (built by Packer + Ansible)                 │
│                  Security Group: 22, 80, 443, 8080                     │
│                  Elastic IP (persistent public IP)                      │
│                  IAM Role → Infisical AWS Auth                          │
│                          │                                              │
│                   Docker Compose Stack                                  │
│                   (started by systemd service on boot)                  │
│                                                                         │
│  Lambda Function (ema2a-lambda) ◄──── API Gateway (ema2a-api-gateway) │
│  start.ema2a.website                                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ GET /  → check instance state → start if stopped               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  CloudWatch Alarm: CPU < 2% for 15m → stop EC2 (cost saving)           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Azure Infrastructure — Terraform

**Directory:** `DevOps/Terraform/main-azure/`

The Azure Terraform configuration provisions a fully serverless, auto-scaled application stack using Azure Container Apps with Cloudflare DNS and managed TLS certificates.

### 2.1 `providers.tf`

**Purpose:** Declares provider versions and configures authentication for Azure, Azure AD, and Cloudflare.

```hcl
terraform {
  required_providers {
    azurerm  = { source = "hashicorp/azurerm",  version = "4.67.0" }
    azuread  = { source = "hashicorp/azuread",  version = "3.8.0"  }
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id                  = "62dc5b60-eeb2-4c57-a565-cb1751b65a43"
  resource_provider_registrations  = "none"
  storage_use_azuread              = true   # Use Entra ID (AAD) for storage ops
}

provider "azuread" {}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
```

| Provider | Version | Purpose |
|----------|---------|---------|
| `azurerm` | 4.67.0 | Azure Resource Manager (ARM) resources |
| `azuread` | 3.8.0 | Azure Active Directory / Entra ID lookups |
| `cloudflare` | ~5.0 | DNS record automation |

**Key Setting:** `resource_provider_registrations = "none"` — disables automatic resource provider registration, which requires the Terraform service principal to have `Microsoft.Authorization/*/write` on the subscription. This is a common permission-scoping best practice.

**Key Setting:** `storage_use_azuread = true` — uses Azure Active Directory tokens instead of storage account keys for blob operations within Terraform, which is required for user-delegation SAS token generation used in the CI pipeline.

### 2.2 `variables.tf`

| Variable | Type | Default | Sensitive | Description |
|----------|------|---------|-----------|-------------|
| `subscription_id` | string | `62dc5b60-…` | No | Azure subscription |
| `database_admin` | string | `ema2a_admin` | No | SQL Server admin login |
| `database_admin_pass` | string | — | **Yes** | SQL Server admin password |
| `frontend_custom_domain` | string | `test.ema2a.website` | No | Custom domain for frontend |
| `cloudflare_api_token` | string | — | **Yes** | Cloudflare DNS API token |
| `cloudflare_zone_id` | string | `6203992…` | No | Cloudflare DNS zone |
| `frontend_dns_record_name` | string | `test` | No | Subdomain prefix (A record) |
| `backend_secrets_values` | map(string) | — | **Yes** | Map of all backend secret values |

### 2.3 `main.tf`

The main configuration is organised into six logical sections:

#### Section 0 — Local Secrets Map

```hcl
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
```

This map drives the `for` expression that creates Container Apps secrets. The **key** is the environment variable name inside the container; the **value** is the Azure Container Apps secret name. Using a `locals` map eliminates duplication between the `secrets` block and the `env` block in the container template.

#### Section 1 — Core Resource Group

```hcl
resource "azurerm_resource_group" "ema2a_rg" {
  location = "westus2"
  name     = "GraduationProject-Ema2a"
}
```

All resources are co-located in the `westus2` region inside the `GraduationProject-Ema2a` resource group.

#### Section 3 — Storage & Databases

**Storage Account** (`Azure/avm-res-storage-storageaccount` v0.6.8):
- **Name:** `ema2asgxyz1234` (globally unique, no dashes)
- **Replication:** LRS (Locally Redundant Storage) — cost-effective for a dev/graduation project
- **Tier:** Standard StorageV2
- **Blob Container:** `ema2a-apitest-reports` — stores CI pipeline test report JSON files uploaded by the `test` job
- **File Share:** `ema2a-user-images` (100 GB quota) — mounted as an Azure Files volume into the backend Container App at `/app/wwwroot/Images`

**Azure SQL Server** (`Azure/avm-res-sql-server` v0.2.0):
- **Name:** `ema2a-sql-server-azure1234`
- **Version:** 12.0 (SQL Server 2019+)
- **Database:** `ema2a-database`, SKU `Free` (development tier)
- **Firewall Rule:** `AllowAzureServices` — IP range `0.0.0.0–0.0.0.0` allows all Azure-internal services (including Container Apps) to connect without whitelisting individual IPs

**Azure Cognitive Services** (`Azure/avm-res-cognitiveservices-account` v0.11.0):
- **Name:** `ema2a-speech-services`
- **Kind:** `SpeechServices` — Azure AI Speech API for TTS/STT
- **SKU:** `F0` (free tier)

#### Section 4 — Serverless Compute (Azure Container Apps)

**Log Analytics Workspace:**
```hcl
resource "azurerm_log_analytics_workspace" "law" {
  name              = "ema2a-law"
  sku               = "PerGB2018"
  retention_in_days = 30
}
```
All Container Apps logs stream to this workspace for centralised observability.

**Container App Environment** (`Azure/avm-res-app-managedenvironment` v0.4.0):
- **Name:** `ema2a-env`
- Shared Kubernetes-based runtime for all Container Apps
- Connected to the Log Analytics workspace
- `zone_redundancy_enabled = false` (single zone, cost-saving for graduation project)
- Provides an auto-generated `default_domain` used for internal service-to-service URLs

**Storage Mount:**
```hcl
resource "azurerm_container_app_environment_storage" "mount_images" {
  name                         = "images-mount"
  container_app_environment_id = module.container_app_environment.resource_id
  account_name                 = module.storage_account.name
  share_name                   = azurerm_storage_share.images.name
  access_key                   = data.azurerm_storage_account.storage_keys.primary_access_key
  access_mode                  = "ReadWrite"
}
```
This creates an Azure Files volume accessible to Container Apps within the environment.

**Backend Container App** (`Azure/avm-res-app-containerapp` v0.8.0):

| Property | Value |
|----------|-------|
| Name | `ema2a-backend-app` |
| Image | `docker.io/abdelhameed208/graduationproject-backend:latest` |
| CPU | 0.25 vCPU |
| Memory | 0.5 Gi |
| Min Replicas | **0** (scale to zero when idle) |
| Max Replicas | 5 |
| Ingress Target Port | 5001 |
| External Ingress | Yes |
| Identity | System-assigned Managed Identity |

Secrets are injected from the `backend_secret_map` locals using a `for` expression — each secret is stored as a Container Apps secret and referenced by name in the container environment:

```hcl
secrets = {
  for env_key, azure_val in local.backend_secret_map : azure_val => {
    name  = azure_val
    value = var.backend_secrets_values[env_key]
  }
}
```

The volume mount for user images:
```hcl
volume_mounts = [{
  name = "images-volume"
  path = "/app/wwwroot/Images"   # ASP.NET Core static files path
}]
```

**Frontend Container App:**

| Property | Value |
|----------|-------|
| Name | `ema2a-frontend-app` |
| Image | `docker.io/abdelhameed208/graduationproject-frontend:v1.0-9-c6809db-azure` |
| CPU | 0.25 vCPU |
| Memory | 0.5 Gi |
| Min Replicas | **0** (scale to zero) |
| Max Replicas | 5 |
| Ingress Target Port | 8080 |
| External Ingress | Yes |

The `BACKEND_URL` environment variable is set to the backend's internal Container Apps URL:
```hcl
env = [{
  name  = "BACKEND_URL"
  value = "https://ema2a-backend-app.${module.container_app_environment.default_domain}"
}]
```
This is picked up by `envsubst` in the Nginx template at container startup, dynamically setting the reverse proxy target.

#### Section 5 — Cloudflare DNS Automation

Two DNS records are created automatically by Terraform:

| Record Type | Name | Value |
|-------------|------|-------|
| TXT | `asuid.test` | Azure domain verification ID (for managed cert) |
| A | `test` | Static IP of the Container App Environment |

```hcl
resource "cloudflare_dns_record" "azure_verification" {
  name    = "asuid.${var.frontend_dns_record_name}"
  type    = "TXT"
  content = module.container_app_environment.custom_domain_verification_id
}

resource "cloudflare_dns_record" "frontend_a_record" {
  name    = var.frontend_dns_record_name
  type    = "A"
  content = module.container_app_environment.static_ip_address
}
```

#### Section 6 — Managed Certificate & Domain Binding

```hcl
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
```

Azure provisions and automatically renews a TLS certificate for the custom domain. The `depends_on` block ensures the DNS verification TXT record and A record exist before Azure attempts domain validation.

### 2.4 `outputs.tf`

| Output | Sensitive | Value |
|--------|-----------|-------|
| `FRONTEND_DEFAULT_URL` | No | Auto-generated FQDN of the frontend Container App |
| `BACKEND_DEFAULT_URL` | No | Auto-generated FQDN of the backend Container App |
| `DNS_CUSTOM_DOMAIN_VERIFICATION_ID` | **Yes** | TXT record content for DNS verification |

---

## 3. AWS Backup Infrastructure — Terraform

**Directory:** `DevOps/Terraform/backup-aws/`

The AWS configuration provisions a low-cost, auto-stopping EC2 backup server with a serverless wake-on-request mechanism via API Gateway and Lambda.

### 3.1 Providers (embedded in `main.tf`)

| Provider | Source | Version | Purpose |
|----------|--------|---------|---------|
| `aws` | `hashicorp/aws` | ~6.0 | EC2, Lambda, API Gateway, CloudWatch, IAM |
| `cloudflare` | `cloudflare/cloudflare` | ~5.0 | DNS record automation |
| `infisical` | `infisical/infisical` | latest | Secrets manager authentication binding |

```hcl
provider "aws" {
  region = var.aws_region   # default: us-east-1
}

provider "infisical" {
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}
```

### 3.2 `variables.tf`

| Variable | Default | Sensitive | Description |
|----------|---------|-----------|-------------|
| `aws_region` | `us-east-1` | No | Target AWS region |
| `ami` | `ami-0c07d44e910203efc` | No | Fallback AMI ID (Packer-built AMI is auto-discovered) |
| `instance_type` | `c7i-flex.large` | No | EC2 instance type |
| `instance_root_volume_size` | `30` | No | Root EBS volume size in GB |
| `domain_name` | `start.ema2a.website` | No | API Gateway custom domain |
| `certificate_arn` | `arn:aws:acm:us-east-1:…` | No | ACM certificate ARN for API Gateway domain |
| `cloudflare_zone_id` | `6203992…` | No | Cloudflare zone ID (shared with Azure) |
| `server_dns_record_name` | `backup` | No | Server subdomain (⇒ `backup.ema2a.website`) |
| `infisical_identity_id` | `dd22bb8a-…` | No | Infisical machine identity ID |
| `infisical_allowed_account_id` | `863030157396` | No | AWS account ID for Infisical IAM auth |
| `cloudflare_api_token` | — | **Yes** | Cloudflare API token |
| `infisical_client_id` | — | **Yes** | Infisical machine identity client ID |
| `infisical_client_secret` | — | **Yes** | Infisical machine identity client secret |

### 3.3 `main.tf`

#### Data Sources

```hcl
# Use the default VPC and its subnets (no custom VPC required)
data "aws_vpc"     "default" { default = true }
data "aws_subnets" "default" { filter { name = "vpc-id" } }

# Auto-discover the most recent Packer-built AMI by tag filter
data "aws_ami" "ema2a_ami" {
  owners = ["self"]
  filter { name = "tag:Project",   values = ["ema2a"]      }
  filter { name = "tag:Component", values = ["server-ami"] }
}
```

The AMI data source automatically uses the latest Packer-built image by filtering on tags — no hardcoded AMI IDs needed after initial build.

#### SSH Key Pair

```hcl
resource "aws_key_pair" "devops_ema2a" {
  key_name   = "ema2a_ssh_key"
  public_key = file("~/.ssh/ema2a.pub")
}
```

Reads the operator's local public key and registers it in AWS for SSH access during maintenance.

#### IAM Role & Instance Profile

```hcl
module "iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"
  name   = "ema2a-instance-profile"
  create_instance_profile = true
  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions    = ["sts:AssumeRole", "sts:TagSession"]
      principals = [{ type = "Service", identifiers = ["ec2.amazonaws.com"] }]
    }
  }
}
```

Creates an IAM role that EC2 can assume. This role is linked to Infisical's AWS IAM authentication, allowing the EC2 instance to fetch secrets from Infisical without storing any credentials on disk.

#### EC2 Instance

```hcl
module "ec2_instance" {
  source        = "terraform-aws-modules/ec2-instance/aws"
  ami           = data.aws_ami.ema2a_ami.id
  instance_type = var.instance_type           # c7i-flex.large
  name          = "ema2a-backup-deployment-server"

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  create_eip                  = true           # Persistent Elastic IP
  iam_instance_profile        = module.iam_role.instance_profile_name
  key_name                    = aws_key_pair.devops_ema2a.key_name
  monitoring                  = true           # CloudWatch detailed monitoring
  vpc_security_group_ids      = [aws_security_group.ema2a_sg.id]

  root_block_device = { size = 30 }            # 30 GB root volume
}
```

| Property | Value | Reason |
|----------|-------|--------|
| Instance type | `c7i-flex.large` | Compute-optimised; flexible pricing |
| Elastic IP | Yes | DNS record stays stable across stop/start cycles |
| Root volume | 30 GB | Accommodates Docker images and app data |
| Detailed monitoring | Yes | Feeds the auto-stop CloudWatch alarm |

#### CloudWatch Auto-Stop Alarm

```hcl
module "alarm_metric_query" {
  alarm_name          = "auto stop ec2"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  threshold           = 2
  metric_name         = "CPUUtilization"
  period              = 300
  statistic           = "Average"
  dimensions          = { InstanceId = module.ec2_instance.id }
  alarm_actions       = ["arn:aws:automate:us-east-1:ec2:stop"]
}
```

**Logic:** If CPU utilisation is below **2%** for **3 consecutive 5-minute periods** (15 minutes total), the alarm automatically stops the EC2 instance. This dramatically reduces costs when the backup server is idle.

#### Security Group

| Rule | Protocol | Ports | Source | Purpose |
|------|----------|-------|--------|---------|
| `allow_http` | TCP | 80 | 0.0.0.0/0 | HTTP traffic |
| `allow_https` | TCP | 443 | 0.0.0.0/0 | HTTPS/TLS traffic |
| `allow_jenkins` | TCP | 8080 | 0.0.0.0/0 | Jenkins / alternative web |
| `allow_ssh` | TCP | 22 | 0.0.0.0/0 | SSH access (⚠ restrict in prod) |
| `allow_all_outbound` | All | All | 0.0.0.0/0 | Unrestricted egress |

> **Note:** The SSH rule allows `0.0.0.0/0`. The Terraform code itself flags this as a security risk and recommends restricting to a known IP.

#### IAM Policy — Lambda EC2 Control

```json
{
  "Statement": [
    { "Effect": "Allow", "Action": ["ec2:StartInstances", "ec2:StopInstances"],
      "Resource": "<ec2-instance-arn>" },
    { "Effect": "Allow", "Action": "ec2:DescribeInstances", "Resource": "*" }
  ]
}
```

This scoped policy restricts the Lambda function to only start/stop the specific backup EC2 instance — not any other resources.

#### Lambda Function

```hcl
module "lambda_function" {
  source        = "terraform-aws-modules/lambda/aws"
  function_name = "ema2a-lambda"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  source_path   = "./lambda_src"
  publish       = true
  attach_policy = true
  policy        = module.iam_policy.arn
  environment_variables = {
    INSTANCE_ID = module.ec2_instance.id
  }
}
```

#### API Gateway

```hcl
module "api_gateway" {
  source        = "terraform-aws-modules/apigateway-v2/aws"
  name          = "ema2a-api-gateway"
  protocol_type = "HTTP"
  domain_name   = var.domain_name             # start.ema2a.website
  domain_name_certificate_arn = var.certificate_arn

  routes = {
    "GET /" = {
      integration = {
        uri                    = module.lambda_function.lambda_function_arn
        payload_format_version = "2.0"
      }
    }
  }
}
```

A simple HTTP API Gateway with a single `GET /` route that invokes the Lambda. The custom domain `start.ema2a.website` (with ACM certificate) is mapped to this gateway.

#### Cloudflare DNS Records (AWS)

| Type | Name | Content | Proxied |
|------|------|---------|---------|
| A | `backup` | EC2 Elastic IP | Yes (Cloudflare proxy) |
| CNAME | `start` | API Gateway domain target | No (DNS-only) |

#### Infisical AWS IAM Authentication

```hcl
resource "infisical_identity_aws_auth" "aws-auth" {
  identity_id            = var.infisical_identity_id
  sts_endpoint           = "https://sts.us-east-1.amazonaws.com/"
  allowed_account_ids    = [var.infisical_allowed_account_id]
  allowed_principal_arns = [module.iam_role.arn]
  access_token_ttl       = 2592000   # 30 days
}
```

Configures Infisical to trust the EC2 instance's IAM role for secret retrieval. At runtime, the EC2 instance calls AWS STS to get a token, then exchanges it with Infisical for an API access token — no static credentials are stored.

### 3.4 Lambda Function

**File:** `DevOps/Terraform/backup-aws/lambda_src/index.py`  
**Runtime:** Python 3.12

**Purpose:** Provides a serverless HTTP endpoint to start the backup EC2 instance on-demand. When users need the backup deployment, they hit `https://start.ema2a.website` to wake the server.

```python
import boto3, os

REGION      = os.environ.get('REGION', 'us-east-1')
INSTANCE_ID = os.environ.get('INSTANCE_ID')

ec2 = boto3.client('ec2', region_name=REGION)

def lambda_handler(event, context):
    if not INSTANCE_ID:
        return {'statusCode': 400, 'body': 'INSTANCE_ID environment variable is missing'}
    
    response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
    state    = response['Reservations'][0]['Instances'][0]['State']['Name']
    
    if state == 'running':
        return {'statusCode': 200, 'body': f'Instance {INSTANCE_ID} is already running.'}
    elif state == 'stopped':
        ec2.start_instances(InstanceIds=[INSTANCE_ID])
        return {'statusCode': 200, 'body': f'Instance {INSTANCE_ID} was stopped and is now starting.'}
    else:
        # Handles 'pending', 'stopping' transition states
        return {'statusCode': 200, 'body': f'Instance is currently in "{state}" state. Please wait.'}
```

**Flow:**
1. Describe the instance state via `ec2:DescribeInstances`
2. If **running** → return 200, do nothing
3. If **stopped** → call `ec2:StartInstances`, return 200
4. If **transitioning** → return 200 with state message (idempotent)

---

## 4. VM Image Building — Packer

**File:** `DevOps/packer-ansible/ema2a.pkr.hcl`

### Purpose

Builds a pre-baked Amazon Machine Image (AMI) for the AWS backup deployment server. The AMI has Docker, the GitHub Actions deploy user, and the application systemd service pre-installed — so when Terraform provisions the EC2 instance from this image, the application starts automatically on boot.

### Packer Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ami-prefix` | `ema2a-backup-deployment-instance` | Prefix for the AMI name |
| `instance-type` | `c7i-flex.large` | EC2 instance type used during the build |
| `region` | `us-east-1` | Target AWS region |
| `ssh-user` | `ec2-user` | SSH user for the base Amazon Linux 2023 image |
| `base-ami` | `al2023-ami-2023.*-x86_64` | Pattern to find the latest Amazon Linux 2023 AMI |

### Source Block — `amazon-ebs`

```hcl
source "amazon-ebs" "ema2a" {
  ami_name      = "${var.ami-prefix}-{{timestamp}}"    # Unique name per build
  instance_type = var.instance-type
  region        = var.region

  tags = {
    Project   = "ema2a"
    Component = "server-ami"
  }

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["137112412989"]    # AWS official Amazon Linux owner ID
  }

  ssh_username = "ec2-user"
}
```

The `{{timestamp}}` in `ami_name` ensures each build produces a unique AMI name, preventing conflicts with previous builds.

### Build Block — Three Provisioners

```
[1] Shell → Wait for cloud-init
     ↓
[2] Ansible → Full server configuration (4 playbooks)
     ↓
[3] Shell → Clean YUM cache to reduce AMI size
```

**Provisioner 1 — Cloud-Init Wait:**
```bash
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 2; done
```
Ensures the base instance is fully initialised before Ansible runs, preventing package manager lock conflicts.

**Provisioner 2 — Ansible:**
```hcl
provisioner "ansible" {
  playbook_file = "./Ansible/site.yml"
  user          = var.ssh-user
  extra_arguments = [
    "--scp-extra-args", "'-O'",
    "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa"
  ]
}
```
The SSH extra arguments are required to work with Packer's auto-generated ephemeral SSH key pair, which uses the older RSA algorithm format.

**Provisioner 3 — Cleanup:**
```bash
sudo yum clean all && sudo rm -rf /var/cache/yum
```
Removes YUM package cache to reduce the final AMI size.

### Build Commands

```bash
# Navigate to the packer directory
cd DevOps/packer-ansible

# Initialize — downloads the amazon and ansible plugins
packer init ema2a.pkr.hcl

# Validate the configuration
packer validate ema2a.pkr.hcl

# Build the AMI (requires AWS credentials in environment or ~/.aws)
packer build ema2a.pkr.hcl

# Build with a custom prefix
packer build -var 'ami-prefix=ema2a-v2' ema2a.pkr.hcl
```

---

## 5. Server Configuration — Ansible

**Directory:** `DevOps/packer-ansible/Ansible/`

The Ansible project uses a **role-based** architecture, with a clear separation of concerns across four roles. All roles are composable and executed in the correct order by `site.yml`.

### 5.1 `site.yml` — Master Playbook

```yaml
---
- name: setup agents
  hosts: all
  become: true
  gather_facts: yes

- import_playbook: ./playbooks/initialization.yml
- import_playbook: ./playbooks/docker_installation.yml
- import_playbook: ./playbooks/gha-setup.yml
- import_playbook: ./playbooks/deploy.yml
```

**Execution order is critical:**
1. `initialization.yml` — system packages must be installed first
2. `docker_installation.yml` — Docker must exist before deploy user is added to docker group
3. `gha-setup.yml` — `github` user must be created before deploy role chowns files to them
4. `deploy.yml` — final application setup

### 5.2 Role: `initialization`

**Playbook:** `playbooks/initialization.yml` → **Role:** `roles/initialization`

**Purpose:** Bootstraps the system with required packages.

**Tasks (`roles/initialization/tasks/main.yml`):**

```yaml
# Update apt cache (Ubuntu/Debian only)
- name: update cache
  apt:
    update_cache: yes
  when: ansible_os_family == "Debian"
  changed_when: false

# Add Infisical package repository (via install script)
- name: Add Infisical repository
  shell:
    cmd: curl -1sLf 'https://artifacts-cli.infisical.com/setup.rpm.sh' | sudo -E bash

# Install common system tools
- name: install important needed packages
  package:
    name:
      - vim
      - git
      - acl            # Access Control Lists for fine-grained permissions
      - python3-pip
      - infisical      # Secrets manager CLI
    state: present
```

**Installed Packages:**

| Package | Purpose |
|---------|---------|
| `vim` | Text editor for server-side config edits |
| `git` | Required by the deploy role to clone the repository |
| `acl` | ACL utilities needed for Ansible to set file permissions correctly |
| `python3-pip` | Python package manager (for Ansible modules) |
| `infisical` | CLI for fetching secrets at runtime in the systemd service |

### 5.3 Role: `Docker_installation`

**Playbook:** `playbooks/docker_installation.yml` → **Role:** `roles/Docker_installation`

**Purpose:** Installs Docker CE on both Debian/Ubuntu and RedHat/Amazon Linux systems (dual-OS support).

**Tasks breakdown:**

```yaml
# 1. Check if Docker already exists (idempotent guard)
- name: check docker is installed
  command: which docker
  register: docker_check
  ignore_errors: true

# 2-4. Debian/Ubuntu path — add GPG key and apt repository
- name: install docker dependencies (Debian only)
  apt: { name: [curl, ca-certificates, gnupg] }
  when: docker_check.failed and ansible_os_family == "Debian"

- name: Create GPG keyrings directory
  file: { path: /etc/apt/keyrings, mode: '0755' }
  when: docker_check.rc != 0 and ansible_os_family == "Debian"

- name: Download Docker GPG key
  get_url:
    url: https://download.docker.com/linux/{{ ansible_distribution | lower }}/gpg
    dest: /etc/apt/keyrings/docker.asc
    mode: 'a+r'

- name: Add Docker apt repository
  apt_repository:
    repo: "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/{{ ansible_distribution | lower }} {{ ansible_distribution_release }} stable"

# 5-6. RedHat/Amazon Linux path — yum repository
- name: add Docker yum repository
  yum_repository:
    name: docker-ce-stable
    baseurl: https://download.docker.com/linux/rhel/9/$basearch/stable/
    gpgkey: https://download.docker.com/linux/rhel/gpg
  when: ansible_os_family == "RedHat" and docker_check.rc != 0

- name: Clean and rebuild DNF cache
  dnf: { name: '*', update_cache: yes }
  when: ansible_os_family == "RedHat"

# 7. Install Docker packages (both OS families)
- name: install docker engine
  package:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin      # Installs `docker compose` (v2) plugin
    state: present
  notify: start_enable_docker       # Triggers the handler below

# 8. Add ansible user to docker group (no sudo required)
- name: add ansible user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes
```

**Handler (`roles/Docker_installation/handlers/main.yml`):**
```yaml
- name: start_enable_docker
  service:
    name: docker
    state: started
    enabled: yes        # Auto-starts on system reboot
```

### 5.4 Role: `github_actions_ssh_setup`

**Playbook:** `playbooks/gha-setup.yml` → **Role:** `roles/github_actions_ssh_setup`

**Purpose:** Creates a dedicated `github` user for GitHub Actions SSH deployments and configures key-based authentication.

```yaml
# Create a dedicated CI/CD user
- name: Create GitHub Actions user
  user:
    name: github
    comment: "Github actions (CI/CD) User"
    create_home: yes
    groups: docker     # Must be in docker group to run docker compose
    state: present
    append: yes

# Install the GitHub Actions SSH public key
- name: Add GitHub Actions SSH key
  ansible.posix.authorized_key:
    user: github
    key: "{{ lookup('file', '../files/ema2a-github-actions-key.pub') }}"
```

**Key Design Decisions:**
- The `github` user is **in the `docker` group** — this is essential so the GitHub Actions runner can execute `docker compose` commands without `sudo`.
- The SSH public key is sourced from `roles/github_actions_ssh_setup/files/ema2a-github-actions-key.pub` — the corresponding private key must be stored as a GitHub Actions secret (`SSH_PRIVATE_KEY`).

### 5.5 Role: `deploy`

**Playbook:** `playbooks/deploy.yml` → **Role:** `roles/deploy`

**Purpose:** Clones the application repository, sets file ownership, deploys the systemd service, and enables it to start on boot.

```yaml
# Clone the app repo from GitHub to /opt/ema2a-app
- name: pull the repo
  ansible.builtin.git:
    repo: 'https://github.com/Abdelhamid108/GraduationProjectDotNet-Deploy.git'
    dest: /opt/ema2a-app
    clone: yes
    version: DEV
    single_branch: yes

# Transfer ownership to the github CI/CD user
- name: Hand over ownership to the github user
  file:
    path: /opt/ema2a-app
    owner: github
    group: github
    recurse: yes

# Deploy the systemd service from Jinja2 template
- name: transfer systemd file
  template:
    src: files/ema2a-app.serivce.j2
    dest: /etc/systemd/system/ema2a-app.service
    owner: root
    group: root
    mode: '0644'
  vars:
    infisical_identity_id: "dd22bb8a-6524-475b-a2ad-5080da6ac999"
    infisical_project_id:  "8289c0bc-5bf9-458d-b86d-3d16276fed55"

# Enable the service to run on system boot
- name: enable the application service
  systemd:
    name: ema2a-app.service
    enabled: yes
    daemon_reload: yes
```

### 5.6 Systemd Service Template (`ema2a-app.service.j2`)

**File:** `roles/deploy/files/ema2a-app.serivce.j2`

This Jinja2 template produces the systemd unit file that manages the application lifecycle on the EC2 instance.

```ini
[Unit]
Description=Ema2a Backup Deployment app
After=docker.service network-online.target
Requires=docker.service

[Service]
WorkingDirectory=/opt/ema2a-app

Type=oneshot
RemainAfterExit=yes       # Service stays "active" after the oneshot completes

Restart=on-failure
RestartSec=5
StartLimitBurst=3
StartLimitIntervalSec=60

User=github
Group=github

# Step 1: Fetch secrets from Infisical using AWS IAM auth, write to .env
ExecStartPre=/bin/bash -c 'TOKEN=$(infisical login \
  --method=aws-iam \
  --machine-identity-id="{{ infisical_identity_id }}" \
  --silent --plain); \
  infisical export \
  --token="$TOKEN" \
  --projectId="{{ infisical_project_id }}" \
  --env=prod \
  --path=/ema2a \
  --format=dotenv > .env'

# Step 2: Pull latest images and start; remove .env after startup (security)
ExecStart=/bin/bash -c '/usr/bin/docker compose -f docker-compose.yml up -d --pull always && rm -f .env'

# Graceful shutdown
ExecStop=/usr/bin/docker compose -f docker-compose.yml down

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
MemoryMax=2500M

[Install]
WantedBy=multi-user.target
```

**Security Features:**
- `NoNewPrivileges=true` — prevents privilege escalation
- `PrivateTmp=true` — private `/tmp` directory
- `ProtectSystem=full` — read-only `/usr` and `/boot`
- `.env` is **deleted immediately after startup** — secrets never persist on disk longer than necessary
- `MemoryMax=2500M` — hard memory cap for the entire service

**Secret Fetching Flow:**
1. `infisical login --method=aws-iam` — authenticates using the EC2 instance's IAM role (no stored credentials)
2. `infisical export` — fetches all secrets from the `ema2a` path in the `prod` environment and writes them to `.env`
3. `docker compose up` reads `.env` and starts the stack
4. `rm -f .env` removes the secrets file from disk

---

## 6. Azure vs AWS — Architecture Comparison

| Dimension | Azure (Primary) | AWS (Backup) |
|-----------|-----------------|--------------|
| **Compute model** | Serverless Container Apps (Kubernetes-based) | Single EC2 VM (`c7i-flex.large`) |
| **Scaling** | 0–5 replicas auto-scaled | Manual (single instance) |
| **Cost optimization** | Scale-to-zero (0 min replicas) | Auto-stop via CloudWatch alarm + on-demand Lambda wake |
| **Database** | Azure SQL (managed PaaS) | MS SQL Server in Docker container |
| **TLS** | Azure Managed Certificates | Self-managed / Let's Encrypt |
| **Secrets** | Azure Container Apps secrets (Terraform-managed) | Infisical (pulled at boot via AWS IAM auth) |
| **Deployment trigger** | GitHub Actions → `Azure/container-apps-deploy-action` | GitHub Actions → SSH → `docker compose pull && up` |
| **DNS** | Cloudflare A record → Container App static IP | Cloudflare A record (proxied) → EC2 Elastic IP |
| **Image provisioning** | Not required (Container Apps pull from Docker Hub) | Packer + Ansible bakes AMI with Docker pre-installed |
| **Storage** | Azure Files (managed) | Docker volume on EBS |
| **Observability** | Log Analytics Workspace | CloudWatch (basic) |
| **IaC** | Terraform (AVM modules) | Terraform (community modules) |

---

## 7. End-to-End Provisioning Flow

### Azure (Primary) — First-Time Setup

```
1. terraform init          # Download providers: azurerm, azuread, cloudflare
2. terraform plan          # Review resources to be created
3. terraform apply         # Provision:
   ├── Resource Group (GraduationProject-Ema2a)
   ├── Storage Account + Blob Container + File Share
   ├── Azure SQL Server + Database + Firewall Rule
   ├── Azure Cognitive Services (Speech)
   ├── Log Analytics Workspace
   ├── Container App Environment
   ├── Container App Environment Storage (images mount)
   ├── Backend Container App (with secrets + volume)
   ├── Frontend Container App
   ├── Cloudflare TXT record (domain verification)
   ├── Cloudflare A record (frontend domain)
   └── Azure Managed Certificate + Custom Domain Binding
4. Open outputs:
   - FRONTEND_DEFAULT_URL  → test application
   - BACKEND_DEFAULT_URL   → validate API
```

### AWS (Backup) — First-Time Setup

```
Step A: Build AMI with Packer
─────────────────────────────
1. cd DevOps/packer-ansible
2. packer init ema2a.pkr.hcl
3. packer build ema2a.pkr.hcl
   └── Packer provisions temporary EC2 → runs Ansible:
       ├── initialization    (packages + infisical CLI)
       ├── docker_installation (Docker CE + Compose)
       ├── gha-setup         (github user + SSH key)
       └── deploy            (clone repo + systemd service)
   └── Packer snapshots the instance → publishes AMI with tags

Step B: Provision Infrastructure with Terraform
───────────────────────────────────────────────
4. cd DevOps/Terraform/backup-aws
5. terraform init
6. terraform apply
   ├── SSH Key Pair
   ├── IAM Role + Instance Profile
   ├── Security Group (22, 80, 443, 8080)
   ├── EC2 Instance (using Packer AMI, with Elastic IP)
   ├── CloudWatch Auto-Stop Alarm (CPU < 2% for 15 min)
   ├── IAM Policy (Lambda: StartInstances, StopInstances)
   ├── Lambda Function (ema2a-lambda in Python 3.12)
   ├── API Gateway (ema2a-api-gateway, HTTP, GET /)
   ├── Cloudflare A record (backup.ema2a.website → EIP)
   ├── Cloudflare CNAME (start → API Gateway domain)
   └── Infisical AWS IAM auth binding

Step C: Runtime (on EC2 boot)
──────────────────────────────
7. systemd starts ema2a-app.service
8. ExecStartPre: Authenticates with Infisical via AWS IAM
9. ExecStartPre: Fetches secrets → writes to .env
10. ExecStart: docker compose up -d --pull always
11. ExecStart: rm -f .env (clean up secrets)
12. Application is live at https://backup.ema2a.website
```

---

## 8. Required Credentials & Secrets

> ⚠️ **Never commit actual secret values to version control.** The following describes what credentials are required conceptually.

### Azure Terraform Variables (set via `terraform.tfvars` or environment variables)

| Secret | How to Obtain |
|--------|--------------|
| `database_admin_pass` | Choose a strong password for the SQL admin account |
| `cloudflare_api_token` | Cloudflare dashboard → API Tokens → Edit zone DNS |
| `backend_secrets_values` | Map of all application secrets (AI keys, JWT, SMTP, Google OAuth) |

### Azure Authentication (for `terraform apply`)

```bash
# Login with Azure CLI before running Terraform
az login
az account set --subscription "62dc5b60-eeb2-4c57-a565-cb1751b65a43"
```

Or set service principal environment variables:
```bash
export ARM_CLIENT_ID=<app-id>
export ARM_CLIENT_SECRET=<client-secret>
export ARM_TENANT_ID=<tenant-id>
export ARM_SUBSCRIPTION_ID=62dc5b60-eeb2-4c57-a565-cb1751b65a43
```

### AWS Terraform Variables

| Secret | How to Obtain |
|--------|--------------|
| `cloudflare_api_token` | Same Cloudflare token (shared with Azure config) |
| `infisical_client_id` | Infisical dashboard → Machine Identities → Client ID |
| `infisical_client_secret` | Infisical dashboard → Machine Identities → Client Secret |

### AWS Authentication

```bash
export AWS_ACCESS_KEY_ID=<access-key>
export AWS_SECRET_ACCESS_KEY=<secret-key>
# Or use AWS CLI SSO: aws sso login
```

### GitHub Actions Secrets (for CI/CD pipeline)

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | JSON service principal credentials for the CI deploy job |
| `AZURE_STORAGE_ACCOUNT` | Storage account name for test artifact upload |
| `AZURE_STORAGE_CONTAINER` | Blob container name for test artifacts |
| `DOCKER_USERNAME` | Docker Hub username (`abdelhameed208`) |
| `DOCKER_PASSWORD` | Docker Hub password or access token |
| `SONAR_TOKEN` | SonarCloud project analysis token |
| `EMA2A_ENV_FILE_CONTENT` | Full `.env` file content for the integration test environment |
| `VITE_BASE_URI_AZURE` | Backend URL for the Azure frontend image build |
| `VITE_BASE_URI_AWS` | Backend URL for the AWS frontend image build |
| `MAIL_ACCOUNT` | Gmail address for sending test result notifications |
| `MAIL_PASSWORD` | Gmail app password |
| `MAIL_USERNAME` | Gmail display-name sender address |
| `TARGET_EMAIL` | Recipient email for CI notifications |

---

## 9. Dependabot — Automated Dependency Updates

**File:** `.github/dependabot.yml`

Dependabot is configured to automatically open pull requests targeting the `DEV` branch on a **weekly** schedule for all dependency types in the monorepo:

| # | Ecosystem | Directory | Schedule | Target Branch |
|---|-----------|-----------|----------|---------------|
| 1 | `docker` | `/backend`, `/frontend` | Weekly | `DEV` |
| 2 | `docker-compose` | `/` | Weekly | `DEV` |
| 3 | `dotnet-sdk` | `/backend` | Weekly | `DEV` |
| 4 | `nuget` | `/backend` | Weekly | `DEV` |
| 5 | `npm` | `/frontend` | Weekly | `DEV` |
| 6 | `github-actions` | `/` | Weekly | `DEV` |
| 7 | `terraform` | `/DevOps/Terraform` | Weekly | `DEV` |
| 8 | `pub` (Flutter/Dart) | `/flutter` | Weekly | `DEV` |

All PRs target `DEV` rather than `main` to allow human review before merging into the production branch.
