#!/bin/bash
# File: cleanup_k3s_images.sh
# Usage: ./cleanup_k3s_images.sh [TAG_TO_KEEP]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TAG_TO_KEEP="$1"

echo -e "\n${YELLOW}Cleaning up old k3s images...${NC}"

# Only clean if we have a tag to exclude
grep_exclude=""
if [ -n "$TAG_TO_KEEP" ]; then
    grep_exclude="grep -v $TAG_TO_KEEP"
else
    grep_exclude="cat"
fi

# Remove old backend images
echo "Cleaning up old backend images..."
sudo k3s ctr images list | grep 'diy-auth-backend:' | $grep_exclude | \
while read -r image; do
    img_name=$(echo "$image" | awk '{print $1}')
    if [ -n "$img_name" ]; then
        echo "Removing old image: $img_name"
        sudo k3s ctr images rm "$img_name" 2>/dev/null || true
    fi
done

# Remove old frontend images
echo "Cleaning up old frontend images..."
sudo k3s ctr images list | grep 'diy-auth-frontend:' | $grep_exclude | \
while read -r image; do
    img_name=$(echo "$image" | awk '{print $1}')
    if [ -n "$img_name" ]; then
        echo "Removing old image: $img_name"
        sudo k3s ctr images rm "$img_name" 2>/dev/null || true
    fi
done

echo -e "${GREEN}Old k3s images cleanup complete.${NC}"
