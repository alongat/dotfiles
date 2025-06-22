#!/bin/bash

set -e

echo "› Installing Google Cloud components"

# Check if gcloud is installed
if ! command -v gcloud >/dev/null 2>&1; then
    echo "  ❌ Google Cloud CLI is not installed. Please install it first."
    echo "  Run: brew install --cask google-cloud-sdk"
    exit 1
fi

echo "  Google Cloud CLI version: $(gcloud version --format='value(Google Cloud SDK)')"

# Install GKE auth plugin
echo "  Installing GKE gcloud auth plugin..."
if gcloud components install gke-gcloud-auth-plugin --quiet; then
    echo "  ✅ GKE gcloud auth plugin installed successfully"
else
    echo "  ❌ Failed to install GKE gcloud auth plugin"
    exit 1
fi

echo "  ✅ Google Cloud components installation completed"