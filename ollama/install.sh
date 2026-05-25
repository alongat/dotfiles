#!/bin/bash

set -e

DOTFILES_DIR="$HOME/.dotfiles"
MODELS_FILE="$DOTFILES_DIR/ollama/models.txt"

echo "› Setting up Ollama"

# ── 1. Install Ollama ──────────────────────────────────────────────────────────

if command -v ollama &> /dev/null; then
    echo "  Ollama is already installed ($(ollama --version 2>/dev/null || echo 'version unknown'))"
else
    echo "  Installing Ollama via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install ollama
    else
        echo "  ❌ Homebrew not found. Install Homebrew first."
        exit 1
    fi
    if command -v ollama &> /dev/null; then
        echo "  ✅ Ollama installed successfully"
    else
        echo "  ❌ Ollama installation failed"
        exit 1
    fi
fi

# ── 2. Ensure Ollama service is running ───────────────────────────────────────

if ! curl -sf http://localhost:11434 &> /dev/null; then
    echo "  Starting Ollama service..."
    ollama serve &> /dev/null &
    OLLAMA_PID=$!
    # Wait up to 10 seconds for the service to be ready
    for i in $(seq 1 10); do
        if curl -sf http://localhost:11434 &> /dev/null; then
            echo "  ✅ Ollama service started"
            break
        fi
        sleep 1
        if [ "$i" -eq 10 ]; then
            echo "  ❌ Ollama service failed to start"
            exit 1
        fi
    done
else
    echo "  Ollama service is already running"
fi

# ── 3. Load desired models from manifest ──────────────────────────────────────

if [ ! -f "$MODELS_FILE" ]; then
    echo "  ❌ Models manifest not found: $MODELS_FILE"
    exit 1
fi

# Parse manifest: strip comments and blank lines, grab the model name (first field)
DESIRED_MODELS=()
while IFS= read -r line; do
    # Strip inline comments
    model=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$model" ] && continue
    DESIRED_MODELS+=("$model")
done < "$MODELS_FILE"

echo "  Models in manifest: ${#DESIRED_MODELS[@]}"

# ── 4. Pull models that are not yet installed ─────────────────────────────────

for model in "${DESIRED_MODELS[@]}"; do
    # ollama list output: "name:tag   ID   SIZE   MODIFIED"
    if ollama list 2>/dev/null | awk '{print $1}' | grep -qx "$model"; then
        echo "  Already pulled: $model"
    else
        echo "  Pulling $model..."
        if ollama pull "$model"; then
            echo "  ✅ Pulled: $model"
        else
            echo "  ❌ Failed to pull: $model"
            # Don't exit — continue with remaining models
        fi
    fi
done

# ── 5. Remove models that are no longer in the manifest ───────────────────────

echo "  Checking for models to remove..."

INSTALLED_MODELS=()
while IFS= read -r line; do
    model=$(echo "$line" | awk '{print $1}')
    # Skip header line
    [ "$model" = "NAME" ] && continue
    [ -z "$model" ] && continue
    INSTALLED_MODELS+=("$model")
done <<EOF
$(ollama list 2>/dev/null)
EOF

REMOVED_COUNT=0
for installed in "${INSTALLED_MODELS[@]}"; do
    found=false
    for desired in "${DESIRED_MODELS[@]}"; do
        if [ "$installed" = "$desired" ]; then
            found=true
            break
        fi
    done
    if [ "$found" = false ]; then
        echo "  Removing unlisted model: $installed"
        if ollama rm "$installed"; then
            echo "  ✅ Removed: $installed"
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        else
            echo "  ❌ Failed to remove: $installed"
        fi
    fi
done

if [ "$REMOVED_COUNT" -eq 0 ]; then
    echo "  No models to remove"
fi

echo "  ✅ Ollama setup completed"
