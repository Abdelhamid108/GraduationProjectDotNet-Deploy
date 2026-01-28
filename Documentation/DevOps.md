# DevOps & Infrastructure Guide

This document serves as the central hub for the project's DevOps processes, including infrastructure provisioning and configuration management.

## Overview

The project utilizes an automated pipeline for infrastructure and deployment:

1.  **Infrastructure as Code (IaC)**: **Terraform** is used to provision AWS resources (EC2, Networking, Security Groups).
2.  **Configuration Management**: **Ansible** is used to configure the servers, install dependencies (Docker, Jenkins), and deploy the application.

## Workflow Summary

The general workflow for setting up the environment is as follows:

1.  **Provision Infrastructure**: Use Terraform to create the servers.
2.  **Generate Inventory**: Terraform automatically creates the Ansible inventory file.
3.  **Configure Servers**: Use Ansible to set up the software stack on the provisioned servers.

## Detailed Documentation

Please refer to the following detailed guides for specific instructions:

*   **[Terraform Guide](Terraform.md)**: Instructions for provisioning AWS infrastructure.
    *   Prerequisites & Setup
    *   Provisioning (Init, Plan, Apply)
    *   Destruction
*   **[Ansible Guide](Ansible.md)**: Instructions for server configuration and deployment.
    *   Inventory & Playbooks
    *   Running the Deployment
    *   Troubleshooting & Optimization
*   **[Pipeline Guide](Pipeline.md)**: Instructions for the Jenkins CI/CD pipeline.
    *   Configuration & Parameters
    *   Stages & Logic
    *   Troubleshooting
*   **[Docker Guide](Docker.md)**: Details on container configuration and Dockerfiles.
    *   Compose Services & Networks
    *   Dockerfile Optimization
    *   Operational Commands

## Quick Start

### 1. Provision with Terraform
```bash
cd DevOps/Terraform
terraform init
terraform apply -auto-approve
```

### 2. Configure with Ansible
```bash
cd ../Ansible
ansible-playbook -i inventory/hosts.ini site.yml
```

---

