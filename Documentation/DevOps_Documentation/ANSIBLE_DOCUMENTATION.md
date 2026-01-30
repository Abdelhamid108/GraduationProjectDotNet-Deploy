# Ansible Configuration & Deployment Documentation
**Version:** 1.0.0

This document provides a detailed technical breakdown of the Ansible configuration used to prepare the application server. It explains the purpose of every playbook, role, and task.

## 1. Architecture Overview

The Ansible setup is designed to be **modular** and **idempotent**.
*   **Controller**: Your local machine (where you run the commands).
*   **Target**: The EC2 instance provisioned by Terraform.
*   **User**: Connects as the default user (e.g., `ubuntu`), escalating to `root` via `sudo`.

## 2. Directory & File Breakdown

### `ansible.cfg`
The global configuration file.
*   `host_key_checking = False`: Prevents "Are you sure you want to connect?" prompts.
*   `inventory = ./inventory/hosts.ini`: Default inventory path.
*   `remote_user = admin`: The default SSH user (may be overridden in inventory).
*   `become = true`: Automatically use `sudo` for tasks.

### `site.yml` (The Master Playbook)
This is the entry point. It orchestrates the configuration by importing other playbooks:

| Order | Playbook | Purpose |
| :---- | :------- | :------ |
| 1 | `playbooks/initialization.yml` | System preparation (apt update, git, vim). |
| 2 | `playbooks/docker_installation.yml` | Installs Docker runtime and dependencies. |

### Playbooks & Roles Detail

#### 1. Initialization (`playbooks/initialization.yml`)
*   **Role**: `initialization`
*   **Tasks**:
    *   Updates `apt` cache.
    *   Installs essential tools: `git`, `vim`, `curl`, `wget`.
    *   Ensures the server is ready for further software installation.

#### 2. Docker Installation (`playbooks/docker_installation.yml`)
*   **Role**: `Docker_installation`
*   **Tasks**:
    *   Installs prerequisites (`ca-certificates`, `gnupg`).
    *   Adds the official Docker GPG key and repository.
    *   Installs `docker-ce`, `docker-ce-cli`, `containerd.io`.
    *   **Handler**: Restarts Docker service if config changes.

## 3. Execution Guide

### Step 1: Verify Inventory
Ensure `inventory/hosts.ini` exists and contains the correct IP.
```ini
[all]
x.x.x.x ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ema2a
```
*(Note: Terraform generates this. Ensure `ansible_user` matches your AMI, e.g., `ubuntu`.)*

### Step 2: Connectivity Test
```bash
cd DevOps/Ansible
ansible all -m ping
```
*Expected Output: `SUCCESS` with `"ping": "pong"`.*

### Step 3: Run Configuration
```bash
ansible-playbook site.yml
```
*Watch the output. Green means "no change", Yellow means "changed", Red means "failed".*

## 4. Troubleshooting

### "UNREACHABLE! => {'changed': false, 'msg': 'Failed to connect to the host via ssh...'}"
*   **Check IP**: Is the IP in `hosts.ini` correct?
*   **Check Key**: Does `~/.ssh/ema2a` (private key) exist?
*   **Check User**: The `ansible.cfg` sets `remote_user = admin`. If you are using an Ubuntu AMI, the user is `ubuntu`.
    *   *Fix*: Edit `inventory/hosts.ini` to add `ansible_user=ubuntu` next to the IP.
