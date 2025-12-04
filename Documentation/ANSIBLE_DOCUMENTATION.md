# Ansible Configuration & Deployment Documentation
**Version:** 0.1.3

This document provides a detailed technical breakdown of the Ansible configuration used to deploy the application stack. It explains the purpose of every playbook, role, and task.

## 1. Architecture Overview

The Ansible setup is designed to be **modular** and **idempotent**.
*   **Controller**: Your local machine (where you run the commands).
*   **Target**: The EC2 instance provisioned by Terraform.
*   **User**: Connects as `admin` (defined in `ansible.cfg`), escalating to `root` via `sudo`.

## 2. Directory & File Breakdown

### `ansible.cfg`
The global configuration file.
*   `host_key_checking = False`: Prevents "Are you sure you want to connect?" prompts.
*   `inventory = ./inventory/hosts.ini`: Default inventory path.
*   `remote_user = admin`: The default SSH user.
*   `become = true`: Automatically use `sudo` for tasks.

### `site.yml` (The Master Playbook)
This is the entry point. It orchestrates the entire deployment by importing other playbooks in a specific order:

| Order | Playbook | Purpose |
| :---- | :------- | :------ |
| 1 | `playbooks/initialization.yml` | System preparation (apt update, git, vim). |
| 2 | `playbooks/docker_installation.yml` | Installs Docker runtime and dependencies. |
| 3 | `playbooks/jenkins_agents_setup.yml` | Prepares node as a Jenkins agent (Java, user). |
| 4 | `playbooks/jenkins_master_setup.yml` | Installs and configures Jenkins master. |

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

#### 3. Jenkins Agent Setup (`playbooks/jenkins_agents_setup.yml`)
*   **Role**: `jenkins_agents_setup`
*   **Purpose**: Prepares the node to act as a Jenkins agent (worker).
*   **Tasks**:
    *   Installs Java (JDK 17) - required for Jenkins agents.
    *   Creates a dedicated `jenkins` user.
    *   Creates working directories for agent workspaces.

#### 4. Jenkins Master Setup (`playbooks/jenkins_master_setup.yml`)
*   **Role**: `jenkins_master_setup`
*   **Purpose**: Installs and configures the main Jenkins server.
*   **Tasks**:
    *   **Repo Setup**: Adds Jenkins GPG key and `apt` repository.
    *   **Install**: Installs `jenkins` package.
    *   **Permissions**: Adds `jenkins` user to `docker` group (CRITICAL for building Docker images).
    *   **Unlock**: Reads `initialAdminPassword` and runs a Groovy script to create the `admin` user.
    *   **Plugins**: Installs a curated list of plugins defined in `vars/main.yml` (e.g., `git`, `docker-workflow`, `blueocean`).
    *   **Optimization**: Checks for `/var/lib/jenkins/ansible_plugins_installed` marker file to skip slow plugin installation on subsequent runs.

## 3. Execution Guide

### Step 1: Verify Inventory
Ensure `inventory/hosts.ini` exists and contains the correct IP.
```ini
[all]
x.x.x.x ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ema2a
```
*(Note: Terraform generates this, but you should verify the user is correct. For Ubuntu AMIs, it is usually `ubuntu`, not `admin` as set in `ansible.cfg`. You may need to override this in the inventory or command line.)*

### Step 2: Connectivity Test
```bash
cd DevOps/Ansible
ansible all -m ping
```
*Expected Output: `SUCCESS` with `"ping": "pong"`.*

### Step 3: Run Deployment
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

### "Jenkins 502 Bad Gateway" (after installation)
*   **Cause**: Jenkins is still starting up.
*   **Fix**: Wait 1-2 minutes. Check status with `sudo systemctl status jenkins` on the server.

### "Permission denied" when Jenkins runs Docker
*   **Cause**: The `jenkins` user wasn't added to the `docker` group correctly, or the service wasn't restarted.
*   **Fix**: The playbook handles this, but if it fails, run:
    ```bash
    sudo usermod -aG docker jenkins
    sudo systemctl restart jenkins
    ```

### Forcing Plugin Re-installation
If you added new plugins to the list and need them installed:
```bash
ssh ubuntu@<server-ip> "sudo rm /var/lib/jenkins/ansible_plugins_installed"
ansible-playbook playbooks/jenkins_master_setup.yml
```

