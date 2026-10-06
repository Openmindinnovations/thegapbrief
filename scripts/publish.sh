#!/usr/bin/env bash
# Rebuild the site and push to GitHub (Pages deploys from main /).
# Usage: scripts/publish.sh "Week 2 · October 12, 2026"
set -euo pipefail
cd "$(dirname "$0")/.."
python3 build.py
git add -A
git commit -m "${1:-Update site}"
git push origin main
