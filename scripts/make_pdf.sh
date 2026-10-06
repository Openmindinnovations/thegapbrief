#!/usr/bin/env bash
# Render a week's brief HTML to PDF with headless Chrome, then make a PNG preview of page 1.
# Usage: scripts/make_pdf.sh 2026-10-05
set -euo pipefail
DATE="${1:?usage: make_pdf.sh YYYY-MM-DD}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/briefs/$DATE/brief.html"
OUT="$ROOT/pdfs/thegapbrief-$DATE.pdf"
PNG="$ROOT/previews/thegapbrief-$DATE-p1"
[[ -f "$SRC" ]] || { echo "missing $SRC (run scripts/new_week.sh first)"; exit 1; }
if grep -qE '\{\{|HEADLINE-STYLE TITLE|example\.com|>…<' "$SRC"; then
  echo "WARNING: template placeholders still present in $SRC"
fi
CHROME="$(command -v google-chrome || command -v chromium || command -v chromium-browser)"
mkdir -p "$ROOT/pdfs" "$ROOT/previews"
rm -f "$OUT"
"$CHROME" --headless=new --no-sandbox --disable-gpu --no-pdf-header-footer \
  --run-all-compositor-stages-before-draw --virtual-time-budget=5000 \
  --print-to-pdf="$OUT" "file://$SRC" 2>/dev/null
[[ -s "$OUT" ]] || { echo "PDF render failed"; exit 1; }
PAGES=$(pdfinfo "$OUT" | awk '/^Pages/{print $2}')
LINKS=$(pdfinfo -url "$OUT" 2>/dev/null | grep -c http || true)
echo "Pages: $PAGES   Links: $LINKS"
(( PAGES >= 3 && PAGES <= 6 )) || echo "NOTE: $PAGES pages (full issues target 3–6; fine for a light/preview issue)"
pdftoppm -png -r 110 -f 1 -l 1 -singlefile "$OUT" "$PNG"
echo "PDF: $OUT"
echo "PNG: $PNG.png   <- open this and check the layout"
