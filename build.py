#!/usr/bin/env python3
"""Build TheGapBrief static site from weeks.json.

Generates:
  index.html                  home page (newest week featured, archive below)
  weeks/<date>/index.html     per-week page (outline + embedded PDF)
  feed.xml                    simple RSS feed

The ranked outline on each week page is extracted from the brief source
(briefs/<date>/brief.html): every <section data-section="gaps|markets|ai">
and the <h3> headlines inside it.
"""
import html, json, os, re, sys
from email.utils import format_datetime
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.abspath(__file__))
SECTIONS = [("gaps", "Gaps", "Missing pieces in real products"),
            ("markets", "Markets", "Emerging in apps and digital products"),
            ("ai", "AI", "The week's key AI updates")]


def read(p):
    with open(os.path.join(ROOT, p), encoding="utf-8") as f:
        return f.read()


def write(p, s):
    full = os.path.join(ROOT, p)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(s)
    print("wrote", p)


def label(w):
    """Display label: explicit "label" (e.g. "Preview issue") or "Week N"."""
    return w.get("label") or f"Week {w['week']}"


def badge(w):
    return '<span class="badge-preview">Preview</span> ' if w.get("preview") else ""


def strip_tags(s):
    return html.unescape(re.sub(r"<[^>]+>", "", s)).strip()


def outline(week):
    """Return {section_key: [headline, ...]} from the brief HTML."""
    src = week.get("source")
    out = {k: [] for k, _, _ in SECTIONS}
    if not src or not os.path.exists(os.path.join(ROOT, src)):
        return out
    doc = read(src)
    for m in re.finditer(r'<section[^>]*data-section="(\w+)"[^>]*>(.*?)</section>', doc, re.S):
        key, body = m.group(1), m.group(2)
        for h in re.finditer(r"<h3>(.*?)</h3>", body, re.S):
            text = re.sub(r'<span class="n">.*?</span>', "", h.group(1), flags=re.S)
            out.setdefault(key, []).append(strip_tags(text))
    return out


def svg(name, cls):
    s = read(f"assets/{name}")
    s = re.sub(r"<\?xml[^>]*>", "", s).strip()
    # unique title ids are not needed for decorative copies
    return s.replace("<svg ", f'<svg class="{cls}" aria-hidden="true" focusable="false" ', 1) if cls != "mascot-hero" \
        else s.replace("<svg ", f'<svg class="{cls}" ', 1)


def page(title, body, prefix, description):
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<meta name="description" content="{html.escape(description)}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,700&family=Fraunces:opsz,wght@9..144,600;9..144,700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{prefix}assets/style.css">
<link rel="icon" href="{prefix}assets/gappy-head.svg" type="image/svg+xml">
<link rel="alternate" type="application/rss+xml" title="TheGapBrief" href="{prefix}feed.xml">
</head>
<body>
{body}
</body>
</html>
"""


def legend():
    return '<ul class="legend">' + "".join(
        f'<li class="sec-{k}"><span class="dot"></span>{lab}<span class="legend-note"> · {note}</span></li>'
        for k, lab, note in SECTIONS) + "</ul>"


def counts(o):
    return '<ul class="counts">' + "".join(
        f'<li class="sec-{k}"><span class="dot"></span>{len(o.get(k, []))} {lab}</li>' for k, lab, _ in SECTIONS) + "</ul>"


def footer(prefix, site):
    return f"""<footer class="site-footer">
  <div class="wrap footer-inner">
    {svg('gappy-head.svg', 'mascot-mini')}
    <p>Gappy checks the gaps every Monday. <a href="{prefix}feed.xml">RSS</a> · Published by {html.escape(site['publisher'])}.</p>
  </div>
</footer>"""


def header(prefix, site, small=False):
    if small:
        return f"""<header class="site-header small">
  <div class="wrap header-inner">
    <a class="brand" href="{prefix}index.html">{svg('gappy-head.svg', 'mascot-mini')}<span>TheGapBrief</span></a>
    <a class="back" href="{prefix}index.html">← All weeks</a>
  </div>
</header>"""
    return f"""<header class="site-header">
  <div class="wrap hero">
    <div class="hero-text">
      <h1 class="brand-title">TheGapBrief</h1>
      <p class="tagline">{html.escape(site['tagline'])}</p>
      {legend()}
    </div>
    <div class="hero-mascot">
      {svg('gappy.svg', 'mascot-hero')}
      <p class="mascot-name">Meet <strong>Gappy</strong>, our scout fox.</p>
    </div>
  </div>
</header>"""


def build_home(site, weeks):
    prefix = ""
    feat, rest = weeks[0], weeks[1:]
    o = outline(feat)
    featured = f"""<section class="featured" aria-labelledby="latest">
  <p class="eyebrow" id="latest">{badge(feat)}Latest · {label(feat)} · <time datetime="{feat['date']}">{feat['date_label']}</time></p>
  <article class="card card-featured">
    <div class="card-body">
      <h2><a href="weeks/{feat['date']}/index.html">{html.escape(feat['title'])}</a></h2>
      <p class="summary">{html.escape(feat['summary'])}</p>
      {counts(o)}
      <div class="actions">
        <a class="btn btn-primary" href="{feat['pdf']}" download>Download PDF</a>
        <a class="btn btn-ghost" href="weeks/{feat['date']}/index.html">Read online →</a>
      </div>
    </div>
    <aside class="says">
      {svg('gappy-head.svg', 'mascot-small')}
      <p><span class="says-label">Gappy says</span>“{html.escape(feat.get('mascot_says', ''))}”</p>
    </aside>
  </article>
