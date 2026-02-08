# API Testing Framework Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Usage](#usage)
7. [Test Execution Flow](#test-execution-flow)
8. [Endpoint Reference](#endpoint-reference)
9. [Adding New Tests](#adding-new-tests)
10. [Troubleshooting](#troubleshooting)
11. [CI/CD Integration](#cicd-integration)

---

## Overview

### What is This?

A production-grade, Bash-based API testing framework for validating:
- **28 REST API endpoints** across .NET Backend and Python TTS Service
- **1 SignalR WebSocket hub** for real-time sign language translation

### Why Use This Framework?

| Feature | Benefit |
|---------|---------|
| **Data-driven tests** | Add/modify tests without code changes |
| **Cross-platform** | Works on Linux, macOS, and Windows (Git Bash) |
| **CI/CD ready** | GitHub Actions workflow included |
| **Unified reporting** | Single report for REST + WebSocket tests |
| **Failure analysis** | Detailed diagnosis for debugging |

### How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                         run_tests.sh                                │
│  (Main Orchestrator)                                                │
├─────────────────────────────────────────────────────────────────────┤
│  1. Parse arguments (--base-url)                                    │
│  2. Load configuration (env.sh, urls.sh)                            │
│  3. Authenticate (auth.sh → get JWT token)                          │
│  4. Run REST tests (rest_runner.sh + endpoints.json)                │
│  5. Run WebSocket tests (ws_runner.sh + ws_tests.json)              │
│  6. Generate report (report.sh → reports/)                          │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Architecture

### Directory Structure

```
api-tests/
│
├── run_tests.sh              # Main entry point
│
├── config/
│   ├── env.sh                # Environment variables & test credentials
│   ├── auth.sh               # Authentication helpers (login, token refresh)
│   └── urls.sh               # Endpoint URL construction helpers
│
├── rest/
│   ├── endpoints.json        # REST endpoint definitions (data-driven)
│   └── rest_runner.sh        # REST test executor
│
├── websocket/
│   ├── ws_tests.json         # WebSocket test scenarios
│   └── ws_runner.sh          # WebSocket test executor
│
├── utils/
│   ├── logger.sh             # Logging utilities (colors, timestamps)
│   ├── assertions.sh         # Test assertion functions
│   └── report.sh             # Report generation (JSON/HTML)
│
├── reports/                  # Generated test reports
│   └── report_YYYYMMDD_HHMMSS.json
│
└── docs/
    ├── README.md             # This documentation
    ├── CICD_INTEGRATION.md   # CI/CD setup guide
    └── FAILURE_ANALYSIS.md   # Common failures & solutions
```

---

## Quick Start

### 1. Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Bash | 4.0+ | Script execution |
| curl | any | REST API calls |
| jq | 1.6+ | JSON parsing |
| websocat | 1.11+ | WebSocket testing |

### 2. Run Tests

```bash
# Navigate to api-tests directory
cd api-tests

# Make executable (first time only)
chmod +x run_tests.sh

# Run all tests
./run_tests.sh --base-url https://ema2a.ddns.net
```

### 3. View Report

```bash
# Reports are saved in api-tests/reports/
cat reports/report_latest.json | jq .
```

---

## Auto-Registration Feature

The framework is **completely self-contained** - you don't need to pre-create test users!

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    Authentication Flow                       │
├─────────────────────────────────────────────────────────────┤
│  1. Try login with TEST_USERNAME/TEST_PASSWORD              │
│     ↓ (if login fails)                                      │
│  2. Auto-register new unique user (testuser_<timestamp>)    │
│     ↓ (if registration succeeds)                            │
│  3. Login with newly registered user                        │
│  4. Continue tests with valid JWT token                     │
└─────────────────────────────────────────────────────────────┘
```

### Zero Configuration Required

```bash
# Just provide the base URL - that's it!
./run_tests.sh --base-url https://ema2a.ddns.net

# The framework will:
# 1. Attempt login with default credentials
# 2. If login fails, register a new user automatically
# 3. Use the new user for all authenticated tests
# 4. Test both registration AND authenticated endpoints
```

### Benefits

- ✅ Tests registration endpoint automatically
- ✅ Tests authenticated endpoints without manual user creation
- ✅ Creates unique user each run (no conflicts)
- ✅ Works in CI/CD without pre-seeded databases


---

## Installation

### Linux / macOS

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y curl jq

# Install websocat
wget -qO /tmp/websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
chmod +x /tmp/websocat && sudo mv /tmp/websocat /usr/local/bin/

# macOS (Homebrew)
brew install curl jq websocat
```

### Windows (Git Bash)

1. **Install Git for Windows** (includes Git Bash): https://git-scm.com/download/win

2. **Install jq**:
   - Download from https://stedolan.github.io/jq/download/
   - Rename `jq-win64.exe` to `jq.exe`
   - Place in `C:\Program Files\Git\usr\bin\`

3. **Install websocat**:
   - Download from https://github.com/vi/websocat/releases
   - Extract `websocat.exe`
   - Place in `C:\Program Files\Git\usr\bin\`

4. **Verify installation**:
   ```bash
   curl --version
   jq --version
   websocat --version
   ```

---

## Configuration

### Environment Variables (`config/env.sh`)

```bash
# Test credentials (used for authentication)
export TEST_USERNAME="testuser@example.com"
export TEST_PASSWORD="TestPassword123!"

# Timeouts (seconds)
export REQUEST_TIMEOUT=30
export WS_CONNECT_TIMEOUT=10

# Retry settings
export MAX_RETRIES=3
export RETRY_DELAY=2

# Report format: "json" | "html" | "both"
export REPORT_FORMAT="json"
```

### Custom Test User

To use your own test user, edit `config/env.sh`:

```bash
export TEST_USERNAME="your-email@domain.com"
export TEST_PASSWORD="your-password"
```

---

## Usage

### Command-Line Options

```bash
./run_tests.sh [OPTIONS]

Options:
  --base-url URL    API base URL (required)
                    Example: https://ema2a.ddns.net
  
  --dry-run         Print test plan without executing
  
  --rest-only       Run only REST API tests
  
  --ws-only         Run only WebSocket tests
  
  --verbose         Enable detailed output
  
  --skip-auth       Skip authentication tests
                    (requires valid token in environment)
  
  --help            Show this help message
```

### Examples

```bash
# Full test suite
./run_tests.sh --base-url https://ema2a.ddns.net

# REST tests only
./run_tests.sh --base-url https://ema2a.ddns.net --rest-only

# Verbose output for debugging
./run_tests.sh --base-url https://ema2a.ddns.net --verbose

# Dry run (see what would execute)
./run_tests.sh --base-url https://ema2a.ddns.net --dry-run
```

---

## Test Execution Flow

### Sequence Diagram

```
┌────────┐     ┌────────────┐     ┌─────────┐     ┌──────────┐     ┌────────┐
│  User  │     │ run_tests  │     │  auth   │     │   API    │     │ report │
└───┬────┘     └─────┬──────┘     └────┬────┘     └────┬─────┘     └───┬────┘
    │                │                  │               │               │
    │ ./run_tests.sh │                  │               │               │
    │ --base-url ... │                  │               │               │
    │───────────────>│                  │               │               │
    │                │                  │               │               │
    │                │ 1. Load config   │               │               │
    │                │─────────────────>│               │               │
    │                │                  │               │               │
    │                │ 2. Login         │               │               │
    │                │─────────────────>│ POST /login   │               │
    │                │                  │──────────────>│               │
    │                │                  │    JWT Token  │               │
    │                │                  │<──────────────│               │
    │                │                  │               │               │
    │                │ 3. Run REST tests│               │               │
    │                │──────────────────────────────────>               │
    │                │                  (for each endpoint)             │
    │                │<──────────────────────────────────               │
    │                │                  │               │               │
    │                │ 4. Run WS tests  │               │               │
    │                │──────────────────────────────────>               │
    │                │                  (SignalR /signHub)              │
    │                │<──────────────────────────────────               │
    │                │                  │               │               │
    │                │ 5. Generate report               │               │
    │                │─────────────────────────────────────────────────>│
    │                │                  │               │               │
    │  Test Report   │                  │               │               │
    │<───────────────│                  │               │               │
    │                │                  │               │               │
```

### Execution Phases

| Phase | Description | Duration |
|-------|-------------|----------|
| **1. Initialization** | Load config, parse args | ~1s |
| **2. Authentication** | Login, get JWT token | ~2s |
| **3. REST Tests** | Test 28 endpoints | ~30-60s |
| **4. WebSocket Tests** | SignalR connection & messaging | ~10-20s |
| **5. Report Generation** | Create JSON/HTML report | ~1s |

---

## Endpoint Reference

### Authentication Endpoints (Auth Controller)

| # | Method | Path | Auth | Purpose |
|---|--------|------|------|---------|
| 1 | POST | `/api/Auth/register-user` | ❌ | Register new user |
| 2 | POST | `/api/Auth/login-user` | ❌ | Login, get JWT token |
| 3 | POST | `/api/Auth/refresh-tokens` | ❌ | Refresh access token |
| 4 | POST | `/api/Auth/get-reset-password-token` | ❌ | Request password reset |
| 5 | POST | `/api/Auth/reset-password` | ❌ | Reset password with OTP |
| 6 | POST | `/api/Auth/change-password` | ✅ | Change password (auth) |
| 7 | GET | `/api/Auth/login-google` | ❌ | Google OAuth redirect |
| 8 | GET | `/api/Auth/google-callback` | ❌ | Google OAuth callback |
| 9 | POST | `/api/Auth/update-user-image` | ✅ | Update profile image |
| 10 | POST | `/api/Auth/logout` | ✅ | Logout, invalidate token |
| 11 | GET | `/api/Auth/user-profile` | ✅ | Get user profile |
| 12 | POST | `/api/Auth/update-user-profile` | ✅ | Update user profile |
| 13 | GET | `/api/Auth/TestAuthentication` | ✅ | Verify authentication |

### Arabic Translator Endpoints

| # | Method | Path | Auth | Purpose |
|---|--------|------|------|---------|
| 14 | POST | `/api/ArabicLanguageTranslator/text-to-sign` | ❌ | Convert text to sign images |
| 15 | POST | `/api/ArabicLanguageTranslator/audio-to-text` | ❌ | Transcribe audio to text |
| 16 | GET | `/api/ArabicLanguageTranslator/letters-keyboard` | ❌ | Get sign for single letter |

### Sign Language Translator Endpoints

| # | Method | Path | Auth | Purpose |
|---|--------|------|------|---------|
| 17 | POST | `/api/SignLanguageTranslator` | ❌ | Translate sign image to text |
| 18 | POST | `/api/SignLanguageTranslator/finalize-sentence` | ❌ | Finalize concatenated letters |
| 19 | POST | `/api/SignLanguageTranslator/CorrectSentence` | ❌ | Correct grammar/spelling |
| 20 | POST | `/api/SignLanguageTranslator/GenerateAudio` | ❌ | Generate audio from text |
| 21 | POST | `/api/SignLanguageTranslator/text-to-audio` | ❌ | Complete text-to-audio flow |

### User History Endpoints

| # | Method | Path | Auth | Purpose |
|---|--------|------|------|---------|
| 22 | GET | `/api/UserHistory/get-user-history` | ✅ | Get user's history |
| 23 | DELETE | `/api/UserHistory/delete-user-history-record` | ✅ | Delete single record |
| 24 | DELETE | `/api/UserHistory/delete-all-user-history` | ✅ | Delete all history |

### TTS Service Endpoints

| # | Method | Path | Auth | Purpose |
|---|--------|------|------|---------|
| 25 | GET | `/tts/health` | ❌ | Health check |
| 26 | GET | `/tts/speakers` | ❌ | List voice options |
| 27 | POST | `/tts/tts` | ❌ | Text-to-speech (POST) |
| 28 | GET | `/tts/tts` | ❌ | Text-to-speech (GET) |

### WebSocket Endpoint

| Hub | Path | Method | Purpose |
|-----|------|--------|---------|
| SignHub | `/signHub` | `ProcessFrame` | Real-time sign translation |

---

## Adding New Tests

### Adding a REST Endpoint Test

Edit `rest/endpoints.json`:

```json
{
  "endpoints": [
    {
      "id": "new_endpoint_001",
      "name": "My New Endpoint",
      "method": "POST",
      "path": "/api/Controller/action",
      "auth_required": true,
      "payload": {
        "field1": "value1",
        "field2": 123
      },
      "expected_status": 200,
      "expected_fields": ["success", "data"],
      "skip": false
    }
  ]
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ | Unique test identifier |
| `name` | string | ✅ | Human-readable test name |
| `method` | string | ✅ | HTTP method (GET/POST/PUT/DELETE) |
| `path` | string | ✅ | API path (without base URL) |
| `auth_required` | bool | ✅ | Whether to include JWT token |
| `payload` | object | ❌ | Request body (for POST/PUT) |
| `query_params` | object | ❌ | Query string parameters |
| `expected_status` | int | ✅ | Expected HTTP status code |
| `expected_fields` | array | ❌ | Fields to verify in response |
| `skip` | bool | ❌ | Set true to skip this test |

### Adding a WebSocket Test

Edit `websocket/ws_tests.json`:

```json
{
  "tests": [
    {
      "id": "ws_new_test",
      "name": "My New WebSocket Test",
      "action": "invoke",
      "method": "ProcessFrame",
      "payload": {
        "imageData": "data:image/jpeg;base64,..."
      },
      "expected_event": "ReceiveTranslation",
      "timeout_ms": 5000
    }
  ]
}
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `curl: command not found` | curl not installed | Install curl |
| `jq: command not found` | jq not installed | Install jq |
| `Connection refused` | API not running | Verify base URL |
| `401 Unauthorized` | Invalid/expired token | Check credentials |
| `429 Too Many Requests` | Rate limit hit | Wait and retry |
| `WebSocket connect failed` | SignalR negotiation issue | Check /signHub endpoint |

### Debug Mode

Run with `--verbose` for detailed output:

```bash
./run_tests.sh --base-url https://ema2a.ddns.net --verbose
```

### Check Dependencies

```bash
# Verify all tools are installed
curl --version
jq --version
websocat --version
bash --version
```

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/api-tests.yml`:

```yaml
name: API Tests

on:
  workflow_dispatch:
    inputs:
      base_url:
        description: 'API Base URL'
        required: true
        default: 'https://ema2a.ddns.net'
  
  # Optional: run on schedule
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM

jobs:
  api-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq
          wget -qO /tmp/websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
          chmod +x /tmp/websocat && sudo mv /tmp/websocat /usr/local/bin/
      
      - name: Run API Tests
        run: |
          chmod +x api-tests/run_tests.sh
          ./api-tests/run_tests.sh --base-url ${{ inputs.base_url || 'https://ema2a.ddns.net' }}
      
      - name: Upload Test Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: api-test-report
          path: api-tests/reports/
          retention-days: 30
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    parameters {
        string(name: 'BASE_URL', defaultValue: 'https://ema2a.ddns.net', description: 'API Base URL')
    }
    
    stages {
        stage('Install Dependencies') {
            steps {
                sh 'apt-get update && apt-get install -y jq'
            }
        }
        
        stage('Run API Tests') {
            steps {
                sh """
                    chmod +x api-tests/run_tests.sh
                    ./api-tests/run_tests.sh --base-url ${params.BASE_URL}
                """
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'api-tests/reports/**', allowEmptyArchive: true
        }
    }
}
```

---

## Report Format

### JSON Report Structure

```json
{
  "metadata": {
    "timestamp": "2026-02-08T13:45:00Z",
    "base_url": "https://ema2a.ddns.net",
    "duration_seconds": 45
  },
  "summary": {
    "total": 35,
    "passed": 33,
    "failed": 2,
    "skipped": 0,
    "pass_rate": "94.3%"
  },
  "rest_tests": [
    {
      "id": "auth_login",
      "name": "Login User",
      "endpoint": "POST /api/Auth/login-user",
      "status": "PASSED",
      "latency_ms": 245,
      "expected_status": 200,
      "actual_status": 200
    }
  ],
  "websocket_tests": [
    {
      "id": "ws_connect",
      "name": "SignalR Connection",
      "status": "PASSED",
      "latency_ms": 120
    }
  ],
  "failures": [
    {
      "id": "audio_to_text",
      "name": "Audio to Text",
      "error": "502 Bad Gateway",
      "diagnosis": "External Gemini API unavailable",
      "suggested_fix": "Check API key validity and Gemini service status"
    }
  ]
}
```

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [FAILURE_ANALYSIS.md](./FAILURE_ANALYSIS.md)
3. Open an issue in the repository
