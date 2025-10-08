# System Architecture & Flow Overview
This document provides a technical overview of the project's architecture, container setup, and data flow, intended to help the development team understand how the components interact.

## 1. System Architecture
The application uses a containerized, multi-service architecture to separate concerns and improve scalability.

### Core Components:
- **Frontend (Nginx Reverse Proxy):** Serves static UI files and acts as a secure gateway, routing API requests to the backend.  
- **Backend (.NET 8 API):** The core application server handling business logic, user authentication, data processing, AI model interaction, and database communication.  
- **Database (MS SQL Server):** The system's persistent data store for user information, history, etc.  
- **AI Models:** ONNX models used for sign language translation, loaded directly by the backend service.

### Architecture Diagram
This diagram shows the high-level interaction between the system's components.
---
![System Architecture](https://drive.google.com/uc?id=1i9VWWZD-4O8nzSUBWEwMkehu8Q5qoks_)
---

## 2. Infrastructure & Containerization
The application is orchestrated using Docker Compose, with the configuration defined in `docker-compose.yml`.

### Service Overview

| Service   | Image/Dockerfile              | Exposed Ports  | Networks             | Key Responsibilities |
|-----------|-------------------------------|--------------- |----------------------|-----------------------|
| nginx     | ./nginx-proxy/Dockerfile      | 80, 443        | api_network          | Serves frontend, SSL termination, reverse proxy. |
| backend   | ./backend/Dockerfile          | 5001           | api_network, local   | Core application logic, API endpoints. |
| database  | mcr.microsoft.com/mssql/server| -              | local                | Data persistence. |

### Networking
Two isolated networks manage communication between services:
- **api_network:** An external-facing network connecting the nginx proxy to the backend.  
- **local:** A private, internal network allowing the backend to communicate securely with the database, which is not exposed externally.

---

## 3. Request & Data Flow
This section details the journey of a user request through the system.

## Request & Data Flow Diagram

```mermaid
sequenceDiagram
    participant User as User (Browser)
    participant Nginx as Nginx (Reverse Proxy)
    participant Backend as Backend API (.NET)
    participant DB as Database (MS SQL)

    User->>Nginx: HTTPS Request
    Nginx->>Backend: HTTP Request
    Backend->>DB: DB Query
    DB-->>Backend: DB Result
    Backend-->>Nginx: HTTP Response
    Nginx-->>User: HTTPS Response

---
### Flow Explanation:
1. **Client Request:** The user's browser sends an HTTPS request to an API endpoint (e.g., `/api/login-user`).  
2. **SSL Termination & Proxy:** The nginx service receives the request, handles SSL, and inspects the URL path.  
3. **Routing:** As the path starts with `/api/`, Nginx's configuration forwards the request internally to the backend service at `http://backend:5001`.  
4. **Business Logic:** The .NET backend processes the request, executing the relevant business logic.  
5. **Database Interaction:** If necessary, the backend connects to the database over the secure local network to read or write data.  
6. **Response Generation:** The backend creates a JSON response.  
7. **Return Journey:** The response is sent back through nginx to the user's browser via HTTPS.

---

## 4. API Documentation
For a detailed guide on all available API endpoints, request bodies, and response schemas, please refer to the **API Documentation**.



