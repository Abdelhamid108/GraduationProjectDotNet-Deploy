#!/usr/bin/env bash
#==============================================================================
# Authentication Helpers for API Testing Framework
#
# Provides functions for:
# - User login and token retrieval
# - Token storage and refresh
# - Authentication header generation
#==============================================================================

# Source guard - prevent multiple sourcing
[[ -n "${_AUTH_SH_LOADED:-}" ]] && return 0
_AUTH_SH_LOADED=1

# Source dependencies
AUTH_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${AUTH_SCRIPT_DIR}/env.sh"
source "${AUTH_SCRIPT_DIR}/../utils/logger.sh"

#------------------------------------------------------------------------------
# Global Token Storage
#------------------------------------------------------------------------------
ACCESS_TOKEN=""
REFRESH_TOKEN=""
TOKEN_EXPIRES=""

#------------------------------------------------------------------------------
# get_curl_ssl_opts
# Returns curl SSL options based on SSL_INSECURE setting
#------------------------------------------------------------------------------
get_curl_ssl_opts() {
    if [[ "${SSL_INSECURE:-false}" == "true" ]]; then
        echo "-k"
    fi
}

#------------------------------------------------------------------------------
# login_user
# Authenticates with the API and stores tokens
#
# Arguments:
#   $1 - Base URL (required)
#   $2 - Username (optional, uses TEST_USERNAME if not provided)
#   $3 - Password (optional, uses TEST_PASSWORD if not provided)
#
# Returns:
#   0 on success, 1 on failure
#
# Example:
#   login_user "https://ema2a.ddns.net"
#------------------------------------------------------------------------------
login_user() {
    local base_url="${1:?Base URL is required}"
    local username="${2:-$TEST_USERNAME}"
    local password="${3:-$TEST_PASSWORD}"
    
    log_info "Authenticating as ${username}..."
    
    local login_url="${base_url}/api/Auth/login-user"
    local payload=$(cat <<EOF
{
    "userName": "${username}",
    "password": "${password}"
}
EOF
)
    
    local response
    local http_code
    local ssl_opts=$(get_curl_ssl_opts)
    
    # Make login request
    response=$(curl -s -w "\n%{http_code}" \
        ${ssl_opts} \
        --max-time "${REQUEST_TIMEOUT}" \
        -X POST "${login_url}" \
        -H "Content-Type: application/json" \
        -d "${payload}")
    
    # Extract HTTP code (last line)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    # Check HTTP status
    if [[ "$http_code" != "200" ]]; then
        log_error "Login failed with HTTP ${http_code}"
        log_debug "Response: ${response}"
        return 1
    fi
    
    # Parse success field
    local success=$(echo "$response" | jq -r '.success // false')
    if [[ "$success" != "true" ]]; then
        local error=$(echo "$response" | jq -r '.errorMessage // "Unknown error"')
        log_error "Login failed: ${error}"
        return 1
    fi
    
    # Extract tokens
    ACCESS_TOKEN=$(echo "$response" | jq -r '.data.accessToken // empty')
    REFRESH_TOKEN=$(echo "$response" | jq -r '.data.refreshToken // empty')
    TOKEN_EXPIRES=$(echo "$response" | jq -r '.data.accessTokenExpires // empty')
    
    if [[ -z "$ACCESS_TOKEN" ]]; then
        log_error "No access token in response"
        return 1
    fi
    
    log_info "Login successful. Token expires: ${TOKEN_EXPIRES}"
    return 0
}

#------------------------------------------------------------------------------
# refresh_tokens
# Refreshes the access token using the refresh token
#
# Arguments:
#   $1 - Base URL (required)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
refresh_tokens() {
    local base_url="${1:?Base URL is required}"
    
    if [[ -z "$REFRESH_TOKEN" ]]; then
        log_error "No refresh token available"
        return 1
    fi
    
    log_info "Refreshing tokens..."
    
    local refresh_url="${base_url}/api/Auth/refresh-tokens"
    local payload=$(cat <<EOF
{
    "refreshToken": "${REFRESH_TOKEN}"
}
EOF
)
    
    local response
    local http_code
    local ssl_opts=$(get_curl_ssl_opts)
    
    response=$(curl -s -w "\n%{http_code}" \
        ${ssl_opts} \
        --max-time "${REQUEST_TIMEOUT}" \
        -X POST "${refresh_url}" \
        -H "Content-Type: application/json" \
        -d "${payload}")
    
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" != "200" ]]; then
        log_error "Token refresh failed with HTTP ${http_code}"
        return 1
    fi
    
    local success=$(echo "$response" | jq -r '.success // false')
    if [[ "$success" != "true" ]]; then
        log_error "Token refresh failed"
        return 1
    fi
    
    ACCESS_TOKEN=$(echo "$response" | jq -r '.data.accessToken // empty')
    REFRESH_TOKEN=$(echo "$response" | jq -r '.data.refreshToken // empty')
    TOKEN_EXPIRES=$(echo "$response" | jq -r '.data.accessTokenExpires // empty')
    
    log_info "Tokens refreshed successfully"
    return 0
}

#------------------------------------------------------------------------------
# get_auth_header
# Returns the Authorization header value
#
# Returns:
#   Authorization header string or empty if not authenticated
#
# Example:
#   curl -H "$(get_auth_header)" https://api.example.com/endpoint
#------------------------------------------------------------------------------
get_auth_header() {
    if [[ -n "$ACCESS_TOKEN" ]]; then
        echo "Authorization: Bearer ${ACCESS_TOKEN}"
    fi
}

