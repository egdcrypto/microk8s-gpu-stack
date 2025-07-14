#!/bin/bash

# Woodpecker API helper script
WOODPECKER_SERVER="http://woodpecker-server.woodpecker.svc.cluster.local"

# Function to get pipeline status
get_pipelines() {
    local repo="${1:-egdcrypto/mmorpg-narrative-engine}"
    echo "Fetching pipelines for $repo..."
    
    # Port forward to access Woodpecker API
    kubectl port-forward -n woodpecker svc/woodpecker-server 8000:80 &
    PF_PID=$!
    sleep 2
    
    # Get pipelines (Woodpecker API doesn't require auth for public repos)
    curl -s "http://localhost:8000/api/repos/${repo}/builds" | jq '.[0:5] | .[] | {id: .id, status: .status, branch: .branch, message: .message, started: .started, finished: .finished}'
    
    # Clean up port forward
    kill $PF_PID 2>/dev/null
}

# Function to get specific pipeline logs
get_pipeline_logs() {
    local repo="${1:-egdcrypto/mmorpg-narrative-engine}"
    local build_id="${2:-latest}"
    
    # Port forward to access Woodpecker API
    kubectl port-forward -n woodpecker svc/woodpecker-server 8000:80 &
    PF_PID=$!
    sleep 2
    
    if [ "$build_id" = "latest" ]; then
        # Get latest build ID
        build_id=$(curl -s "http://localhost:8000/api/repos/${repo}/builds" | jq '.[0].id')
    fi
    
    echo "Fetching logs for build #$build_id..."
    
    # Get pipeline steps
    curl -s "http://localhost:8000/api/repos/${repo}/builds/${build_id}" | jq '.procs[].children[] | {name: .name, state: .state, exit_code: .exit_code}'
    
    # Clean up port forward
    kill $PF_PID 2>/dev/null
}

# Main script
case "${1:-status}" in
    "status")
        get_pipelines "${2:-egdcrypto/mmorpg-narrative-engine}"
        ;;
    "logs")
        get_pipeline_logs "${2:-egdcrypto/mmorpg-narrative-engine}" "${3:-latest}"
        ;;
    *)
        echo "Usage: $0 [status|logs] [repo] [build_id]"
        echo "Example: $0 status"
        echo "Example: $0 logs egdcrypto/mmorpg-narrative-engine 2"
        ;;
esac