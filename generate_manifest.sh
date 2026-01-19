#!/bin/bash

set -e

# Usage: ./generate_manifest.sh <tool> --version <version>
# Example: ./generate_manifest.sh constraint --version v1.0.0

TOOL=""
VERSION=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --version)
      VERSION="$2"
      shift 2
      ;;
    constraint|newton)
      TOOL="$1"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$TOOL" ] || [ -z "$VERSION" ]; then
  echo "Usage: $0 <tool> --version <version>"
  echo "Example: $0 constraint --version v1.0.0"
  exit 1
fi

# Remove 'v' prefix if present
VERSION_CLEAN=${VERSION#v}

# Repository mapping
declare -A repos=(
  ["constraint"]="gonewton/constraints"
  ["newton"]="gonewton/newton"
)

REPO=${repos[$TOOL]}

if [ -z "$REPO" ]; then
  echo "Unknown tool: $TOOL"
  exit 1
fi

# Fetch release info from GitHub API
API_URL="https://api.github.com/repos/$REPO/releases/tags/$VERSION"
echo "Fetching release info from $API_URL"

RELEASE_DATA=$(curl -s "$API_URL")

if [ "$(echo "$RELEASE_DATA" | jq -r '.message')" = "Not Found" ]; then
  echo "Release $VERSION not found for $REPO"
  exit 1
fi

# Extract Windows download URL and SHA256
WINDOWS_URL=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | contains("windows")) | .browser_download_url' | head -1)
WINDOWS_SHA=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | contains("windows")) | .browser_download_url' | xargs curl -s | sha256sum | cut -d' ' -f1)

# Update JSON manifest
MANIFEST_FILE="bucket/${TOOL}.json"

jq --arg version "$VERSION_CLEAN" \
   --arg url "$WINDOWS_URL" \
   --arg hash "$WINDOWS_SHA" \
   '.version = $version | .url = $url | .hash = $hash' \
   "$MANIFEST_FILE" > "${MANIFEST_FILE}.tmp"

mv "${MANIFEST_FILE}.tmp" "$MANIFEST_FILE"

echo "Updated $MANIFEST_FILE"