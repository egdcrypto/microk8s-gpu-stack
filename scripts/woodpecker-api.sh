#!/bin/bash

# Woodpecker API client
NAMESPACE="woodpecker"
SERVICE="woodpecker-server"
PORT="80"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to make API calls through kubectl proxy
api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="$3"
    
    # Start kubectl proxy in background
    kubectl proxy --port=8001 &>/dev/null &
    PROXY_PID=$!
    sleep 1
    
    # Make API call through proxy
    if [ "$method" = "GET" ]; then
        result=$(curl -s "http://localhost:8001/api/v1/namespaces/${NAMESPACE}/services/${SERVICE}:${PORT}/proxy${endpoint}")
    else
        result=$(curl -s -X "$method" -H "Content-Type: application/json" \
            -d "$data" \
            "http://localhost:8001/api/v1/namespaces/${NAMESPACE}/services/${SERVICE}:${PORT}/proxy${endpoint}")
    fi
    
    # Kill proxy
    kill $PROXY_PID 2>/dev/null
    
    echo "$result"
}

# Get all repos
list_repos() {
    echo "=== Repositories ==="
    api_call "/api/user/repos" | jq -r '.[] | "\(.full_name) - Active: \(.active)"'
}

# Get builds for a repo
list_builds() {
    local repo="${1:-egdcrypto/mmorpg-narrative-engine}"
    echo "=== Recent builds for $repo ==="
    api_call "/api/repos/$repo/builds" | jq -r '.[:5] | .[] | "Build #\(.number) - \(.status) - \(.branch) - \(.message // "No message")"'
}

# Get detailed build info
build_details() {
    local repo="${1:-egdcrypto/mmorpg-narrative-engine}"
    local build="${2:-last}"
    
    if [ "$build" = "last" ]; then
        build=$(api_call "/api/repos/$repo/builds" | jq -r '.[0].number')
    fi
    
    echo "=== Build #$build details ==="
    api_call "/api/repos/$repo/builds/$build" | jq '{
        number: .number,
        status: .status,
        error: .error,
        branch: .branch,
        commit: .commit[:8],
        message: .message,
        started: .started_at | strftime("%Y-%m-%d %H:%M:%S"),
        finished: .finished_at | strftime("%Y-%m-%d %H:%M:%S"),
        duration: (.finished_at - .started_at),
        steps: .procs[].children[] | {name: .name, state: .state, exit_code: .exit_code, error: .error}
    }'
}

# Get logs for a specific step
step_logs() {
    local repo="${1:-egdcrypto/mmorpg-narrative-engine}"
    local build="${2:-last}"
    local step="${3:-1}"
    
    if [ "$build" = "last" ]; then
        build=$(api_call "/api/repos/$repo/builds" | jq -r '.[0].number')
    fi
    
    # Get step ID
    local step_id=$(api_call "/api/repos/$repo/builds/$build" | jq -r ".procs[].children[$step].pid")
    
    echo "=== Logs for step $step in build #$build ==="
    api_call "/api/repos/$repo/logs/$build/$step_id"
}

# Main menu
case "${1:-help}" in
    "repos")
        list_repos
        ;;
    "builds")
        list_builds "$2"
        ;;
    "build")
        build_details "$2" "$3"
        ;;
    "logs")
        step_logs "$2" "$3" "$4"
        ;;
    "status")
        # Quick status check
        repo="${2:-egdcrypto/mmorpg-narrative-engine}"
        latest=$(api_call "/api/repos/$repo/builds" | jq -r '.[0] | {number: .number, status: .status, branch: .branch}')
        echo "Latest build: $latest"
        ;;
    *)
        echo "Woodpecker API Client"
        echo ""
        echo "Usage:"
        echo "  $0 repos                                    - List all repositories"
        echo "  $0 builds [repo]                           - List recent builds"
        echo "  $0 build [repo] [build_num|last]           - Show build details"
        echo "  $0 logs [repo] [build_num|last] [step_idx] - Show step logs"
        echo "  $0 status [repo]                           - Quick status check"
        echo ""
        echo "Examples:"
        echo "  $0 builds"
        echo "  $0 build egdcrypto/mmorpg-narrative-engine last"
        echo "  $0 logs egdcrypto/mmorpg-narrative-engine last 0"
        ;;
esac