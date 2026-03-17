# Docker Containerization Documentation
**Version:** 0.1.3

This document details the containerization strategy for the application, including the Docker Compose configuration and individual Dockerfiles for each service.

## 1. Architecture Overview

The application is orchestrated using **Docker Compose**, managing three primary services:
1.  **Backend**: .NET 8 Web API.
2.  **Nginx**: Reverse proxy and SSL termination.
3.  **Database**: MS SQL Server (internal access only).

## 2. Docker Compose Configuration

The `docker-compose.yml` file defines the services, networks, and volumes.

### Services Breakdown

| Service    | Image                                          | Ports               | Networks                 | Dependencies |
| :--------- | :--------------------------------------------- | :------------------ | :----------------------- | :----------- |
| `backend`  | `graduationproject-backend:latest`             | `5001:5001`         | `local`, `api_network`   | `database`   |
| `nginx`    | `graduationproject-nginx:latest`               | `80:80`, `443:443`  | `api_network`            | `backend`    |
| `database` | `mcr.microsoft.com/mssql/server:2025-latest`   | None (Internal)     | `local`                  | None         |

### Environment Variables
Configuration is injected via environment variables. In local development (`docker-compose.local.yml`), `backend/.env` is used as the env file.

| Service    | Variable                  | Description                                      | Value / Source |
| :--------- | :------------------------ | :----------------------------------------------- | :------------- |
| `backend`  | `ASPNETCORE_URLS`         | URLs the app listens on.                         | `http://+:5001`|
| `backend`  | `DEFAULT_CONNECTION`      | SQL Connection String.                           | Constructed from DB vars.|
| `backend`  | `ASPNETCORE_ENVIRONMENT`  | Runtime environment mode.                        | `Development`  |
| `backend`  | `HARDWARE_TTS_KEY`        | Azure Speech key for hardware/audio endpoints.   | `backend/.env` |
| `backend`  | `ENDPOINT`                | Azure Speech endpoint URL for STT recognition.   | `backend/.env` |
| `nginx`    | `CERT_PATH`               | Path to SSL certificates on host.                | `${CERT_PATH:-./Dev}`|
| `database` | `MSSQL_SA_PASSWORD`       | System Administrator password.                   | `${DB_ADMIN_PASS}`|
| `database` | `ACCEPT_EULA`             | Acceptance of MS SQL License.                    | `Y`            |

### Networks
Two isolated networks are used to enhance security:

| Network Name  | Driver   | Purpose                                                  |
| :------------ | :------- | :------------------------------------------------------- |
| `api_network` | `bridge` | Public-facing network connecting Nginx and Backend.      |
| `local`       | `bridge` | Internal, private network connecting Backend and Database.|

### Volumes
Persistent storage and configuration mounts:

| Volume/Path              | Target                         | Purpose                                          |
| :----------------------- | :----------------------------- | :----------------------------------------------- |
| `./AIModels`             | `/app/AIModels`                | Live updates for AI models without rebuilding.   |
| `./nginx-proxy/public`   | `/usr/share/nginx/html`        | Serving static frontend files.                   |
| `db` (Named Volume)      | `/var/opt/mssql`               | Persistent storage for SQL Server data.          |
| `./Dev` (Cert Path)      | `/etc/letsencrypt/...`         | SSL Certificates (Read-Only).                    |

## 3. Dockerfile Details

### Backend (`backend/Dockerfile`)
A multi-stage build optimized for .NET 8.

**Stage 1: Build**
*   Base Image: `mcr.microsoft.com/dotnet/sdk:8.0`
*   Actions: Restores dependencies and publishes the release build to `/app/publish`.

**Stage 2: Runtime**
*   Base Image: `mcr.microsoft.com/dotnet/aspnet:8.0`
*   **Garbage Collection Optimization**:
    *   `DOTNET_gcServer=1`: Enables Server GC for high throughput.
    *   `DOTNET_GCHeapCount=2`: Matches the 2 vCPUs allocated.
    *   `DOTNET_GCHeapHardLimit=0x60000000`: Limits heap to 1.5GB to prevent OOM kills.

### Nginx (`nginx-proxy/Dockerfile`)
A lightweight proxy server.

*   Base Image: `nginx:alpine`
*   Configuration: Copies `nginx-proxy.conf` to `/etc/nginx/conf.d/`.
*   Exposed Ports: 80, 443.
*   Command: Runs Nginx in the foreground (`daemon off;`).

## 4. Operational Guide

### Starting the Stack
```bash
docker compose up -d
```

### Stopping the Stack
```bash
docker compose down
```

### Viewing Logs
```bash
docker compose logs -f backend
```

### Rebuilding a Specific Service
```bash
docker compose build backend
docker compose up -d backend
```

## 5. Troubleshooting

### Common Issues

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **Container Exits Immediately** | Application crash or missing env var. | Check logs: `docker compose logs <service>`. |
| **Connection Refused** | Service not ready or wrong port. | Verify `ports` mapping and `healthcheck`. |
| **Permission Denied** | Volume mount permissions. | Check host directory ownership (`chown`). |
| **OOM Killed** | Container exceeded memory limit. | Increase `deploy.resources.limits.memory`. |

### Maintenance Commands

| Command | Description |
| :--- | :--- |
| `docker system prune -a` | Remove all unused images, containers, and networks. |
| `docker volume prune` | Remove all unused volumes (WARNING: Data Loss). |
| `docker stats` | Live view of container resource usage (CPU/RAM). |
