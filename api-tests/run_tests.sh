#!/usr/bin/env bash
#==============================================================================
# API Testing Framework - Main Orchestrator
#
# Production-grade testing script for REST API and WebSocket endpoints
#
# Usage:
#   ./run_tests.sh --base-url https://ema2a.ddns.net [OPTIONS]
#
# Options:
#   --base-url URL    API base URL (required)
#   --dry-run         Print test plan without executing
#   --rest-only       Run only REST API tests
#   --ws-only         Run only WebSocket tests
#   --verbose         Enable detailed output
#   --skip-auth       Skip authentication (use existing token)
#   --help            Show this help message
#
# Examples:
#   ./run_tests.sh --base-url https://ema2a.ddns.net
#   ./run_tests.sh --base-url https://ema2a.ddns.net --rest-only --verbose
#==============================================================================

set -o pipefail

# Script directory - use unique name to avoid conflicts with sourced scripts
RUN_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies using absolute paths
source "${RUN_TESTS_DIR}/config/env.sh"
source "${RUN_TESTS_DIR}/config/auth.sh"
source "${RUN_TESTS_DIR}/config/urls.sh"
source "${RUN_TESTS_DIR}/utils/logger.sh"
source "${RUN_TESTS_DIR}/utils/report.sh"

#------------------------------------------------------------------------------
# Command Line Options
#------------------------------------------------------------------------------
BASE_URL=""
DRY_RUN=false
REST_ONLY=false
WS_ONLY=false
VERBOSE=false
SKIP_AUTH=false

#------------------------------------------------------------------------------
# show_help
# Displays usage information
#------------------------------------------------------------------------------
show_help() {
    cat << EOF
API Testing Framework - Production-grade API testing for REST and WebSocket endpoints

USAGE:
    ./run_tests.sh --base-url <URL> [OPTIONS]

OPTIONS:
    --base-url URL    API base URL (required)
                      Example: https://ema2a.ddns.net

    --dry-run         Print test plan without executing requests
                      Useful for verifying configuration

    --rest-only       Run only REST API tests
                      Skips WebSocket/SignalR tests

    --ws-only         Run only WebSocket/SignalR tests
                      Skips REST API tests

    --verbose         Enable detailed output
                      Shows request/response details

    --skip-auth       Skip authentication tests
                      Uses ACCESS_TOKEN from environment if set

    --help            Show this help message

EXAMPLES:
    # Full test suite
    ./run_tests.sh --base-url https://ema2a.ddns.net

    # REST tests only with verbose output
    ./run_tests.sh --base-url https://ema2a.ddns.net --rest-only --verbose

    # Dry run to preview tests
    ./run_tests.sh --base-url https://ema2a.ddns.net --dry-run

ENVIRONMENT VARIABLES:
    TEST_USERNAME     Test user email/username
    TEST_PASSWORD     Test user password
    REQUEST_TIMEOUT   HTTP timeout in seconds (default: 30)
    LOG_LEVEL         Logging level: DEBUG|INFO|WARN|ERROR

REPORTS:
    Test reports are saved to: api-tests/reports/
    Latest report: api-tests/reports/report_latest.json

EOF
}

#------------------------------------------------------------------------------
# parse_args
# Parses command line arguments
#------------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --base-url)
                BASE_URL="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --rest-only)
                REST_ONLY=true
                shift
                ;;
            --ws-only)
                WS_ONLY=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                export LOG_LEVEL="DEBUG"
                shift
                ;;
            --skip-auth)
                SKIP_AUTH=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Validate required args
    if [[ -z "$BASE_URL" ]]; then
        log_error "Base URL is required. Use --base-url <URL>"
        echo "Use --help for usage information"
        exit 1
    fi
    
    # Remove trailing slash from base URL
    BASE_URL="${BASE_URL%/}"
}

#------------------------------------------------------------------------------
# check_dependencies
# Verifies required tools are installed
#------------------------------------------------------------------------------
check_dependencies() {
    local missing=()
    
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if [[ "$WS_ONLY" == "true" ]] || [[ "$REST_ONLY" != "true" ]]; then
        if ! command -v websocat &> /dev/null; then
            missing+=("websocat")
        fi
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_info "Please install the missing tools before running tests."
        log_info "See docs/README.md for installation instructions."
        return 1
    fi
    
    log_debug "All dependencies verified"
    return 0
}

#------------------------------------------------------------------------------
# print_banner
# Displays the test framework banner
#------------------------------------------------------------------------------
print_banner() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_BLUE}╔══════════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}║${COLOR_RESET}           ${COLOR_BOLD}API Testing Framework${COLOR_RESET}                        ${COLOR_BOLD}${COLOR_BLUE}║${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}║${COLOR_RESET}      Production-Grade REST & WebSocket Testing           ${COLOR_BOLD}${COLOR_BLUE}║${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}╚══════════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""
}

#------------------------------------------------------------------------------
# print_config
# Displays current configuration
#------------------------------------------------------------------------------
print_config() {
    log_subsection "Configuration"
    
    echo "  Base URL:      ${BASE_URL}"
    echo "  WebSocket:     $(get_ws_url "$BASE_URL")"
    echo "  Test User:     ${TEST_USERNAME:-<not set>}"
    echo "  Timeout:       ${REQUEST_TIMEOUT}s"
    echo "  Dry Run:       ${DRY_RUN}"
    echo "  REST Only:     ${REST_ONLY}"
    echo "  WS Only:       ${WS_ONLY}"
    echo "  Verbose:       ${VERBOSE}"
    echo ""
}

#------------------------------------------------------------------------------
# main
# Main execution flow
#------------------------------------------------------------------------------
main() {
    parse_args "$@"
    
    print_banner
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    print_config
    
    # Initialize report
    init_report "$BASE_URL"
    
    local rest_result=0
    local ws_result=0
    
    # Authenticate if not skipping
    if [[ "$SKIP_AUTH" != "true" ]] && [[ "$WS_ONLY" != "true" ]]; then
        log_subsection "Authentication"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would authenticate (login or auto-register)"
        else
            # Use ensure_authenticated which auto-registers if login fails
            if ensure_authenticated "$BASE_URL"; then
                log_success "Authentication ready (user: ${TEST_USERNAME})"
            else
                log_error "Authentication failed - some tests may be skipped"
            fi
        fi
        echo ""
    fi
    
    # Run REST tests
    if [[ "$WS_ONLY" != "true" ]]; then
        source "${RUN_TESTS_DIR}/rest/rest_runner.sh"
        run_rest_tests "$BASE_URL" "$DRY_RUN" "$VERBOSE" || rest_result=1
    fi
    
    # Run WebSocket tests
    if [[ "$REST_ONLY" != "true" ]]; then
        source "${RUN_TESTS_DIR}/websocket/ws_runner.sh"
        run_ws_tests "$BASE_URL" "$DRY_RUN" "$VERBOSE" || ws_result=1
    fi
    
    # Generate report
    local report_file
    if [[ "$DRY_RUN" != "true" ]]; then
        log_section "Report Generation"
        report_file=$(generate_report)
        print_report_summary
        
        log_info "Full report saved to: ${report_file}"
    else
        log_section "Dry Run Complete"
        log_info "No tests were executed. Remove --dry-run to run tests."
    fi
    
    # Exit with appropriate code
    if [[ $rest_result -ne 0 ]] || [[ $ws_result -ne 0 ]]; then
        exit 1
    fi
    
    exit 0
}

# Execute main
main "$@"
