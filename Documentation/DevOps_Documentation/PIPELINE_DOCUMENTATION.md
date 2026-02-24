# GitHub Actions Pipeline Documentation
**Version:** 2.0.0

This document describes the CI/CD workflow defined in `.github/workflows/main.yml`. The pipeline now performs **conditional image builds**, **ephemeral integration testing**, **artifact archival to Azure Blob Storage**, **email notification**, and **deployment to Azure Container Apps**.

## 1. Pipeline Overview

The workflow (`Ema2a-Pipeline`) is triggered by:

1. Pushes to `DEV` and `main` branches.
2. Path changes in:
   - `backend/**`
   - `nginx-proxy/**`
   - `docker-compose.yml`
3. Manual run (`workflow_dispatch`) with optional force rebuild.

### Key Features

- **Change Detection** with `dorny/paths-filter` to build only changed services.
- **Immutable Traceable Tags** based on per-path commit count + short SHA (e.g., `v1.0-25-a1b2c3d`).
- **Ephemeral Integration Test Environment** using `docker compose up -d` on the CI runner.
- **Automated API Test Execution** (REST + WebSocket) using `backend/API_Test/run_tests.sh`.
- **Azure Artifact Storage** for JSON test reports using private blob upload + SAS URL generation.
- **Automated Email Notification** including pass/fail metrics and temporary secure artifact link.
- **Quality Gate** that aborts deployment when failed tests exceed threshold.
- **Azure Container Apps Deployment** gated by successful build + test.

## 2. Trigger & Configuration

### Branch/Path Trigger Rules

The workflow runs on push to:
- `DEV`
- `main`

Only when one or more of these paths changed:
- `backend/**`
- `nginx-proxy/**`
- `docker-compose.yml`

### Manual Trigger Input (`workflow_dispatch`)

| Input | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `FiRST-RUN` | Boolean | `false` | Forces building all images regardless of path filters. |

### Global Environment Variables

| Variable | Value | Description |
| :--- | :--- | :--- |
| `REGISTRY` | `abdelhameed208` | Docker registry/namespace. |
| `BACKEND_IMAGE` | `graduationproject-backend` | Backend image name. |
| `WEB_SERVER_IMAGE` | `graduationproject-nginx` | Nginx/webserver image name. |

## 3. Required GitHub Secrets

### Docker Hub

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

### Azure (Deployment + Artifacts)

- `AZURE_CREDENTIALS`
- `AZURE_STORAGE_ACCOUNT`
- `AZURE_STORAGE_CONTAINER`

### Email Notification

- `MAIL_ACCOUNT`
- `MAIL_PASSWORD`
- `MAIL_USERNAME`
- `TARGET_EMAIL`

### App Runtime Config

- `EMA2A_ENV_FILE_CONTENT` (full `.env` content used in test environment)

## 4. Pipeline Jobs

The pipeline has 3 jobs executed in this order:

1. `build-push-images`
2. `test`
3. `deploy`

---

### Job 1: Build & Push (`build-push-images`)

**Purpose:** Build and push only changed Docker images.

**Runner:** `ubuntu-24.04`

#### Steps

1. Checkout repository with full history (`fetch-depth: 0`).
2. Detect changed paths with `dorny/paths-filter`.
3. Login to Docker Hub only if needed.
4. Build backend image conditionally:
   - Tag format: `v1.0-<commitCount>-<shortSha>`
   - Pushes both immutable tag and `latest`.
5. Build webserver image conditionally with same tag strategy.
6. Export image tags as job outputs:
   - `backend_tag`
   - `webserver_tag`

---

### Job 2: Integration Testing & Artifact Storage (`test`)

**Purpose:** Validate functionality before deployment and preserve test evidence.

**Runner:** `ubuntu-24.04`

**Dependency:** `needs: build-push-images`

#### Steps

1. Checkout repository.
2. Create `.env` from secret (`EMA2A_ENV_FILE_CONTENT`).
3. Provision ephemeral stack via `docker compose up -d`.
4. Wait for service startup (`sleep 120`).
5. Install test dependencies (`curl`, `jq`, `websocat`).
6. Execute API tests:
   - Runs `backend/API_Test/run_tests.sh --verbose --base-url http://localhost`
   - Uses `|| true` so report generation/collection is not skipped on failures.
7. Parse JSON report (`report_latest.json`) and export summary metrics.
8. Login to Azure.
9. Upload report to Azure Blob Storage.
10. Generate 24h user delegation SAS URL for secure artifact access.
11. Send email notification with:
    - pass/fail totals
    - pass rate
    - temporary report URL
12. Enforce quality gate:
    - `ALLOWED_FAILURES=10`
    - pipeline fails if `failed > 10`

---

### Job 3: Deployment (`deploy`)

**Purpose:** Deploy newly built immutable image tags to Azure Container Apps.

**Runner:** `ubuntu-24.04`

**Dependencies:** `needs: [build-push-images, test]`

**Environment Gate:** `Production` (supports required reviewers/approval in GitHub Environments)

#### Steps

1. Authenticate to Azure.
2. Deploy backend image to container app `ema2a` (only if backend tag exists).
3. Deploy webserver image to container app `ema2a-webserver` (only if webserver tag exists).

## 5. Quality & Release Rules

- Deployment happens **only** when build and test jobs succeed.
- If test failures exceed threshold (`> 10`), deployment is aborted.
- Deploy job uses immutable tags from the current run outputs.
- Manual approval can be enforced through `environment: Production` configuration.

## 6. Troubleshooting

### Workflow did not run on push
- Verify branch is `DEV` or `main`.
- Verify changed files are inside monitored paths.
- For forced full run, trigger manually and set `FiRST-RUN=true`.

### Docker login failure
- Check `DOCKER_USERNAME` / `DOCKER_PASSWORD` secrets.

### Tests executed but deployment blocked
- Check **Quality Gate** step output.
- If failed tests exceed 10, deployment is intentionally stopped.

### Azure Blob upload failure
- Verify `AZURE_CREDENTIALS`, `AZURE_STORAGE_ACCOUNT`, and `AZURE_STORAGE_CONTAINER`.
- Ensure the service principal has storage data plane permissions.

### Email notification failure
- Verify SMTP credentials and sender/recipient secrets:
  - `MAIL_ACCOUNT`, `MAIL_PASSWORD`, `MAIL_USERNAME`, `TARGET_EMAIL`.

### Azure deployment failure
- Verify target Container Apps exist:
  - `ema2a`
  - `ema2a-webserver`
- Verify resource group is `Ema2a` and credentials have deploy permissions.
