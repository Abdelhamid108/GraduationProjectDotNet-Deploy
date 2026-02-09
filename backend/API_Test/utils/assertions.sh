#!/usr/bin/env bash
#==============================================================================
# Assertion Functions for API Testing Framework
#
# Provides test assertion functions for validating API responses
#==============================================================================

# Source guard - prevent multiple sourcing
[[ -n "${_ASSERTIONS_SH_LOADED:-}" ]] && return 0
_ASSERTIONS_SH_LOADED=1

# Source logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logger.sh"

#------------------------------------------------------------------------------
# Assertion Result Storage
#------------------------------------------------------------------------------
LAST_ASSERTION_ERROR=""

#------------------------------------------------------------------------------
# assert_status_code
# Validates HTTP status code matches expected
#
# Arguments:
#   $1 - Expected status code
#   $2 - Actual status code
#   $3 - Test name (optional)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_status_code() {
    local expected="${1:?Expected status code required}"
    local actual="${2:?Actual status code required}"
    local test_name="${3:-Status Code Check}"
    
    if [[ "$actual" == "$expected" ]]; then
        log_debug "Assert status code: expected=${expected}, actual=${actual} ✓"
        return 0
    else
        LAST_ASSERTION_ERROR="Expected status ${expected}, got ${actual}"
        log_debug "Assert status code: ${LAST_ASSERTION_ERROR} ✗"
        return 1
    fi
}

#------------------------------------------------------------------------------
# assert_json_field
# Validates a JSON field exists and optionally matches expected value
#
# Arguments:
#   $1 - JSON response body
#   $2 - Field path (jq syntax, e.g., ".data.id" or ".success")
#   $3 - Expected value (optional, if empty just checks existence)
#   $4 - Test name (optional)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_json_field() {
    local json="${1:?JSON body required}"
    local field_path="${2:?Field path required}"
    local expected="${3:-}"
    local test_name="${4:-JSON Field Check}"
    
    # Extract field value
    local actual
    actual=$(echo "$json" | jq -r "${field_path} // \"__NULL__\"" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        LAST_ASSERTION_ERROR="Invalid JSON or jq error"
        return 1
    fi
    
    # Check if field exists
    if [[ "$actual" == "__NULL__" ]] || [[ "$actual" == "null" ]]; then
        LAST_ASSERTION_ERROR="Field '${field_path}' not found in response"
        return 1
    fi
    
    # If expected value provided, compare
    if [[ -n "$expected" ]]; then
        if [[ "$actual" == "$expected" ]]; then
            log_debug "Assert JSON field ${field_path}: expected='${expected}', actual='${actual}' ✓"
            return 0
        else
            LAST_ASSERTION_ERROR="Field '${field_path}': expected '${expected}', got '${actual}'"
            return 1
        fi
    fi
    
    log_debug "Assert JSON field ${field_path} exists ✓"
    return 0
}

#------------------------------------------------------------------------------
# assert_json_success
# Validates the standard API response success field is true
#
# Arguments:
#   $1 - JSON response body
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_json_success() {
    local json="${1:?JSON body required}"
    
    local success
    success=$(echo "$json" | jq -r '.success // false' 2>/dev/null)
    
    if [[ "$success" == "true" ]]; then
        return 0
    else
        local error
        error=$(echo "$json" | jq -r '.errorMessage // "Unknown error"' 2>/dev/null)
        LAST_ASSERTION_ERROR="API returned success=false: ${error}"
        return 1
    fi
}

#------------------------------------------------------------------------------
# assert_contains
# Validates string contains substring
#
# Arguments:
#   $1 - String to search in
#   $2 - Substring to find
#   $3 - Test name (optional)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_contains() {
    local string="${1:-}"
    local substring="${2:?Substring required}"
    local test_name="${3:-Contains Check}"
    
    if [[ "$string" == *"$substring"* ]]; then
        log_debug "Assert contains '${substring}' ✓"
        return 0
    else
        LAST_ASSERTION_ERROR="String does not contain '${substring}'"
        return 1
    fi
}

#------------------------------------------------------------------------------
# assert_not_empty
# Validates string is not empty
#
# Arguments:
#   $1 - String to check
#   $2 - Field name (for error message)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_not_empty() {
    local value="${1:-}"
    local field_name="${2:-Value}"
    
    if [[ -n "$value" ]]; then
        return 0
    else
        LAST_ASSERTION_ERROR="${field_name} is empty"
        return 1
    fi
}

#------------------------------------------------------------------------------
# assert_equals
# Validates two values are equal
#
# Arguments:
#   $1 - Expected value
#   $2 - Actual value
#   $3 - Description (optional)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_equals() {
    local expected="${1:-}"
    local actual="${2:-}"
    local description="${3:-Value}"
    
    if [[ "$expected" == "$actual" ]]; then
        log_debug "Assert equals: '${expected}' == '${actual}' ✓"
        return 0
    else
        LAST_ASSERTION_ERROR="${description}: expected '${expected}', got '${actual}'"
        return 1
    fi
}

#------------------------------------------------------------------------------
# assert_matches
# Validates string matches regex pattern
#
# Arguments:
#   $1 - String to test
#   $2 - Regex pattern
#   $3 - Description (optional)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_matches() {
    local string="${1:-}"
    local pattern="${2:?Pattern required}"
    local description="${3:-Value}"
    
    if [[ "$string" =~ $pattern ]]; then
        log_debug "Assert matches pattern ✓"
        return 0
    else
        LAST_ASSERTION_ERROR="${description} does not match pattern '${pattern}'"
        return 1
    fi
}

#------------------------------------------------------------------------------
# assert_greater_than
# Validates number is greater than threshold
#
# Arguments:
#   $1 - Actual value
#   $2 - Threshold
#   $3 - Description (optional)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_greater_than() {
    local actual="${1:?Actual value required}"
    local threshold="${2:?Threshold required}"
    local description="${3:-Value}"
    
    if (( $(echo "$actual > $threshold" | bc -l 2>/dev/null || echo 0) )); then
        return 0
    else
        LAST_ASSERTION_ERROR="${description}: ${actual} is not greater than ${threshold}"
        return 1
    fi
}

#------------------------------------------------------------------------------
# assert_less_than
# Validates number is less than threshold
#
# Arguments:
#   $1 - Actual value
#   $2 - Threshold
#   $3 - Description (optional)
#
# Returns:
#   0 on success, 1 on failure
#------------------------------------------------------------------------------
assert_less_than() {
    local actual="${1:?Actual value required}"
    local threshold="${2:?Threshold required}"
    local description="${3:-Value}"
    
    if (( $(echo "$actual < $threshold" | bc -l 2>/dev/null || echo 0) )); then
        return 0
    else
        LAST_ASSERTION_ERROR="${description}: ${actual} is not less than ${threshold}"
        return 1
    fi
}

#------------------------------------------------------------------------------
# get_last_assertion_error
# Returns the last assertion error message
#------------------------------------------------------------------------------
get_last_assertion_error() {
    echo "$LAST_ASSERTION_ERROR"
}

#------------------------------------------------------------------------------
# clear_assertion_error
# Clears the last assertion error
#------------------------------------------------------------------------------
clear_assertion_error() {
    LAST_ASSERTION_ERROR=""
}
