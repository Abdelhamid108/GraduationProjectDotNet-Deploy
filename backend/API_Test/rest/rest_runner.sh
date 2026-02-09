#!/usr/bin/env bash
#==============================================================================
# REST API Test Runner for API Testing Framework
#
# Executes REST endpoint tests defined in endpoints.json
#==============================================================================

# Source guard - prevent multiple sourcing
[[ -n "${_REST_RUNNER_SH_LOADED:-}" ]] && return 0
_REST_RUNNER_SH_LOADED=1

set -o pipefail

# Script directory
REST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_TESTS_ROOT="${REST_SCRIPT_DIR}/.."

# Source dependencies
source "${API_TESTS_ROOT}/config/env.sh"
source "${API_TESTS_ROOT}/config/auth.sh"
source "${API_TESTS_ROOT}/config/urls.sh"
source "${API_TESTS_ROOT}/utils/logger.sh"
source "${API_TESTS_ROOT}/utils/assertions.sh"
source "${API_TESTS_ROOT}/utils/report.sh"

#------------------------------------------------------------------------------
# Globals (only set if not already defined)
#------------------------------------------------------------------------------
ENDPOINTS_FILE="${REST_SCRIPT_DIR}/endpoints.json"
# Don't reset BASE_URL if already set by parent script
[[ -z "${_REST_BASE_URL_SET:-}" ]] && _REST_DRY_RUN=false
[[ -z "${_REST_VERBOSE_SET:-}" ]] && _REST_VERBOSE=false

#------------------------------------------------------------------------------
# replace_placeholders
# Replaces template placeholders in a string
#
# Arguments:
#   $1 - String with placeholders
#
# Returns:
#   String with placeholders replaced
#------------------------------------------------------------------------------
replace_placeholders() {
    local str="$1"
    local timestamp=$(date +%s)
    
    # Replace common placeholders
    str="${str//\{\{TEST_USERNAME\}\}/$TEST_USERNAME}"
    str="${str//\{\{TEST_PASSWORD\}\}/$TEST_PASSWORD}"
    str="${str//\{\{timestamp\}\}/$timestamp}"
    str="${str//\{\{ACCESS_TOKEN\}\}/$(get_access_token)}"
    str="${str//\{\{REFRESH_TOKEN\}\}/$(get_refresh_token)}"
    
    echo "$str"
}

