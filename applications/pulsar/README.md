# Apache Pulsar on MicroK8s

## Overview
This deployment sets up a production-ready Apache Pulsar standalone instance with management UI and proper security on MicroK8s.

## Components

### Deployed Resources
- **Namespace**: `pulsar`
- **StatefulSet**: `pulsar` (standalone mode with embedded ZooKeeper and BookKeeper)
- **Pulsar Manager**: Web UI for administration
- **PVC**: `pulsar-data-pvc` (50Gi persistent storage)
- **Services**: Internal and external access points

### Key Features
- **Standalone Mode**: All components (ZooKeeper, BookKeeper, Broker) in single pod
- **Persistent Storage**: 50Gi for production workloads
- **Health Checks**: Comprehensive liveness and readiness probes
- **Auto-initialization**: Topics and subscriptions created automatically
- **Management UI**: Pulsar Manager for administration
- **External Access**: NodePort services for external connectivity

## Access Points

### Internal (Within Cluster)
- **Pulsar Service URL**: `pulsar://pulsar-broker.pulsar.svc.cluster.local:6650`
- **Admin URL**: `http://pulsar-broker.pulsar.svc.cluster.local:8080`
- **ZooKeeper**: `pulsar.pulsar.svc.cluster.local:2181`

### External (Network Access)
- **Pulsar Broker**: `pulsar://192.168.0.118:30650`
- **Admin API**: `http://192.168.0.118:30080`
- **Pulsar Manager UI**: `http://192.168.0.118:30527/pulsar-manager`

## Connection Information

### Client Configuration
```bash
# Pulsar Service URL (for producers/consumers)
PULSAR_SERVICE_URL=pulsar://pulsar-broker.pulsar.svc.cluster.local:6650

# Admin URL (for topic management)
PULSAR_ADMIN_URL=http://pulsar-broker.pulsar.svc.cluster.local:8080

# External access
PULSAR_EXTERNAL_URL=pulsar://192.168.0.118:30650
```

### Pre-created Topics
- `persistent://public/default/narrative-events`
- `persistent://public/default/narrative-events-narrativedocument`
- `persistent://public/default/narrative-events-narrativeworld`
- `persistent://public/default/narrative-events-narrativecharacter`

### Pre-created Subscriptions
- `document-processor-worker` (on narrative-events-narrativedocument)
- `entity-extraction-worker` (on narrative-events)

## Deployment

### Apply Configuration
```bash
kubectl apply -f pulsar-standalone.yaml
```

### Verify Deployment
```bash
# Check pod status
kubectl get pods -n pulsar

# Check services
kubectl get svc -n pulsar

# Check Pulsar broker health
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin brokers healthcheck

# List topics
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin topics list public/default
```

## Configuration Details

### Storage
- **Size**: 50Gi
- **Storage Class**: microk8s-hostpath
- **Mount Path**: /pulsar/data
- **Includes**: Metadata, BookKeeper ledgers, ZooKeeper data

### Resources
- **Requests**: 3Gi memory, 1000m CPU
- **Limits**: 4Gi memory, 2000m CPU
- **JVM Settings**: -Xms2g -Xmx2g -XX:MaxDirectMemorySize=2g

### Security
- **User Context**: Non-root (UID: 10000, GID: 10000)
- **JWT Secret**: Configured for future authentication
- **Network**: Cluster-internal by default

## Usage Examples

### Producer Example (Java)
```java
PulsarClient client = PulsarClient.builder()
    .serviceUrl("pulsar://pulsar-broker.pulsar.svc.cluster.local:6650")
    .build();

Producer<String> producer = client.newProducer(Schema.STRING)
    .topic("persistent://public/default/narrative-events")
    .create();

producer.send("Hello Pulsar!");
```

### Consumer Example (Java)
```java
Consumer<String> consumer = client.newConsumer(Schema.STRING)
    .topic("persistent://public/default/narrative-events")
    .subscriptionName("my-subscription")
    .subscribe();

Message<String> message = consumer.receive();
System.out.println("Received: " + message.getValue());
consumer.acknowledge(message);
```

### Command Line Tools
```bash
# Produce messages
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-client produce \
  persistent://public/default/narrative-events \
  --messages "Hello from command line"

# Consume messages
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-client consume \
  persistent://public/default/narrative-events \
  --subscription-name cli-consumer \
  --num-messages 10
```

## Administration

### Pulsar Manager UI
1. **Access**: http://192.168.0.118:30527/pulsar-manager
2. **Setup**: First-time setup required
3. **Add Environment**: 
   - Environment Name: `microk8s-pulsar`
   - Service URL: `http://pulsar-broker.pulsar.svc.cluster.local:8080`

### Topic Management
```bash
# Create topic
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin topics create persistent://public/default/my-topic

# List topics
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin topics list public/default

# Create subscription
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin topics create-subscription \
  --subscription my-subscription \
  persistent://public/default/my-topic

# Topic stats
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin topics stats persistent://public/default/my-topic
```

### Monitoring
```bash
# Broker stats
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin brokers list

# Namespace stats
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin namespaces list public

# Check subscription backlog
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin topics stats-internal persistent://public/default/narrative-events
```

## Troubleshooting

### Common Issues

1. **Pod not ready**: Check if ZooKeeper and BookKeeper are initialized
   ```bash
   kubectl logs -n pulsar pulsar-0
   kubectl describe pod -n pulsar pulsar-0
   ```

2. **Connection refused**: Verify services and pod status
   ```bash
   kubectl get svc -n pulsar
   kubectl get pods -n pulsar
   ```

3. **Topics not created**: Check initialization logs
   ```bash
   kubectl logs -n pulsar pulsar-0 -c pulsar | grep "init-topics"
   ```

4. **Manager UI not accessible**: Check manager pod status
   ```bash
   kubectl logs -n pulsar deployment/pulsar-manager
   ```

### Health Checks
```bash
# Broker health
curl -f http://192.168.0.118:30080/admin/v2/brokers/health

# Ready status
curl -f http://192.168.0.118:30080/admin/v2/brokers/ready

# Internal health check
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin brokers healthcheck
```

### Performance Monitoring
```bash
# JVM stats
kubectl exec -n pulsar pulsar-0 -- /pulsar/bin/pulsar-admin brokers monitoring-metrics

# Resource usage
kubectl top pod -n pulsar
kubectl top node
```

## Backup and Maintenance

### Backup Strategy
```bash
# Backup BookKeeper ledgers (requires stopping Pulsar)
kubectl scale statefulset pulsar --replicas=0 -n pulsar
# Copy /pulsar/data from persistent volume
kubectl scale statefulset pulsar --replicas=1 -n pulsar
```

### Updates
```bash
# Update to newer Pulsar version
kubectl set image statefulset/pulsar pulsar=apachepulsar/pulsar:3.2.0 -n pulsar

# Rolling restart
kubectl rollout restart statefulset/pulsar -n pulsar
```

## Cleanup

To remove the entire Pulsar deployment:
```bash
kubectl delete -f pulsar-standalone.yaml
```

To completely remove including persistent data:
```bash
kubectl delete namespace pulsar
```

## Notes

- Standalone mode is suitable for development and small production workloads
- For high availability, consider deploying separate ZooKeeper, BookKeeper, and Pulsar clusters
- The deployment includes automatic topic initialization
- JWT authentication is configured but disabled by default
- External access is available via NodePort on ports 30650 (broker) and 30080 (admin)
- Pulsar Manager UI is available on port 30527