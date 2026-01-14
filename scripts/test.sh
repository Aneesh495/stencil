#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Running Stencil ActionScript 3 Test Suite"
echo "=========================================================="

python3 tooling/run_tests.py
