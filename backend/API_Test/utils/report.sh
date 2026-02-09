#!/usr/bin/env bash
#==============================================================================
# Report Generation for API Testing Framework
#
# Generates JSON and HTML test reports
#==============================================================================

# Source guard - prevent multiple sourcing
[[ -n "${_REPORT_SH_LOADED:-}" ]] && return 0
_REPORT_SH_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logger.sh"

#------------------------------------------------------------------------------
# Global Report Data
#------------------------------------------------------------------------------
declare -a REST_TEST_RESULTS=()
declare -a WS_TEST_RESULTS=()
declare -a FAILURES=()
REPORT_START_TIME=""
REPORT_BASE_URL=""

#------------------------------------------------------------------------------
# json_escape
# Escapes a string for safe inclusion in JSON
#
# Arguments:
#   $1 - String to escape
#------------------------------------------------------------------------------
json_escape() {
    local str="$1"
    # Remove control characters and escape special chars
    str=$(printf '%s' "$str" | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
    # Truncate if too long
    [[ ${#str} -gt 500 ]] && str="${str:0:500}..."
    echo "$str"
}

#------------------------------------------------------------------------------
# init_report
# Initializes a new test report
#
# Arguments:
#   $1 - Base URL being tested
#------------------------------------------------------------------------------
init_report() {
    local base_url="${1:?Base URL required}"
    
    REST_TEST_RESULTS=()
    WS_TEST_RESULTS=()
    FAILURES=()
    REPORT_START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    REPORT_BASE_URL="$base_url"
    
    log_debug "Report initialized at ${REPORT_START_TIME}"
}

#------------------------------------------------------------------------------
# add_rest_result
# Adds a REST test result to the report
#
# Arguments:
#   $1 - Test ID
#   $2 - Test Name
#   $3 - Method
#   $4 - Endpoint path
#   $5 - Status (PASSED/FAILED/SKIPPED)
#   $6 - Expected status code
#   $7 - Actual status code
#   $8 - Latency (ms)
#   $9 - Error message (optional)
#   $10 - Response body (optional)
#   $11 - Auth used (optional - true/false)
#------------------------------------------------------------------------------
add_rest_result() {
    local id="$1"
    local name="$2"
    local method="$3"
    local endpoint="$4"
    local status="$5"
    local expected_code="$6"
    local actual_code="$7"
    local latency="$8"
    local error="${9:-}"
    local response_body="${10:-}"
    local auth_used="${11:-false}"
    
    local result=$(cat <<EOF
{
    "id": "${id}",
    "name": "${name}",
    "endpoint": "${method} ${endpoint}",
    "status": "${status}",
    "expected_status": ${expected_code},
    "actual_status": ${actual_code},
    "latency_ms": ${latency},
    "auth_used": ${auth_used}
EOF
)
    
    if [[ -n "$error" ]]; then
        # Escape error message for JSON
        error=$(json_escape "$error")
        result+=",
    \"error\": \"${error}\""
    fi
    
    if [[ -n "$response_body" ]] && [[ "$status" == "FAILED" ]]; then
        # Include truncated response body for failed tests
        response_body=$(json_escape "$response_body")
        result+=",
    \"response_body\": \"${response_body}\""
    fi
    
    result+="
}"
    
    REST_TEST_RESULTS+=("$result")
    
    # Track failures with response body
    if [[ "$status" == "FAILED" ]]; then
        add_failure "$id" "$name" "${method} ${endpoint}" "$error" "$response_body"
    fi
}

#------------------------------------------------------------------------------
# add_ws_result
# Adds a WebSocket test result to the report
#
# Arguments:
#   $1 - Test ID
#   $2 - Test Name
#   $3 - Action
#   $4 - Status (PASSED/FAILED/SKIPPED)
#   $5 - Latency (ms)
#   $6 - Error message (optional)
#------------------------------------------------------------------------------
add_ws_result() {
    local id="$1"
    local name="$2"
    local action="$3"
    local status="$4"
    local latency="$5"
    local error="${6:-}"
    
    local result=$(cat <<EOF
{
    "id": "${id}",
    "name": "${name}",
    "action": "${action}",
    "status": "${status}",
    "latency_ms": ${latency}
EOF
)
    
    if [[ -n "$error" ]]; then
        error=$(json_escape "$error")
        result+=",
    \"error\": \"${error}\""
    fi
    
    result+="
}"
    
    WS_TEST_RESULTS+=("$result")
    
    if [[ "$status" == "FAILED" ]]; then
        add_failure "$id" "$name" "WebSocket: ${action}" "$error"
    fi
}

#------------------------------------------------------------------------------
# add_failure
# Adds a failure with diagnosis to the report
#
# Arguments:
#   $1 - Test ID
#   $2 - Test Name
#   $3 - Endpoint/Action
#   $4 - Error message
#   $5 - Response body (optional)
#------------------------------------------------------------------------------
add_failure() {
    local id="$1"
    local name="$2"
    local endpoint="$3"
    local error="$4"
    local response_body="${5:-}"
    
    # Generate diagnosis based on error
    local diagnosis=""
    local suggested_fix=""
    
    case "$error" in
        *"401"* | *"Unauthorized"*)
            diagnosis="Authentication failed or token expired"
            suggested_fix="Check credentials in config/env.sh or re-run authentication"
            ;;
        *"403"* | *"Forbidden"*)
            diagnosis="User does not have permission for this endpoint"
            suggested_fix="Use account with appropriate role/permissions"
            ;;
        *"404"* | *"Not Found"*)
            diagnosis="Endpoint not found - may be renamed or removed"
            suggested_fix="Verify endpoint path matches API documentation"
            ;;
        *"429"* | *"Too Many"*)
            diagnosis="Rate limit exceeded"
            suggested_fix="Wait before retrying or reduce test frequency"
            ;;
        *"500"* | *"Internal Server"*)
            diagnosis="Server-side error - check backend logs"
            suggested_fix="Review backend logs for exception details"
            ;;
        *"502"* | *"Bad Gateway"*)
            diagnosis="Upstream service unavailable (e.g., Gemini API)"
            suggested_fix="Check external service status and API keys"
            ;;
        *"Connection refused"*)
            diagnosis="Cannot connect to server"
            suggested_fix="Verify server is running and URL is correct"
            ;;
        *"timeout"* | *"Timeout"*)
            diagnosis="Request timed out"
            suggested_fix="Increase timeout in config/env.sh or check server load"
            ;;
        *)
            diagnosis="Unknown error"
            suggested_fix="Review error message and check endpoint implementation"
            ;;
    esac
    
    error=$(json_escape "$error")
    response_body=$(json_escape "$response_body")
    
    local failure=$(cat <<EOF
{
    "id": "${id}",
    "name": "${name}",
    "endpoint": "${endpoint}",
    "error": "${error}",
    "diagnosis": "${diagnosis}",
    "suggested_fix": "${suggested_fix}",
    "response_body": "${response_body}"
}
EOF
)
    
    FAILURES+=("$failure")
}

