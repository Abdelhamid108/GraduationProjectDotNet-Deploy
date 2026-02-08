#!/usr/bin/env bash
#==============================================================================
# Logging Utilities for API Testing Framework
#
# Provides colored, timestamped logging with multiple severity levels
#==============================================================================

# Source guard - prevent multiple sourcing
[[ -n "${_LOGGER_SH_LOADED:-}" ]] && return 0
_LOGGER_SH_LOADED=1

#------------------------------------------------------------------------------
# Color Codes (if supported and enabled)
#------------------------------------------------------------------------------
if [[ "${COLORIZED_OUTPUT:-true}" == "true" ]] && [[ -t 1 ]]; then
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_CYAN='\033[0;36m'
    readonly COLOR_GRAY='\033[0;90m'
    readonly COLOR_BOLD='\033[1m'
else
    readonly COLOR_RESET=''
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_CYAN=''
    readonly COLOR_GRAY=''
    readonly COLOR_BOLD=''
fi

#------------------------------------------------------------------------------
# Log Level Constants
#------------------------------------------------------------------------------
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

#------------------------------------------------------------------------------
# get_log_level_value
# Converts log level string to numeric value
#------------------------------------------------------------------------------
get_log_level_value() {
    case "${1^^}" in
        DEBUG) echo $LOG_LEVEL_DEBUG ;;
        INFO)  echo $LOG_LEVEL_INFO ;;
        WARN)  echo $LOG_LEVEL_WARN ;;
        ERROR) echo $LOG_LEVEL_ERROR ;;
        *)     echo $LOG_LEVEL_INFO ;;
    esac
}

# Current log level
CURRENT_LOG_LEVEL=$(get_log_level_value "${LOG_LEVEL:-INFO}")

#------------------------------------------------------------------------------
# get_timestamp
# Returns current timestamp in ISO format
#------------------------------------------------------------------------------
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

#------------------------------------------------------------------------------
# _log
# Internal logging function
#
# Arguments:
#   $1 - Level (DEBUG/INFO/WARN/ERROR)
#   $2 - Message
#   $3 - Color code (optional)
#------------------------------------------------------------------------------
_log() {
    local level="$1"
    local message="$2"
    local color="${3:-$COLOR_RESET}"
    
    local level_value=$(get_log_level_value "$level")
    
    # Check if should log
    if [[ $level_value -lt $CURRENT_LOG_LEVEL ]]; then
        return
    fi
    
    local timestamp=$(get_timestamp)
    local formatted_msg="${COLOR_GRAY}[${timestamp}]${COLOR_RESET} ${color}[${level}]${COLOR_RESET} ${message}"
    
    echo -e "$formatted_msg"
    
    # Also write to log file if configured
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi
}

#------------------------------------------------------------------------------
# Logging Functions
#------------------------------------------------------------------------------

log_debug() {
    _log "DEBUG" "$1" "$COLOR_GRAY"
}

log_info() {
    _log "INFO" "$1" "$COLOR_CYAN"
}

log_warn() {
    _log "WARN" "$1" "$COLOR_YELLOW"
}

log_error() {
    _log "ERROR" "$1" "$COLOR_RED"
}

log_success() {
    _log "INFO" "$1" "$COLOR_GREEN"
}

#------------------------------------------------------------------------------
# Test Result Logging
#------------------------------------------------------------------------------

log_test_pass() {
    local test_name="$1"
    local latency="${2:-}"
    
    local msg="${COLOR_GREEN}✓${COLOR_RESET} ${test_name}"
    [[ -n "$latency" ]] && msg+=" ${COLOR_GRAY}(${latency}ms)${COLOR_RESET}"
    
    echo -e "$msg"
}

log_test_fail() {
    local test_name="$1"
    local error="${2:-}"
    
    local msg="${COLOR_RED}✗${COLOR_RESET} ${test_name}"
    [[ -n "$error" ]] && msg+=" ${COLOR_RED}— ${error}${COLOR_RESET}"
    
    echo -e "$msg"
}

log_test_skip() {
    local test_name="$1"
    local reason="${2:-}"
    
    local msg="${COLOR_YELLOW}○${COLOR_RESET} ${test_name} ${COLOR_GRAY}(skipped)"
    [[ -n "$reason" ]] && msg+=" — ${reason}"
    msg+="${COLOR_RESET}"
    
    echo -e "$msg"
}

#------------------------------------------------------------------------------
# Section Headers
#------------------------------------------------------------------------------

log_section() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_BLUE}$(printf '═%.0s' $(seq 1 $width))${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}$(printf ' %.0s' $(seq 1 $padding)) ${title} $(printf ' %.0s' $(seq 1 $padding))${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}$(printf '═%.0s' $(seq 1 $width))${COLOR_RESET}"
    echo ""
}

log_subsection() {
    local title="$1"
    echo ""
    echo -e "${COLOR_BOLD}── ${title} ──${COLOR_RESET}"
    echo ""
}

#------------------------------------------------------------------------------
# Progress Indicators
#------------------------------------------------------------------------------

log_progress() {
    local current="$1"
    local total="$2"
    local label="${3:-Progress}"
    
    local percent=$(( current * 100 / total ))
    local filled=$(( percent / 5 ))
    local empty=$(( 20 - filled ))
    
    local bar="${COLOR_GREEN}"
    bar+=$(printf '█%.0s' $(seq 1 $filled 2>/dev/null) || true)
    bar+="${COLOR_GRAY}"
    bar+=$(printf '░%.0s' $(seq 1 $empty 2>/dev/null) || true)
    bar+="${COLOR_RESET}"
    
    printf "\r${label}: [${bar}] ${percent}%% (${current}/${total})  "
}

log_progress_done() {
    echo ""  # Move to new line after progress bar
}

#------------------------------------------------------------------------------
# Summary Table
#------------------------------------------------------------------------------

log_summary() {
    local passed="$1"
    local failed="$2"
    local skipped="${3:-0}"
    local total=$((passed + failed + skipped))
    
    echo ""
    echo -e "${COLOR_BOLD}Test Summary${COLOR_RESET}"
    echo "────────────────────────────"
    echo -e "  ${COLOR_GREEN}Passed${COLOR_RESET}:  ${passed}"
    echo -e "  ${COLOR_RED}Failed${COLOR_RESET}:  ${failed}"
    [[ $skipped -gt 0 ]] && echo -e "  ${COLOR_YELLOW}Skipped${COLOR_RESET}: ${skipped}"
    echo "────────────────────────────"
    echo -e "  ${COLOR_BOLD}Total${COLOR_RESET}:   ${total}"
    
    if [[ $failed -eq 0 ]]; then
        echo ""
        echo -e "  ${COLOR_GREEN}${COLOR_BOLD}All tests passed! ✓${COLOR_RESET}"
    else
        echo ""
        echo -e "  ${COLOR_RED}${COLOR_BOLD}${failed} test(s) failed ✗${COLOR_RESET}"
    fi
    echo ""
}
