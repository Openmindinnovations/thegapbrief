#!/usr/bin/env bash
# Verify the live site, a week page, and its PDF; waits up to ~3 min for Pages to deploy.
# Usage: scripts/verify.sh 2026-10-05 [base_url]          (weekly issue)
#        scripts/verify.sh side SLUG [base_url]           (side report)
# Note: a plain (non-cache-busted) load of the home page can show the old version for up to 10 minutes.
set -uo pipefail
if [[ "${1:-}" == "side" ]]; then
  SLUG="${2:?usage: verify.sh side SLUG [base_url]}"; BASE="${3:-https://thegapbrief.com}"
  NEEDLE="$SLUG/index.html"; HUB="$BASE/side/"
  PAGES=("$BASE/side/" "text/html" "$BASE/side/$SLUG/" "text/html" "$BASE/pdfs/side/$SLUG.pdf" "application/pdf" "$BASE/side/feed.xml" "" "$BASE/" "text/html")
else
  DATE="${1:?usage: verify.sh YYYY-MM-DD [base_url]  |  verify.sh side SLUG [base_url]}"; BASE="${2:-https://thegapbrief.com}"
  NEEDLE="weeks/$DATE/"; HUB="$BASE/"
  PAGES=("$BASE/" "text/html" "$BASE/weeks/$DATE/" "text/html" "$BASE/pdfs/thegapbrief-$DATE.pdf" "application/pdf" "$BASE/feed.xml" "")
fi
# GitHub Pages' CDN caches HTML (max-age=600) and edges can disagree right after a deploy,
# so require 3 consecutive cache-busted hits before checking.
hits=0
for i in $(seq 1 30); do
  page=$(curl -sL -H 'Cache-Control: no-cache' "$HUB?v=$RANDOM$i")   # capture first: curl|grep -q + pipefail = false failures
  if [[ "$page" == *"$NEEDLE"* ]]; then
    hits=$((hits+1)); (( hits >= 3 )) && break; sleep 3
  else
    hits=0; echo "waiting for deploy ($i)…"; sleep 10
  fi
done
ok=0
check() { # url expected_type_prefix
  read -r code ctype < <(curl -sL -o /dev/null -w '%{http_code} %{content_type}\n' "$1")
  printf '%s  %s  %s\n' "$code" "$ctype" "$1"
  [[ "$code" == 200 && "$ctype" == $2* ]] || ok=1
}
for ((j=0; j<${#PAGES[@]}; j+=2)); do check "${PAGES[j]}" "${PAGES[j+1]}"; done
page=$(curl -sL -H "Cache-Control: no-cache" "$HUB?v=final$RANDOM")
[[ "$page" == *"$NEEDLE"* ]] && echo "OK: $HUB lists $NEEDLE" || { echo "FAIL: $HUB does not list $NEEDLE"; ok=1; }
exit $ok