#------------------------------------------------------------------------------
# generate_report
# Generates the final test report
#
# Arguments:
#   $1 - Output directory (optional, defaults to REPORTS_DIR)
#
# Returns:
#   Path to generated report file
#------------------------------------------------------------------------------
generate_report() {
    local output_dir="${1:-${REPORTS_DIR:-./reports}}"
    
    mkdir -p "$output_dir"
    
    local end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="${output_dir}/report_${timestamp}.json"
    
    # Calculate duration
    local start_epoch=$(date -d "${REPORT_START_TIME}" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "${REPORT_START_TIME}" +%s 2>/dev/null || echo 0)
    local end_epoch=$(date +%s)
    local duration=$((end_epoch - start_epoch))
    
    # Calculate summary
    local rest_total=${#REST_TEST_RESULTS[@]}
    local ws_total=${#WS_TEST_RESULTS[@]}
    local total=$((rest_total + ws_total))
    local failed=${#FAILURES[@]}
    local passed=$((total - failed))
    local pass_rate="0%"
    
    if [[ $total -gt 0 ]]; then
        pass_rate=$(echo "scale=1; $passed * 100 / $total" | bc 2>/dev/null || echo "0")
        pass_rate="${pass_rate}%"
    fi
    
    # Build JSON arrays
    local rest_json="[]"
    if [[ ${#REST_TEST_RESULTS[@]} -gt 0 ]]; then
        rest_json="["
        for i in "${!REST_TEST_RESULTS[@]}"; do
            [[ $i -gt 0 ]] && rest_json+=","
            rest_json+="${REST_TEST_RESULTS[$i]}"
        done
        rest_json+="]"
    fi
    
    local ws_json="[]"
    if [[ ${#WS_TEST_RESULTS[@]} -gt 0 ]]; then
        ws_json="["
        for i in "${!WS_TEST_RESULTS[@]}"; do
            [[ $i -gt 0 ]] && ws_json+=","
            ws_json+="${WS_TEST_RESULTS[$i]}"
        done
        ws_json+="]"
    fi
    
    local failures_json="[]"
    if [[ ${#FAILURES[@]} -gt 0 ]]; then
        failures_json="["
        for i in "${!FAILURES[@]}"; do
            [[ $i -gt 0 ]] && failures_json+=","
            failures_json+="${FAILURES[$i]}"
        done
        failures_json+="]"
    fi
    
    # Generate report
    cat > "$report_file" <<EOF
{
    "metadata": {
        "timestamp": "${end_time}",
        "start_time": "${REPORT_START_TIME}",
        "end_time": "${end_time}",
        "base_url": "${REPORT_BASE_URL}",
        "duration_seconds": ${duration}
    },
    "summary": {
        "total": ${total},
        "passed": ${passed},
        "failed": ${failed},
        "skipped": 0,
        "pass_rate": "${pass_rate}"
    },
    "rest_tests": ${rest_json},
    "websocket_tests": ${ws_json},
    "failures": ${failures_json}
}
EOF
    
    # Create latest symlink
    ln -sf "report_${timestamp}.json" "${output_dir}/report_latest.json" 2>/dev/null || \
        cp "$report_file" "${output_dir}/report_latest.json"
    
    log_info "Report generated: ${report_file}"
    echo "$report_file"
}

#------------------------------------------------------------------------------
# print_report_summary
# Prints a summary of the test results to console
#------------------------------------------------------------------------------
print_report_summary() {
    local rest_total=${#REST_TEST_RESULTS[@]}
    local ws_total=${#WS_TEST_RESULTS[@]}
    local failed=${#FAILURES[@]}
    local passed=$((rest_total + ws_total - failed))
    
    log_summary "$passed" "$failed" 0
    
    if [[ ${#FAILURES[@]} -gt 0 ]]; then
        log_subsection "Failures"
        for failure in "${FAILURES[@]}"; do
            local name=$(echo "$failure" | jq -r '.name')
            local error=$(echo "$failure" | jq -r '.error')
            local diagnosis=$(echo "$failure" | jq -r '.diagnosis')
            local response=$(echo "$failure" | jq -r '.response_body // ""')
            
            echo -e "${COLOR_RED}✗${COLOR_RESET} ${name}"
            echo -e "  ${COLOR_GRAY}Error:${COLOR_RESET} ${error}"
            echo -e "  ${COLOR_GRAY}Likely cause:${COLOR_RESET} ${diagnosis}"
            
            # Show truncated response body if available
            if [[ -n "$response" ]] && [[ "$response" != "null" ]] && [[ ${#response} -gt 0 ]]; then
                # Truncate to first 200 chars for console
                local truncated="${response:0:200}"
                [[ ${#response} -gt 200 ]] && truncated+="..."
                echo -e "  ${COLOR_GRAY}Response:${COLOR_RESET} ${truncated}"
            fi
            echo ""
        done
    fi
}
