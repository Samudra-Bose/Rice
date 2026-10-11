#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Launching Rice Prototype..."
echo "Command: qs -p \"${PROJECT_ROOT}/shell/core\""
exec qs -p "${PROJECT_ROOT}/shell/core"
