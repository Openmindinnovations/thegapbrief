#!/usr/bin/env bash
# Scaffold a new issue: briefs/<date>/brief.html from the template, and print a weeks.json stub.
# Usage: scripts/new_week.sh YYYY-MM-DD "Week 2" "October 5 – October 12, 2026"
#        scripts/new_week.sh 2026-10-06 "Preview issue" "October 1 – October 6, 2026"
set -euo pipefail
DATE="${1:?usage: new_week.sh YYYY-MM-DD LABEL COVERING}"; LABEL="${2:?label, e.g. \"Week 2\"}"; COVERING="${3:?covering range}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATE_LABEL="$(date -d "$DATE" '+%B %-d, %Y')"
DEST="$ROOT/briefs/$DATE/brief.html"
[[ -e "$DEST" ]] && { echo "exists: $DEST (not overwriting)"; exit 1; }
mkdir -p "$(dirname "$DEST")"
sed -e "s/{{LABEL}}/$LABEL/g" -e "s/{{DATE_LABEL}}/$DATE_LABEL/g" -e "s/{{COVERING}}/$COVERING/g" "$ROOT/briefs/_template.html" > "$DEST"
WEEKNUM=$(python3 -c "import json;w=[x['week'] for x in json.load(open('$ROOT/weeks.json'))['weeks'] if isinstance(x.get('week'),int)];print(max(w)+1 if w else 1)")
echo "created $DEST"
echo "Add this to the \"weeks\" array in weeks.json (edit title/summary/mascot_says; for a preview set \"preview\": true and keep a label):"
cat <<JSON
    {
      "week": $WEEKNUM,
      "label": "$LABEL",
      "date": "$DATE",
      "date_label": "$DATE_LABEL",
      "covering": "$COVERING",
      "title": "",
      "summary": "",
      "mascot_says": "",
      "pdf": "pdfs/thegapbrief-$DATE.pdf",
      "source": "briefs/$DATE/brief.html"
    }
JSON
