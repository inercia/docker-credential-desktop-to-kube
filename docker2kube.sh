#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DOCKER_CREDENTIAL_HELPER="docker-credential-desktop"
NAMESPACE="default"
DRY_RUN=""
EMAIL="noreply@example.com"

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Translates credentials from Docker credential store to Kubernetes registry secrets.

OPTIONS:
    -h, --help              Show this help message
    -c, --credential-helper Helper name (default: docker-credential-desktop)
    -n, --namespace         Kubernetes namespace (default: default)
    -e, --email             Email for docker-registry secret (default: noreply@example.com)
    -d, --dry-run           Use dry-run mode (client)
    -s, --server            Process only a specific server URL
    -x, --exclude           Exclude servers matching pattern (can be used multiple times)

EXAMPLES:
    # Create secrets in default namespace
    $0

    # Create secrets in specific namespace with dry-run
    $0 -n my-namespace -d

    # Process only a registry
    $0 -s "some.registry.com"

    # Exclude certain registries
    $0 -x "access-token" -x "refresh-token"

EOF
    exit 0
}

# Parse command line arguments
EXCLUDE_PATTERNS=()
SPECIFIC_SERVER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -c|--credential-helper)
            DOCKER_CREDENTIAL_HELPER="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN="--dry-run=client"
            shift
            ;;
        -s|--server)
            SPECIFIC_SERVER="$2"
            shift 2
            ;;
        -x|--exclude)
            EXCLUDE_PATTERNS+=("$2")
            shift 2
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Check if required commands are available
for cmd in jq kubectl "$DOCKER_CREDENTIAL_HELPER"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Error: Required command '$cmd' not found${NC}"
        exit 1
    fi
done

# Function to sanitize server URL to create valid Kubernetes secret name
sanitize_name() {
    local url="$1"
    # Remove https:// or http://
    url="${url#https://}"
    url="${url#http://}"
    # Remove trailing slashes
    url="${url%/}"
    # Replace invalid characters with dashes and convert to lowercase
    echo "$url" | tr '/:@.' '-' | tr '[:upper:]' '[:lower:]' | sed 's/^-//;s/-$//'
}

# Function to check if server should be excluded
should_exclude() {
    local server="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$server" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to create Kubernetes secret from Docker credentials
create_k8s_secret() {
    local server="$1"
    local username="$2"
    local secret="$3"
    
    # Create a valid secret name
    local secret_name
    secret_name="registry-$(sanitize_name "$server")"
    
    # Ensure server has protocol prefix
    local server_url="$server"
    if [[ ! "$server_url" =~ ^https?:// ]]; then
        server_url="https://$server_url"
    fi
    
    echo -e "${YELLOW}Creating secret: ${secret_name}${NC}"
    echo "  Server: $server_url"
    echo "  Username: $username"
    
    # Create the secret
    if kubectl create secret docker-registry "$secret_name" \
        --docker-server="$server_url" \
        --docker-username="$username" \
        --docker-password="$secret" \
        --docker-email="$EMAIL" \
        --namespace="$NAMESPACE" \
        $DRY_RUN 2>&1; then
        echo -e "${GREEN}✓ Successfully created secret: ${secret_name}${NC}\n"
        return 0
    else
        echo -e "${RED}✗ Failed to create secret: ${secret_name}${NC}\n"
        return 1
    fi
}

# Main script
echo -e "${GREEN}=== Docker to Kubernetes Secret Converter ===${NC}\n"
echo "Credential Helper: $DOCKER_CREDENTIAL_HELPER"
echo "Namespace: $NAMESPACE"
echo "Email: $EMAIL"
[[ -n "$DRY_RUN" ]] && echo "Mode: DRY RUN"
[[ -n "$SPECIFIC_SERVER" ]] && echo "Specific Server: $SPECIFIC_SERVER"
[[ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]] && echo "Exclude Patterns: ${EXCLUDE_PATTERNS[*]}"
echo ""

# Get list of servers from credential helper
echo -e "${YELLOW}Fetching credentials from $DOCKER_CREDENTIAL_HELPER...${NC}"
SERVERS_JSON=$("$DOCKER_CREDENTIAL_HELPER" list 2>/dev/null)

if [[ -z "$SERVERS_JSON" ]]; then
    echo -e "${RED}Error: No credentials found or unable to access credential helper${NC}"
    exit 1
fi

# Parse servers
SERVERS=$(echo "$SERVERS_JSON" | jq -r 'keys[]')

if [[ -z "$SERVERS" ]]; then
    echo -e "${RED}Error: No servers found in credential store${NC}"
    exit 1
fi

echo -e "${GREEN}Found $(echo "$SERVERS" | wc -l | tr -d ' ') server(s)${NC}\n"

# Process each server
SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

while IFS= read -r server; do
    # Skip empty lines
    [[ -z "$server" ]] && continue
    
    # If specific server is set, only process that one
    if [[ -n "$SPECIFIC_SERVER" ]] && [[ "$server" != *"$SPECIFIC_SERVER"* ]]; then
        echo -e "${YELLOW}⊘ Skipping (not matching specific server): $server${NC}\n"
        ((SKIP_COUNT++))
        continue
    fi
    
    # Check if server should be excluded
    if should_exclude "$server"; then
        echo -e "${YELLOW}⊘ Skipping (excluded): $server${NC}\n"
        ((SKIP_COUNT++))
        continue
    fi
    
    # Remove https:// prefix for the credential helper query
    server_query="${server#https://}"
    server_query="${server_query#http://}"
    
    # Get credentials for this server
    echo -e "${YELLOW}Processing: $server${NC}"
    CRED_JSON=$(echo "$server_query" | "$DOCKER_CREDENTIAL_HELPER" get 2>/dev/null)
    
    if [[ -z "$CRED_JSON" ]]; then
        echo -e "${RED}✗ Failed to get credentials for: $server${NC}\n"
        ((FAIL_COUNT++))
        continue
    fi
    
    # Extract username and secret
    USERNAME=$(echo "$CRED_JSON" | jq -r '.Username // empty')
    SECRET=$(echo "$CRED_JSON" | jq -r '.Secret // empty')
    
    if [[ -z "$USERNAME" ]] || [[ -z "$SECRET" ]]; then
        echo -e "${RED}✗ Invalid credentials (missing username or secret): $server${NC}\n"
        ((FAIL_COUNT++))
        continue
    fi
    
    # Create Kubernetes secret
    if create_k8s_secret "$server_query" "$USERNAME" "$SECRET"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
    
done <<< "$SERVERS"

# Summary
echo -e "${GREEN}=== Summary ===${NC}"
echo -e "${GREEN}✓ Successfully created: $SUCCESS_COUNT${NC}"
[[ $SKIP_COUNT -gt 0 ]] && echo -e "${YELLOW}⊘ Skipped: $SKIP_COUNT${NC}"
[[ $FAIL_COUNT -gt 0 ]] && echo -e "${RED}✗ Failed: $FAIL_COUNT${NC}"

exit 0
