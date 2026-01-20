#!/bin/bash
# Check if Helm is installed and install if needed

set -euo pipefail

echo "=== Checking Helm Installation ==="

# Check if helm is in PATH
if command -v helm &> /dev/null; then
  echo "✅ Helm is installed: $(which helm)"
  helm version --short
  exit 0
fi

# Check common installation locations
HELM_PATHS=(
  "/usr/local/bin/helm"
  "/opt/homebrew/bin/helm"
  "$HOME/.local/bin/helm"
  "$HOME/bin/helm"
)

for path in "${HELM_PATHS[@]}"; do
  if [ -f "$path" ]; then
    echo "✅ Found Helm at: $path"
    echo "Add to PATH: export PATH=\$(dirname $path):\$PATH"
    exit 0
  fi
done

echo "❌ Helm not found"
echo ""
echo "To install Helm:"
echo ""
echo "  # macOS (Homebrew)"
echo "  brew install helm"
echo ""
echo "  # Linux (script)"
echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
echo ""
echo "  # Or download from: https://github.com/helm/helm/releases"
