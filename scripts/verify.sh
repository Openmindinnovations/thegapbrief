#!/usr/bin/env bash
# Verify the live site, a week page, and its PDF; waits up to ~3 min for Pages to deploy.
# Usage: scripts/verify.sh 2026-10-05 [base_url]
# Note: a plain (non-cache-busted) load of the home page can show the old version for up to 10 minutes.
set -uo pipefail
DATE="${1:?usage: verify.sh YYYY-MM-DD [base_url]}"
BASE="${2:-https://thegapbrief.com}"
# GitHub Pages' CDN caches HTML (max-age=600) and edges can disagree right after a deploy,
# so require 3 consecutive cache-busted hits before checking.
hits=0
for i in $(seq 1 30); do
  if curl -sL -H 'Cache-Control: no-cache' "$BASE/?v=$RANDOM$i" | grep -q "weeks/$DATE/"; then
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
check "$BASE/" "text/html"
check "$BASE/weeks/$DATE/" "text/html"
check "$BASE/pdfs/thegapbrief-$DATE.pdf" "application/pdf"
check "$BASE/feed.xml" ""
curl -sL -H "Cache-Control: no-cache" "$BASE/?v=final$RANDOM" | grep -q "weeks/$DATE/" && echo "OK: home lists $DATE" || { echo "FAIL: home does not list $DATE"; ok=1; }
exit $ok
