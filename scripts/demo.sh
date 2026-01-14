#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Stencil End-to-End Document Generation Demo"
echo "=========================================================="

mkdir -p dist

cat << 'EOF' > dist/sample_vector.svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600" width="800" height="600">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#38bdf8" />
      <stop offset="100%" stop-color="#3b82f6" />
    </linearGradient>
  </defs>
  <rect width="800" height="600" fill="#0f1117" />
  <rect x="50" y="50" width="700" height="500" rx="16" fill="#161922" stroke="#2e3447" stroke-width="2" />
  <path d="M 120 400 C 220 150, 480 120, 680 420" fill="none" stroke="url(#grad1)" stroke-width="6" stroke-linecap="round" />
  <circle cx="120" cy="400" r="8" fill="#38bdf8" />
  <circle cx="680" cy="420" r="8" fill="#3b82f6" />
  <text x="80" y="110" font-family="system-ui, sans-serif" font-size="28" font-weight="bold" fill="#f1f5f9">Stencil Document Engine</text>
  <text x="80" y="145" font-family="system-ui, sans-serif" font-size="14" fill="#94a3b8">Pure ActionScript 3 Vector Pipeline &amp; Computational Geometry</text>
</svg>
EOF

echo "Generated: dist/sample_vector.svg"
echo "Demo complete."
