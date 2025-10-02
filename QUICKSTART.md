# Quick Start Guide for Krew Plugin

## For Users

### Install the plugin

```bash
# Via Krew (once published)
kubectl krew install dockerlogin

# Verify installation
kubectl dockerlogin --help
```

### Use the plugin

```bash
# Basic usage - migrate all credentials to default namespace
kubectl dockerlogin

# Preview changes without applying (dry-run)
kubectl dockerlogin --dry-run

# Specify target namespace
kubectl dockerlogin --namespace my-namespace

# Process only specific registry
kubectl dockerlogin --server "ghcr.io"

# Exclude certain patterns (like tokens)
kubectl dockerlogin --exclude "token" --exclude "oauth"
```

## For Developers/Maintainers

### First Time Setup

1. **Test locally**:
   ```bash
   # Make the plugin executable
   chmod +x kubectl-dockerlogin
   
   # Test it
   ./kubectl-dockerlogin --help
   ```

2. **Test as kubectl plugin**:
   ```bash
   # Copy to PATH
   sudo cp kubectl-dockerlogin /usr/local/bin/
   
   # Use via kubectl
   kubectl dockerlogin --help
   ```

3. **Create first release**:
   ```bash
   # Build artifacts
   ./build.sh v0.1.0
   
   # Create and push tag
   git tag -a v0.1.0 -m "Initial release"
   git push origin v0.1.0
   
   # GitHub Actions will create the release automatically
   ```

4. **Update checksums**:
   ```bash
   # After GitHub release is created, download checksums.txt
   # Update dockerlogin.yaml with actual SHA256 values
   # Commit and push the updated manifest
   ```

5. **Submit to Krew**:
   - Fork https://github.com/kubernetes-sigs/krew-index
   - Add your `dockerlogin.yaml` to `plugins/` directory
   - Create PR
   - Wait for review and merge

### Testing Before Release

```bash
# Test with local manifest
kubectl krew install --manifest=dockerlogin.yaml \
  --archive=dist/dockerlogin_$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m).tar.gz

# Test the plugin
kubectl dockerlogin --help

# Uninstall
kubectl krew uninstall dockerlogin
```

### Updating the Plugin

1. Make your changes to `kubectl-dockerlogin`
2. Update version in `dockerlogin.yaml`
3. Create new tag: `git tag -a v0.2.0 -m "Release v0.2.0"`
4. Push tag: `git push origin v0.2.0`
5. Update checksums in `dockerlogin.yaml`
6. Submit PR to krew-index updating `plugins/dockerlogin.yaml`

## Troubleshooting

### Plugin not found after installation

```bash
# Ensure Krew is installed
kubectl krew version

# Ensure Krew bin is in PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Update Krew index
kubectl krew update
```

### jq not found

```bash
# Install jq
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Windows (via Chocolatey)
choco install jq
```

### docker-credential-desktop not found

Make sure Docker Desktop is installed and running, or specify a different credential helper:

```bash
kubectl dockerlogin --credential-helper docker-credential-pass
```

## Resources

- [Krew Documentation](https://krew.sigs.k8s.io/)
- [Plugin Development Guide](https://krew.sigs.k8s.io/docs/developer-guide/)
- [Krew Index Repository](https://github.com/kubernetes-sigs/krew-index)
