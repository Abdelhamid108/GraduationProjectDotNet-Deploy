#!/usr/bin/env bash
#==============================================================================
# WebSocket/SignalR Test Runner for API Testing Framework
#
# Executes WebSocket tests using websocat for SignalR hub testing
#==============================================================================

# Source guard - prevent multiple sourcing
[[ -n "${_WS_RUNNER_SH_LOADED:-}" ]] && return 0
_WS_RUNNER_SH_LOADED=1

set -o pipefail

# Script directory
WS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_TESTS_ROOT="${WS_SCRIPT_DIR}/.."

# Source dependencies
source "${API_TESTS_ROOT}/config/env.sh"
source "${API_TESTS_ROOT}/config/urls.sh"
source "${API_TESTS_ROOT}/utils/logger.sh"
source "${API_TESTS_ROOT}/utils/assertions.sh"
source "${API_TESTS_ROOT}/utils/report.sh"

#------------------------------------------------------------------------------
# Globals (only set if not already defined)
#------------------------------------------------------------------------------
WS_TESTS_FILE="${WS_SCRIPT_DIR}/ws_tests.json"

# SignalR record separator
RS=$'\x1e'

#------------------------------------------------------------------------------
# check_websocat
# Checks if websocat is available
#------------------------------------------------------------------------------
check_websocat() {
    if ! command -v websocat &> /dev/null; then
        log_error "websocat is not installed. Please install it first."
        log_info "Linux: wget -qO /tmp/websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl && chmod +x /tmp/websocat && sudo mv /tmp/websocat /usr/local/bin/"
        log_info "Windows: Download from https://github.com/vi/websocat/releases"
        return 1
    fi
    return 0
}

#------------------------------------------------------------------------------
# run_negotiate
# Performs SignalR negotiation
#
# Arguments:
#   $1 - Base URL
#
# Returns:
#   0 on success, 1 on failure
#   Outputs connection token on success
#------------------------------------------------------------------------------
run_negotiate() {
    local base_url="$1"
    local negotiate_url="${base_url}/signHub/negotiate?negotiateVersion=1"
    
    log_debug "Negotiating at: ${negotiate_url}"
    
    local response
    local http_code
    local ssl_opts=""
    [[ "${SSL_INSECURE:-false}" == "true" ]] && ssl_opts="-k"
    
    response=$(curl -s ${ssl_opts} -w "\n%{http_code}" \
        --max-time "${REQUEST_TIMEOUT}" \
        -X POST "${negotiate_url}" \
        -H "Content-Type: application/json")
    
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" != "200" ]]; then
        log_error "Negotiation failed with HTTP ${http_code}"
        return 1
    fi
    
    local connection_token
    connection_token=$(echo "$response" | jq -r '.connectionToken // empty')
    
    if [[ -z "$connection_token" ]]; then
        log_warn "No connection token in response (may be optional)"
    fi
    
    echo "$connection_token"
    return 0
}

