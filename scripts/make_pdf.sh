#!/usr/bin/env bash
# Render a week's brief HTML to PDF with headless Chrome, then make a PNG preview of page 1.
# Usage: scripts/make_pdf.sh 2026-10-05
set -euo pipefail
DATE="${1:?usage: make_pdf.sh YYYY-MM-DD}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/briefs/$DATE/brief.html"
OUT="$ROOT/pdfs/thegapbrief-$DATE.pdf"
CHROME="$(command -v google-chrome || command -v chromium || command -v chromium-browser)"
mkdir -p "$ROOT/pdfs" "$ROOT/previews"
"$CHROME" --headless=new --no-sandbox --disable-gpu --no-pdf-header-footer \
  --run-all-compositor-stages-before-draw --virtual-time-budget=5000 \
  --print-to-pdf="$OUT" "file://$SRC" 2>/dev/null
pdfinfo "$OUT" | grep -E "Pages|Page size"
pdftoppm -png -r 110 -f 1 -l 1 -singlefile "$OUT" "$ROOT/previews/thegapbrief-$DATE-p1"
echo "PDF: $OUT"
echo "PNG: $ROOT/previews/thegapbrief-$DATE-p1.png"
