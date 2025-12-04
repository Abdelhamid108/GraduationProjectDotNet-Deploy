# Terraform Infrastructure Documentation
**Version:** 0.1.3

This document provides a comprehensive, deep-dive guide to the project's infrastructure provisioning using Terraform. It details every resource, variable, and configuration used to deploy the environment on AWS.

## 1. Project Overview & Prerequisites

### Purpose
The Terraform configuration in `DevOps/Terraform` is responsible for provisioning a single, robust EC2 instance that serves as the host for Jenkins, Docker, and the application backend. It handles networking, security, and static IP assignment.

### Prerequisites
Before running any commands, ensure your environment meets these requirements:

1.  **Terraform**: Version 1.0.0+.
2.  **AWS CLI**: Configured with `aws configure`. You must have an IAM user with `AmazonEC2FullAccess` and `AmazonVPCFullAccess`.
3.  **SSH Key**: A public key file must exist at `~/.ssh/ema2a.pub`.
    *   *To generate one:* `ssh-keygen -t rsa -b 4096 -f ~/.ssh/ema2a`

## 2. File Structure & Detailed Breakdown

### `main.tf`
The core configuration file. Here is a breakdown of the resources it creates:

| Resource Type      | Name              | Description                               | Configuration Details                                                                 |
| :----------------- | :---------------- | :---------------------------------------- | :------------------------------------------------------------------------------------ |
| **Provider**       | `aws`             | Configures the connection to AWS.         | **Region**: `us-east-1`                                                               |
| **Key Pair**       | `devops_ema2a`    | Uploads your local public key to AWS.     | **Key Name**: `ema2a_ssh_key`<br>**Source**: `~/.ssh/ema2a.pub`                       |
| **EC2 Instance**   | `ema2a_server`    | The main server.                          | **AMI**: `ami-0fa3fe0fa7920f68e` (Ubuntu)<br>**Type**: `c7i-flex.large`<br>**Storage**: 20GB |
| **Elastic IP**     | `ema2a_public_ip` | Static public IP address.                 | Associated with `ema2a_server`. Ensures the IP doesn't change on reboot.              |
| **Security Group** | `ema2a_sg`        | Firewall rules for the server.            | See "Security Group Rules" below.                                                     |

### Security Group Rules (`ema2a_sg`)
The security group defines exactly what traffic is allowed.

| Direction | Port | Protocol | Source      | Purpose                     |
| :-------- | :--- | :------- | :---------- | :-------------------------- |
| **Ingress** | 22   | TCP      | `0.0.0.0/0` | SSH Access (Admin)          |
| **Ingress** | 80   | TCP      | `0.0.0.0/0` | HTTP Web Traffic            |
| **Ingress** | 443  | TCP      | `0.0.0.0/0` | HTTPS Secure Web Traffic    |
| **Ingress** | 8080 | TCP      | `0.0.0.0/0` | Jenkins Dashboard           |
| **Egress**  | All  | All      | `0.0.0.0/0` | Outbound Internet Access    |

### `ansible_inventory.tf` & `ansible_inventory.tpl`
These files automate the bridge between Terraform and Ansible.
*   **Logic**: After the EC2 instance is created and assigned an Elastic IP, Terraform uses the `local_file` resource to generate a file.
*   **Output**: It writes the public IP address into `../Ansible/inventory/hosts.ini`.
*   **Benefit**: You never have to manually copy-paste IP addresses.

## 3. Execution Guide

### Step 1: Initialization
Downloads the AWS provider plugin.
```bash
cd DevOps/Terraform
terraform init
```

### Step 2: Validation & Planning
Checks syntax and shows you exactly what will be built.
```bash
terraform validate
terraform plan -out=tfplan
```
*Look for "Plan: 6 to add, 0 to change, 0 to destroy."*

### Step 3: Apply
Provisions the infrastructure.
```bash
terraform apply "tfplan"
```
*Wait for the "Apply complete!" message.*

### Step 4: Verification
1.  **Check Output**: Terraform will display `ema2a_server_ip = "x.x.x.x"`.
2.  **Check AWS Console**: Verify the instance is "Running" in `us-east-1`.
3.  **Check Inventory**: Verify that `DevOps/Ansible/inventory/hosts.ini` exists and contains the correct IP.

## 4. Troubleshooting & Maintenance

### "Error: file not found"
*   **Cause**: The SSH public key `~/.ssh/ema2a.pub` does not exist.
*   **Fix**: Generate the key using `ssh-keygen` or update the path in `main.tf` (line 9).

### "Error: Error launching source instance: InvalidAMIID.NotFound"
*   **Cause**: The AMI ID `ami-0fa3fe0fa7920f68e` might not exist in your selected region (`us-east-1`).
*   **Fix**: Go to the AWS Console > EC2 > Launch Instance, find a valid Ubuntu AMI ID for your region, and update `main.tf`.

### "Error: Error creating Security Group: InvalidGroup.Duplicate"
*   **Cause**: A security group named `ema2a_server_sg` already exists.
*   **Fix**: Delete the existing group in AWS or rename it in `main.tf`.

### State Management
Terraform tracks the state of your resources in `terraform.tfstate`. **NEVER** delete this file manually. If you lose it, Terraform loses track of your infrastructure.

