#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
set -oue pipefail

echo "Installing OrcaSlicer from GitHub..."

# Define variables
REPO="OrcaSlicer/OrcaSlicer"
ARCH="x86_64"
TEMP_DIR="/tmp/orcaslicer-install"

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Get the latest release version and download URL
echo "Fetching latest OrcaSlicer release info..."
LATEST_VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_VERSION}/OrcaSlicer-Linux-flatpak_${LATEST_VERSION}_${ARCH}.flatpak"

echo "Latest version: ${LATEST_VERSION}"
echo "Download URL: ${DOWNLOAD_URL}"

# Download the flatpak
echo "Downloading OrcaSlicer Flatpak..."
curl -L -o "orcaslicer.flatpak" "$DOWNLOAD_URL"

# Install the flatpak system-wide
echo "Installing OrcaSlicer Flatpak..."
flatpak install --system -y --noninteractive "orcaslicer.flatpak"

# Cleanup
echo "Cleaning up temporary files..."
cd /
rm -rf "$TEMP_DIR"

echo "OrcaSlicer installation completed successfully!"