</section>"""
    if rest:
        cards = "".join(f"""
    <article class="card card-archive">
      <p class="eyebrow">{badge(w)}{label(w)} · <time datetime="{w['date']}">{w['date_label']}</time></p>
      <h3><a href="weeks/{w['date']}/index.html">{html.escape(w['title'])}</a></h3>
      <p class="summary">{html.escape(w['summary'])}</p>
      <div class="actions">
        <a class="btn btn-small" href="{w['pdf']}" download>Download PDF</a>
        <a class="link" href="weeks/{w['date']}/index.html">Read →</a>
      </div>
    </article>""" for w in rest)
        archive = f'<div class="archive-grid">{cards}\n  </div>'
    else:
        archive = f"""<div class="empty">
    {svg('gappy-head.svg', 'mascot-small')}
    <p>This is the first issue. Earlier weeks will collect here, one every Monday.</p>
  </div>"""
    body = f"""{header(prefix, site)}
<main class="wrap">
{featured}
<section class="archive" aria-labelledby="archive-h">
  <h2 class="section-title" id="archive-h">Earlier weeks</h2>
  {archive}
</section>
</main>
{footer(prefix, site)}"""
    write("index.html", page(f"{site['name']}: weekly product gaps, emerging markets, and AI updates", body, prefix, site["tagline"]))


def build_week(site, w, newer, older):
    prefix = "../../"
    o = outline(w)
    blocks = ""
    for k, lab, note in SECTIONS:
        items = o.get(k, [])
        if not items:
            continue
        lis = "".join(f"<li>{html.escape(t)}</li>" for t in items)
        blocks += f"""
    <div class="outline-block sec-{k}">
      <h3><span class="chip">{lab}</span>{note}</h3>
      <ol>{lis}</ol>
    </div>"""
    pdf = prefix + w["pdf"]
    nav = '<nav class="week-nav">'
    nav += f'<a href="{prefix}weeks/{newer["date"]}/index.html">← {label(newer)}</a>' if newer else "<span></span>"
    nav += f'<a href="{prefix}weeks/{older["date"]}/index.html">{label(older)} →</a>' if older else "<span></span>"
    nav += "</nav>"
    body = f"""{header(prefix, site, small=True)}
<main class="wrap week-page">
  <p class="eyebrow">{badge(w)}{label(w)} · <time datetime="{w['date']}">{w['date_label']}</time> · covering {html.escape(w.get('covering', ''))}</p>
  <h1 class="week-title">{html.escape(w['title'])}</h1>
  <p class="summary lead">{html.escape(w['summary'])}</p>
  <div class="actions">
    <a class="btn btn-primary" href="{pdf}" download>Download PDF</a>
    <a class="btn btn-ghost" href="{pdf}" target="_blank" rel="noopener">Open PDF in a new tab</a>
  </div>
  <aside class="says says-inline">
    {svg('gappy-head.svg', 'mascot-small')}
    <p><span class="says-label">Gappy says</span>“{html.escape(w.get('mascot_says', ''))}”</p>
  </aside>
  <section class="outline" aria-labelledby="outline-h">
    <h2 class="section-title" id="outline-h">This week at a glance <span class="muted">ranked, most important first</span></h2>
    <div class="outline-grid">{blocks}
    </div>
  </section>
  <section class="reader" aria-labelledby="reader-h">
    <h2 class="section-title" id="reader-h">Read the full brief</h2>
    <object class="pdf-frame" data="{pdf}#view=FitH" type="application/pdf" aria-label="TheGapBrief {label(w)} PDF">
      <div class="pdf-fallback">
        <p>Your browser can’t show the PDF here.</p>
        <a class="btn btn-primary" href="{pdf}" download>Download PDF</a>
      </div>
    </object>
  </section>
  {nav}
</main>
{footer(prefix, site)}"""
    write(f"weeks/{w['date']}/index.html",
          page(f"{label(w)} · {w['date_label']}: {w['title']} | {site['name']}", body, prefix, w["summary"]))


def build_feed(site, weeks):
    items = ""
    for w in weeks:
        d = datetime.strptime(w["date"], "%Y-%m-%d").replace(hour=12, tzinfo=timezone.utc)
        link = f"{site['url']}/weeks/{w['date']}/"
        items += f"""
  <item>
    <title>{html.escape(label(w))} · {html.escape(w['date_label'])}: {html.escape(w['title'])}</title>
    <link>{link}</link>
    <guid>{link}</guid>
    <pubDate>{format_datetime(d)}</pubDate>
    <description>{html.escape(w['summary'])}</description>
    <enclosure url="{site['url']}/{w['pdf']}" type="application/pdf" length="{os.path.getsize(os.path.join(ROOT, w['pdf'])) if os.path.exists(os.path.join(ROOT, w['pdf'])) else 0}"/>
  </item>"""
    write("feed.xml", f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel>
  <title>{site['name']}</title>
  <link>{site['url']}/</link>
  <description>{html.escape(site['tagline'])}</description>{items}
</channel></rss>
""")


def main():
    data = json.loads(read("weeks.json"))
    site = data["site"]
    weeks = sorted(data["weeks"], key=lambda w: w["date"], reverse=True)
    missing = [w["pdf"] for w in weeks if not os.path.exists(os.path.join(ROOT, w["pdf"]))]
    if missing:
        sys.exit(f"missing PDF(s): {missing}")
    build_home(site, weeks)
    for i, w in enumerate(weeks):
        build_week(site, w, weeks[i - 1] if i > 0 else None, weeks[i + 1] if i + 1 < len(weeks) else None)
    build_feed(site, weeks)


if __name__ == "__main__":
    main()
