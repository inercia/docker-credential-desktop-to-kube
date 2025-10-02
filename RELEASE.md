# Release Checklist for Krew Plugin

## Preparing a New Release

Follow these steps to create a new release of the kubectl-dockerlogin plugin:

### 1. Update Version

- Update version in `dockerlogin.yaml`
- Tag the release in git

### 2. Build Release Artifacts

```bash
# Build all platform binaries
./build.sh v0.1.0

# This creates tarballs in dist/ directory for:
# - linux/amd64
# - linux/arm64
# - darwin/amd64
# - darwin/arm64
# - windows/amd64
```

### 3. Create GitHub Release

```bash
# Create a git tag
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0

# Create release on GitHub
gh release create v0.1.0 \
  --title "v0.1.0" \
  --notes "Initial release of kubectl-dockerlogin plugin" \
  dist/*.tar.gz
```

Or manually:
1. Go to https://github.com/inercia/docker-credential-desktop-to-kube/releases
2. Click "Draft a new release"
3. Choose tag: v0.1.0
4. Upload all `.tar.gz` files from `dist/`
5. Publish release

### 4. Update Krew Manifest

After uploading artifacts, the build script will print SHA256 checksums. Update `dockerlogin.yaml`:

```bash
# Get SHA256 checksums
sha256sum dist/*.tar.gz
```

Replace all `REPLACE_WITH_ACTUAL_SHA256_*` placeholders in `dockerlogin.yaml` with actual checksums.

### 5. Test Installation Locally

```bash
# Install from local manifest
kubectl krew install --manifest=dockerlogin.yaml

# Test the plugin
kubectl dockerlogin --help

# Uninstall
kubectl krew uninstall dockerlogin
```

### 6. Submit to Krew Index

1. Fork https://github.com/kubernetes-sigs/krew-index
2. Add `dockerlogin.yaml` to `plugins/` directory
3. Create a PR with:
   - Title: "Add kubectl-dockerlogin plugin"
   - Description explaining what the plugin does
4. Wait for review and merge

### 7. Announce

Once merged into krew-index, users can install with:

```bash
kubectl krew install dockerlogin
```

## Updating an Existing Release

For updates, repeat the process but:

1. Increment version number
2. Include changelog in release notes
3. Submit PR to krew-index updating the existing `plugins/dockerlogin.yaml`

## Testing Before Release

```bash
# Test the script works
./kubectl-dockerlogin --help
./kubectl-dockerlogin -d  # dry-run mode

# Test as kubectl plugin (copy to PATH)
cp kubectl-dockerlogin /usr/local/bin/
kubectl dockerlogin --help
```
