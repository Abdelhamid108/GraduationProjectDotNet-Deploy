# GitHub Actions Pipeline Documentation
**Version:** 1.0.0

This document details the CI/CD pipeline configuration defined in `.github/workflows/main.yml`. The pipeline automates the build, test, and deployment process for the application stack using GitHub Actions.

## 1. Pipeline Overview

The pipeline is triggered on pushes to `DEV` and `main` branches, but only if changes are detected in specific paths (`backend/**`, `nginx-proxy/**`, `docker-compose.yml`). It can also be triggered manually via the **Actions** tab with an option to force a full rebuild.

### Key Features
*   **Change Detection**: Uses `dorny/paths-filter` to detect changes in specific directories.
*   **Dynamic Versioning**: Tags Docker images based on the git commit count and short SHA (e.g., `v1.0-15-a1b2c3d`).
*   **Efficient Builds**: Only builds and pushes images for services that have changed.
*   **Secure Deployment**: Uses GitHub Secrets for sensitive data (SSH keys, creating `.env` file).

## 2. Configuration & Inputs

### Manual Trigger Inputs (`workflow_dispatch`)
When running the workflow manually, you can specify:

| Input | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `FiRST-RUN` | Boolean | `false` | If set to `true`, forces a rebuild and redeploy of ALL components, ignoring change detection. |

### Environment Variables
| Variable | Value | Description |
| :--- | :--- | :--- |
| `REGISTRY` | `abdelhameed208` | Docker Hub username/registry. |
| `BACKEND_IMAGE` | `graduationproject-backend` | Name of the backend image. |
| `WEB_SERVER_IMAGE` | `graduationproject-nginx` | Name of the frontend/proxy image. |

### GitHub Secrets
The pipeline relies on the following secrets configured in the repository settings:

| Secret | Description |
| :--- | :--- |
| `DOCKER_USERNAME` | Docker Hub username. |
| `DOCKER_PASSWORD` | Docker Hub password/token. |
| `EMA2A_SSH_HOST` | IP address of the target deployment server. |
| `EMA2A_SSH_USER` | SSH username (e.g., `ubuntu`). |
| `EMA2A_PRIVATE_KEY` | SSH private key for authentication. |
| `EMA2A_ENV_FILE_CONTENT` | Full content of the `.env` file to be generated on the server. |

## 3. Pipeline Jobs

### Job 1: Build & Push (`build-push-images`)
**Purpose**: Builds Docker images and pushes them to Docker Hub.

1.  **Checkout Code**: Fetches the full history (`fetch-depth: 0`) to allow for correct version counting.
2.  **Check Changes**: Identifies which components have changed using `dorny/paths-filter`.
3.  **Login to Docker Hub**: Authenticates using provided secrets.
4.  **Build Backend** (Conditional):
    *   Run if `backend` changed OR `FiRST-RUN` is true.
    *   Calculates version tag: `v1.0-<CommitCount>-<ShortSHA>`.
    *   Builds and pushes `graduationproject-backend`.
5.  **Build Web Server** (Conditional):
    *   Run if `nginx-proxy` changed OR `FiRST-RUN` is true.
    *   Calculates version tag.
    *   Builds and pushes `graduationproject-nginx`.

### Job 2: Deploy (`deploy`)
**Purpose**: Updates the running application on the server.
**Condition**: Runs only if `build-push-images` completes successfully.

1.  **Generate `.env`**: Creates the `.env` file from the `EMA2A_ENV_FILE_CONTENT` secret.
2.  **Ensure App Folder**: Connects via SSH to create the target directory.
3.  **Copy Files**: Uses `scp` to copy `docker-compose.yml`, `.env`, and `Dev` folder to the server.
4.  **Execute Deployment**:
    *   Connects via SSH.
    *   Runs `docker compose pull` to fetch new images.
    *   Runs `docker compose up -d --remove-orphans` to restart updated services.
    *   Runs `docker image prune -f` to clean up old images.

## 4. Troubleshooting

### "No changes detected"
*   **Cause**: You pushed a change but not in the monitored paths (`backend/`, `nginx-proxy/`, `docker-compose.yml`).
*   **Fix**: If you need to force a deploy, run the workflow manually and check the **"Set to true to force build all images"** box.

### "Permission denied (publickey)" during Deploy
*   **Cause**: The `EMA2A_PRIVATE_KEY` secret is incorrect or does not match the public key on the server (`~/.ssh/authorized_keys`).
*   **Fix**: Verify the SSH key pair and update the GitHub Secret.

### "Docker login failed"
*   **Cause**: `DOCKER_USERNAME` or `DOCKER_PASSWORD` secrets are invalid.
*   **Fix**: Update the secrets in GitHub repository settings.
