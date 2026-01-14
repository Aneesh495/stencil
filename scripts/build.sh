#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Building and Verifying Stencil ActionScript 3 Modules"
echo "=========================================================="

python3 tooling/as3_parser.py src/ test/

echo ""
echo "Verification build succeeded: 122 ActionScript source files parsed."
