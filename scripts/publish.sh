#!/usr/bin/env bash
# Rebuild the site and push to GitHub (Pages deploys from main /).
# Usage: scripts/publish.sh "Week 2 · October 12, 2026"
set -euo pipefail
cd "$(dirname "$0")/.."
python3 build.py
git add -A
if git diff --cached --quiet; then echo "nothing to commit"; else git commit -m "${1:-Update site}"; fi
git pull --rebase --quiet origin main
git push origin main
echo "Pushed. Pages usually deploys in 1–2 minutes; then run scripts/verify.sh <date>."
