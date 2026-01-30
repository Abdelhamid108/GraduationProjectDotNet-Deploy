# DevOps & Infrastructure Guide

This document serves as the central hub for the project's DevOps processes, including infrastructure provisioning, configuration management, and the CI/CD pipeline.

## Overview

The project utilizes an automated pipeline for infrastructure and deployment:

1.  **Infrastructure as Code (IaC)**: **Terraform** is used to provision AWS resources (EC2, Networking, Security Groups).
2.  **Configuration Management**: **Ansible** is used to configure the servers and install dependencies (Docker).
3.  **CI/CD Pipeline**: **GitHub Actions** is used for continuous integration and deployment.

## Workflow Summary

The general workflow for setting up the environment is as follows:

1.  **Provision Infrastructure**: Use Terraform to create the servers.
2.  **Generate Inventory**: Terraform automatically creates the Ansible inventory file.
3.  **Configure Servers**: Use Ansible to set up the software stack (Docker) on the provisioned servers.
4.  **Deploy Application**: Push code to GitHub to trigger the automated pipeline, or manually trigger it via GitHub Actions.

## Detailed Documentation

Please refer to the following detailed guides for specific instructions:

*   **[Terraform Guide](TERRAFORM_DOCUMENTATION.md)**: Instructions for provisioning AWS infrastructure.
    *   Prerequisites & Setup
    *   Provisioning (Init, Plan, Apply)
    *   Destruction
*   **[Ansible Guide](ANSIBLE_DOCUMENTATION.md)**: Instructions for server configuration.
    *   Inventory & Playbooks
    *   Docker Installation
    *   Troubleshooting
*   **[Pipeline Guide](PIPELINE_DOCUMENTATION.md)**: Instructions for the GitHub Actions CI/CD pipeline.
    *   Workflow Overview
    *   Jobs & Steps
    *   Secrets & Variables
*   **[Docker Guide](DOCKER_DOCUMENTATION.md)**: Details on container configuration and Dockerfiles.
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
