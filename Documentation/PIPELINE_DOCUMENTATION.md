# Jenkins Pipeline Documentation
**Version:** 0.1.3

This document details the CI/CD pipeline configuration defined in the `Jenkinsfile`. The pipeline automates the build, test, and deployment process for the application stack.

## 1. Pipeline Overview

The pipeline is a **Declarative Pipeline** that executes on any available agent (`agent any`). It is designed to be smart, only rebuilding and redeploying services that have changed, unless a full rebuild is forced.

### Key Features
*   **Change Detection**: Uses a Shared Library to detect changes in specific directories (`backend`, `nginx-proxy`, `docker-compose.yml`).
*   **Dynamic Versioning**: Tags Docker images based on the git commit count of the respective service directory (e.g., `v1.0-15`).
*   **Parallel Builds**: Builds backend and frontend images concurrently to save time.
*   **Secure Deployment**: Uses credentials management for Docker Hub and environment variables.

## 2. Configuration & Parameters

### Global Constants
| Constant          | Value                                              | Description                                     |
| :---------------- | :------------------------------------------------- | :---------------------------------------------- |
| `MONITORED_PATHS` | `['backend', 'nginx-proxy', 'docker-compose.yml']` | List of directories/files to watch for changes. |

### Build Parameters
The pipeline accepts the following parameters when triggered manually:

| Parameter      | Type    | Default | Description                                                                           |
| :------------- | :------ | :------ | :------------------------------------------------------------------------------------ |
| `IsFirstRun`   | Boolean | `false` | If checked, forces a rebuild and redeploy of ALL components, ignoring change detection. |

### Environment Variables
| Variable                | Value                       | Description                                 |
| :---------------------- | :-------------------------- | :------------------------------------------ |
| `REGISTRY`              | `abdelhameed208`            | Docker Hub username/registry.               |
| `BACKEND_IMAGE`         | `graduationproject-backend` | Name of the backend image.                  |
| `WEB_SERVER_IMAGE`      | `graduationproject-nginx`   | Name of the frontend/proxy image.           |
| `DOCKER_CREDENTIALS_ID` | `docker-hub-cred`           | Jenkins Credential ID for Docker Hub login. |
| `ENV_FILE`              | `docker_compose_env`        | Jenkins Credential ID for the `.env` file.  |

## 3. Pipeline Stages

### Stage 1: Check_Diffs
**Purpose**: Determines what needs to be built.
*   **Logic**: Calls `checkServiceChanges` from the shared library.
*   **Output**: Sets `env.SERVICES_TO_UPDATE` (comma-separated list of changed services).
*   **Versioning**: Calculates `BACKEND_IMAGE_TAG` and `FRONTEND_IMAGE_TAG` using `git rev-list --count`.

### Stage 2: Build & Push Images
**Purpose**: Builds Docker images and pushes them to the registry.
*   **Execution**: Runs in **Parallel**.
*   **Sub-Stage: Build Backend**:
    *   *Condition*: `backend` changed OR `IsFirstRun` is true.
    *   *Action*: Builds `backend/Dockerfile`, tags with version & `latest`, pushes to Docker Hub.
*   **Sub-Stage: Build Frontend**:
    *   *Condition*: `nginx-proxy` changed OR `IsFirstRun` is true.
    *   *Action*: Builds `nginx-proxy/Dockerfile`, tags with version & `latest`, pushes to Docker Hub.

### Stage 3: Deploy
**Purpose**: Updates the running application on the server.
*   **Condition**: Any monitored service changed OR `IsFirstRun` is true.
*   **Actions**:
    1.  Injects the secure `.env` file from Jenkins credentials.
    2.  Runs `docker compose pull` to get the new images.
    3.  Runs `docker compose up -d` to restart updated services.

## 4. Shared Library
The pipeline relies on a shared library imported at the top of the file:
*   **Library**: `jenkins-shared-library`
*   **Source**: `https://github.com/Abdelhamid108/jenkins_Shared-Library.git`
*   **Function**: `checkServiceChanges` - Compares the current commit against the base branch to identify modified paths.

## 5. Troubleshooting

### "No changes detected" (but I made changes)
*   **Cause**: The shared library compares against `main`. If you are on a feature branch, ensure you have committed your changes.
*   **Fix**: You can force a build by checking the `IsFirstRun` parameter when building manually.

### "Docker permission denied"
*   **Cause**: The Jenkins user on the agent does not have permission to run Docker commands.
*   **Fix**: Ensure the `jenkins` user is part of the `docker` group (handled by Ansible).

### "Credentials not found"
*   **Cause**: The `DOCKER_CREDENTIALS_ID` or `ENV_FILE` ID in the Jenkinsfile does not match what is configured in Jenkins > Manage Jenkins > Credentials.
*   **Fix**: Verify the IDs match exactly.

