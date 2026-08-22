# LookAway — captured product brief

Source: lookaway.com as of 2026-08-22. Author: Kushagra Agarwal, Mystical Bits, LLC.

This is evidence from their site, not a spec we have to copy. Open Look Away should be free and open source. Do not reuse their name, icon, copy, or screenshots in the product.

## One-line

A native Mac menu-bar app that reminds you to look away from the screen, and tries not to interrupt you at a bad moment.

## Differentiating idea (theirs)

Breaks are interruptions. The only good interruption is one you do not mind. Timing and control beat more features.

Quoted from the 2025-04-07 essay:

> I started thinking of breaks not as timers, but as interruptions. And the only good interruptions are the ones you don’t mind.

> If you’re forced into taking a break when you’re not ready, the app feels like a dictator.

## What it does

### Screen breaks

- Timer counts **focused screen time**, not wall clock.
- Short break after N minutes (docs examples: 15–45 min work, 15–45 sec break).
- Long break every Nth short break (example: every 3rd break is 5 minutes).
- Planned breaks at a fixed clock time (lunch, walk). Independent of office hours. Suppress nearby regular breaks. 1 min–2 hours. Weekly recurrence. Do not affect streak.
- On-demand break from menu bar, shortcut, or AppleScript (2.3).
- Advance skip of the next break, with a daily cap (2.3).

Preset modes from docs:

| Mode | Screen time | Break | Long break |
| --- | --- | --- | --- |
| Balanced | 20 min | 20 sec | off |
| Deep Focus | 45 min | 30 sec | 5 min every 3 shorts |
| Eye Care | 15 min | 15 sec | 3 min every 4 shorts |
| Wellness | 25 min | 45 sec | 5 min every 2 shorts |

### Heads-up, then break

1. Reminder ~1 minute before (default stay 10s). Toast: countdown, message, Start now, +1m / +5m / +15m.
2. Floating countdown 5–10s before, follows the cursor.
3. Full break screen: custom background (image, gradient, or animated), custom message, optional sound. Fade in. Soft chime on end.

### Skip discipline

Three levels, shown as cards in Settings → Screen Breaks:

- **Casual** — skip anytime
- **Balanced** — skip button disabled for a few seconds
- **Hardcore** — no skip before or during

Also:

- Snooze cap per day and per session
- Double-Escape action (e.g. snooze 5 min)
- “End break early if nearly done” (Skip becomes End after enough time)
- Optional lock Mac when a break starts
- 2.3.1: a skip does not hurt Screen Score if you take a full break within 5 minutes

### Smart Pause (the product)

Do not show a break while:

- Typing or dragging (optional; dictation treated like typing)
- Meetings/calls — mic or camera in use; per-device and per-app exclusions
- Video playback — frontmost only, or background too; exclude editors/music apps
- Calendar events
- Deep-focus apps — fullscreen / foreground / any-open
- Fullscreen games
- Screen recording or sharing
- macOS Focus Filters
- Manual pause

After the activity ends: configurable cooldown (example: 1 minute). Post-meeting grace so notes are not punished.

Idle / away (2.3 rewrite):

- Stepping away no longer blocks you with a dialog on return.
- App guesses: count as natural break, resume session, or stay silent if you never left.
- Toast with undo. Menu bar shows how last away time was handled.
- Keep-awake utilities (Caffeine) can fool away-detection; 2.4.x warns.

### Wellness (separate from breaks)

- Posture nudges
- Blink reminders
- Size/position configurable
- Can hide during screen share/record
- Stay on top through Mission Control

### Stats

- Total screen time, break count, longest stretch, typical/median stretch
- LookAway breaks vs natural (idle) breaks vs snoozes
- App usage during active sessions
- Website usage by domain (Safari/Chromium everywhere; Firefox only in standalone/Setapp, needs Accessibility)
- **Screen Score** 0–100: session discipline ≤60 + break adherence ≤40. Starts at 100. Drops on skips and long stretches.

