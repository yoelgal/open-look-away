---
title: LookAway product site
type: site
author: Kushagra Agarwal / Mystical Bits, LLC
url: https://lookaway.com/
date: 2026-08-22
captured: 2026-08-22
extraction: reader-mode HTML + headless Chromium screenshots + official product images
tags:
  - lookaway
  - break-reminder
  - macos
  - competitor
  - product-spec
feeds: Product definition for an open-source free LookAway alternative. Best content is on rungs 2 and 5: settings screenshots and the author's "less annoying" design essay.
---

# LookAway (lookaway.com)

Native macOS break reminder. Current ship is **v2.4.2**, macOS 13+. Paid: $19 / $29 / $29-per-seat. Windows listed as coming soon.

## Depth ladder

1. Canonical text - CAPTURED. Homepage, pricing, manifesto, download, docs index + intro/setup/scheduling/planned-breaks/smart-pause/stats/automations/focus-filters/mobile-sync, changelog through 2.4.2, compare index, privacy, product posts (2.0, 2.2-2.4, how-I-made-break-reminders-less-annoying, 2026 Mac break-app roundup).
2. Media - CAPTURED. Full-page homepage and pricing screenshots; settings, Smart Pause, stats, Quick Look, and iPhone Mirror images transcribed. Hero/posture/blink videos noted, not frame-extracted.
3. Conversation - SKIPPED: out of assigned scope. Discord, X, and App Store review threads not crawled. One HN comment captured (`item?id=37934001`): mic/camera meeting detection suggested Oct 2023; author `_kush` said he would try it.
4. Linked payloads - CAPTURED. GitHub releases repo is DMG-only (`mysticalbits/lookaway-releases`). App Store id `6747192301`. Mirror app id `6748218279`. Stripe + Mixpanel named in privacy. Competitors listed on `/compare` and the 2026 roundup.
5. Author's rationale - CAPTURED. Manifesto; `How I Made Break Reminders Less Annoying` (2025-04-07); changelog 2.0–2.4.2. Core thesis: treat breaks as interruptions; only good interruptions are ones you do not mind.
6. Reception - CAPTURED. On-site testimonials (The Verge installer newsletter, Easlo, Victoria Peña, etc.). Author claims 1,500 DAU as of Apr 2025. App Store / Discord sentiment not fetched.
7. Negative space - CAPTURED. Closed source. Mixpanel analytics (opt-out in Settings → About). No Linux. Windows promised, not shipped. No public API beyond AppleScript. App Store Firefox website-stats gap. License lock and seat model. No security writeup beyond privacy policy.

## FEEDS

Use `article.md` as the product brief for `/groundwork`. Do not copy LookAway assets, copy, or trademarks into the product. The useful steal is the **behavior**: context-aware pause, heads-up then floating countdown, skip-difficulty ladder, short+long breaks, posture/blink as separate nudges.

## Pages read

- https://lookaway.com/
- https://lookaway.com/pricing/
- https://lookaway.com/manifesto/
- https://lookaway.com/download/
- https://lookaway.com/changelog/
- https://lookaway.com/compare/
- https://lookaway.com/privacy/
- https://lookaway.com/docs/ and the Deep Dive docs listed above
- https://lookaway.com/blog/2025/04/07/how-i-made-break-reminders-less-annoying/
- https://lookaway.com/blog/2026/04/07/lookaway-20-screen-score-liquid-glass-and-more/
- https://lookaway.com/blog/2026/04/24/best-break-reminder-apps-for-mac-in-2026/
- sitemap.xml (full URL inventory)

## Media transcribed

| File | What it shows |
| --- | --- |
| `media/homepage-full.webp` | Cream page, navy italic "body", hero Mac window, three claims |
| `media/pricing-full.webp` | $19 / $29 / $29 seat cards, Believer $99 |
| `media/settings-screenshot.jpg` | Settings IA + Screen Breaks + Casual/Balanced/Hardcore |
| `media/docs-break-settings.jpg` | Same window, snoozes=3, lock-Mac toggle |
| `media/docs-work-mode.jpg` | Smart Pause toggles + idle tracking |
| `media/blog-quick-look.jpg` | Menu-bar Quick Look: timer, snooze, score 100 |
| `media/blog-stats.jpg` | Screen Score 100, natural vs LookAway breaks, app list |
| `media/iphone-display.png` | Mirror lock: "Relax those eyes" |

## Visual system (from screenshots)

- Marketing site: warm off-white, near-black navy type, one italic accent word, rounded navy Download pill, no dark hero.
- App: dark liquid-glass panels, magenta section icons, orange-pink skip-enforcement cards, purple stats gauges.
- Break heads-up: compact dark toast, countdown, "Almost time…", Start now / +1m / +5m / +15m.
- iPhone Mirror: full-screen dim lock, custom message, single OK (blocked until Mac break ends).