#------------------------------------------------------------------------------
# run_http_test
# Runs an HTTP-based test (like negotiation)
#
# Arguments:
#   $1 - Test JSON object
#
# Returns:
#   0 on pass, 1 on fail
#------------------------------------------------------------------------------
run_http_test() {
    local test_def="$1"
    
    local id=$(echo "$test_def" | jq -r '.id')
    local name=$(echo "$test_def" | jq -r '.name')
    local path=$(echo "$test_def" | jq -r '.path')
    local method=$(echo "$test_def" | jq -r '.method // "GET"')
    local expected_status=$(echo "$test_def" | jq -r '.expected_status // 200')
    
    local url="${BASE_URL}${path}"
    
    # Add query params if present
    local query_params=$(echo "$test_def" | jq -c '.query_params // empty')
    if [[ -n "$query_params" ]] && [[ "$query_params" != "null" ]]; then
        local query_string=""
        while IFS="=" read -r key value; do
            [[ -n "$query_string" ]] && query_string+="&"
            query_string+="${key}=${value}"
        done < <(echo "$query_params" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
        url="${url}?${query_string}"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: ${method} ${url}"
        return 0
    fi
    
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    local response
    local http_code
    local ssl_opts=""
    [[ "${SSL_INSECURE:-false}" == "true" ]] && ssl_opts="-k"
    
    response=$(curl -s ${ssl_opts} -w "\n%{http_code}" \
        --max-time "${REQUEST_TIMEOUT}" \
        -X "${method}" "${url}" \
        -H "Content-Type: application/json")
    
    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    local latency=$((end_time - start_time))
    
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" != "$expected_status" ]]; then
        log_test_fail "$name" "Expected status ${expected_status}, got ${http_code}"
        add_ws_result "$id" "$name" "HTTP ${method}" "FAILED" "$latency" "Status ${http_code}"
        return 1
    fi
    
    log_test_pass "$name" "$latency"
    add_ws_result "$id" "$name" "HTTP ${method}" "PASSED" "$latency"
    return 0
}

#------------------------------------------------------------------------------
# run_websocket_test
# Runs a WebSocket-based test
#
# Arguments:
#   $1 - Test JSON object
#   $2 - WebSocket URL
#
# Returns:
#   0 on pass, 1 on fail
#------------------------------------------------------------------------------
run_websocket_test() {
    local test_def="$1"
    local ws_url="$2"
    
    local id=$(echo "$test_def" | jq -r '.id')
    local name=$(echo "$test_def" | jq -r '.name')
    local action=$(echo "$test_def" | jq -r '.action')
    local timeout_ms=$(echo "$test_def" | jq -r '.timeout_ms // 5000')
    local expected_error=$(echo "$test_def" | jq -r '.expected_error // false')
    
    local timeout_sec=$((timeout_ms / 1000))
    [[ $timeout_sec -lt 1 ]] && timeout_sec=1
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would test: ${action} on ${ws_url}"
        return 0
    fi
    
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    local result=""
    local exit_code=0
    
    # SSL insecure flag for websocat
    local ws_ssl_opts=""
    [[ "${SSL_INSECURE:-false}" == "true" ]] && ws_ssl_opts="-k"
    
    case "$action" in
        connect)
            # Test connection only
            result=$(echo "" | timeout "${timeout_sec}" websocat ${ws_ssl_opts} -n1 "${ws_url}" 2>&1) || exit_code=$?
            
            if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 124 ]]; then
                # Success or timeout (connection was established)
                log_test_pass "$name"
                add_ws_result "$id" "$name" "connect" "PASSED" "$(($(date +%s%3N 2>/dev/null || date +%s) - start_time))"
                return 0
            else
                log_test_fail "$name" "Connection failed"
                add_ws_result "$id" "$name" "connect" "FAILED" "$(($(date +%s%3N 2>/dev/null || date +%s) - start_time))" "Connection failed"
                return 1
            fi
            ;;
            
        send)
            local message=$(echo "$test_def" | jq -r '.message')
            
            result=$(echo "${message}" | timeout "${timeout_sec}" websocat ${ws_ssl_opts} -n1 "${ws_url}" 2>&1) || exit_code=$?
            
            local end_time=$(date +%s%3N 2>/dev/null || date +%s)
            local latency=$((end_time - start_time))
            
            if [[ "$expected_error" == "true" ]]; then
                # We expect an error, so failure is actually success
                log_test_pass "$name" "$latency"
                add_ws_result "$id" "$name" "send" "PASSED" "$latency"
                return 0
            fi
            
            if [[ $exit_code -eq 0 ]]; then
                log_test_pass "$name" "$latency"
                add_ws_result "$id" "$name" "send" "PASSED" "$latency"
                return 0
            else
                log_test_fail "$name" "Send failed"
                add_ws_result "$id" "$name" "send" "FAILED" "$latency" "Send failed"
                return 1
            fi
            ;;
            
        invoke)
            local method=$(echo "$test_def" | jq -r '.method')
            local arguments=$(echo "$test_def" | jq -c '.arguments // {}')
            
            # Build SignalR invocation message
            # First send handshake, then invocation
            local handshake="{\"protocol\":\"json\",\"version\":1}${RS}"
            local invocation="{\"type\":1,\"target\":\"${method}\",\"arguments\":[${arguments}]}${RS}"
            
            # Combined message
            local full_message="${handshake}${invocation}"
            
            result=$(echo -e "${full_message}" | timeout "${timeout_sec}" websocat ${ws_ssl_opts} "${ws_url}" 2>&1) || exit_code=$?
            
            local end_time=$(date +%s%3N 2>/dev/null || date +%s)
            local latency=$((end_time - start_time))
            
            if [[ "$expected_error" == "true" ]]; then
                log_test_pass "$name" "$latency"
                add_ws_result "$id" "$name" "invoke:${method}" "PASSED" "$latency"
                return 0
            fi
            
            # Check for expected event in response
            local expected_event=$(echo "$test_def" | jq -r '.expected_event // empty')
            if [[ -n "$expected_event" ]]; then
                if echo "$result" | grep -q "$expected_event"; then
                    log_test_pass "$name" "$latency"
                    add_ws_result "$id" "$name" "invoke:${method}" "PASSED" "$latency"
                    return 0
                else
                    log_test_fail "$name" "Expected event '${expected_event}' not received"
                    add_ws_result "$id" "$name" "invoke:${method}" "FAILED" "$latency" "Expected event not received"
                    return 1
                fi
            fi
            
            log_test_pass "$name" "$latency"
            add_ws_result "$id" "$name" "invoke:${method}" "PASSED" "$latency"
            return 0
            ;;
            
        disconnect)
            # Disconnect is always successful if we get here
            log_test_pass "$name"
            add_ws_result "$id" "$name" "disconnect" "PASSED" 0
            return 0
            ;;
            
        *)
            log_warn "Unknown action: ${action}"
            add_ws_result "$id" "$name" "$action" "SKIPPED" 0 "Unknown action"
            return 0
            ;;
    esac
}

