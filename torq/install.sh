#!/bin/bash

set -e

echo "› Setting up Torq development environment"

# Check if required tools are installed
if ! command -v gcloud >/dev/null 2>&1; then
    echo "  ❌ Google Cloud CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
    echo "  ❌ kubectl is not installed. Please install it first."
    exit 1
fi

# Check if kubectl config exists and has required content
if [ ! -f ~/.kube/config ]; then
    echo "  ⚠️ kubectl config not found, skipping Torq cluster setup"
    exit 0
fi

if ! grep -q "prdeu" ~/.kube/config 2>/dev/null; then
    echo "  ⚠️ Torq clusters not configured in kubectl, skipping setup"
    exit 0
fi

echo "  Setting up Torq Kubernetes cluster credentials..."

# Array of cluster configurations
declare -a clusters=(
    "sp-development europe-west1 stackpulse-development"
    "sp-staging europe-west1 stackpulse-staging"
    "sp-production us-central1 stackpulse-production"
    "steps-staging europe-west1 torqio-stg-steps"
    "sp-playbooks us-central1 stackpulse-playbooks"
    "steps-production-us-central1 us-central1 stackpulse-playbooks"
    "torqio-steps europe-west3 torqio-eu-steps"
    "torq-production europe-west3 torqio-eu-production"
)

# Get cluster credentials
failed_count=0
for cluster_info in "${clusters[@]}"; do
    read -r cluster region project <<< "$cluster_info"
    echo "    Getting credentials for $cluster..."
    if ! gcloud container clusters get-credentials "$cluster" --region="$region" --project="$project" 2>/dev/null; then
        echo "    ⚠️ Failed to get credentials for $cluster (may not have access)"
        failed_count=$((failed_count + 1))
    fi
done

# Rename contexts for easier access
echo "  Renaming kubectl contexts..."
declare -A context_renames=(
    ["gke_stackpulse-demo_us-central1_demo-cluster"]="demo"
    ["gke_stackpulse-development_europe-west1_sp-development"]="dev"
    ["gke_stackpulse-staging_europe-west1_sp-staging"]="stg"
    ["gke_stackpulse-production_us-central1_sp-production"]="prd"
    ["gke_torqio-eu-production_europe-west3_torq-production"]="prdeu"
    ["gke_torqio-eu-steps_europe-west3_torqio-steps"]="prdeu-steps"
    ["gke_torqio-stg-steps_europe-west1_steps"]="stg-steps"
    ["gke_stackpulse-playbooks_us-central1_sp-playbooks"]="prd-steps"
)

for old_name in "${!context_renames[@]}"; do
    new_name="${context_renames[$old_name]}"
    if kubectl config get-contexts "$old_name" >/dev/null 2>&1; then
        echo "    Renaming $old_name -> $new_name"
        kubectl config rename-context "$old_name" "$new_name" >/dev/null 2>&1 || true
    fi
done

if [ $failed_count -eq 0 ]; then
    echo "  ✅ Torq development environment setup completed successfully"
else
    echo "  ⚠️ Torq setup completed with $failed_count failed cluster connections"
fi
