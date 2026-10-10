#!/usr/bin/env bash
# Scaffold a Side Report: briefs/side/<slug>/report.html from the side template, and print a side.json stub.
# Usage: scripts/new_side.sh SLUG "Title" [YYYY-MM-DD]     (date defaults to today)
set -euo pipefail
SLUG="${1:?usage: new_side.sh SLUG \"Title\" [YYYY-MM-DD]}"; TITLE="${2:?title}"; DATE="${3:-$(date +%F)}"
[[ "$SLUG" =~ ^[a-z0-9-]+$ ]] || { echo "slug must be lowercase letters, digits, and dashes"; exit 1; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATE_LABEL="$(date -d "$DATE" '+%B %-d, %Y')"
DEST="$ROOT/briefs/side/$SLUG/report.html"
[[ -e "$DEST" ]] && { echo "exists: $DEST (not overwriting)"; exit 1; }
mkdir -p "$(dirname "$DEST")"
python3 - "$ROOT/briefs/side/_template.html" "$DEST" "$TITLE" "$DATE_LABEL" <<'PY'
import sys, html
src, dest, title, dl = sys.argv[1:]
s = open(src, encoding="utf-8").read().replace("{{TITLE}}", html.escape(title)).replace("{{DATE_LABEL}}", dl)
open(dest, "w", encoding="utf-8").write(s)
PY
echo "created $DEST"
echo "Add this to the \"reports\" array in side.json (edit summary/mascot_says):"
cat <<JSON
    {
      "slug": "$SLUG",
      "date": "$DATE",
      "date_label": "$DATE_LABEL",
      "title": "$TITLE",
      "summary": "",
      "mascot_says": "",
      "pdf": "pdfs/side/$SLUG.pdf",
      "source": "briefs/side/$SLUG/report.html"
    }
JSON
