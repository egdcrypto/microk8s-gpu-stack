#!/bin/bash

# Query Woodpecker database
query="${1:-.tables}"

# Create a temporary pod with sqlite3
kubectl run -n woodpecker sqlite-helper --rm -i --restart=Never --image=keinos/sqlite3:latest \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "sqlite",
        "image": "keinos/sqlite3:latest",
        "command": ["sleep", "3600"],
        "volumeMounts": [{
          "name": "woodpecker-data",
          "mountPath": "/data"
        }]
      }],
      "volumes": [{
        "name": "woodpecker-data",
        "persistentVolumeClaim": {
          "claimName": "woodpecker-server-data"
        }
      }]
    }
  }' &

# Wait for pod to be ready
echo "Starting SQLite helper pod..."
sleep 5

# Execute query
echo "Running query: $query"
kubectl exec -n woodpecker sqlite-helper -- sqlite3 /data/woodpecker.db "$query"

# Clean up
kubectl delete pod -n woodpecker sqlite-helper --force --grace-period=0 2>/dev/null