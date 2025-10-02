# docker-credential-desktop-to-kube

A kubectl plugin that automatically converts credentials stored in Docker credential store to Kubernetes registry secrets.

## What does it do?

The `kubectl dockerlogin` plugin automates the process of migrating Docker credentials stored locally (using docker-credential-desktop or other helpers) to `docker-registry` type secrets in Kubernetes. This is especially useful when you have credentials configured in Docker Desktop and need your Kubernetes pods to pull images from the same private registries.

### Key Features:

- ✅ **Automatic migration**: Converts all Docker credentials to Kubernetes secrets
- ✅ **Multi-registry support**: Processes all registries configured in your credential store
- ✅ **Flexible filtering**: Allows including/excluding specific registries
- ✅ **Dry-run mode**: Preview changes without applying them
- ✅ **Valid naming**: Automatically generates valid Kubernetes secret names
- ✅ **Namespace configuration**: Specify target namespace

## Installation

### Via Krew (Recommended)

```bash
kubectl krew install dockerlogin
```

### Manual Installation

1. Download the latest release for your platform from the [releases page](https://github.com/inercia/docker-credential-desktop-to-kube/releases)
2. Extract and move to your PATH:

```bash
# Linux/macOS
tar -xzf dockerlogin_*.tar.gz
sudo mv kubectl-dockerlogin /usr/local/bin/
chmod +x /usr/local/bin/kubectl-dockerlogin

# Verify installation
kubectl dockerlogin --help
```

## Prerequisites

- `kubectl` with appropriate cluster access
- `jq` command-line JSON processor
- A Docker credential helper (default: `docker-credential-desktop`)
  - On Docker Desktop, this is included automatically
  - On other systems, you may need to install it separately

## Usage

### Basic Usage

```bash
# Create secrets in default namespace
kubectl dockerlogin

# Create secrets in a specific namespace
kubectl dockerlogin -n my-namespace

# Dry-run mode to preview changes
kubectl dockerlogin -d

# Process only a specific registry
kubectl dockerlogin -s "my-registry.com"
```

### Advanced Usage

```bash
# Use a different credential helper
kubectl dockerlogin -c docker-credential-pass

# Exclude certain registries (useful for tokens)
kubectl dockerlogin -x "access-token" -x "refresh-token"

# Combine options
kubectl dockerlogin -n production -d -x "token"

# Show help
kubectl dockerlogin --help
```

## Examples

### Migrate all Docker Hub credentials to Kubernetes

```bash
kubectl dockerlogin -n default
```

### Preview changes before applying

```bash
kubectl dockerlogin -d
```

### Migrate only specific registry

```bash
kubectl dockerlogin -s "ghcr.io" -n my-namespace
```

### Exclude authentication tokens

```bash
kubectl dockerlogin -x "desktop.oauth" -x "vscode"
```
