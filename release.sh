#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Docker Credential Desktop to Kube - Release Script ===${NC}\n"

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}Warning: Working directory is not clean${NC}"
    git status --short
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted.${NC}"
        exit 1
    fi
fi

# Show existing tags
echo -e "${GREEN}Existing tags:${NC}"
if git tag -l | grep -q .; then
    git tag -l | sort -V | tail -10
else
    echo "  (no tags found)"
fi
echo ""

# Ask for new tag
read -p "Enter the new tag (e.g., v0.1.0): " NEW_TAG

# Validate tag format
if [[ ! $NEW_TAG =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}Warning: Tag doesn't follow semantic versioning format (vX.Y.Z)${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted.${NC}"
        exit 1
    fi
fi

# Check if tag already exists
if git tag -l | grep -q "^${NEW_TAG}$"; then
    echo -e "${RED}Error: Tag ${NEW_TAG} already exists${NC}"
    exit 1
fi

# Ask for release notes
echo ""
echo -e "${YELLOW}Enter release notes (press Ctrl+D when done):${NC}"
RELEASE_NOTES=$(cat)

# Create annotated tag
echo ""
echo -e "${BLUE}Creating annotated tag ${NEW_TAG}...${NC}"
git tag -a "$NEW_TAG" -m "Release $NEW_TAG

$RELEASE_NOTES"

# Push tag to remote
echo -e "${BLUE}Pushing tag to remote repository...${NC}"
git push origin "$NEW_TAG"

echo ""
echo -e "${GREEN}✓ Tag ${NEW_TAG} created and pushed successfully!${NC}"
echo ""

# Build release artifacts
echo -e "${BLUE}=== Building Release Artifacts ===${NC}"
if [ ! -f "./build.sh" ]; then
    echo -e "${RED}Error: build.sh not found${NC}"
    exit 1
fi

if ! bash ./build.sh "$NEW_TAG"; then
    echo -e "${RED}Error: Build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Build completed successfully!${NC}"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}Warning: GitHub CLI (gh) not found${NC}"
    echo -e "${YELLOW}Please install it from: https://cli.github.com/${NC}"
    echo ""
    echo -e "${YELLOW}Manual steps required:${NC}"
    echo -e "1. Create release at: ${BLUE}https://github.com/inercia/docker-credential-desktop-to-kube/releases/new?tag=${NEW_TAG}${NC}"
    echo -e "2. Upload artifacts from dist/ directory"
    exit 0
fi

# Create GitHub release
echo -e "${BLUE}=== Creating GitHub Release ===${NC}"

# Check if there are any artifacts to upload
if [ ! -d "dist" ] || [ -z "$(ls -A dist/*.tar.gz 2>/dev/null)" ]; then
    echo -e "${RED}Error: No artifacts found in dist/ directory${NC}"
    exit 1
fi

# Create release with artifacts
echo -e "${BLUE}Creating release ${NEW_TAG} and uploading artifacts...${NC}"
if gh release create "$NEW_TAG" \
    --title "Release $NEW_TAG" \
    --notes "$RELEASE_NOTES" \
    dist/*.tar.gz; then
    
    echo ""
    echo -e "${GREEN}✓ GitHub release created successfully!${NC}"
    echo ""
else
    echo -e "${RED}Error: Failed to create GitHub release${NC}"
    exit 1
fi

# Update dockerlogin.yaml with checksums
echo -e "${BLUE}=== Updating dockerlogin.yaml ===${NC}"

if [ -f "dockerlogin.yaml" ]; then
    # Create backup
    cp dockerlogin.yaml dockerlogin.yaml.bak
    
    # Update version
    if command -v sed &> /dev/null; then
        # macOS sed requires explicit backup extension
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/version: v[0-9.]\+/version: $NEW_TAG/" dockerlogin.yaml
        else
            sed -i "s/version: v[0-9.]\+/version: $NEW_TAG/" dockerlogin.yaml
        fi
        echo -e "${GREEN}✓ Updated version in dockerlogin.yaml${NC}"
    fi
    
    # Calculate and display checksums
    echo ""
    echo -e "${YELLOW}SHA256 checksums for manual verification:${NC}"
    echo ""
    
    if command -v sha256sum &> /dev/null; then
        sha256sum dist/*.tar.gz
    elif command -v shasum &> /dev/null; then
        shasum -a 256 dist/*.tar.gz
    fi
    
    echo ""
    echo -e "${YELLOW}Note: dockerlogin.yaml version updated to ${NEW_TAG}${NC}"
    echo -e "${YELLOW}Please manually update SHA256 checksums in dockerlogin.yaml${NC}"
    echo -e "${YELLOW}Backup saved as: dockerlogin.yaml.bak${NC}"
else
    echo -e "${YELLOW}Warning: dockerlogin.yaml not found${NC}"
fi

echo ""
echo -e "${BLUE}=== Release Complete! ===${NC}"
echo ""
echo -e "${GREEN}✓ Tag created and pushed: ${NEW_TAG}${NC}"
echo -e "${GREEN}✓ Artifacts built in dist/ directory${NC}"
echo -e "${GREEN}✓ GitHub release created with artifacts${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Update SHA256 checksums in dockerlogin.yaml (see above)"
echo -e "2. Update release URLs in dockerlogin.yaml if needed"
echo -e "3. Test the plugin installation:"
echo -e "   ${GREEN}kubectl krew install --manifest=dockerlogin.yaml${NC}"
echo -e "4. Submit to Krew Index when ready:"
echo -e "   - Fork: https://github.com/kubernetes-sigs/krew-index"
echo -e "   - Add/update dockerlogin.yaml in plugins/ directory"
echo -e "   - Create PR with description"
echo ""
echo -e "${GREEN}Done!${NC}"
