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

# Extract Windows download URL (single asset; prefer msvc)
WINDOWS_URL=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | contains("windows")) | .browser_download_url' | head -1)
if [ -z "$WINDOWS_URL" ] || [ "$WINDOWS_URL" = "null" ]; then
  echo "No Windows asset found for release $VERSION. GitHub may still be indexing assets; retry the workflow or run Update Package Managers manually."
  exit 1
fi
# Hash the same URL we use in the manifest (avoid race where API lists no assets yet)
WINDOWS_SHA=$(curl -sL "$WINDOWS_URL" | sha256sum | cut -d' ' -f1)
EMPTY_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
if [ "$WINDOWS_SHA" = "$EMPTY_HASH" ]; then
  echo "Downloaded asset is empty. GitHub may still be serving the new asset; retry the workflow or run Update Package Managers manually."
  exit 1
fi

# Update JSON manifest
MANIFEST_FILE="bucket/${TOOL}.json"

jq --arg version "$VERSION_CLEAN" \
   --arg url "$WINDOWS_URL" \
   --arg hash "$WINDOWS_SHA" \
   '.version = $version | .architecture."64bit".url = $url | .architecture."64bit".hash = $hash' \
   "$MANIFEST_FILE" > "${MANIFEST_FILE}.tmp"

mv "${MANIFEST_FILE}.tmp" "$MANIFEST_FILE"

echo "Updated $MANIFEST_FILE"