#------------------------------------------------------------------------------
# build_curl_command
# Builds curl command for an endpoint
#
# Arguments:
#   $1 - Endpoint JSON object
#
# Returns:
#   Curl command string
#------------------------------------------------------------------------------
build_curl_command() {
    local endpoint="$1"
    
    local method=$(echo "$endpoint" | jq -r '.method')
    local path=$(echo "$endpoint" | jq -r '.path')
    local auth_required=$(echo "$endpoint" | jq -r '.auth_required // false')
    local content_type=$(echo "$endpoint" | jq -r '.content_type // "application/json"')
    local payload=$(echo "$endpoint" | jq -c '.payload // empty')
    local query_params=$(echo "$endpoint" | jq -c '.query_params // empty')
    local is_binary=$(echo "$endpoint" | jq -r '.is_binary_response // false')
    
    # Build URL
    local url="${BASE_URL}${path}"
    
    # Add query parameters
    if [[ -n "$query_params" ]] && [[ "$query_params" != "null" ]]; then
        local query_string=""
        while IFS="=" read -r key value; do
            [[ -n "$query_string" ]] && query_string+="&"
            value=$(replace_placeholders "$value")
            query_string+="${key}=$(url_encode "$value")"
        done < <(echo "$query_params" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
        
        url="${url}?${query_string}"
    fi
    
    # Get SSL options
    local ssl_opts=""
    if [[ "${SSL_INSECURE:-false}" == "true" ]]; then
        ssl_opts="-k"
    fi
    
    # Start building curl command
    local cmd="curl -s ${ssl_opts} -w '\n%{http_code}\n%{time_total}'"
    cmd+=" --max-time ${REQUEST_TIMEOUT}"
    cmd+=" -X ${method}"
    
    # Add authentication header
    if [[ "$auth_required" == "true" ]] && is_authenticated; then
        cmd+=" -H '$(get_auth_header)'"
    fi
    
    # Add content type and payload
    if [[ -n "$payload" ]] && [[ "$payload" != "null" ]]; then
        payload=$(replace_placeholders "$payload")
        
        if [[ "$content_type" == "multipart/form-data" ]]; then
            # Build form data
            while IFS="=" read -r key value; do
                value=$(replace_placeholders "$value")
                cmd+=" -F '${key}=${value}'"
            done < <(echo "$payload" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
        else
            cmd+=" -H 'Content-Type: ${content_type}'"
            cmd+=" -d '${payload}'"
        fi
    fi
    
    # Handle binary response
    if [[ "$is_binary" == "true" ]]; then
        cmd+=" -o /dev/null"
    fi
    
    cmd+=" '${url}'"
    
    echo "$cmd"
}

#------------------------------------------------------------------------------
# run_single_test
# Executes a single endpoint test
#
# Arguments:
#   $1 - Endpoint JSON object
#
# Returns:
#   0 on pass, 1 on fail
#------------------------------------------------------------------------------
run_single_test() {
    local endpoint="$1"
    
    local id=$(echo "$endpoint" | jq -r '.id')
    local name=$(echo "$endpoint" | jq -r '.name')
    local method=$(echo "$endpoint" | jq -r '.method')
    local path=$(echo "$endpoint" | jq -r '.path')
    local expected_status=$(echo "$endpoint" | jq -r '.expected_status')
    local skip=$(echo "$endpoint" | jq -r '.skip // false')
    local skip_reason=$(echo "$endpoint" | jq -r '.skip_reason // ""')
    local depends_on=$(echo "$endpoint" | jq -r '.depends_on // ""')
    local store_tokens=$(echo "$endpoint" | jq -r '.store_tokens // false')
    local expected_fields=$(echo "$endpoint" | jq -r '.expected_fields // [] | .[]' 2>/dev/null)
    local is_binary=$(echo "$endpoint" | jq -r '.is_binary_response // false')
    local is_plain_text=$(echo "$endpoint" | jq -r '.is_plain_text // false')
    local auth_required=$(echo "$endpoint" | jq -r '.auth_required // false')
    
    # Track if auth was used
    local auth_used="false"
    if [[ "$auth_required" == "true" ]] && is_authenticated; then
        auth_used="true"
    fi
    
    # Check if skipped
    if [[ "$skip" == "true" ]]; then
        log_test_skip "$name" "$skip_reason"
        add_rest_result "$id" "$name" "$method" "$path" "SKIPPED" "$expected_status" 0 0 "$skip_reason" "" "$auth_used"
        return 0
    fi
    
    # Check dependencies (auth required but not authenticated)
    if [[ -n "$depends_on" ]] && [[ "$depends_on" == "auth_login" ]] && ! is_authenticated; then
        log_test_skip "$name" "Authentication required but not logged in"
        add_rest_result "$id" "$name" "$method" "$path" "SKIPPED" "$expected_status" 0 0 "Authentication required" "" "false"
        return 0
    fi
    
    # Build and execute curl command
    local curl_cmd=$(build_curl_command "$endpoint")
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: ${method} ${path}"
        log_debug "Command: ${curl_cmd}"
        return 0
    fi
    
    [[ "$VERBOSE" == "true" ]] && log_debug "Executing: ${curl_cmd}"
    
    # Execute curl
    local response
    response=$(eval "$curl_cmd" 2>&1)
    local curl_exit=$?
    
    if [[ $curl_exit -ne 0 ]]; then
        log_test_fail "$name" "curl error: ${response}" "$payload" ""
        add_rest_result "$id" "$name" "$method" "$path" "FAILED" "$expected_status" 0 0 "curl error: ${response}" "$response" "$auth_used"
        return 1
    fi
    
    # Parse response (format depends on binary vs text)
    # For binary: only http_code and time_total (2 lines)
    # For text: body + http_code + time_total (3+ lines)
    local time_total http_code body
    local line_count=$(echo "$response" | wc -l)
    
    if [[ "$is_binary" == "true" ]]; then
        # Binary response: output is just "http_code\ntime_total"
        time_total=$(echo "$response" | tail -n1)
        http_code=$(echo "$response" | head -n1)
        body="[binary data]"
    else
        # Text response: output is "body\nhttp_code\ntime_total"
        if [[ $line_count -ge 2 ]]; then
            time_total=$(echo "$response" | tail -n1)
            http_code=$(echo "$response" | tail -n2 | head -n1)
            body=$(echo "$response" | sed '$d' | sed '$d')
        else
            # Response has unexpected format
            time_total="0"
            http_code="000"
            body="$response"
        fi
    fi
    
    # Validate http_code is numeric (strip any non-numeric chars)
    http_code=$(echo "$http_code" | tr -dc '0-9')
    [[ -z "$http_code" ]] && http_code="000"
    
    # Convert time to milliseconds
    local latency_ms=$(echo "$time_total * 1000" | bc 2>/dev/null | cut -d. -f1 || echo "0")
    [[ -z "$latency_ms" ]] && latency_ms=0
    
    # Validate status code
    if ! assert_status_code "$expected_status" "$http_code"; then
        local error=$(get_last_assertion_error)
        log_test_fail "$name" "$error" "$payload" "$body"
        add_rest_result "$id" "$name" "$method" "$path" "FAILED" "$expected_status" "$http_code" "$latency_ms" "$error" "$body" "$auth_used"
        return 1
    fi
    
    # For non-binary, non-plain-text responses, validate JSON fields
    if [[ "$is_binary" != "true" ]] && [[ "$is_plain_text" != "true" ]] && [[ -n "$expected_fields" ]]; then
        for field in $expected_fields; do
            if ! assert_json_field "$body" ".$field"; then
                local error=$(get_last_assertion_error)
                log_test_fail "$name" "$error" "$payload" "$body"
                add_rest_result "$id" "$name" "$method" "$path" "FAILED" "$expected_status" "$http_code" "$latency_ms" "$error" "$body" "$auth_used"
                return 1
            fi
        done
    fi
    
    # Store tokens if this is a login response
    if [[ "$store_tokens" == "true" ]]; then
        ACCESS_TOKEN=$(echo "$body" | jq -r '.data.accessToken // empty')
        REFRESH_TOKEN=$(echo "$body" | jq -r '.data.refreshToken // empty')
        
        if [[ -n "$ACCESS_TOKEN" ]]; then
            log_debug "Tokens stored from login response"
        fi
    fi
    
    log_test_pass "$name" "$latency_ms" "$payload" "$body"
    add_rest_result "$id" "$name" "$method" "$path" "PASSED" "$expected_status" "$http_code" "$latency_ms" "" "$body" "$auth_used"
    
    # Apply rate limiting delay if configured
    local throttle_delay=$(echo "$endpoint" | jq -r '.rate_limit.throttle_delay_ms // 0')
    if [[ "$throttle_delay" -gt 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
        local delay_seconds=$((throttle_delay / 1000))
        log_debug "Rate limit throttle: waiting ${delay_seconds}s before next request"
        sleep "$delay_seconds"
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# run_rest_tests
# Main function to run all REST tests
#
# Arguments:
#   $1 - Base URL
#   $2 - Dry run flag (optional)
#   $3 - Verbose flag (optional)
#
# Returns:
#   0 on all pass, 1 on any failure
#------------------------------------------------------------------------------
run_rest_tests() {
    BASE_URL="${1:?Base URL is required}"
    DRY_RUN="${2:-false}"
    VERBOSE="${3:-false}"
    
    log_section "REST API Tests"
    
    # Check if endpoints file exists
    if [[ ! -f "$ENDPOINTS_FILE" ]]; then
        log_error "Endpoints file not found: ${ENDPOINTS_FILE}"
        return 1
    fi
    
    # Get test order or default to all endpoints
    local test_order
    test_order=$(jq -r '.test_order // [] | .[]' "$ENDPOINTS_FILE" 2>/dev/null)
    
    if [[ -z "$test_order" ]]; then
        # If no order specified, use all endpoints in file order
        test_order=$(jq -r '.endpoints[].id' "$ENDPOINTS_FILE")
    fi
    
    local total_tests=$(echo "$test_order" | wc -l)
    local current=0
    local failures=0
    
    log_info "Running ${total_tests} REST tests..."
    echo ""
    
    # Run tests in order
    while IFS= read -r test_id; do
        [[ -z "$test_id" ]] && continue
        
        ((current++))
        
        # Get endpoint by ID
        local endpoint
        endpoint=$(jq --arg id "$test_id" '.endpoints[] | select(.id == $id)' "$ENDPOINTS_FILE")
        
        if [[ -z "$endpoint" ]]; then
            log_warn "Endpoint not found: ${test_id}"
            continue
        fi
        
        if ! run_single_test "$endpoint"; then
            ((failures++))
        fi
        
    done <<< "$test_order"
    
    echo ""
    log_info "REST tests completed: $((current - failures)) passed, ${failures} failed"
    
    return $((failures > 0 ? 1 : 0))
}

# Allow direct execution (not sourcing)
# Use basename comparison to handle path differences
_SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
_CALLER_NAME=$(basename "$0")
if [[ "$_SCRIPT_NAME" == "$_CALLER_NAME" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <base_url> [--dry-run] [--verbose]"
        exit 1
    fi
    
    run_rest_tests "$@"
fi
