#!/bin/bash

# Update version script for dynamic build numbers
# Usage: ./update_version.sh [build_number]

BUILD_NUMBER=${1:-$(date +%s)}  # Use provided build number or timestamp
VERSION_NAME="1.0.0"

echo "Updating pubspec.yaml with version: $VERSION_NAME+$BUILD_NUMBER"

# Update pubspec.yaml with new version
sed -i.bak "s/^version: .*/version: $VERSION_NAME+$BUILD_NUMBER/" pubspec.yaml

echo "Version updated successfully!"
echo "New version: $VERSION_NAME+$BUILD_NUMBER"