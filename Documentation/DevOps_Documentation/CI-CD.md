# CI/CD Documentation — Ema2a Application

> **Project:** Ema2a Graduation Project  
> **Pipeline Name:** `Ema2a-Pipeline`  
> **Runner:** `ubuntu-24.04`  
> **Docker Registry:** `docker.io/abdelhameed208`  
> **SonarCloud Organization:** `abdelhamid108`  
> **Deployment Target:** Azure Container Apps

---

## Table of Contents

1. [Pipeline Overview](#1-pipeline-overview)
2. [Workflow: `main.yml` — Primary CI/CD Pipeline](#2-workflow-mainyml--primary-cicd-pipeline)
   - [Trigger Configuration](#21-trigger-configuration)
   - [Global Environment Variables](#22-global-environment-variables)
   - [Job: `sonar-backend`](#23-job-sonar-backend)
   - [Job: `sonar-frontend-devops`](#24-job-sonar-frontend-devops)
   - [Job: `backend-build-push`](#25-job-backend-build-push)
   - [Job: `frontend-build-push`](#26-job-frontend-build-push)
   - [Job: `trivy-backend`](#27-job-trivy-backend)
   - [Job: `trivy-frontend`](#28-job-trivy-frontend)
   - [Job: `test`](#29-job-test)
   - [Job: `deploy`](#210-job-deploy)
3. [Workflow: `CodeQl.yml` — Deep Security Analysis](#3-workflow-codeqlyml--deep-security-analysis)
4. [Workflow: `sonar-flutter.yml` — Flutter Mobile Analysis](#4-workflow-sonar-flutteryml--flutter-mobile-analysis)
5. [Workflow: `sonar-hardware.yml` — Hardware Service Analysis](#5-workflow-sonar-hardwareyml--hardware-service-analysis)
6. [Pipeline Dependency Graph](#6-pipeline-dependency-graph)
7. [Secrets & Environment Variables](#7-secrets--environment-variables)
8. [Tools Used](#8-tools-used)
9. [Tag & Versioning Strategy](#9-tag--versioning-strategy)
10. [SonarCloud Configuration](#10-sonarcloud-configuration)
11. [Quality Gates](#11-quality-gates)

---

## 1. Pipeline Overview

The Ema2a CI/CD system consists of **four GitHub Actions workflows**, each with a distinct scope of responsibility:

| Workflow File | Name | Trigger | Purpose |
|--------------|------|---------|---------|
| `main.yml` | `Ema2a-Pipeline` | Push to `DEV`/`main` (backend, frontend, DevOps paths) | Full CI/CD pipeline: SAST → Build → Security Scan → Test → Deploy |
| `CodeQl.yml` | `CodeQL & Security Scans` | Push to `main` | Deep semantic security analysis (SQLi, XSS, logic flaws) |
| `sonar-flutter.yml` | `Sonar · Flutter Mobile` | Push/PR when `flutter/**` changes | SonarCloud analysis + test coverage for Flutter/Dart |
| `sonar-hardware.yml` | `Sonar · Hardware Service` | Push/PR when `Hardware-Service/**` changes | SonarCloud analysis for Python hardware service |

### Architecture Principles

- **Path-based triggering** — each workflow only runs when relevant files change, minimising unnecessary CI compute.
- **Parallel SAST gates** — backend and frontend/DevOps Sonar scans run simultaneously before any build starts.
- **Immutable image tags** — Docker images are tagged with git-derived version strings (`v1.0-<commit-count>-<short-sha>`), never overwriting previously deployed images.
- **Dual-target frontend builds** — two frontend images are produced per run (Azure and AWS), each compiled with a different backend URL baked into the JavaScript bundle.
- **Conditional step execution** — build/push steps are skipped using `dorny/paths-filter` when no relevant files changed, unless overridden by the `FiRST-RUN` manual dispatch input.
- **Manual approval gate** — the `deploy` job targets the `Production` GitHub Environment, which requires a human reviewer to approve before deployment proceeds.

---

## 2. Workflow: `main.yml` — Primary CI/CD Pipeline

**File:** `.github/workflows/main.yml`  
**Total Lines:** 544  
**Jobs:** 8

### 2.1 Trigger Configuration

```yaml
on:
  push:
    branches:
      - "DEV"
      - "main"
    paths:
      - "backend/**"
      - "frontend/**"
      - "DevOps/**"
      - "docker-compose*.yml"
      - "**/Dockerfile"
  workflow_dispatch:
    inputs:
      FiRST-RUN:
        description: 'Set to true to force build all images ignoring path filters'
        required: false
        default: false
        type: boolean
```

| Trigger | Condition | Purpose |
|---------|-----------|---------|
| `push` to `DEV` | Any of the listed paths changed | Standard development flow |
| `push` to `main` | Any of the listed paths changed | Production deployment |
| `workflow_dispatch` | Manual trigger from GitHub Actions UI | Force-build all images (e.g., first-time setup, infrastructure drift) |

**`FiRST-RUN` input:** When set to `true`, bypasses the `dorny/paths-filter` detection so all images are rebuilt even if no code changed. Essential for the initial deployment or after a long period of inactivity.

### 2.2 Global Environment Variables

```yaml
env:
  REGISTRY: 'abdelhameed208'
  BACKEND_IMAGE: 'graduationproject-backend'
  FRONTEND_IMAGE: 'graduationproject-frontend'
```

These three variables are available to all jobs and steps within the workflow. They define the Docker Hub namespace and image names used consistently across build, push, scan, and deploy operations.

---

### 2.3 Job: `sonar-backend`

**Name:** `Sonar · Backend (.NET)`  
**Runner:** `ubuntu-24.04`  
**Needs:** *(none — runs at pipeline start)*

#### Purpose

Performs Static Application Security Testing (SAST) and code quality analysis on the .NET 8 backend using **SonarCloud**. Uses the `dotnet-sonarscanner` MSBuild integration which instruments the build process to collect code coverage and analysis data.

#### Steps

```yaml
1. Checkout Repository
   - fetch-depth: 0    # Full history required for blame and diff operations

2. Set up JDK 17
   - distribution: zulu
   # SonarScanner CLI itself runs on JVM — JDK 17 is a firm requirement

3. Setup .NET 8 SDK
   - dotnet-version: '8.0.x'

4. Cache NuGet Packages
   - path: ~/.nuget/packages
   - key: ${{ runner.os }}-nuget-${{ hashFiles('**/backend/**/*.csproj') }}
   # Hash includes all .csproj files — cache is invalidated when deps change

5. Cache SonarCloud Packages
   - path: ~/.sonar/cache
   - key: ${{ runner.os }}-sonar

6. Install dotnet-sonarscanner
   - run: dotnet tool install --global dotnet-sonarscanner

7. Create Backend .env File
   - run: echo "${{ secrets.EMA2A_ENV_FILE_CONTENT }}" > ./backend/.env
   # Required so the project builds successfully (reads .env at compile/runtime)

8. Build and Analyze
   env:
     GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
     SONAR_TOKEN:  ${{ secrets.SONAR_TOKEN }}
   run: |
     cd ./backend
     dotnet-sonarscanner begin \
       /k:"Abdelhamid108_GraduationProjectDotNet-Deploy" \
       /o:"abdelhamid108" \
       /d:sonar.token="${{ secrets.SONAR_TOKEN }}" \
       /d:sonar.host.url="https://sonarcloud.io"
     dotnet build
     dotnet-sonarscanner end /d:sonar.token="${{ secrets.SONAR_TOKEN }}"
```

**Three-Phase Sonar Analysis:**
1. `begin` — initialises the scanner and attaches hooks to the MSBuild process
2. `dotnet build` — compiles the code; scanner collects instrumentation data
3. `end` — finalises analysis and uploads results to SonarCloud

**SonarCloud Project Key:** `Abdelhamid108_GraduationProjectDotNet-Deploy`

#### Secrets Used

| Secret | Purpose |
|--------|---------|
| `GITHUB_TOKEN` | PR decoration (adds Sonar comments to PRs) |
| `SONAR_TOKEN` | Authentication with SonarCloud |
| `EMA2A_ENV_FILE_CONTENT` | Full `.env` file content for build-time env vars |

---

### 2.4 Job: `sonar-frontend-devops`

**Name:** `Sonar · Frontend + DevOps`  
**Runner:** `ubuntu-24.04`  
**Needs:** *(none — runs at pipeline start, parallel with `sonar-backend`)*

#### Purpose

Analyzes the **React/TypeScript frontend** and **all DevOps Infrastructure as Code** (Terraform, Ansible, Dockerfiles, Compose files) in a single SonarCloud project using the `sonar-scanner` CLI. Runs from the repository root so all relative paths in `sonar-frontend-devops.properties` resolve correctly.

#### Steps

```yaml
1. Checkout Repository
   - fetch-depth: 0

2. Set up JDK 17
   - distribution: zulu

3. Cache Node Modules
   - path: frontend/node_modules
   - key: ${{ runner.os }}-node-${{ hashFiles('frontend/package-lock.json') }}

4. Cache SonarCloud Packages
   - path: ~/.sonar/cache

5. Install Frontend Dependencies
   - working-directory: frontend
   - run: npm ci
   # npm ci (not npm install) — deterministic; uses package-lock.json

6. Install SonarScanner CLI
   - run: npm install -g sonar-scanner

7. Run Sonar Analysis
   env:
     GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
     SONAR_TOKEN:  ${{ secrets.SONAR_TOKEN }}
   run: |
     sonar-scanner \
       -Dproject.settings=sonar-frontend-devops.properties \
       -Dsonar.token="${{ secrets.SONAR_TOKEN }}" \
       -Dsonar.host.url="https://sonarcloud.io"
```

**Config File:** `sonar-frontend-devops.properties` (repo root)

```properties
sonar.projectKey=Abdelhamid108_ema2a-frontend-devops
sonar.organization=abdelhamid108
sonar.projectName=Ema2a Frontend & DevOps
sonar.sources=frontend/src,DevOps,backend/Dockerfile,frontend/Dockerfile,docker-compose.yml,...
sonar.typescript.tsconfigPath=frontend/tsconfig.app.json
sonar.exclusions=**/node_modules/**,**/dist/**,**/.terraform/**,**/*.tfstate,...
```

**Why frontend deps are installed before scanning:** The TypeScript compiler (`tsc`) is invoked by SonarScanner to resolve type information. Without `node_modules`, the type resolution fails, producing incomplete or inaccurate analysis results.

---

### 2.5 Job: `backend-build-push`

**Name:** `Build & Push · Backend (.NET)`  
**Runner:** `ubuntu-24.04`  
**Needs:** `[sonar-backend, sonar-frontend-devops]`  
**Condition:** `if: success()` — only runs if **both** SAST jobs pass

#### Purpose

Builds the .NET backend Docker image using BuildKit layer caching and pushes two tags to Docker Hub: an immutable versioned tag and `:latest`.

#### Steps

```yaml
1. Checkout Repository
   - fetch-depth: 0    # Needed for git rev-list commit counting

2. Detect Backend Changes
   id: changes
   uses: dorny/paths-filter@v3
   with:
     base: ${{ github.ref_name }}
     filters: |
       backend:
         - 'backend/**'

3. Set up Docker Buildx
   if: steps.changes.outputs.backend == 'true' || inputs.FiRST-RUN == true
   # Docker BuildKit for advanced caching + multi-platform support

4. Authenticate to Docker Hub
   if: steps.changes.outputs.backend == 'true' || inputs.FiRST-RUN == true
   uses: docker/login-action@v4
   with:
     username: ${{ secrets.DOCKER_USERNAME }}
     password: ${{ secrets.DOCKER_PASSWORD }}

5. Generate Immutable Image Tag
   id: tag
   if: steps.changes.outputs.backend == 'true' || inputs.FiRST-RUN == true
   run: |
     COUNT=$(git rev-list --count HEAD backend/ || echo "0")
     SHORT_SHA=$(git rev-parse --short HEAD)
     echo "value=v1.0-${COUNT}-${SHORT_SHA}" >> $GITHUB_OUTPUT

6. Build and Push Backend Image
   if: steps.changes.outputs.backend == 'true' || inputs.FiRST-RUN == true
   uses: docker/build-push-action@v7
   with:
     context: ./backend
     push: true
     tags: |
       ${{ env.REGISTRY }}/${{ env.BACKEND_IMAGE }}:${{ steps.tag.outputs.value }}
       ${{ env.REGISTRY }}/${{ env.BACKEND_IMAGE }}:latest
     cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.BACKEND_IMAGE }}:buildcache
     cache-to:   type=registry,ref=${{ env.REGISTRY }}/${{ env.BACKEND_IMAGE }}:buildcache,mode=max
```

#### Tag Format

```
v1.0-<commit-count-in-backend/>-<short-sha>
```

Example: `v1.0-47-a3f9b12`

- `commit-count` = number of commits that touched `backend/` (provides monotonically increasing build number)
- `short-sha` = 7-character git commit hash (uniquely identifies the exact code version)

#### Registry Caching

Registry-mode BuildKit caching stores layer cache manifests in Docker Hub under the tag `:buildcache`. This means:
- **cache-from**: restore cached layers from the previous build
- **cache-to**: update the cache after the current build, with `mode=max` (cache all intermediate layers, not just the final)

This dramatically reduces build time for incremental changes to the application code (SDK installation and dependency restore layers are cached).

#### Job Outputs

```yaml
outputs:
  backend_tag: ${{ steps.tag.outputs.value }}
```

This output is consumed by downstream jobs (`trivy-backend`, `deploy`) to reference the exact image tag built in this job.

---

### 2.6 Job: `frontend-build-push`

**Name:** `Build & Push · Frontend (React)`  
**Runner:** `ubuntu-24.04`  
**Needs:** `[sonar-backend, sonar-frontend-devops]`  
**Condition:** `if: success()` — runs parallel to `backend-build-push`

#### Purpose

Builds **two separate React frontend Docker images** — one for Azure deployment and one for AWS — each compiled with a different backend API URL baked into the JavaScript bundle. Uses separate registry cache namespaces per target environment.

#### Steps

```yaml
1-4. Checkout + Detect Changes + Setup Buildx + Docker Login
     (identical pattern to backend job)

5. Generate Immutable Image Tags
   id: tag
   run: |
     COUNT=$(git rev-list --count HEAD frontend/ || echo "0")
     SHORT_SHA=$(git rev-parse --short HEAD)
     BASE="v1.0-${COUNT}-${SHORT_SHA}"
     echo "azure_tag=${BASE}-azure" >> $GITHUB_OUTPUT
     echo "aws_tag=${BASE}-aws"   >> $GITHUB_OUTPUT

6. Build and Push Frontend Image (Azure)
   uses: docker/build-push-action@v7
   with:
     context: ./frontend
     push: true
     build-args: VITE_BASE_URI=${{ secrets.VITE_BASE_URI_AZURE }}
     tags: ${{ env.REGISTRY }}/${{ env.FRONTEND_IMAGE }}:${{ steps.tag.outputs.azure_tag }}
     cache-from: type=registry,ref=.../buildcache-azure
     cache-to:   type=registry,ref=.../buildcache-azure,mode=max

7. Build and Push Frontend Image (AWS)
   uses: docker/build-push-action@v7
   with:
     context: ./frontend
     push: true
     build-args: VITE_BASE_URI=${{ secrets.VITE_BASE_URI_AWS }}
     tags: |
       ${{ env.REGISTRY }}/${{ env.FRONTEND_IMAGE }}:${{ steps.tag.outputs.aws_tag }}
       ${{ env.REGISTRY }}/${{ env.FRONTEND_IMAGE }}:latest
     cache-from: type=registry,ref=.../buildcache-aws
     cache-to:   type=registry,ref=.../buildcache-aws,mode=max
```

#### Why Two Images?

Vite (the React build tool) uses `import.meta.env.VITE_BASE_URI` at build time to embed the backend URL as a string constant in the compiled JavaScript. This means:
- The URL cannot be changed at runtime without rebuilding the image
- Azure and AWS deployments point to different backend URLs
- Therefore, two separate builds (and images) are required

The AWS image is also tagged `:latest` to make it the default for the integration test job that uses `docker-compose.yml`.

#### Job Outputs

```yaml
outputs:
  frontend_azure_tag: ${{ steps.tag.outputs.azure_tag }}
  frontend_aws_tag:   ${{ steps.tag.outputs.aws_tag }}
```

---

### 2.7 Job: `trivy-backend`

**Name:** `Trivy · Backend Image Scan`  
**Runner:** `ubuntu-24.04`  
**Needs:** `backend-build-push`  
**Condition:** `if: success()`  
**Permissions:** `contents: read`, `security-events: write`

#### Purpose

Scans the pushed backend Docker image for known CVEs (vulnerabilities) and hardcoded secrets using **Aqua Security Trivy**. Results are uploaded to the GitHub Security tab (Dependabot/Security alerts) in SARIF format.

#### Steps

```yaml
1. Checkout Repository

2. Scan Backend Image
   if: needs.backend-build-push.outputs.backend_tag != ''
   uses: aquasecurity/trivy-action@v0.35.0
   with:
     image-ref:      ${{ env.REGISTRY }}/${{ env.BACKEND_IMAGE }}:${{ needs.backend-build-push.outputs.backend_tag }}
     exit-code:      0           # Do NOT fail the pipeline on findings
     severity:       'HIGH,CRITICAL'
     ignore-unfixed: true        # Filter out vulnerabilities with no fix available
     format:         'sarif'
     output:         'trivy-backend.sarif'
     scanners:       'vuln,secret'

3. Upload Results to GitHub Security Tab
   if: needs.backend-build-push.outputs.backend_tag != ''
   uses: github/codeql-action/upload-sarif@v4
   with:
     sarif_file: 'trivy-backend.sarif'
     category:   'trivy-backend'
```

**`exit-code: 0`** — Trivy findings do NOT block the pipeline. This is an intentional design decision: for a graduation project, the goal is visibility, not blocking. In a production system, this would typically be `exit-code: 1` for `CRITICAL` findings.

**`ignore-unfixed: true`** — Filters out vulnerabilities for which no patched version exists yet, reducing noise.

**`scanners: 'vuln,secret'`** — Scans both for CVEs in the image layers and for hardcoded secrets (API keys, tokens, passwords) in the image filesystem.

#### Job Outputs (Tag Relay Pattern)

```yaml
outputs:
  backend_tag: ${{ needs.backend-build-push.outputs.backend_tag }}
```

The `trivy-backend` job relays the `backend_tag` output from `backend-build-push` so the `deploy` job can depend on `trivy-backend` (not directly on `backend-build-push`) while still knowing the tag. This creates a cleaner dependency chain.

---

### 2.8 Job: `trivy-frontend`

**Name:** `Trivy · Frontend Image Scan`  
**Runner:** `ubuntu-24.04`  
**Needs:** `frontend-build-push`  
**Condition:** `if: success()`

#### Purpose

Scans the Azure-variant frontend image (the one intended for production deployment). Mirrors the backend Trivy job structure.

```yaml
uses: aquasecurity/trivy-action@v0.35.0
with:
  image-ref: ${{ env.REGISTRY }}/${{ env.FRONTEND_IMAGE }}:${{ needs.frontend-build-push.outputs.frontend_azure_tag }}
  exit-code: 0
  severity: 'HIGH,CRITICAL'
  ignore-unfixed: true
  format: 'sarif'
  output: 'trivy-frontend.sarif'
  scanners: 'vuln,secret'
```

Only the Azure tag is scanned; the AWS tag uses the same code base and differs only in the `VITE_BASE_URI` build argument (a URL string), which would not affect vulnerability findings.

#### Job Outputs (Tag Relay)

```yaml
outputs:
  frontend_azure_tag: ${{ needs.frontend-build-push.outputs.frontend_azure_tag }}
  frontend_aws_tag:   ${{ needs.frontend-build-push.outputs.frontend_aws_tag }}
```

---

### 2.9 Job: `test`

**Name:** *(no `name` field — defaults to job key)*  
**Runner:** `ubuntu-24.04`  
**Needs:** `[trivy-backend, trivy-frontend]`  
**Condition:** `if: success()`

#### Purpose

Spins up an ephemeral integration test environment using `docker compose`, executes the full API test suite against it, uploads test artifacts to Azure Blob Storage, sends an email notification with results, and enforces a Pass/Fail quality gate.

#### Steps

**Step 1 — Checkout**
```yaml
- name: Checkout Repository
  uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

**Step 2 — Provision Ephemeral Test Environment**
```yaml
- name: Provision Ephemeral Test Environment
  run: |
    echo "${{ secrets.EMA2A_ENV_FILE_CONTENT }}" >> .env
    docker compose up -d
    sleep 120   # Wait 2 minutes for SQL Server + backend to fully initialise
```

`docker compose up -d` uses `docker-compose.yml` which pulls the `:latest` tags from Docker Hub — the images built in `backend-build-push` and the AWS frontend image from `frontend-build-push`.

**Step 3 — Install Testing Dependencies**
```yaml
- name: Install Testing Dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y curl jq
    wget -qO /tmp/websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
    chmod +x /tmp/websocat && sudo mv /tmp/websocat /usr/local/bin/
```

`websocat` enables WebSocket testing (used for the SignalR `/signHub` endpoint).

**Step 4 — Execute API Tests**
```yaml
- name: Execute API Tests
  run: |
    cd ./backend/API_Test
    chmod +x run_tests.sh
    ./run_tests.sh --verbose --base-url http://localhost || true
```

`|| true` ensures the pipeline continues even if some tests fail — the quality gate in Step 7 handles the pass/fail decision.

**Step 5 — Parse Test Report JSON**
```yaml
- name: Parse Test Report JSON
  id: test_results
  run: |
    LATEST_REPORT=$(readlink -f "./backend/API_Test/reports/report_latest.json")
    TOTAL=$(jq    -r '.summary.total'     $LATEST_REPORT)
    PASSED=$(jq   -r '.summary.passed'    $LATEST_REPORT)
    FAILED=$(jq   -r '.summary.failed'    $LATEST_REPORT)
    PASS_RATE=$(jq -r '.summary.pass_rate' $LATEST_REPORT)

    echo "report_file=$LATEST_REPORT" >> $GITHUB_OUTPUT
    echo "total=$TOTAL"               >> $GITHUB_OUTPUT
    echo "passed=$PASSED"             >> $GITHUB_OUTPUT
    echo "failed=$FAILED"             >> $GITHUB_OUTPUT
    echo "pass_rate=$PASS_RATE"       >> $GITHUB_OUTPUT
```

The test script produces a JSON report at `backend/API_Test/reports/report_latest.json` — a symlink to the timestamp-named actual file. `jq` extracts `total`, `passed`, `failed`, and `pass_rate` fields which are stored as step outputs.

**Step 6a — Authenticate to Azure**
```yaml
- name: Authenticate to Azure
  if: always()
  uses: Azure/login@v2
  continue-on-error: true
  with:
    creds: "${{ secrets.AZURE_CREDENTIALS }}"
```

`if: always()` and `continue-on-error: true` ensure that even if tests fail, the artifact upload and notification still attempt to run.

**Step 6b — Upload Test Artifacts to Azure Blob Storage**
```yaml
- name: Upload Test Artifacts to Azure Blob Storage
  if: always()
  id: upload_blob
  continue-on-error: true
  uses: azure/CLI@v2
  with:
    azcliversion: latest
    inlineScript: |
      # Upload the test report JSON to the private blob container
      az storage blob upload \
        --account-name ${{ secrets.AZURE_STORAGE_ACCOUNT }} \
        --container-name ${{ secrets.AZURE_STORAGE_CONTAINER }} \
        --file $REPORT_PATH \
        --name "reports/$FILE_NAME" \
        --auth-mode login

      # Generate a User Delegation SAS token valid for 24 hours
      EXPIRY=$(date -u -d '24 hours' +%Y-%m-%dT%H:%MZ)
      SAS_URL=$(az storage blob generate-sas \
        --account-name ${{ secrets.AZURE_STORAGE_ACCOUNT }} \
        --container-name ${{ secrets.AZURE_STORAGE_CONTAINER }} \
        --name "reports/$FILE_NAME" \
        --permissions r \
        --expiry $EXPIRY \
        --as-user \
        --full-uri -otsv \
        --auth-mode login)

      echo "sas_url=$SAS_URL" >> $GITHUB_OUTPUT
```

**SAS Token Design:** A **User Delegation SAS** token is used (not an account key SAS). User delegation SAS tokens are more secure because they are signed with Azure AD credentials rather than the storage account key, and they expire automatically after 24 hours.

**Step 6c — Send Notification Email**
```yaml
- name: Send Notification Email
  if: always()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 587
    username: ${{ secrets.MAIL_ACCOUNT }}
    password: ${{ secrets.MAIL_PASSWORD }}
    from: "Ema2a CI/CD <${{ secrets.MAIL_USERNAME }}>"
    to: ${{ secrets.TARGET_EMAIL }}
    subject: Ema2a Pipeline Test Results (${{ steps.test_results.outputs.pass_rate }})
    body: |
      Test execution for Ema2a has completed.

      ✅ Passed:    ${{ steps.test_results.outputs.passed }}
      ❌ Failed:    ${{ steps.test_results.outputs.failed }}
      🔄 Total:     ${{ steps.test_results.outputs.total }}
      📈 Pass Rate: ${{ steps.test_results.outputs.pass_rate }}

      🔗 Secure Artifact Access (Expires in 24h): [SAS URL if upload succeeded]

      Note: Access is restricted. Link is generated dynamically for security.
```

The email body conditionally includes the SAS URL depending on whether the Azure upload step succeeded.

**Step 7 — Enforce Quality Gate**
```yaml
- name: Enforce Quality Gate (Pass/Fail Threshold)
  run: |
    FAILED_TESTS=${{ steps.test_results.outputs.failed }}
    ALLOWED_FAILURES=10

    if [ "$FAILED_TESTS" -gt "$ALLOWED_FAILURES" ]; then
      echo "❌ Pipeline failed! ($FAILED_TESTS) tests failed. Deployment aborted."
      exit 1
    else
      echo "✅ Quality gate passed! Proceeding to Deployment."
      exit 0
    fi
```

**Quality Gate Threshold:** If more than **10 tests fail**, the pipeline returns `exit 1`, which blocks subsequent jobs (including `deploy`). The threshold of 10 allows for minor flakiness while still preventing severely broken builds from reaching production.

---

### 2.10 Job: `deploy`

**Name:** *(no `name` field)*  
**Runner:** `ubuntu-24.04`  
**Needs:** `[trivy-backend, trivy-frontend, test]`  
**Condition:** `if: success()` — requires ALL three predecessors to pass  
**Environment:** `Production` (requires manual approval)

#### Purpose

Deploys the exact immutable image tags (built and security-scanned earlier in the pipeline) to Azure Container Apps. Uses the `Production` environment gate to require a human approval before any production change goes live.

#### Steps

**Step 1 — Authenticate to Azure**
```yaml
- name: Authenticate to Azure
  uses: Azure/login@v2
  with:
    creds: "${{ secrets.AZURE_CREDENTIALS }}"
```

**Step 2 — Deploy Backend**
```yaml
- name: Deploy Backend to Azure Container Apps
  if: needs.trivy-backend.outputs.backend_tag != ''
  uses: Azure/container-apps-deploy-action@v2
  with:
    imageToDeploy: ${{ env.REGISTRY }}/${{ env.BACKEND_IMAGE }}:${{ needs.trivy-backend.outputs.backend_tag }}
    containerAppName: ema2a
    resourceGroup: Ema2a
```

**Step 3 — Deploy Frontend (Azure-specific tag)**
```yaml
- name: Deploy Frontend to Azure Container Apps
  if: needs.trivy-frontend.outputs.frontend_azure_tag != ''
  uses: Azure/container-apps-deploy-action@v2
  with:
    # Critically: uses the *-azure tag, NOT the :latest or *-aws tag
    imageToDeploy: ${{ env.REGISTRY }}/${{ env.FRONTEND_IMAGE }}:${{ needs.trivy-frontend.outputs.frontend_azure_tag }}
    containerAppName: ema2a-webserver
    resourceGroup: Ema2a
```

| Container App | Image Deployed |
|--------------|---------------|
| `ema2a` | `abdelhameed208/graduationproject-backend:<version-tag>` |
| `ema2a-webserver` | `abdelhameed208/graduationproject-frontend:<version-tag>-azure` |

**Critical Design Note:** The deployment explicitly uses `needs.trivy-frontend.outputs.frontend_azure_tag` — the Azure-compiled variant. Using `:latest` would accidentally deploy the AWS variant (which uses a different backend URL), causing API calls to fail.

#### Production Environment Gate

The `environment: Production` field activates GitHub Environments protection rules:
- Required reviewers must approve the deployment before the job can start
- Deployment history is tracked per environment
- Deployment status is visible on the main branch's commit page

---

## 3. Workflow: `CodeQl.yml` — Deep Security Analysis

**File:** `.github/workflows/CodeQl.yml`  
**Trigger:** Push to `main` | Manual (`workflow_dispatch`)  
**Runner:** `ubuntu-latest`

### Purpose

Performs deep semantic code analysis using GitHub's **CodeQL** engine, which understands the control flow and data flow of the application. Unlike SonarCloud (which uses pattern matching), CodeQL can detect complex multi-step vulnerabilities like SQL injection chains, XSS via tainted data flows, and logical flaws.

### Strategy Matrix

```yaml
strategy:
  fail-fast: false
  matrix:
    language: [ 'csharp', 'javascript-typescript' ]
```

Two parallel CodeQL jobs run simultaneously:
- **`csharp`** — scans `backend/` for C# vulnerabilities
- **`javascript-typescript`** — scans `frontend/` for JS/TS vulnerabilities

`fail-fast: false` ensures both analyses complete even if one finds critical issues.

### Steps

```yaml
1. Checkout Repository

2. Initialize CodeQL
   uses: github/codeql-action/init@v3
   with:
     languages: ${{ matrix.language }}
     queries: security-extended,security-and-quality
   # security-extended = broadest ruleset, including CWE coverage

3. Setup .NET (C# only)
   if: matrix.language == 'csharp'
   uses: actions/setup-dotnet@v4
   with:
     dotnet-version: '8.0.x'

4. Build C# Backend (C# only)
   if: matrix.language == 'csharp'
   run: |
     cd ./backend
     dotnet restore
     dotnet build
   # CodeQL traces the build to understand code structure

5. Perform CodeQL Analysis
   uses: github/codeql-action/analyze@v3
   with:
     category: "/language:${{ matrix.language }}"
```

**Query Suites:**
- `security-extended` — extensive security queries including OWASP Top 10 coverage
- `security-and-quality` — combines security with code quality/reliability queries

Results are reported in the GitHub Security → Code Scanning Alerts tab.

---

## 4. Workflow: `sonar-flutter.yml` — Flutter Mobile Analysis

**File:** `.github/workflows/sonar-flutter.yml`  
**Trigger:** Push/PR to `DEV`/`main` when `flutter/**` changes | Manual dispatch

### Purpose

Runs the Flutter test suite with code coverage and uploads results to SonarCloud for quality tracking of the mobile application. Completely independent from the main CI/CD pipeline.

### Steps

```yaml
1. Checkout Repository (fetch-depth: 0)

2. Set up JDK 17 (Zulu distribution)

3. Set up Flutter SDK
   uses: subosito/flutter-action@v2
   with:
     flutter-version: '3.41.6'
     channel: 'stable'
     cache: true

4. Cache Pub Dependencies
   - path: ~/.pub-cache
   - key: ${{ runner.os }}-pub-${{ hashFiles('flutter/pubspec.lock') }}

5. Cache SonarCloud Packages

6. Install Dependencies
   working-directory: flutter
   run: flutter pub get

7. Run Tests with Coverage
   working-directory: flutter
   run: flutter test --coverage || true
   # || true — Sonar analysis runs regardless of test failures

8. Install SonarScanner CLI
   run: npm install -g sonar-scanner

9. Run Sonar Analysis
   working-directory: flutter
   env:
     GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
     SONAR_TOKEN:  ${{ secrets.SONAR_TOKEN }}
   run: |
     sonar-scanner \
       -Dsonar.token="${{ secrets.SONAR_TOKEN }}" \
       -Dsonar.host.url="https://sonarcloud.io"
```

The SonarCloud configuration is read from `flutter/sonar-project.properties` (the `working-directory: flutter` setting makes this the relative root).

**Flutter Version:** `3.41.6` (stable channel) — pinned to match the version specified in `pubspec.yaml` (`sdk: ^3.10.0`).

---

## 5. Workflow: `sonar-hardware.yml` — Hardware Service Analysis

**File:** `.github/workflows/sonar-hardware.yml`  
**Trigger:** Push/PR to `DEV`/`main` when `Hardware-Service/**` changes | Manual dispatch

### Purpose

Analyzes the **Python** hardware service code using SonarCloud. Like the Flutter workflow, it is completely isolated from the main pipeline and only runs when relevant files change.

### Steps

```yaml
1. Checkout Repository (fetch-depth: 0)

2. Set up JDK 17 (Zulu)

3. Cache SonarCloud Packages

4. Install SonarScanner CLI
   run: npm install -g sonar-scanner

5. Run Sonar Analysis
   working-directory: Hardware-Service
   env:
     GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
     SONAR_TOKEN:  ${{ secrets.SONAR_TOKEN }}
   run: |
     sonar-scanner \
       -Dsonar.token="${{ secrets.SONAR_TOKEN }}" \
       -Dsonar.host.url="https://sonarcloud.io"
```

The SonarCloud configuration is read from `Hardware-Service/sonar-project.properties` (the `working-directory: Hardware-Service` makes this the root). No test execution or coverage collection is performed in this workflow — Sonar runs static analysis only.

---

## 6. Pipeline Dependency Graph

```
main.yml — Job Dependency Graph
═══════════════════════════════════════════════════════════════════════

                    ┌────────────────────┐   ┌──────────────────────────┐
                    │   sonar-backend    │   │  sonar-frontend-devops   │
                    │ (.NET SonarCloud)  │   │ (React+DevOps SonarCloud)│
                    └────────┬───────────┘   └───────────┬──────────────┘
                             │  (both must pass)         │
                    ┌────────┴───────────────────────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
         ▼                     ▼
┌────────────────┐    ┌─────────────────────┐
│backend-build-  │    │ frontend-build-push  │
│push            │    │ (Azure + AWS images) │
│(.NET image)    │    │                      │
└────────┬───────┘    └──────────┬───────────┘
         │                       │
         ▼                       ▼
┌────────────────┐    ┌──────────────────────┐
│  trivy-backend │    │   trivy-frontend      │
│  (CVE scan)    │    │   (CVE scan)          │
└────────┬───────┘    └──────────┬────────────┘
         │                       │
         └───────────┬───────────┘
                     │ (both must pass)
                     ▼
              ┌─────────────┐
              │    test      │
              │ (Integration │
              │  Tests +     │
              │  Quality     │
              │  Gate)       │
              └──────┬───────┘
                     │
                     ▼
              ┌─────────────────────────────┐
              │          deploy              │
              │ (Production Env Approval →   │
              │  Azure Container Apps)       │
              └─────────────────────────────┘

═══ PARALLEL WORKFLOWS (independent, path-triggered) ═══════════════════

flutter/**  ──► sonar-flutter.yml     (Flutter + Dart SonarCloud)
Hardware-Service/** ──► sonar-hardware.yml (Python SonarCloud)
main push ──► CodeQl.yml              (Deep semantic analysis)
```

---

## 7. Secrets & Environment Variables

All secrets are defined at the **repository level** in GitHub Settings → Secrets and Variables → Actions.

| Secret Name | Used By | Description |
|-------------|---------|-------------|
| `GITHUB_TOKEN` | All Sonar jobs, CodeQL | Automatically provided by GitHub; used for PR decoration and SARIF upload |
| `SONAR_TOKEN` | All Sonar jobs | SonarCloud project analysis token |
| `DOCKER_USERNAME` | `backend-build-push`, `frontend-build-push` | Docker Hub login username |
| `DOCKER_PASSWORD` | `backend-build-push`, `frontend-build-push` | Docker Hub password or access token |
| `EMA2A_ENV_FILE_CONTENT` | `sonar-backend`, `test` | Full content of the `.env` file (all app secrets) |
| `VITE_BASE_URI_AZURE` | `frontend-build-push` | Backend URL baked into the Azure frontend bundle |
| `VITE_BASE_URI_AWS` | `frontend-build-push` | Backend URL baked into the AWS frontend bundle |
| `AZURE_CREDENTIALS` | `test`, `deploy` | JSON service principal: `{ clientId, clientSecret, subscriptionId, tenantId }` |
| `AZURE_STORAGE_ACCOUNT` | `test` | Azure Storage account name for test report upload |
| `AZURE_STORAGE_CONTAINER` | `test` | Blob container name (`ema2a-apitest-reports`) |
| `MAIL_ACCOUNT` | `test` | Gmail address used for SMTP authentication |
| `MAIL_PASSWORD` | `test` | Gmail app-specific password |
| `MAIL_USERNAME` | `test` | Display name / sender address in notification emails |
| `TARGET_EMAIL` | `test` | Recipient address for CI test notification emails |

### Environment-Level Protection (`Production`)

The `deploy` job targets the `Production` GitHub Environment. This environment must be configured in the repository settings with:
- **Required reviewers** — one or more GitHub users who must approve before the job proceeds
- **Wait timer** (optional) — delay between approval and execution
- **Branch restrictions** — only allow deployment from `main` branch

---

## 8. Tools Used

| Tool | Version | Purpose | Job(s) |
|------|---------|---------|--------|
| **GitHub Actions** | N/A | CI/CD orchestration | All |
| **SonarCloud** | Latest | SAST, code quality, code smells | `sonar-backend`, `sonar-frontend-devops`, `sonar-flutter`, `sonar-hardware` |
| **dotnet-sonarscanner** | Latest | .NET MSBuild Sonar integration | `sonar-backend` |
| **sonar-scanner** (CLI) | Latest | Language-agnostic Sonar CLI | `sonar-frontend-devops`, `sonar-flutter`, `sonar-hardware` |
| **GitHub CodeQL** | v3 | Deep semantic security analysis | `CodeQl.yml` |
| **Trivy** | v0.35.0 | Container image CVE + secret scanning | `trivy-backend`, `trivy-frontend` |
| **Docker Buildx** | v4 | BuildKit-powered image builds with registry caching | `backend-build-push`, `frontend-build-push` |
| **docker/build-push-action** | v7 | Build and push Docker images | `backend-build-push`, `frontend-build-push` |
| **dorny/paths-filter** | v3 | Detect which paths changed to skip unnecessary builds | `backend-build-push`, `frontend-build-push` |
| **Azure Container Apps Deploy** | v2 | Deploy updated images to Container Apps | `deploy` |
| **Azure CLI** | Latest | Blob storage upload + SAS token generation | `test` |
| **dawidd6/action-send-mail** | v3 | Email notification via Gmail SMTP | `test` |
| **subosito/flutter-action** | v2 | Install Flutter SDK | `sonar-flutter` |
| **websocat** | Latest | WebSocket testing for SignalR hub | `test` |
| **jq** | System package | JSON parsing for test report | `test` |
| **Infisical CLI** | Latest | Secret fetching on EC2 backup (via systemd, not CI) | N/A |

---

## 9. Tag & Versioning Strategy

### Backend Tag Format

```
abdelhameed208/graduationproject-backend:<VERSION_TAG>
abdelhameed208/graduationproject-backend:latest
```

### Frontend Tag Format

```
abdelhameed208/graduationproject-frontend:<VERSION_TAG>-azure
abdelhameed208/graduationproject-frontend:<VERSION_TAG>-aws
abdelhameed208/graduationproject-frontend:latest         (= aws image)
```

### Version Tag Formula

```bash
COUNT=$(git rev-list --count HEAD <directory>/)   # Commits that touched this directory
SHA=$(git rev-parse --short HEAD)                  # 7-char commit hash
TAG="v1.0-${COUNT}-${SHA}"
```

**Example:** `v1.0-47-a3f9b12`

| Component | Example | Meaning |
|-----------|---------|---------|
| `v1.0` | `v1.0` | Manual major.minor version prefix |
| `47` | Commit count | Monotonically increasing build number |
| `a3f9b12` | Short SHA | Unique commit reference |
| `-azure` / `-aws` | Suffix | Target deployment environment (frontend only) |

**Why not just use `:latest`?**  
Using only `:latest` would make it impossible to roll back to a previous version without rebuilding. The immutable versioned tags allow the `deploy` job to reference the exact image built and scanned in the same pipeline run, and Azure Container Apps can be instructed to roll back to any previous tag.

**Build Cache Tags:**

| Cache Tag | Purpose |
|-----------|---------|
| `buildcache` | Backend layer cache |
| `buildcache-azure` | Azure frontend layer cache |
| `buildcache-aws` | AWS frontend layer cache |

These cache tags are never used as deployment targets — they are internal to the CI build process.

---

## 10. SonarCloud Configuration

### Projects

| SonarCloud Project Key | Project Name | Source Files |
|------------------------|--------------|-------------|
| `Abdelhamid108_GraduationProjectDotNet-Deploy` | *(Backend)* | `backend/` |
| `Abdelhamid108_ema2a-frontend-devops` | `Ema2a Frontend & DevOps` | `frontend/src`, `DevOps/`, Dockerfiles, compose files |
| `Abdelhamid108_ema2a-frontend` | `Ema2a Frontend` | `frontend/src` (standalone) |
| *(flutter project key in pubspec)* | Mobile (Flutter/Dart) | `flutter/` |
| *(hardware project key in properties)* | Hardware (Python) | `Hardware-Service/` |

### `sonar-frontend-devops.properties` Configuration

```properties
sonar.projectKey=Abdelhamid108_ema2a-frontend-devops
sonar.organization=abdelhamid108
sonar.projectName=Ema2a Frontend & DevOps

sonar.sources=frontend/src,DevOps,backend/Dockerfile,frontend/Dockerfile,\
  docker-compose.yml,docker-compose.local.yml,docker-compose-backup-deployment.yml

sonar.typescript.tsconfigPath=frontend/tsconfig.app.json

sonar.exclusions=**/node_modules/**,**/dist/**,**/.terraform/**,\
  **/*.tfstate,**/*.tfstate.backup,**/*.tfplan,**/.terraform.lock.hcl
```

**Why combine Frontend + DevOps in one project?** The DevOps code (Terraform, Ansible, Dockerfiles) does not warrant a separate analysis job — adding it to the existing frontend job shares the JDK and Sonar cache setup without additional pipeline overhead.

---

## 11. Quality Gates

### Integration Test Quality Gate

```bash
ALLOWED_FAILURES=10
if [ "$FAILED_TESTS" -gt "$ALLOWED_FAILURES" ]; then
  exit 1   # Block deployment
fi
```

| Threshold | Effect |
|-----------|--------|
| ≤ 10 failures | Pipeline continues to `deploy` |
| > 10 failures | Pipeline fails; deployment blocked |

This threshold exists to tolerate minor test flakiness (network issues in the ephemeral environment, timing-sensitive WebSocket tests) while still blocking severely broken builds.

### SAST Gate

Both `sonar-backend` and `sonar-frontend-devops` must **exit 0** for `backend-build-push` and `frontend-build-push` to proceed. If either Sonar job fails (e.g., compilation error, token revoked), the entire pipeline stops after the SAST stage.

### Security Scan Gate

`trivy-backend` and `trivy-frontend` use `exit-code: 0` — findings are **reported but do not block**. This is appropriate for the current project stage (awareness, not enforcement). In a mature production pipeline, this would be changed to `exit-code: 1` with defined severity thresholds.

### Production Deployment Gate

The `deploy` job is protected by the `Production` GitHub Environment — a human reviewer must explicitly approve the deployment before it runs. This provides a final manual safety check even after all automated gates pass.
