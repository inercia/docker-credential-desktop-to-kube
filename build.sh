#!/bin/bash

# Build script for creating Krew plugin releases
# This script packages the kubectl-dockerlogin plugin for different platforms

set -e

VERSION="${1:-v0.1.0}"
PLUGIN_NAME="dockerlogin"

echo "Building ${PLUGIN_NAME} ${VERSION} for all platforms..."

# Create dist directory
mkdir -p dist

# Platforms to build for
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
)

for platform in "${PLATFORMS[@]}"; do
    OS=$(echo "$platform" | cut -d'/' -f1)
    ARCH=$(echo "$platform" | cut -d'/' -f2)
    
    echo "Building for ${OS}/${ARCH}..."
    
    # Create temporary directory for this build
    BUILD_DIR="dist/${PLUGIN_NAME}_${OS}_${ARCH}"
    mkdir -p "$BUILD_DIR"
    
    # Copy the plugin script
    if [ "$OS" = "windows" ]; then
        cp kubectl-dockerlogin "${BUILD_DIR}/kubectl-dockerlogin.exe"
        # Add shebang fix for Windows (Git Bash)
        sed -i '1i#!/usr/bin/env bash' "${BUILD_DIR}/kubectl-dockerlogin.exe" 2>/dev/null || true
    else
        cp kubectl-dockerlogin "${BUILD_DIR}/"
    fi
    
    # Create tarball
    TARBALL="dist/${PLUGIN_NAME}_${OS}_${ARCH}.tar.gz"
    tar -czf "$TARBALL" -C "$BUILD_DIR" .
    
    # Calculate SHA256
    if command -v sha256sum &> /dev/null; then
        SHA256=$(sha256sum "$TARBALL" | cut -d' ' -f1)
    elif command -v shasum &> /dev/null; then
        SHA256=$(shasum -a 256 "$TARBALL" | cut -d' ' -f1)
    else
        echo "Warning: sha256sum or shasum not found, skipping checksum"
        SHA256="CALCULATE_MANUALLY"
    fi
    
    echo "  ✓ Created: $TARBALL"
    echo "  SHA256: $SHA256"
    echo ""
    
    # Clean up build directory
    rm -rf "$BUILD_DIR"
done

echo "Build complete! Artifacts are in the dist/ directory"
echo ""
echo "Next steps:"
echo "1. Create a GitHub release with tag ${VERSION}"
echo "2. Upload all tar.gz files from dist/ to the release"
echo "3. Update dockerlogin.yaml with the actual SHA256 checksums"
echo "4. Submit a PR to https://github.com/kubernetes-sigs/krew-index"
