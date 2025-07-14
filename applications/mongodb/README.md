# MongoDB Replica Set on MicroK8s

## Overview
This deployment sets up a secure MongoDB replica set with proper authentication and network access on MicroK8s.

## Components

### Security Features
- **Secure passwords**: Generated using OpenSSL with base64 encoding
- **Replica set keyfile**: Internal authentication between replica set members
- **Root user**: Administrative access with generated password
- **Application user**: Database-specific access for applications

### Deployed Resources
- **Namespace**: `mongodb`
- **Secret**: `mongodb-secrets` (contains all credentials and keyfile)
- **StatefulSet**: `mongodb` (single-node replica set)
- **PVC**: `mongodb-data-pvc` (50Gi persistent storage)
- **Services**: 
  - `mongodb` (headless service for StatefulSet)
  - `mongodb-client` (ClusterIP for internal applications)
  - `mongodb-external` (NodePort for external access)

## Access Points

### Internal (Within Cluster)
- **Headless Service**: `mongodb.mongodb.svc.cluster.local:27017`
- **Client Service**: `mongodb-client.mongodb.svc.cluster.local:27017`

### External (Network Access)
- **NodePort Service**: `192.168.0.118:30017`

## Connection Information

### Credentials
```bash
# Admin user (for MongoDB Compass and administration)
Username: admin
Password: admin123

# Root user (administrative access)
Username: root
Password: SAwhOP7UwPgve5nCrfeoufLCEqDWfo8F/Ff9BBBRcQE=

# Application user (database access)
Username: narrative_user
Password: 0qJXBckS6huZWJtTgBEEHd0dc/uE9RBkbH7sRx11vpg=
Database: narrative_world_system

# Compass user (simplified access for GUI tools)
Username: compass_user
Password: compass123
Database: narrative_world_system
```

### Connection Strings

**Internal (from within cluster):**
```
mongodb://narrative_user:0qJXBckS6huZWJtTgBEEHd0dc/uE9RBkbH7sRx11vpg=@mongodb-client.mongodb.svc.cluster.local:27017/narrative_world_system?authSource=admin&replicaSet=rs0
```

**External (from outside cluster):**
```
mongodb://narrative_user:0qJXBckS6huZWJtTgBEEHd0dc%2FuE9RBkbH7sRx11vpg%3D@192.168.0.118:30017/narrative_world_system?authSource=admin&replicaSet=rs0
```

**For MongoDB Compass (recommended):**
```
mongodb://admin:admin123@192.168.0.118:30017/?authSource=admin&directConnection=true
```

**Alternative (with separate auth parameters):**
```bash
mongosh --host 192.168.0.118:30017 --username admin --password admin123 --authenticationDatabase admin
```

## Deployment

### Apply Configuration
```bash
kubectl apply -f mongodb-replica-set.yaml
```

### Manual Replica Set Initialization (if needed)
```bash
kubectl exec -n mongodb mongodb-0 -- mongosh --quiet --eval "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongodb-0.mongodb.mongodb.svc.cluster.local:27017'}]})"
```

### Create Users
```bash
# Create admin user (for Compass and administration)
kubectl exec -n mongodb mongodb-0 -- mongosh admin --quiet --eval "
db.createUser({
  user: 'admin',
  pwd: 'admin123',
  roles: [{role: 'root', db: 'admin'}]
});
"

# Create compass user (for GUI tools)
kubectl exec -n mongodb mongodb-0 -- mongosh admin --username admin --password admin123 --quiet --eval "
db.createUser({
  user: 'compass_user',
  pwd: 'compass123',
  roles: [
    {role: 'readWrite', db: 'narrative_world_system'},
    {role: 'dbAdmin', db: 'narrative_world_system'},
    {role: 'read', db: 'admin'}
  ]
});
"

# Create application user
kubectl exec -n mongodb mongodb-0 -- mongosh admin --username admin --password admin123 --quiet --eval "
db.createUser({
  user: 'narrative_user',
  pwd: '0qJXBckS6huZWJtTgBEEHd0dc/uE9RBkbH7sRx11vpg=',
  roles: [
    {role: 'readWrite', db: 'narrative_world_system'},
    {role: 'dbAdmin', db: 'narrative_world_system'}
  ]
});
"
```

## Verification

### Check Pod Status
```bash
kubectl get pods -n mongodb
```

### Check Services
```bash
kubectl get svc -n mongodb
```

### Test Replica Set Status
```bash
kubectl exec -n mongodb mongodb-0 -- mongosh --quiet --eval "rs.status()"
```

### Test Database Connection
```bash
# From within cluster
kubectl run -n mongodb test-client --rm -it --image=mongo:7.0 -- \
  mongosh "mongodb://narrative_user:0qJXBckS6huZWJtTgBEEHd0dc/uE9RBkbH7sRx11vpg=@mongodb-client:27017/narrative_world_system?authSource=admin&replicaSet=rs0"

# Test external access (from host)
mongosh "mongodb://narrative_user:0qJXBckS6huZWJtTgBEEHd0dc/uE9RBkbH7sRx11vpg=@192.168.0.118:30017/narrative_world_system?authSource=admin&replicaSet=rs0"
```

## Configuration Details

### Storage
- **Size**: 50Gi
- **Storage Class**: microk8s-hostpath
- **Mount Path**: /data/db

### Resources
- **Requests**: 1Gi memory, 500m CPU
- **Limits**: 2Gi memory, 1000m CPU
- **WiredTiger Cache**: 2GB

### Replica Set
- **Name**: rs0
- **Members**: 1 (single-node for development)
- **Internal Authentication**: Enabled with keyfile

## Troubleshooting

### Common Issues

1. **Pod not ready**: Check if replica set is initialized
   ```bash
   kubectl logs -n mongodb mongodb-0
   kubectl exec -n mongodb mongodb-0 -- mongosh --eval "rs.status()"
   ```

2. **Authentication failed**: Ensure users are created properly
   ```bash
   kubectl exec -n mongodb mongodb-0 -- mongosh --eval "use admin; db.getUsers()"
   ```

3. **External access not working**: Verify NodePort service
   ```bash
   kubectl get svc -n mongodb mongodb-external
   ```

### View Logs
```bash
kubectl logs -n mongodb mongodb-0 --follow
```

## Cleanup

To remove the entire MongoDB deployment:
```bash
kubectl delete -f mongodb-replica-set.yaml
```

To completely remove including persistent data:
```bash
kubectl delete namespace mongodb
```

## Notes

- The deployment uses a single-node replica set suitable for development
- For production, consider scaling to 3 nodes for high availability
- Passwords are generated securely and stored in Kubernetes secrets
- The replica set supports MongoDB transactions
- External access is available via NodePort on port 30017