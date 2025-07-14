# CI/CD Setup for MMORPG Narrative Engine

This directory contains the CI/CD configuration for building and deploying applications directly within the Kubernetes cluster.

## Architecture

We use a simple build system that:
1. Receives webhooks from GitHub
2. Clones the repository
3. Builds Docker images
4. Pushes to the local microk8s registry (localhost:32000)
5. Updates deployments

## Components

- **build-pod.yaml**: Pod template for building applications
- **webhook-receiver.yaml**: Service to receive GitHub webhooks
- **rbac.yaml**: Permissions for the CI/CD system