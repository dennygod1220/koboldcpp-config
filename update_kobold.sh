#!/bin/bash

# KoboldCPP Automatic Updater
# This script fetches the latest linux-x64 binary from GitHub releases.

REPO="LostRuins/koboldcpp"
BINARY_NAME="koboldcpp-linux-x64"
TARGET_FILE="./$BINARY_NAME"

echo "Checking for the latest release of $REPO..."

# Fetch the latest release metadata and extract the download URL for the target binary
LATEST_RELEASE_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
    grep "browser_download_url" | \
    grep "$BINARY_NAME" | \
    grep -v "nocuda" | \
    grep -v "oldpc" | \
    head -n 1 | \
    cut -d '"' -f 4)

if [ -z "$LATEST_RELEASE_URL" ]; then
    echo "Error: Could not find the download URL for $BINARY_NAME."
    exit 1
fi

echo "Found latest release: $LATEST_RELEASE_URL"
echo "Downloading..."

# Download the binary
curl -L "$LATEST_RELEASE_URL" -o "$TARGET_FILE"

if [ $? -eq 0 ]; then
    echo "Download successful."
    chmod +x "$TARGET_FILE"
    echo "Made $TARGET_FILE executable."
    echo "Update complete! You can now run: $TARGET_FILE"
else
    echo "Error: Download failed."
    exit 1
fi
