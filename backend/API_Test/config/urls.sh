#!/usr/bin/env bash
#==============================================================================
# URL Helper Functions for API Testing Framework
#
# Provides functions for URL construction and manipulation
#==============================================================================

# Source guard - prevent multiple sourcing
[[ -n "${_URLS_SH_LOADED:-}" ]] && return 0
_URLS_SH_LOADED=1

#------------------------------------------------------------------------------
# build_url
# Constructs a full URL from base URL and path
#
# Arguments:
#   $1 - Base URL (required)
#   $2 - Path (required)
#   $3 - Query string (optional)
#
# Returns:
#   Full URL string
#
# Example:
#   build_url "https://api.example.com" "/api/users" "page=1&limit=10"
#   # Output: https://api.example.com/api/users?page=1&limit=10
#------------------------------------------------------------------------------
build_url() {
    local base_url="${1:?Base URL is required}"
    local path="${2:?Path is required}"
    local query="${3:-}"
    
    # Remove trailing slash from base URL
    base_url="${base_url%/}"
    
    # Ensure path starts with /
    [[ "$path" != /* ]] && path="/${path}"
    
    local url="${base_url}${path}"
    
    # Add query string if provided
    if [[ -n "$query" ]]; then
        url="${url}?${query}"
    fi
    
    echo "$url"
}

#------------------------------------------------------------------------------
# get_ws_url
# Converts HTTP(S) base URL to WebSocket URL
#
# Arguments:
#   $1 - Base URL (required)
#   $2 - WebSocket path (optional, defaults to SIGNALR_HUB_PATH)
#
# Returns:
#   WebSocket URL (wss:// or ws://)
#
# Example:
#   get_ws_url "https://api.example.com"
#   # Output: wss://api.example.com/signHub
#------------------------------------------------------------------------------
get_ws_url() {
    local base_url="${1:?Base URL is required}"
    local ws_path="${2:-${SIGNALR_HUB_PATH:-/signHub}}"
    
    # Remove trailing slash
    base_url="${base_url%/}"
    
    # Convert http(s) to ws(s)
    local ws_url
    if [[ "$base_url" == https://* ]]; then
        ws_url="wss://${base_url#https://}"
    elif [[ "$base_url" == http://* ]]; then
        ws_url="ws://${base_url#http://}"
    else
        # Assume https if no protocol
        ws_url="wss://${base_url}"
    fi
    
    # Append path
    [[ "$ws_path" != /* ]] && ws_path="/${ws_path}"
    ws_url="${ws_url}${ws_path}"
    
    echo "$ws_url"
}

#------------------------------------------------------------------------------
# url_encode
# URL-encodes a string
#
# Arguments:
#   $1 - String to encode
#
# Returns:
#   URL-encoded string
#------------------------------------------------------------------------------
url_encode() {
    local string="${1:-}"
    local encoded=""
    local length=${#string}
    local i=0
    
    # Use printf with %s to safely handle the string, then process byte-by-byte
    # This handles multi-byte UTF-8 characters (like Arabic) correctly
    while IFS= read -r -n1 -d '' char || [[ -n "$char" ]]; do
        case "$char" in
            [a-zA-Z0-9.~_-])
                encoded+="$char"
                ;;
            *)
                # For multi-byte chars, encode each byte separately
                while IFS= read -r -n2 hex; do
                    [[ -n "$hex" ]] && encoded+="%${hex}"
                done < <(printf '%s' "$char" | xxd -p -u | fold -w2)
                ;;
        esac
    done < <(printf '%s' "$string")
    
    echo "$encoded"
}

#------------------------------------------------------------------------------
# build_query_string
# Builds a query string from key-value pairs
#
# Arguments:
#   Pairs of key value (e.g., "key1" "value1" "key2" "value2")
#
# Returns:
#   Query string without leading ?
#
# Example:
#   build_query_string "page" "1" "limit" "10"
#   # Output: page=1&limit=10
#------------------------------------------------------------------------------
build_query_string() {
    local query=""
    while [[ $# -gt 1 ]]; do
        local key="$1"
        local value="$2"
        shift 2
        
        [[ -n "$query" ]] && query+="&"
        query+="$(url_encode "$key")=$(url_encode "$value")"
    done
    
    echo "$query"
}

#------------------------------------------------------------------------------
# extract_host
# Extracts the host from a URL
#
# Arguments:
#   $1 - URL
#
# Returns:
#   Host portion of URL
#------------------------------------------------------------------------------
extract_host() {
    local url="${1:?URL is required}"
    
    # Remove protocol
    local host="${url#*://}"
    
    # Remove path
    host="${host%%/*}"
    
    # Remove port
    host="${host%%:*}"
    
    echo "$host"
}

#------------------------------------------------------------------------------
# extract_port
# Extracts the port from a URL (or default for protocol)
#
# Arguments:
#   $1 - URL
#
# Returns:
#   Port number
#------------------------------------------------------------------------------
extract_port() {
    local url="${1:?URL is required}"
    
    # Check for explicit port
    if [[ "$url" =~ ://[^/]+:([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return
    fi
    
    # Default ports
    if [[ "$url" == https://* ]] || [[ "$url" == wss://* ]]; then
        echo "443"
    else
        echo "80"
    fi
}
