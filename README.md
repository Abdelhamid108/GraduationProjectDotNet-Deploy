<div align="center">

# 🤝 ايماءه — Ema2a

### An AI-Powered Arabic Sign Language Translation Platform

**Bridging the communication gap between the deaf community and the hearing world**

[![CI/CD](https://github.com/Abdelhamid108/GraduationProjectDotNet-Deploy/actions/workflows/main.yml/badge.svg)](https://github.com/Abdelhamid108/GraduationProjectDotNet-Deploy/actions/workflows/main.yml)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=Abdelhamid108_GraduationProjectDotNet-Deploy&metric=alert_status)](https://sonarcloud.io/project/overview?id=Abdelhamid108_GraduationProjectDotNet-Deploy)
[![Security](https://sonarcloud.io/api/project_badges/measure?project=Abdelhamid108_GraduationProjectDotNet-Deploy&metric=security_rating)](https://sonarcloud.io/project/overview?id=Abdelhamid108_GraduationProjectDotNet-Deploy)

</div>

---

## 📖 Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Components](#3-components)
   - [Backend — .NET 8 API](#31-backend--net-8-api)
   - [Frontend — React Web App](#32-frontend--react-web-app)
   - [Mobile App — Flutter](#33-mobile-app--flutter)
   - [Hardware Module — Raspberry Pi](#34-hardware-module--raspberry-pi)
4. [Features](#4-features)
5. [AI Models](#5-ai-models)
6. [Technology Stack](#6-technology-stack)
7. [API Overview](#7-api-overview)
8. [Getting Started — Local Development](#8-getting-started--local-development)
9. [Deployment](#9-deployment)
10. [CI/CD Pipeline](#10-cicd-pipeline)
11. [Repository Structure](#11-repository-structure)
12. [Documentation](#12-documentation)
13. [Security](#13-security)
14. [Team](#14-team)

---

## 1. Project Overview

**ايماءه (Ema2a)** is a graduation project that provides an end-to-end Arabic Sign Language (ArSL) translation platform. The system enables real-time communication between deaf/hard-of-hearing individuals and the hearing world through multiple interfaces — a web application, a mobile app, and a physical Raspberry Pi hardware device.

### The Problem

Deaf and hard-of-hearing individuals face significant communication barriers with people who do not understand sign language. Existing tools are either language-limited (English only), require expensive hardware, or lack real-time capability.

### The Solution

Ema2a provides:
- **Real-time sign language recognition** using a custom-trained ONNX AI model
- **Arabic sentence construction and AI correction** (Groq LLaMA 3.3 / internal NLP)
- **Text-to-speech audio output** (Azure Speech Services / gTTS fallback)
- **Multi-platform access** — Web, Mobile (iOS/Android), and physical hardware

---

## 2. System Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                                 │
│                                                                      │
│   🌐 Web App (React/TS)    📱 Mobile App (Flutter)                  │
│   Sign via webcam          Sign via phone camera                     │
│                                                                      │
│   🖥️ Hardware Device (Raspberry Pi + Camera)                        │
│   Standalone portable translator                                     │
└───────────────────────────────┬──────────────────────────────────────┘
                                │  HTTPS / WebSocket (SignalR)
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    REVERSE PROXY (Nginx)                             │
│   /api/*  ──► Backend      /signHub  ──► SignalR    /*  ──► SPA    │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      BACKEND (.NET 8 API)                            │
│                                                                      │
│  ┌─────────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │  Sign Language  │  │   Arabic NLP │  │   Auth & User Mgmt     │  │
│  │  Translator     │  │   Translator │  │   JWT + Google OAuth   │  │
│  │  (ONNX Model)   │  │   (AI/NLP)   │  │                        │  │
│  └─────────────────┘  └──────────────┘  └────────────────────────┘  │
│                                                                      │
│        Azure Speech Services (TTS/STT)    SignalR Hub                │
└──────────┬───────────────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      DATA LAYER                                      │
│   MS SQL Server (Azure SQL / Docker)   Azure Files (User Images)    │
└──────────────────────────────────────────────────────────────────────┘

   PRIMARY DEPLOYMENT                    BACKUP DEPLOYMENT
   ─────────────────                     ─────────────────
   Azure Container Apps                  AWS EC2 (c7i-flex.large)
   Auto-scale 0–5 replicas              Wake-on-request via Lambda
   test.ema2a.website                   backup.ema2a.website
```

---

## 3. Components

### 3.1 Backend — .NET 8 API

**Directory:** `backend/`

The core of the system — a RESTful API built with ASP.NET Core 8 that handles all business logic, AI inference, and real-time communication.

**Key capabilities:**
- **Sign Language Recognition** — receives Base64-encoded frames, runs inference through a custom ONNX model, returns detected Arabic letter/gesture
- **Arabic Sentence Builder** — tracks letter sequences and finalizes them into full sentences
- **AI Sentence Correction** — corrects grammatically incomplete sentences using NLP
- **Text-to-Speech** — converts corrected Arabic text to audio (Azure Speech, with gTTS fallback for hardware)
- **Authentication** — JWT Bearer tokens, refresh tokens, Google OAuth 2.0, email OTP password reset
- **Real-time** — SignalR hub at `/signHub` for live translation streaming
- **Rate Limiting** — per-endpoint rate limits for all public endpoints

| Endpoint Group | Prefix |
|----------------|--------|
| Authentication | `/api/Auth` |
| Sign Language Translator | `/api/SignLanguageTranslator` |
| Arabic Language Translator | `/api/ArabicLanguageTranslator` |
| User History | `/api/UserHistory` |

---

### 3.2 Frontend — React Web App

**Directory:** `frontend/`

A modern React + TypeScript SPA, built with Vite and served by a hardened Nginx container.

**Key features:**
- Live sign language translation via webcam using SignalR WebSocket connection
- Arabic text-to-sign conversion
- User authentication (register, login, Google OAuth, password reset)
- User history and profile management
- Fully RTL Arabic UI (Cairo & Poppins fonts)

**Tech stack:**
- React 18 + TypeScript
- Vite build tool
- React Router v6
- Sonner (toast notifications)
- Tailwind CSS

The frontend image is built at CI time with the backend URL baked in (`VITE_BASE_URI`). **Two variants are produced** per pipeline run — one for Azure, one for AWS — because the backend URLs differ between environments.

---

### 3.3 Mobile App — Flutter

**Directory:** `flutter/`

A cross-platform Flutter app (iOS & Android) providing the same sign language translation experience via the phone's camera.

**Key features:**
- Live camera capture and real-time gesture recognition via API
- SignalR integration (`signalr_netcore`) for streaming results
- Audio playback of translated sentences (`audioplayers`)
- User authentication with JWT token management (`get_storage`)
- Supports Arabic & Poppins / Cairo fonts

**Flutter version:** 3.41.6 (stable channel)  
**Dart SDK:** ^3.10.0

---

### 3.4 Hardware Module — Raspberry Pi

**Directory:** `Hardware-Service/`

A standalone Python service that runs on a **Raspberry Pi 4** with a Camera Module 2, acting as a portable physical sign language translator.

**How it works:**
1. Continuously captures frames via `picamera2`
2. Sends each frame (Base64) to `/api/SignLanguageTranslator`
3. Builds detected letters into a sentence
4. After a 90-second silence timeout, finalizes the sentence via `/api/SignLanguageTranslator/finalize-sentence`
5. Sends the corrected sentence to the backend TTS endpoint (falls back to `gTTS` if unavailable)
6. Plays the audio output through the speaker via `aplay` / `mpg123`
7. Plays a **beep** on each successful gesture detection

Runs as a **systemd service** (`sign-translator.service`) that auto-starts on boot.

**Hardware requirements:**

| Component | Description |
|-----------|-------------|
| Raspberry Pi 4 | Main compute device |
| Camera Module 2 | Gesture capture |
| Speaker | Audio output |
| MicroSD Card | OS storage |
| 5V/3A Power Supply | Stable power |

---

## 4. Features

| Feature | Web | Mobile | Hardware |
|---------|:---:|:------:|:--------:|
| Real-time sign language recognition | ✅ | ✅ | ✅ |
| Arabic sentence construction | ✅ | ✅ | ✅ |
| AI sentence correction | ✅ | ✅ | ✅ |
| Text-to-speech output | ✅ | ✅ | ✅ |
| Text-to-sign (reverse) | ✅ | ✅ | ❌ |
| User registration & login | ✅ | ✅ | Optional |
| Google OAuth sign-in | ✅ | ✅ | ❌ |
| User history tracking | ✅ | ✅ | ❌ |
| Offline operation | ❌ | ❌ | Partial* |

> *Hardware falls back to local `gTTS` for TTS when the backend is unreachable.

---

## 5. AI Models

ايماءه uses a custom-trained computer vision model served by the backend as an in-process ONNX inference session — no external AI API call is made for gesture recognition.

### 5.1 Model Files

| File | Size | Purpose |
|------|------|---------|
| `AIModels/best.onnx` | ~11.6 MB | **Primary production model** — Arabic Sign Language letter recognition (ArSL) |
| `AIModels/ASL.onnx` | ~11.6 MB | American Sign Language (ASL) letter recognition (alternative/research) |
| `AIModels/WordsModel.onnx` | ~29.4 MB | Full Arabic word/phrase recognition (extended vocabulary model) |

All three ONNX files are bundled directly inside the backend Docker image and copied to `/app/AIModels/` at build time.

---

### 5.2 Model Architecture — YOLOv8 Object Detection

The models follow the **YOLOv8** (You Only Look Once v8) architecture — a single-stage object detector that simultaneously predicts bounding boxes and class probabilities in one forward pass.

```
Input Frame (JPEG / Base64)
        │
        ▼
  Decode → Resize to 256×256
        │
        ▼
  Normalize pixels to [0.0, 1.0]
  (R/255, G/255, B/255)
        │
        ▼
  Build input tensor [1, 3, 256, 256]
  (Batch=1, Channels=3, H=256, W=256)
        │
        ▼
  ONNX Runtime Inference (best.onnx)
  Input name: "images"
  Output name: "output0"
        │
        ▼
  Output tensor [1, (4 + num_classes), num_detections]
  └── 4 bbox attributes: cx, cy, w, h
  └── num_classes scores (sigmoid-activated)
        │
        ▼
  Filter by confidence threshold (0.05)
        │
        ▼
  Non-Maximum Suppression (IoU threshold: 0.45)
        │
        ▼
  Return: top detection { ArabicLabel, EnglishLabel, BBox, Confidence }
```

---

### 5.3 Inference Pipeline (Code Level)

The `ModelService` is registered as a **Singleton** in `Program.cs`, meaning the ONNX session is loaded once at startup and reused for every request:

```csharp
builder.Services.AddSingleton<IModelService, ModelService>();
```

**Session initialisation:**
```csharp
var sessionOptions = new SessionOptions
{
    ExecutionMode         = ExecutionMode.ORT_SEQUENTIAL,
    GraphOptimizationLevel = GraphOptimizationLevel.ORT_ENABLE_ALL
};
_onnxSession = new InferenceSession(modelPath, sessionOptions);
```

- `ORT_SEQUENTIAL` — single-threaded execution, avoids thread contention in a web server context
- `ORT_ENABLE_ALL` — enables all ONNX Runtime graph optimisations (operator fusion, constant folding)

**Thread safety:**
A `SemaphoreSlim(1, 1)` guards the shared `_inputTensor` so that concurrent API requests do not corrupt each other's pixel data:

```csharp
await _semaphore.WaitAsync();
try   { /* preprocess + run inference */ }
finally { _semaphore.Release(); }
```

---

### 5.4 Non-Maximum Suppression (NMS)

After inference, raw detections are filtered using NMS to eliminate duplicate bounding boxes for the same gesture:

1. **Sort** all detections by confidence score (highest first)
2. **Pick** the highest-confidence detection → add to final results
3. **Remove** all remaining detections of the same class with **IoU > 0.45** (overlapping boxes)
4. **Repeat** until no detections remain

The IoU (Intersection over Union) formula:
```
         Area of Overlap
IoU = ──────────────────────
         Area of Union
```

| Parameter | Value | Effect |
|-----------|-------|--------|
| `CONF_THRESHOLD` | `0.05` | Minimum confidence to consider a detection valid |
| `IOU_THRESHOLD` | `0.45` | Maximum overlap allowed before a box is suppressed |

---

### 5.5 Memory Management — GC Tuning

ONNX Runtime loads native (unmanaged) memory for model weights and activations. The .NET Garbage Collector cannot see this memory, which can cause the GC to under-estimate heap pressure and delay collection cycles.

The backend Docker image sets a **hard memory cap** on the GC heap to force more frequent collections:

```dockerfile
# backend/Dockerfile
ENV DOTNET_GCHeapHardLimit=0x60000000   # ~1.5 GB GC heap hard limit
```

This prevents unmanaged ONNX memory (~200–400 MB for the models) from starving the container when Azure/AWS sets a memory limit on the pod/instance.

---

### 5.6 Labels — Supported Gestures

The primary model (`best.onnx`) classifies **Arabic Sign Language letters**. Each detected class is mapped to both an Arabic and an English label:

```csharp
private readonly string[] _arabicLabels = Labels._arabicLabels;
private readonly string[] _englishLabels = Labels._englishLabels;
```

The label arrays cover the full ArSL alphabet (أ ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي) plus common word gestures supported by `WordsModel.onnx`.

---

### 5.7 Sentence Construction Flow

```
Frame 1  → Detected: "م"
Frame 2  → Detected: "م"  (same — stable over N frames, counted once)
Frame 3  → Detected: "ر"
Frame 4  → No detection (pause...)
                ↓
        After timeout / finalize call:
        Raw sentence: "مرحبا كيف ححالك"
                ↓
        POST /finalize-sentence
        → NLP correction via backend AI
        → Corrected: "مرحبا كيف حالك"
                ↓
        POST /generate-audio
        → Azure Speech TTS
        → Returns Base64 WAV audio
```

---

## 6. Technology Stack

### Application

| Layer | Technology | Version |
|-------|-----------|---------|
| Backend API | ASP.NET Core | .NET 8 |
| ORM | Entity Framework Core | 9.x |
| Real-time | SignalR | ASP.NET Core built-in |
| AI Inference | ONNX Runtime | Embedded |
| Speech | Azure Cognitive Services (Speech) | Cloud |
| Frontend | React + TypeScript + Vite | React 18 |
| Mobile | Flutter / Dart | 3.41.6 |
| Hardware | Python | 3.9+ |
| Database | Microsoft SQL Server | 2025 |
| Reverse Proxy | Nginx | Alpine |

### DevOps & Infrastructure

| Category | Tool |
|----------|------|
| CI/CD | GitHub Actions |
| Containerisation | Docker + Docker Compose |
| Image Registry | Docker Hub (`abdelhameed208`) |
| IaC — Azure | Terraform (AVM modules) |
| IaC — AWS | Terraform (community modules) |
| VM Image | HashiCorp Packer + Ansible |
| SAST | SonarCloud |
| Container Security | Aqua Trivy |
| Deep SAST | GitHub CodeQL |
| Secrets (Azure) | Azure Container Apps Secrets |
| Secrets (AWS) | Infisical (AWS IAM Auth) |
| DNS | Cloudflare |
| Dependency Updates | Dependabot (8 ecosystems, weekly) |

---

## 6. API Overview

All endpoints are prefixed with the backend base URL.

### Authentication — `/api/Auth`

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|:-------------:|
| `POST` | `/register-user` | Register a new user | ❌ |
| `POST` | `/login-user` | Login with username & password | ❌ |
| `POST` | `/refresh-tokens` | Refresh access + refresh tokens | ❌ |
| `GET` | `/login-google` | Initiate Google OAuth flow | ❌ |
| `GET` | `/google-callback` | Google OAuth callback (internal) | ❌ |
| `POST` | `/get-reset-password-token` | Request email OTP for password reset | ❌ |
| `POST` | `/reset-password` | Reset password with OTP | ❌ |
| `POST` | `/change-password` | Change authenticated user password | ✅ |
| `POST` | `/logout` | Invalidate refresh token | ✅ |
| `GET` | `/user-profile` | Get authenticated user profile | ✅ |
| `POST` | `/update-user-profile` | Update profile fields | ✅ |
| `POST` | `/update-user-image` | Upload new profile image | ✅ |

### Sign Language Translator — `/api/SignLanguageTranslator`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/` | Classify a single frame (Base64 image) |
| `POST` | `/finalize-sentence` | Finalize and correct accumulated sentence |
| `POST` | `/correct-sentence` | AI-correct a given sentence |
| `POST` | `/generate-audio` | Convert text to audio (Azure Speech) |
| `POST` | `/text-to-audio` | Alternative TTS endpoint |

### Arabic Language Translator — `/api/ArabicLanguageTranslator`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/text-to-sign` | Convert Arabic text to sign image sequence |
| `POST` | `/audio-to-text` | Transcribe audio to Arabic text (STT) |
| `GET` | `/letters-keyboard` | Get sign image for a specific letter |

### User History — `/api/UserHistory`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/get-user-history` | Get all translation history records |
| `DELETE` | `/delete-user-history-record` | Delete a specific record |
| `DELETE` | `/delete-all-user-history` | Clear all history |

### Health Check

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Application health status |

---

## 7. Getting Started — Local Development

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) (for backend-only development)
- [Node.js 20+](https://nodejs.org/) (for frontend-only development)
- [Flutter 3.41.6](https://flutter.dev/) (for mobile development)

### 1. Clone the Repository

```bash
git clone https://github.com/Abdelhamid108/GraduationProjectDotNet-Deploy.git
cd GraduationProjectDotNet-Deploy
```

### 2. Configure Environment Variables

Copy the example env file and fill in the required values:

```bash
cp backend/.env.example backend/.env
```

**Minimum required variables for local development:**

```env
# Database
DEFAULT_CONNECTION=Server=database,1433;Database=ema2a-db;User Id=sa;Password=YourPassword123!;TrustServerCertificate=True

# JWT
SECRET_KEY=your-super-secret-key-at-least-32-characters
ISSUER=https://localhost:5001

# Google OAuth (optional for local dev)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Mail (optional for local dev)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_SSL=false
MAIL_NAME=Ema2a
MAIL_EMAIL_ID=your-email@gmail.com
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-gmail-app-password
```

### 3. Run the Full Stack Locally

```bash
# Builds from local source code (not Docker Hub)
docker compose -f docker-compose.local.yml up --build
```

| Service | URL |
|---------|-----|
| Frontend (Nginx + React) | http://localhost:8080 |
| Backend API | http://localhost:5001 |
| Swagger UI | http://localhost:5001/swagger |
| Database (SQL Server) | localhost:1433 |

### 4. Run Backend Only (for API development)

```bash
cd backend
dotnet restore
dotnet run --project GraduationProjectWebApplication
```

### 5. Run Frontend Only (for UI development)

```bash
cd frontend
npm install
echo "VITE_BASE_URI=http://localhost:5001" > .env.local
npm run dev
# Opens http://localhost:5173
```

### 6. Run Flutter App

```bash
cd flutter
flutter pub get
flutter run
```

### 7. Setup Raspberry Pi Hardware Device

```bash
# On the Raspberry Pi
sudo apt update
sudo apt install python3-picamera2 mpg123 alsa-utils
pip install requests gTTS

# Copy service and enable
sudo cp Hardware-Service/sign-translator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable sign-translator
sudo systemctl start sign-translator
```

---

## 8. Deployment

### Azure (Primary — Serverless)

The primary production deployment runs on **Azure Container Apps** in the `westus2` region.

| Component | Azure Resource |
|-----------|---------------|
| Backend API | Container App `ema2a-backend-app` (0–5 replicas) |
| Frontend | Container App `ema2a-frontend-app` (0–5 replicas) |
| Database | Azure SQL Server + Database (Free tier) |
| Storage | Azure Files (user images), Blob Storage (CI reports) |
| Speech | Azure Cognitive Services (Speech, F0 tier) |
| URL | `https://test.ema2a.website` |

**Deploy via GitHub Actions** — push to `main`, approve the Production environment gate.

**Manual deploy via Terraform:**

```bash
cd DevOps/Terraform/main-azure
terraform init
terraform apply
```

### AWS (Backup — On-Demand)

The backup deployment runs on a single **EC2 instance** (`c7i-flex.large`) that auto-stops when idle and can be woken via a Lambda function.

| URL | Purpose |
|-----|---------|
| `https://backup.ema2a.website` | Application (starts when server is running) |
| `https://start.ema2a.website` | Wakes the EC2 instance on GET request |

**First-time setup:**

```bash
# 1. Build the custom AMI (installs Docker, GitHub Actions user, app startup service)
cd DevOps/packer-ansible
packer init ema2a.pkr.hcl
packer build ema2a.pkr.hcl

# 2. Provision the infrastructure
cd DevOps/Terraform/backup-aws
terraform init
terraform apply
```

**Cost-saving features:**
- EC2 auto-stops after **15 minutes of CPU < 2%** (CloudWatch alarm)
- On-demand wake via `GET https://start.ema2a.website` (Lambda)

### Docker Images

| Image | Tags | Used For |
|-------|------|---------|
| `abdelhameed208/graduationproject-backend` | `v1.0-<N>-<sha>`, `latest` | Azure & AWS |
| `abdelhameed208/graduationproject-frontend` | `v1.0-<N>-<sha>-azure` | Azure only |
| `abdelhameed208/graduationproject-frontend` | `v1.0-<N>-<sha>-aws`, `latest` | AWS & CI tests |

---

## 9. CI/CD Pipeline

The pipeline (`main.yml`) triggers on every push to `DEV` or `main` that touches backend, frontend, or DevOps files.

```
Push to DEV / main
     │
     ├── sonar-backend          SAST for .NET (SonarCloud)
     └── sonar-frontend-devops  SAST for React + IaC (SonarCloud)
             │ (both must pass)
     ┌───────┴─────────┐
     │                 │
backend-build-push   frontend-build-push
(immutable tag)      (Azure tag + AWS tag)
     │                 │
trivy-backend        trivy-frontend
(CVE + secrets)      (CVE + secrets)
     │                 │
     └───────┬──────────┘
             │
         test
  (docker compose up → API tests
   → quality gate ≤10 failures
   → email notification
   → SAS artifact upload to Azure)
             │
     ┌───────┴─────────┐
     │                 │
deploy_main       deploy_backup
  (Azure            (AWS EC2
 Container Apps)    via SSM)
```

**Additional standalone workflows:**

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `CodeQl.yml` | push to `main` | Deep semantic security scan (C# + JS) |
| `sonar-flutter.yml` | `flutter/**` changes | Flutter SonarCloud + test coverage |
| `sonar-hardware.yml` | `Hardware-Service/**` changes | Python SonarCloud analysis |

---

## 10. Repository Structure

```
GraduationProjectDotNet-Deploy/
│
├── .github/
│   ├── workflows/
│   │   ├── main.yml                   ← Primary CI/CD pipeline (9 jobs)
│   │   ├── CodeQl.yml                 ← Deep CodeQL security analysis
│   │   ├── sonar-flutter.yml          ← Flutter code quality
│   │   └── sonar-hardware.yml         ← Hardware service code quality
│   └── dependabot.yml                 ← Automated weekly dependency updates
│
├── backend/
│   ├── Dockerfile                     ← Multi-stage .NET 8 + ONNX image
│   ├── .env.example                   ← All required environment variables
│   └── GraduationProjectWebApplication/
│       ├── Program.cs                 ← App entry point, DI & middleware
│       ├── Controllers/               ← Auth, SignLanguage, Arabic, History
│       ├── Services/                  ← AuthService, EmailService, AI models
│       ├── Models/                    ← Entities, DTOs
│       ├── Data/                      ← EF Core DbContext + Migrations
│       ├── Hubs/                      ← SignalR SignHub
│       └── AIModels/                  ← ONNX model files
│
├── frontend/
│   ├── Dockerfile                     ← Node build → Nginx runtime
│   ├── nginx-proxy.conf.template      ← Nginx SPA + API proxy + WebSocket
│   └── src/
│       ├── Api/                       ← APICalls.ts, AuthSession.ts
│       ├── pages/                     ← Login, Signup, Home, History, ...
│       ├── components/                ← Reusable UI components
│       └── App.tsx                    ← Router + routes
│
├── flutter/                           ← Flutter mobile app (iOS/Android)
│   ├── lib/                           ← Dart source code
│   ├── pubspec.yaml                   ← Dependencies
│   └── test/                         ← Unit & widget tests
│
├── Hardware-Service/
│   ├── translator.py                  ← Main Raspberry Pi translation service
│   ├── sign-translator.service        ← systemd unit file
│   └── README.md                      ← Hardware-specific documentation
│
├── DevOps/
│   ├── Terraform/
│   │   ├── main-azure/                ← Azure Container Apps + SQL + DNS
│   │   └── backup-aws/                ← EC2 + Lambda + API Gateway + DNS
│   └── packer-ansible/
│       ├── ema2a.pkr.hcl              ← Packer: custom AWS AMI build
│       └── Ansible/                   ← 4 roles: init, docker, gha, deploy
│
├── Documentation/
│   ├── Backend/                       ← Backend API documentation
│   ├── DevOps_Documentation/
│   │   ├── DevOps.md                  ← General DevOps overview
│   │   ├── Docker.md                  ← Container documentation
│   │   ├── Provisioning&&Infra.md     ← Terraform + Packer + Ansible docs
│   │   ├── CI-CD.md                   ← Pipeline detailed documentation
│   ├── API_Test_Documentation/        ← API test suite docs
│   └── Hardware/                      ← Hardware module docs
│
├── docker-compose.yml                 ← Production / CI test stack
├── docker-compose.local.yml           ← Local development stack (builds from src)
├── docker-compose-backup-deployment.yml ← AWS EC2 backup stack
└── sonar-frontend-devops.properties   ← SonarCloud config (Frontend + DevOps)
```

---

## 11. Documentation

All documentation lives under the `Documentation/` directory, organized by stack. Every document is based on the actual source code — nothing is assumed or invented.

---

### 🔧 Backend Documentation

**Directory:** `Documentation/Backend/`

| File | What It Covers |
|------|---------------|
| [`Readme.MD`](./Documentation/Backend/Readme.MD) | Backend documentation index — how to use all API docs, authentication flow, quick start for developers, Postman + Swagger setup |
| [`API_Documentaion.MD`](./Documentation/Backend/API_Documentaion.MD) | Full backend API reference — all endpoints with request/response schemas, error codes, validation rules, and integration examples |
| [`Quick_Reference.MD`](./Documentation/Backend/Quick_Reference.MD) | One-page quick reference — endpoint URLs, cURL examples, common patterns, troubleshooting guide |

**Per-controller detailed docs** — `Documentation/Backend/API Documentations/`:

| File | Controller | Covers |
|------|-----------|--------|
| [`Auth.MD`](./Documentation/Backend/API%20Documentations/Auth.MD) | `AuthController` | Register, login, JWT tokens, refresh, Google OAuth, password reset, OTP, profile management |
| [`Sign Language Translator.MD`](./Documentation/Backend/API%20Documentations/Sign%20Language%20Translator.MD) | `SignLanguageTranslatorController` | Frame classification, sentence finalization, AI correction, TTS audio generation |
| [`Arabic Language Translator.MD`](./Documentation/Backend/API%20Documentations/Arabic%20Language%20Translator.MD) | `ArabicLanguageTranslatorController` | Text-to-sign image conversion, speech-to-text (STT), letter keyboard endpoint |
| [`User History.MD`](./Documentation/Backend/API%20Documentations/User%20History.MD) | `UserHistoryController` | Get history, delete single record, delete all history |
| [`SignHub.MD`](./Documentation/Backend/API%20Documentations/SignHub.MD) | `SignHub` (SignalR) | Real-time WebSocket hub — connection protocol, events, streaming translation |
| [`swagger_documentation.json`](./Documentation/Backend/API%20Documentations/swagger_documentation.json) | All controllers | OpenAPI 3.0 / Swagger JSON spec — import into Postman, Swagger UI, or SDK generators |

---

### 🌐 Frontend Documentation

**Directory:** `frontend/`

The frontend is self-documented through:

| Resource | Location | Description |
|----------|----------|-------------|
| Component structure | `frontend/src/` | `pages/` → UI pages · `components/` → reusable elements · `Api/` → typed API layer |
| API type definitions | `frontend/src/Api/APICalls.ts` | All DTOs, interfaces, and typed fetch wrappers matching backend contracts |
| Auth session logic | `frontend/src/Api/AuthSession.ts` | JWT storage, expiry checks, token refresh logic |
| Nginx proxy config | `frontend/nginx-proxy.conf.template` | SPA routing, API proxy rules, WebSocket forwarding, CORS, bot blocking |
| Docker image | `frontend/Dockerfile` | Two-stage build: Node/Vite build → Nginx runtime, `VITE_BASE_URI` baking |
| Vite config | `frontend/vite.config.ts` | Build configuration, path aliases |

---

### 📱 Mobile App Documentation

**Directory:** `flutter/`

| Resource | Location | Description |
|----------|----------|-------------|
| Flutter README | [`flutter/README.md`](./flutter/README.md) | Setup guide, dependencies, run instructions |
| Dependencies | `flutter/pubspec.yaml` | All 16 packages: `signalr_netcore`, `camera`, `audioplayers`, `get`, `dio`, `get_storage`, etc. |
| Source code | `flutter/lib/` | App screens, navigation, API integration, state management |
| Test suite | `flutter/test/` | Widget and unit tests (run by `sonar-flutter.yml` CI workflow) |
| SonarCloud config | `flutter/sonar-project.properties` | Code quality analysis settings |

---

### 🤖 AI Model Documentation

The AI model is documented directly in this README under **[Section 5 — AI Models](#5-ai-models)**, covering:

- The three ONNX model files (`best.onnx`, `ASL.onnx`, `WordsModel.onnx`) and their sizes/purpose
- YOLOv8 architecture and the full inference pipeline diagram
- Input tensor format `[1, 3, 256, 256]`, confidence threshold, and NMS algorithm
- Thread-safety design (`SemaphoreSlim`) and Singleton registration
- GC memory tuning (`DOTNET_GCHeapHardLimit`) for native ONNX memory
- Full ArSL alphabet label coverage
- Sentence construction and finalization flow

---

### 🔌 Hardware Documentation

**Directory:** `Documentation/Hardware/` and `Hardware-Service/`

| File | Description |
|------|-------------|
| [`Hardware/README.md`](./Documentation/Hardware/README.md) | Hardware module overview — system architecture, components, setup |
| [`Hardware-Service/README.md`](./Hardware-Service/README.md) | Full Raspberry Pi service documentation — camera capture, gesture recognition loop, sentence builder, TTS pipeline, systemd service setup, configuration parameters, debugging |
| [`Hardware-Service/translator.py`](./Hardware-Service/translator.py) | Main Python service (13 KB) — all logic is inline-commented |
| [`Hardware-Service/sign-translator.service`](./Hardware-Service/sign-translator.service) | systemd unit file — auto-start on boot configuration |

---

### 🚀 DevOps Documentation

**Directory:** `Documentation/DevOps_Documentation/`

| File | What It Covers |
|------|---------------|
| [`DevOps.md`](./Documentation/DevOps_Documentation/DevOps.md) | **General overview** — full architecture diagram, all technology tools, repo structure map, Azure vs AWS comparison, secrets management strategy, environment table |
| [`Docker.md`](./Documentation/DevOps_Documentation/Docker.md) | **Containerization** — backend Dockerfile (multi-stage, ONNX GC tuning, non-root user), frontend Dockerfile (Vite build → Nginx runtime), Nginx proxy config (SPA + API + WebSocket + CORS), all 3 Compose files compared |
| [`Provisioning&&Infra.md`](./Documentation/DevOps_Documentation/Provisioning&&Infra.md) | **Infrastructure** — Azure Terraform (Container Apps, SQL, Storage, Speech, DNS, TLS), AWS Terraform (EC2, Lambda, API Gateway, CloudWatch auto-stop), Packer AMI build, all 4 Ansible roles step-by-step, systemd service template |
| [`CI-CD.md`](./Documentation/DevOps_Documentation/CI-CD.md) | **CI/CD Pipeline** — all 4 GitHub Actions workflows, every job/step explained, pipeline dependency graph, immutable image tag formula, quality gate logic, secrets reference |

---

### 🧪 API Test Documentation

**Directory:** `Documentation/API_Test_Documentation/`

| File | Description |
|------|-------------|
| [`README.md`](./Documentation/API_Test_Documentation/README.md) | Test suite overview — what is tested, how tests are structured, how to run locally, test categories |
| [`CICD_INTEGRATION.md`](./Documentation/API_Test_Documentation/CICD_INTEGRATION.md) | How the test suite integrates with GitHub Actions — the `test` job, `run_tests.sh`, JSON report generation, Azure Blob upload, SAS token, email notification, quality gate threshold |
| [`FAILURE_ANALYSIS.md`](./Documentation/API_Test_Documentation/FAILURE_ANALYSIS.md) | Common test failure patterns, how to diagnose them, known flaky tests, debugging steps |

---

## 12. Security

| Practice | Implementation |
|----------|---------------|
| **SAST on every push** | SonarCloud analyzes all 4 codebases before any image builds |
| **Container CVE scanning** | Trivy scans every pushed image for HIGH/CRITICAL vulnerabilities |
| **Deep semantic analysis** | GitHub CodeQL runs on `main` for C# and JS/TS |
| **Non-root containers** | Backend: `app` user · Frontend: `nginx` user |
| **Secrets never baked into images** | All secrets injected via environment variables at runtime |
| **No secrets on disk (AWS)** | `.env` file written then deleted immediately after `docker compose up` |
| **Database network isolation** | SQL Server on an `internal: true` Docker network (no external access) |
| **Managed TLS** | Azure Managed Certificates auto-provision and renew |
| **Immutable image tags** | Versioned tags prevent overwriting deployed images |
| **Manual deploy approval** | `Production` GitHub Environment requires human review |
| **Least-privilege IAM** | Lambda policy scoped to `StartInstances`/`StopInstances` only on the specific EC2 |
| **Rate limiting** | Per-endpoint token-bucket and fixed-window rate limits on all public APIs |
| **Dependabot** | Weekly automated PRs for 8 dependency ecosystems |

---

## 13. Team

**Graduation Project — Faculty of Engineering**

| Role | Name |
|------|------|


---

<div align="center">

**Made with ❤️ to bridge the communication gap**

*ايماءه — Ema2a*

</div>
