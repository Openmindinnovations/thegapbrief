# TheGapBrief

A weekly brief on product gaps, emerging markets, and AI updates. Published by Open Mind Innovations LLC.

- Live: https://openmindinnovations.github.io/thegapbrief/ (custom domain `thegapbrief.com` is pending DNS, see below)
- Mascot: **Gappy**, the scout fox (`assets/gappy.svg`, `assets/gappy-head.svg`). Both are original, hand-written SVGs.
- Static HTML/CSS. No framework. GitHub Pages serves the `main` branch from the root (`/`).

## Layout

```
weeks.json                 single source of truth for the week list (newest week can be anywhere; build sorts by date)
build.py                   generates index.html, weeks/<date>/index.html, feed.xml from weeks.json
briefs/brief.css           shared PDF stylesheet (palette and section colors match the site)
briefs/<date>/brief.html   the week's report source (rendered to PDF)
pdfs/thegapbrief-<date>.pdf
assets/style.css           site styles
assets/gappy*.svg          mascot
scripts/make_pdf.sh        brief.html -> PDF (headless Chrome) + page-1 PNG preview in previews/
scripts/publish.sh         build + commit + push
scripts/verify.sh          curl checks against the live site
```

Section color codes are used on both the site and the PDF: **Gaps** coral `#D9573A`, **Markets** teal `#1F8A84`, **AI** violet `#6A55C9`.

## Add a week (weekly job)

Each issue is dated Monday and covers the previous Monday through that Monday. The example below uses `2026-10-12` / Week 2.

1. **Research.** Look for news from the coverage window. The brief has exactly three sections, and items within each are ranked with the most important first. Aim for 5–7 items per section:
   - *Gaps*: a real product, the missing piece, and why neither the product nor its competitors cover it. Back each item with evidence such as complaints, forum threads, changelogs, reviews, or feature-request trackers.
   - *Markets*: new categories, funding rounds, launches, and regulation that creates demand.
   - *AI*: what changed and why it matters.
   - Rules: link a source for every item. Don't invent numbers; only state a figure if a cited source gives it, and attribute it. Leave out anything you can't verify. No hype. Re-check that "this week" news is actually from this week, because aggregators sometimes republish old funding news. Don't pitch the owner's existing projects as new ideas (Kapsoul, iMusement, Hivvly, FlirtFee, Anchor AR, Wash Wizardz, Get UI Now, DeepReach, Fetch).
2. **Write the brief.**
   ```bash
   mkdir -p briefs/2026-10-12
   cp briefs/2026-10-05/brief.html briefs/2026-10-12/brief.html
   # edit: <title>, kicker ("TheGapBrief — Week 2 · October 12, 2026"), <h1> headline, dek, intro, items
   ```
   Keep the structure, because `build.py` reads the outline from it:
   `<section class="s-gaps" data-section="gaps">`, `s-markets`/`markets`, `s-ai`/`ai`, and one `<div class="item"><h3><span class="n">1.1</span>Headline</h3>…</div>` per item.
3. **Render the PDF and check it.**
   ```bash
   scripts/make_pdf.sh 2026-10-12      # -> pdfs/thegapbrief-2026-10-12.pdf and previews/thegapbrief-2026-10-12-p1.png
   ```
   Look at the PNG preview. The PDF should run 3–6 pages, and links should be clickable (`pdfinfo -url pdfs/...pdf`).
4. **Add the entry** to the `weeks` array in `weeks.json`:
   ```json
   {
     "week": 2,
     "date": "2026-10-12",
     "date_label": "October 12, 2026",
     "covering": "October 5 – October 12, 2026",
     "title": "Short headline-style title",
     "summary": "One-line summary for the list.",
     "mascot_says": "A light one-liner from Gappy (keep it friendly, no claims).",
     "pdf": "pdfs/thegapbrief-2026-10-12.pdf",
     "source": "briefs/2026-10-12/brief.html"
   }
   ```
5. **Build and publish.**
   ```bash
   scripts/publish.sh "Week 2 · October 12, 2026"   # python3 build.py && git add -A && git commit && git push origin main
   ```
6. **Verify.** Pages takes about 1–2 minutes to deploy.
   ```bash
   scripts/verify.sh 2026-10-12     # expects 200s and application/pdf; exits non-zero on failure
   ```

Requirements on the box: `python3`, `google-chrome` (or chromium), `poppler-utils` (`pdftoppm`, `pdfinfo`), and `git` with push access to `Openmindinnovations/thegapbrief` (via `gh auth`).

## Custom domain (thegapbrief.com)

The domain is registered at Squarespace Domains, and its DNS is hosted on Squarespace nameservers (`nsb1–4.squarespacedns.com`). To point it at GitHub Pages:

1. In Squarespace → Domains → thegapbrief.com → DNS settings, remove the Squarespace default A/CNAME records for `@` and `www`.
2. Add these records:
   - `A @ 185.199.108.153`, `A @ 185.199.109.153`, `A @ 185.199.110.153`, `A @ 185.199.111.153`
   - optional `AAAA @ 2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`
   - `CNAME www openmindinnovations.github.io`
3. Once `dig +short thegapbrief.com` returns the 185.199.x.153 addresses, set the custom domain:
   `gh api -X PUT repos/Openmindinnovations/thegapbrief/pages -f cname=thegapbrief.com`
   (or add a `CNAME` file containing `thegapbrief.com`), then enable HTTPS:
   `gh api -X PUT repos/Openmindinnovations/thegapbrief/pages -F https_enforced=true` (after the certificate is issued).
4. Change `site.url` in `weeks.json` to `https://thegapbrief.com` and republish.

Don't set the custom domain before DNS points at GitHub. If you do, the github.io URL redirects to thegapbrief.com, which would still be serving the Squarespace page.
