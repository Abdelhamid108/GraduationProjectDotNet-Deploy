#!/usr/bin/env bash
#==============================================================================
# Environment Configuration for API Testing Framework
# 
# This file contains all configurable environment variables for the test suite.
# Copy this file to env.local.sh and modify for your specific environment.
#==============================================================================

# Source guard - prevent multiple sourcing
[[ -n "${_ENV_SH_LOADED:-}" ]] && return 0
_ENV_SH_LOADED=1

#------------------------------------------------------------------------------
# Test Credentials
# Used for authentication tests. Replace with valid test account credentials.
#------------------------------------------------------------------------------
export TEST_USERNAME="${TEST_USERNAME:-testuser@example.com}"
export TEST_PASSWORD="${TEST_PASSWORD:-TestPassword123!}"

# Alternative: If you need to register a new test user each run
export REGISTER_NEW_USER="${REGISTER_NEW_USER:-false}"
export TEST_EMAIL_DOMAIN="${TEST_EMAIL_DOMAIN:-example.com}"

#------------------------------------------------------------------------------
# Timeout Settings (in seconds)
#------------------------------------------------------------------------------
# HTTP request timeout
export REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-30}"

# WebSocket connection timeout
export WS_CONNECT_TIMEOUT="${WS_CONNECT_TIMEOUT:-10}"

# WebSocket message timeout (waiting for response)
export WS_MESSAGE_TIMEOUT="${WS_MESSAGE_TIMEOUT:-5000}"

#------------------------------------------------------------------------------
# Retry Settings
#------------------------------------------------------------------------------
# Maximum number of retries for failed requests
export MAX_RETRIES="${MAX_RETRIES:-3}"

# Delay between retries (seconds)
export RETRY_DELAY="${RETRY_DELAY:-2}"

# Enable exponential backoff for retries
export EXPONENTIAL_BACKOFF="${EXPONENTIAL_BACKOFF:-true}"

#------------------------------------------------------------------------------
# Report Settings
#------------------------------------------------------------------------------
# Report format: "json" | "html" | "both"
export REPORT_FORMAT="${REPORT_FORMAT:-json}"

# Keep last N reports (0 = keep all)
export KEEP_LAST_REPORTS="${KEEP_LAST_REPORTS:-10}"

# Include request/response bodies in report (may contain sensitive data)
export INCLUDE_BODIES="${INCLUDE_BODIES:-false}"

#------------------------------------------------------------------------------
# Logging Settings
#------------------------------------------------------------------------------
# Log level: "DEBUG" | "INFO" | "WARN" | "ERROR"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Enable colored output
export COLORIZED_OUTPUT="${COLORIZED_OUTPUT:-true}"

# Log file path (empty = stdout only)
export LOG_FILE="${LOG_FILE:-}"

#------------------------------------------------------------------------------
# Test Execution Settings
#------------------------------------------------------------------------------
# Skip slow tests (like audio processing)
export SKIP_SLOW_TESTS="${SKIP_SLOW_TESTS:-false}"

# Run tests in parallel (experimental)
export PARALLEL_TESTS="${PARALLEL_TESTS:-false}"

# Number of parallel workers
export PARALLEL_WORKERS="${PARALLEL_WORKERS:-4}"

#------------------------------------------------------------------------------
# WebSocket/SignalR Settings
#------------------------------------------------------------------------------
# SignalR hub path (relative to base URL)
export SIGNALR_HUB_PATH="${SIGNALR_HUB_PATH:-/signHub}"

# Enable WebSocket debug output
export WS_DEBUG="${WS_DEBUG:-false}"

#------------------------------------------------------------------------------
# TTS Service Settings
#------------------------------------------------------------------------------
# TTS service path prefix
export TTS_PATH_PREFIX="${TTS_PATH_PREFIX:-/tts}"

# Default speaker for TTS tests
export TTS_DEFAULT_SPEAKER="${TTS_DEFAULT_SPEAKER:-1}"

#------------------------------------------------------------------------------
# SSL Settings
#------------------------------------------------------------------------------
# Allow self-signed certificates (set to true for development/staging)
export SSL_INSECURE="${SSL_INSECURE:-true}"

#------------------------------------------------------------------------------
# Derived Configuration (do not modify)
#------------------------------------------------------------------------------
# Script directory (for relative path resolution)
ENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export API_TESTS_ROOT="${ENV_SCRIPT_DIR}/.."

# Reports directory
export REPORTS_DIR="${API_TESTS_ROOT}/reports"

# Ensure reports directory exists
mkdir -p "${REPORTS_DIR}"