#------------------------------------------------------------------------------
# is_authenticated
# Checks if a valid token is available
#
# Returns:
#   0 if authenticated, 1 if not
#------------------------------------------------------------------------------
is_authenticated() {
    [[ -n "$ACCESS_TOKEN" ]]
}

#------------------------------------------------------------------------------
# get_access_token
# Returns the current access token
#------------------------------------------------------------------------------
get_access_token() {
    echo "$ACCESS_TOKEN"
}

#------------------------------------------------------------------------------
# get_refresh_token
# Returns the current refresh token
#------------------------------------------------------------------------------
get_refresh_token() {
    echo "$REFRESH_TOKEN"
}

#------------------------------------------------------------------------------
# clear_tokens
# Clears all stored tokens (logout)
#------------------------------------------------------------------------------
clear_tokens() {
    ACCESS_TOKEN=""
    REFRESH_TOKEN=""
    TOKEN_EXPIRES=""
    log_debug "Tokens cleared"
}

#------------------------------------------------------------------------------
# logout
# Performs logout and clears tokens
#
# Arguments:
#   $1 - Base URL (required)
#------------------------------------------------------------------------------
logout() {
    local base_url="${1:?Base URL is required}"
    
    if [[ -z "$REFRESH_TOKEN" ]]; then
        log_debug "No active session to logout"
        return 0
    fi
    
    log_info "Logging out..."
    
    local logout_url="${base_url}/api/Auth/logout"
    local payload=$(cat <<EOF
{
    "refreshToken": "${REFRESH_TOKEN}"
}
EOF
)
    
    local ssl_opts=$(get_curl_ssl_opts)
    
    curl -s ${ssl_opts} \
        --max-time "${REQUEST_TIMEOUT}" \
        -X POST "${logout_url}" \
        -H "Content-Type: application/json" \
        -H "$(get_auth_header)" \
        -d "${payload}" > /dev/null
    
    clear_tokens
    log_info "Logged out successfully"
}

#------------------------------------------------------------------------------
# generate_test_user
# Generates unique test user credentials
#
# Returns:
#   Sets TEST_USERNAME_GENERATED, TEST_PASSWORD_GENERATED, TEST_FULLNAME_GENERATED
#------------------------------------------------------------------------------
generate_test_user() {
    local timestamp=$(date +%s)
    local random_suffix=$((RANDOM % 9999))
    
    TEST_USERNAME_GENERATED="testuser_${timestamp}_${random_suffix}"
    TEST_EMAIL_GENERATED="${TEST_USERNAME_GENERATED}@test.local"
    TEST_PASSWORD_GENERATED="TestPass123!@#"
    TEST_FULLNAME_GENERATED="Test User ${random_suffix}"
    TEST_PHONE_GENERATED="+2010${timestamp: -8}"
    
    log_debug "Generated test user: ${TEST_USERNAME_GENERATED}"
}

#------------------------------------------------------------------------------
# register_user
# Registers a new test user
#
# Arguments:
#   $1 - Base URL (required)
#
# Returns:
#   0 on success, 1 on failure
#   Sets TEST_USERNAME and TEST_PASSWORD to the registered user
#------------------------------------------------------------------------------
register_user() {
    local base_url="${1:?Base URL is required}"
    
    # Generate unique user credentials
    generate_test_user
    
    log_info "Registering new test user: ${TEST_USERNAME_GENERATED}..."
    
    local register_url="${base_url}/api/Auth/register-user"
    
    local response
    local http_code
    local ssl_opts=$(get_curl_ssl_opts)
    
    # Use form data for registration (supports file upload)
    response=$(curl -s -w "\n%{http_code}" \
        ${ssl_opts} \
        --max-time "${REQUEST_TIMEOUT}" \
        -X POST "${register_url}" \
        -F "Email=${TEST_EMAIL_GENERATED}" \
        -F "FullName=${TEST_FULLNAME_GENERATED}" \
        -F "UserName=${TEST_USERNAME_GENERATED}" \
        -F "Password=${TEST_PASSWORD_GENERATED}" \
        -F "PhoneNumber=${TEST_PHONE_GENERATED}")
    
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" != "200" ]]; then
        log_error "Registration failed with HTTP ${http_code}"
        log_debug "Response: ${response}"
        return 1
    fi
    
    local success=$(echo "$response" | jq -r '.success // false')
    if [[ "$success" != "true" ]]; then
        local error=$(echo "$response" | jq -r '.errorMessage // "Unknown error"')
        log_error "Registration failed: ${error}"
        return 1
    fi
    
    # Update test credentials to use the new user
    TEST_USERNAME="${TEST_USERNAME_GENERATED}"
    TEST_PASSWORD="${TEST_PASSWORD_GENERATED}"
    
    log_success "User registered successfully: ${TEST_USERNAME}"
    return 0
}

#------------------------------------------------------------------------------
# ensure_authenticated
# Ensures a valid authentication session exists
# Tries login first, then registers a new user if login fails
#
# Arguments:
#   $1 - Base URL (required)
#
# Returns:
#   0 on success (authenticated), 1 on failure
#------------------------------------------------------------------------------
ensure_authenticated() {
    local base_url="${1:?Base URL is required}"
    
    log_info "Ensuring authentication..."
    
    # First, try to login with existing credentials
    if login_user "$base_url"; then
        return 0
    fi
    
    log_warn "Login failed - attempting to register new test user..."
    
    # Registration failed, try to register a new user
    if ! register_user "$base_url"; then
        log_error "Failed to register new user"
        return 1
    fi
    
    # Now login with the newly registered user
    if login_user "$base_url" "$TEST_USERNAME" "$TEST_PASSWORD"; then
        log_success "Authenticated with newly registered user"
        return 0
    fi
    
    log_error "Failed to login after registration"
    return 1
}
