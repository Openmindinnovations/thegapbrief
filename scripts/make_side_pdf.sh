#!/usr/bin/env bash
# Render a Side Report to PDF with headless Chrome, plus PNG previews of every page (previews/side-<slug>-N.png).
# Usage: scripts/make_side_pdf.sh SLUG
set -euo pipefail
SLUG="${1:?usage: make_side_pdf.sh SLUG}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/briefs/side/$SLUG/report.html"
OUT="$ROOT/pdfs/side/$SLUG.pdf"
[[ -f "$SRC" ]] || { echo "missing $SRC (run scripts/new_side.sh first)"; exit 1; }
if grep -qE '\{\{|example\.com|>…<' "$SRC"; then echo "WARNING: template placeholders still present in $SRC"; fi
CHROME="$(command -v google-chrome || command -v chromium || command -v chromium-browser)"
mkdir -p "$ROOT/pdfs/side" "$ROOT/previews"
rm -f "$OUT" "$ROOT"/previews/side-"$SLUG"-*.png
"$CHROME" --headless=new --no-sandbox --disable-gpu --no-pdf-header-footer \
  --run-all-compositor-stages-before-draw --virtual-time-budget=5000 \
  --print-to-pdf="$OUT" "file://$SRC" 2>/dev/null
[[ -s "$OUT" ]] || { echo "PDF render failed"; exit 1; }
PAGES=$(pdfinfo "$OUT" | awk '/^Pages/{print $2}')
LINKS=$(pdfinfo -url "$OUT" 2>/dev/null | grep -c http || true)
echo "Pages: $PAGES   Links: $LINKS"
pdftoppm -png -r 70 "$OUT" "$ROOT/previews/side-$SLUG"
echo "PDF: $OUT"
echo "PNGs: $ROOT/previews/side-$SLUG-*.png   <- open and check every page"