### Surfaces

- Menu bar live status (icon, optional text, paused/stopped/sharing states)
- **Quick Look** mini control center: time to next break, start/snooze, current focus, upcoming break, snoozes left, Screen Score, pause, settings. Keyboard shortcut.
- Break screen on every display
- Lock Screen live widget on macOS Tahoe (2.4)
- iPhone/iPad **LookAway Mirror**: pair code, up to 3 devices per Mac / 5 Macs per phone; locks non-essential apps and sites for the Mac break; Live Activities + Dynamic Island (2.4); needs internet, must stay in background

### Mac-native extras

- Global shortcuts
- Focus Filters
- Follows appearance
- AppleScript + Shortcuts on break start/end (pause Spotify, Slack away, dim, DND, lock)
- Multi-monitor
- Languages in 2.4.x: de, zh-Hans, zh-Hant, fr, ja, ru, uk
- Accessibility in 2.3.1: VoiceOver, keyboard, Reduce Motion, Increase Contrast, Differentiate Without Color

## Settings IA (from screenshots)

```
General
Focus & Wellbeing
  Screen Breaks
  Smart Pause
  Wellness Reminders
Behavior & Feedback
  Alerts / Nudges
  Sounds
  Keyboard Shortcuts
Integrations
  iPhone Sync
  Automation
LookAway
  About
```

Screen Breaks fields seen: show-after (H/M of focused time), break duration, customize break screen, long breaks, office hours, enforcement cards, snoozes/day, double-escape action, end-early toggle, lock-Mac toggle.

Smart Pause fields seen: typing/dragging toggle; meetings, video, calendar, deep-focus, gaming, screen-share (each with Options except share); cooldown after pause; idle tracking Automatic; “Stepped Away?” dialog on return.

## Pricing (theirs — we will not copy this)

- Single $19 / 1 seat / 1 year updates
- Personal $29 / 2 seats
- Team $29/seat, min 5
- Believer $99 / 5 seats / lifetime updates
- Pay once, keep the version forever; renewal 50% off
- Also Mac App Store (different price) and Setapp
- 30% edu on personal
- Windows seats reserved, not shipping

## Privacy (theirs)

- App does not collect PII directly
- Stripe for licenses
- Mixpanel anonymous usage; opt-out Settings → About
- Website: Plausible
- No cookies in the app
- Keyboard activity used locally for typing detection (permission)

## Competitors they name

Time Out, Stretchly (OSS, Electron, unsigned), BreakTimer (OSS), Viraam, DeskRest, Give Me A Break (OSS, local), Take a Break (likely abandoned).

They position against Stretchly/BreakTimer as: free/OSS/cross-platform vs native, signed, smart pause, iPhone lock, blink/posture.

## Negative space / do not blindly clone

- Closed source + paid license
- Mixpanel
- iPhone Mirror as a second paid-adjacent App Store app
- Liquid Glass / Tahoe-only lock widget
- Website usage via Accessibility (invasive; App Store forbids it for Firefox)
- Hardcore “no skip” + auto-lock can feel hostile; they added it because casual skip trains you to ignore
- Health SEO blog is marketing, not product

## Implied v1 for an open clone

Must exist or it is just another timer:

1. Focused-time short + long breaks
2. Heads-up + cursor countdown
3. Smart pause: typing, idle, mic/camera, fullscreen video, user denylist of apps
4. Skip / snooze with a discipline setting
5. Menu bar + a real break overlay
6. Local-only. No analytics. No license.

Can wait: iPhone lock, Screen Score, website stats, planned breaks, AppleScript, localization, lock-screen widgets.

## Verbatim marketing (do not ship this copy)

- H1: “The Mac app your *body* thanks you for”
- “A smart break reminder for your Mac — posture nudges and blink reminders that quietly take care of your screen habits while you work”
- Claims: Less eye strain. Breaks that don’t break your flow. Healthier screen habits, automatically.
- Manifesto close: “Look away. Look away. Look away.”
