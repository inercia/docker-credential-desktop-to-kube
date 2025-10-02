# docker-credential-desktop-to-kube

Automatically converts credentials stored in Docker credential store to Kubernetes registry secrets.

## What does it do?

The `docker2kube.sh` script automates the process of migrating Docker credentials stored locally (using docker-credential-desktop or other helpers) to `docker-registry` type secrets in Kubernetes. This is especially useful when you have credentials configured in Docker Desktop and need your Kubernetes pods to pull images from the same private registries.

### Key Features:

- ✅ **Automatic migration**: Converts all Docker credentials to Kubernetes secrets
- ✅ **Multi-registry support**: Processes all registries configured in your credential store
- ✅ **Flexible filtering**: Allows including/excluding specific registries
- ✅ **Dry-run mode**: Preview changes without applying them
- ✅ **Valid naming**: Automatically generates valid Kubernetes secret names
- ✅ **Namespace configuration**: Specify target namespace

### Basic Usage:

```bash
# Create secrets in default namespace
./docker2kube.sh

# Create secrets in a specific namespace
./docker2kube.sh -n my-namespace

# Dry-run mode to preview changes
./docker2kube.sh -d

# Process only a specific registry
./docker2kube.sh -s "my-registry.com"
```
