# TheGapBrief

A weekly brief on product gaps, emerging markets, and AI updates. Published by Open Mind Innovations LLC.

- Live: https://thegapbrief.com/ (GitHub Pages; https://openmindinnovations.github.io/thegapbrief/ redirects here)
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
scripts/new_week.sh        scaffold briefs/<date>/brief.html from briefs/_template.html + print weeks.json stub
scripts/make_pdf.sh        brief.html -> PDF (headless Chrome) + page-1 PNG preview in previews/
scripts/publish.sh         build + commit + push
scripts/verify.sh          curl checks against the live site
```

Section color codes are used on both the site and the PDF: **Gaps** coral `#D9573A`, **Markets** teal `#1F8A84`, **AI** violet `#6A55C9`.

## Add a week (weekly job)

Each issue is dated Monday and covers the previous Monday through that Monday. The example below uses `2026-10-12` / Week 2.

1. **Research.** Look for news from the coverage window. The brief has exactly three sections, and items within each are ranked with the most important first. Aim for 5–7 items per section:
   - *Gaps*: a real product, the missing piece, and why neither the product nor its competitors cover it. Back each item with evidence such as complaints, forum threads, changelogs, reviews, or feature-request trackers.
   - *Markets* ("Emerging markets in apps and digital products"): new categories, funding rounds, launches, and regulation that creates demand.
   - *AI*: what changed and why it matters.
   - **Scope (standing rule from Jacob):** sections 1 and 2 cover the whole digital economy, not just AI: consumer and business apps, fintech/payments, commerce/marketplaces, creator tools, gaming, health/fitness apps, productivity, travel, social, devices/smart home, and so on. AI should not dominate sections 1–2; it goes mainly in section 3.
   - Don't repeat items from earlier issues unless there's a genuinely new development.
   - Rules: link a source for every item. Don't invent numbers; only state a figure if a cited source gives it, and attribute it. Leave out anything you can't verify. No hype. Re-check that "this week" news is actually from this week, because aggregators sometimes republish old funding news. Don't pitch the owner's existing projects as new ideas (Kapsoul, iMusement, Hivvly, FlirtFee, Anchor AR, Wash Wizardz, Get UI Now, DeepReach, Fetch).
2. **Scaffold and write the brief.**
   ```bash
   scripts/new_week.sh 2026-10-12 "Week 2" "October 5 – October 12, 2026"
   # creates briefs/2026-10-12/brief.html from briefs/_template.html and prints a weeks.json stub
   ```
   Fill in the `<h1>` headline, intro, the counts in the contents list, and the items. Copy an `<div class="item">` block for each extra item. Keep the structure, because `build.py` reads the outline from it:
   `<section class="s-gaps" data-section="gaps">`, `s-markets`/`markets`, `s-ai`/`ai`, and one `<div class="item"><h3><span class="n">1.1</span>Headline</h3>…</div>` per item.
3. **Render the PDF and check it.**
   ```bash
   scripts/make_pdf.sh 2026-10-12      # -> pdfs/thegapbrief-2026-10-12.pdf and previews/thegapbrief-2026-10-12-p1.png
   ```
   The script warns if template placeholders are left and prints the page and link counts (full issues target 3–6 pages). Open the PNG and check the layout.
4. **Add the entry** printed by `new_week.sh` to the `weeks` array in `weeks.json`, and fill in `title`, `summary`, and `mascot_says`. Order doesn't matter, because the build sorts by date and features the newest.
   - Optional `"label"` overrides the displayed "Week N" text.
   - Previews and test issues: set `"week": "Preview"` (a non-number, so it doesn't use up a week number), `"label": "Preview issue"`, and `"preview": true`. This adds a yellow PREVIEW badge.
5. **Build and publish.**
   ```bash
   scripts/publish.sh "Week 2 · October 12, 2026"   # python3 build.py && git add -A && git commit && git push origin main
   ```
6. **Verify.**
   ```bash
   scripts/verify.sh 2026-10-12     # waits up to ~3 min for Pages, then expects 200s + application/pdf; exits non-zero on failure
   ```
   `publish.sh` does nothing harmful if there is nothing to commit, and it rebases on `origin/main` before pushing.

To remove a preview later, delete its entry from `weeks.json` along with `briefs/<date>/`, `pdfs/thegapbrief-<date>.pdf`, and `weeks/<date>/`, then run `scripts/publish.sh "Remove preview"`.

Requirements on the box: `python3`, `google-chrome` (or chromium), `poppler-utils` (`pdftoppm`, `pdfinfo`), and `git` with push access to `Openmindinnovations/thegapbrief` (via `gh auth`).

## Custom domain (thegapbrief.com)

The domain is live. It's registered at Squarespace Domains, and DNS is on Squarespace nameservers (`nsb1–4.squarespacedns.com`):

- `A @` → 185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153
- `CNAME www` → openmindinnovations.github.io

The repo's `CNAME` file contains `thegapbrief.com`. Keep it. With branch-based Pages, deleting it detaches the custom domain. `build.py` never touches it, and `site.url` in `weeks.json` is `https://thegapbrief.com` (used for the RSS feed). HTTPS is enforced in the Pages settings.

To check the Pages state: `gh api repos/Openmindinnovations/thegapbrief/pages --jq '{cname, https_enforced, cert: .https_certificate.state}'`