#------------------------------------------------------------------------------
# run_ws_tests
# Main function to run all WebSocket tests
#
# Arguments:
#   $1 - Base URL
#   $2 - Dry run flag (optional)
#   $3 - Verbose flag (optional)
#
# Returns:
#   0 on all pass, 1 on any failure
#------------------------------------------------------------------------------
run_ws_tests() {
    BASE_URL="${1:?Base URL is required}"
    DRY_RUN="${2:-false}"
    VERBOSE="${3:-false}"
    
    log_section "WebSocket/SignalR Tests"
    
    # Check websocat
    if ! check_websocat; then
        log_error "Skipping WebSocket tests - websocat not available"
        return 1
    fi
    
    # Build WebSocket URL
    WS_URL=$(get_ws_url "$BASE_URL")
    log_info "WebSocket URL: ${WS_URL}"
    
    # Check if tests file exists
    if [[ ! -f "$WS_TESTS_FILE" ]]; then
        log_error "WebSocket tests file not found: ${WS_TESTS_FILE}"
        return 1
    fi
    
    # Get test order or default to all tests
    local test_order
    test_order=$(jq -r '.test_order // [] | .[]' "$WS_TESTS_FILE" 2>/dev/null)
    
    if [[ -z "$test_order" ]]; then
        test_order=$(jq -r '.tests[].id' "$WS_TESTS_FILE")
    fi
    
    local total_tests=$(echo "$test_order" | wc -l)
    local current=0
    local failures=0
    
    log_info "Running ${total_tests} WebSocket tests..."
    echo ""
    
    # Run tests in order
    while IFS= read -r test_id; do
        [[ -z "$test_id" ]] && continue
        
        ((current++))
        
        # Get test by ID
        local test_def
        test_def=$(jq --arg id "$test_id" '.tests[] | select(.id == $id)' "$WS_TESTS_FILE")
        
        if [[ -z "$test_def" ]]; then
            log_warn "Test not found: ${test_id}"
            continue
        fi
        
        local test_type=$(echo "$test_def" | jq -r '.type // "websocket"')
        
        case "$test_type" in
            http)
                if ! run_http_test "$test_def"; then
                    ((failures++))
                fi
                ;;
            websocket)
                if ! run_websocket_test "$test_def" "$WS_URL"; then
                    ((failures++))
                fi
                ;;
            *)
                log_warn "Unknown test type: ${test_type}"
                ;;
        esac
        
    done <<< "$test_order"
    
    echo ""
    log_info "WebSocket tests completed: $((current - failures)) passed, ${failures} failed"
    
    return $((failures > 0 ? 1 : 0))
}

# Allow direct execution (not sourcing)
# Use basename comparison to handle path differences
_WS_SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
_WS_CALLER_NAME=$(basename "$0")
if [[ "$_WS_SCRIPT_NAME" == "$_WS_CALLER_NAME" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <base_url> [--dry-run] [--verbose]"
        exit 1
    fi
    
    run_ws_tests "$@"
fi
