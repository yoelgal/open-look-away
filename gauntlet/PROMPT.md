This is a Gauntlet Loop prompt - run it here, directly; do not route it into a planning or foundation skill, the method it needs is below.

workflowz

Build Open Look Away: a free MIT Mac-native menu-bar break reminder that reads as a calm LookAway clone, with opt-in Beast Mode that adds honor-system push-ups to each break. Work only inside `/Users/yoelgal/Developer/open-look-away`. No credentials, no deploys, no network calls except Apple frameworks and in-repo generate_image for missing assets. The plan is `raw/sources/2026-08-22-site-lookaway-com/agreed-v1.md`. Locked look is `raw/sources/2026-08-22-site-lookaway-com/media/mockups/` (icon, quick-look, calm-break, beast-break). Product evidence is `raw/sources/2026-08-22-site-lookaway-com/article.md`.

Bar rows, graded separately:
1. behavioral — every In-v1 line in agreed-v1.md exists in a running Mac app; Out-of-v1 lines must stay absent. Critic launches the app and tries to prove a listed line is missing or an out-of-v1 line shipped.
2. visual — default chrome matches the quiet native Quick Look and calm-break mockups; Beast Mode overlay matches beast-break.png (full-screen, no window traffic lights). LookAway.com is the interaction-shape bar (heads-up, cursor countdown, overlay, skip ladder), not the brand. Delta: own name, icon, copy; Beast Mode fire. Do not report those deltas as gaps.
3. security — local only, no telemetry, no license server. Critic greps the tree and the running binary's traffic for Mixpanel, Stripe, analytics, or license checks.

House rules: Swift/SwiftUI native Mac, macOS 13+; MIT; no LookAway name, icon, or copy in the shipping app; do not invent a new look once mockups exist; Beast Mode is a toggle, honor-system N tap Done, default N=10; eyes default 20m/20s, long break 5m every 3rd; generate any missing icon/sound with generate_image (provider xai) and lock it in the repo. Stop when every In-v1 line exists in a running Mac app. Do not keep looping for polish after that.

Carve the work into the smallest units you can improve and grade independently — the split is yours, and each unit names the bar row it answers to. Fan them out to subagents: one builder and one critic per unit, the critic starting from a clean context with the artifact and that unit's bar row and nothing else, trying to prove the artifact fails that row — side by side and blind where the row is the LookAway interaction shape, never on the named deltas. Keep looping until the stop condition. Use workflowz.

The run appends one block per round to a single run-local record file - round number, one state word per unit (BUILDING, JUDGING, WAITING, STUCK), the critic's named gap, spend so far against the ceiling - and the progress page is a self-refreshing renderer over that file, never a second memory. A fork the house rules do not settle writes that unit's block WAITING with the question and two candidate answers, advances the other units, and reads the answer file at each round boundary. When the stop condition hits, your last act is the return report: two paragraphs on what I now have and what it cannot do yet, then one line per unit naming its bar row and the round its last gap closed.
