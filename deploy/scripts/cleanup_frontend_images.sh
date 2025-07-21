#!/bin/bash
# File: cleanup_frontend_images.sh
# Purpose: Clean up old frontend images from k3s container runtime
# Usage: ./cleanup_frontend_images.sh [TAG_TO_KEEP]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TAG_TO_KEEP="$1"

echo -e "\n${YELLOW}Cleaning up old frontend images...${NC}"

# Only clean if we have a tag to exclude
grep_exclude=""
if [ -n "$TAG_TO_KEEP" ]; then
    grep_exclude="grep -v $TAG_TO_KEEP"
else
    grep_exclude="cat"
fi

# Remove old frontend images
sudo k3s ctr images list | grep 'diy-auth-frontend:' | $grep_exclude | \
while read -r image; do
    img_name=$(echo "$image" | awk '{print $1}')
    if [ -n "$img_name" ]; then
        echo "Removing old frontend image: $img_name"
        sudo k3s ctr images rm "$img_name" 2>/dev/null || true
    fi
done

echo -e "${GREEN}Frontend images cleanup complete.${NC}"
