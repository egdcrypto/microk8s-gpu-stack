# GPU Setup Guide for MicroK8s

## Overview

This guide covers setting up and using NVIDIA GPUs with MicroK8s for machine learning and compute-intensive workloads.

## Prerequisites

- NVIDIA GPU (RTX 4060 Ti or similar)
- NVIDIA drivers installed (version 570+)
- NVIDIA Container Toolkit
- MicroK8s with GPU addon enabled

## GPU Addon Installation

```bash
# Enable GPU support in MicroK8s
sudo microk8s enable gpu

# Verify GPU is detected
sudo microk8s kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPUs:.status.capacity.'nvidia\.com/gpu'
```

## GPU Resource Management

### Resource Requests and Limits

GPUs in Kubernetes are managed as extended resources. You can request GPUs in your pod specifications:

```yaml
resources:
  limits:
    nvidia.com/gpu: 1  # Request 1 GPU
  requests:
    nvidia.com/gpu: 1
```

### GPU Sharing

Currently, NVIDIA GPUs cannot be shared between pods. Each pod requesting a GPU gets exclusive access to it.

## Example GPU Workloads

### 1. Jupyter Notebook with TensorFlow

Deploy a GPU-enabled Jupyter notebook:

```bash
sudo microk8s kubectl apply -f /home/repos/k8s-setup/applications/gpu-jupyter-notebook.yaml
```

Access the notebook:
1. Get the service endpoint
2. Use the token specified in the deployment (default: "changeme")

### 2. LLM Inference Server

Deploy a vLLM server for large language model inference:

```bash
# Create namespace if not exists
sudo microk8s kubectl create namespace gpu-workloads

# Deploy LLM server
sudo microk8s kubectl apply -f /home/repos/k8s-setup/applications/gpu-llm-inference.yaml
```

### 3. Custom GPU Application

Example Dockerfile for GPU applications:

```dockerfile
FROM nvidia/cuda:12.3-base-ubuntu22.04

# Install your dependencies
RUN apt-get update && apt-get install -y python3 python3-pip

# Install ML frameworks
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Copy your application
COPY . /app
WORKDIR /app

CMD ["python3", "your-gpu-app.py"]
```

## Monitoring GPU Usage

### Using nvidia-smi

```bash
# Real-time GPU monitoring
watch -n 1 nvidia-smi

# Check GPU processes
nvidia-smi pmon
```

### Kubernetes GPU Metrics

```bash
# Get GPU metrics from DCGM exporter
sudo microk8s kubectl port-forward -n gpu-operator-resources svc/nvidia-dcgm-exporter 9400:9400

# Access metrics at http://localhost:9400/metrics
```

### Grafana Dashboard

Import the NVIDIA GPU dashboard (ID: 12239) in Grafana for comprehensive GPU monitoring.

## Best Practices

### 1. GPU Scheduling

- Use node selectors to ensure GPU workloads run on GPU nodes
- Set appropriate resource requests and limits
- Use pod anti-affinity for distributed training

### 2. Image Optimization

- Use NVIDIA's optimized base images
- Multi-stage builds to reduce image size
- Cache model weights in persistent volumes

### 3. Memory Management

```yaml
# Example with shared memory for PyTorch DataLoader
volumes:
- name: dshm
  emptyDir:
    medium: Memory
    sizeLimit: 8Gi
volumeMounts:
- name: dshm
  mountPath: /dev/shm
```

### 4. GPU Health Checks

Add health checks to ensure GPU is accessible:

```yaml
livenessProbe:
  exec:
    command:
    - nvidia-smi
  initialDelaySeconds: 30
  periodSeconds: 60
```

## Troubleshooting

### GPU Not Available in Pod

```bash
# Check GPU operator status
sudo microk8s kubectl get pods -n gpu-operator-resources

# Check device plugin logs
sudo microk8s kubectl logs -n gpu-operator-resources -l app=nvidia-device-plugin-daemonset
```

### CUDA Version Mismatch

Ensure your application's CUDA version matches the driver:

```bash
nvidia-smi  # Check CUDA Version in output
```

### Out of Memory Errors

1. Reduce batch size in your application
2. Enable GPU memory growth (TensorFlow)
3. Use gradient accumulation for large models

## Performance Optimization

### 1. Use Mixed Precision Training

```python
# PyTorch example
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()
with autocast():
    output = model(input)
    loss = loss_fn(output, target)
```

### 2. Enable TensorRT Optimization

For inference workloads, use TensorRT for better performance:

```python
import torch_tensorrt

trt_model = torch_tensorrt.compile(
    model,
    inputs=[torch_tensorrt.Input(shape=[1, 3, 224, 224])],
    enabled_precisions={torch.float, torch.half}
)
```

### 3. Profile GPU Usage

```bash
# NVIDIA Nsight Systems
nsys profile -o profile python3 your_app.py

# PyTorch Profiler
with torch.profiler.profile(activities=[ProfilerActivity.GPU]) as prof:
    model(input)
```

## Security Considerations

1. **Isolate GPU Workloads**: Use dedicated namespaces
2. **Resource Quotas**: Limit GPU usage per namespace
3. **Network Policies**: Restrict communication between GPU pods
4. **Image Scanning**: Scan GPU container images for vulnerabilities

## Additional Resources

- [NVIDIA GPU Operator Documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)
- [CUDA Toolkit Documentation](https://docs.nvidia.com/cuda/)
- [PyTorch GPU Documentation](https://pytorch.org/docs/stable/cuda.html)
- [TensorFlow GPU Guide](https://www.tensorflow.org/guide/gpu)