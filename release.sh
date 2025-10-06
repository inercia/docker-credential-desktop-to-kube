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

# Show next steps
echo -e "${BLUE}=== Next Steps ===${NC}"
echo ""
echo -e "${YELLOW}1. Build release artifacts:${NC}"
echo -e "   ${GREEN}./build.sh ${NEW_TAG}${NC}"
echo ""
echo -e "${YELLOW}2. Create GitHub release with artifacts:${NC}"
echo -e "   ${GREEN}gh release create ${NEW_TAG} \\${NC}"
echo -e "   ${GREEN}  --title \"${NEW_TAG}\" \\${NC}"
echo -e "   ${GREEN}  --notes \"${RELEASE_NOTES}\" \\${NC}"
echo -e "   ${GREEN}  dist/*.tar.gz${NC}"
echo ""
echo -e "   Or manually at:"
echo -e "   ${BLUE}https://github.com/inercia/docker-credential-desktop-to-kube/releases/new?tag=${NEW_TAG}${NC}"
echo ""
echo -e "${YELLOW}3. Update dockerlogin.yaml with SHA256 checksums:${NC}"
echo -e "   ${GREEN}sha256sum dist/*.tar.gz${NC}"
echo ""
echo -e "${YELLOW}4. Test the plugin installation:${NC}"
echo -e "   ${GREEN}kubectl krew install --manifest=dockerlogin.yaml${NC}"
echo ""
echo -e "${YELLOW}5. Submit to Krew Index (if ready):${NC}"
echo -e "   - Fork: https://github.com/kubernetes-sigs/krew-index"
echo -e "   - Add/update dockerlogin.yaml in plugins/ directory"
echo -e "   - Create PR with description"
echo ""
echo -e "${GREEN}Done!${NC}"
