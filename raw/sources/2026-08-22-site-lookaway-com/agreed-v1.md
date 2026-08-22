# Open Look Away — agreed v1

Settled 2026-08-22. Ratified 2026-08-22. This is the plan.

Stop the gauntlet when every In-v1 line exists in a running Mac app. Do not keep looping for polish after that.
Assets (icon, overlay art, copy) are generated in-session with Grok Imagine / generate_image, then locked into the repo. The run does not invent a new look.

## Product

Open Look Away is a free, open-source, Mac-native break reminder.

On the surface it should read as a LookAway clone: calm, native, menu-bar, same job.

Beast Mode is an opt-in switch. When it is on, each break also tells you to do N push-ups. That overlay is the only loud, fiery moment. The rest of the app stays calm.

## Design

- Default chrome: quiet native Mac. Follow system materials, SF Pro, semantic colors, menu-bar extra.
- Clone the LookAway interaction shape: heads-up toast, cursor countdown, full-screen break, skip/snooze.
- Do not copy LookAway’s name, icon, trademarked copy, or screenshots into the shipping app.
- Beast Mode overlay: heat, energy, fire. Same break engine. Different voice and motion.
- Generate our own icon, sounds, and copy.

## In v1

- Focused-time short breaks and periodic long breaks
- Heads-up toast (~1 min) then a cursor-following countdown
- Full-screen break overlay on every display
- Smart pause: typing/dragging, idle/away, mic or camera (meetings), video playback, user app denylist
- Skip/snooze with Casual / Balanced / Hardcore
- Menu bar live status + Quick Look-style panel
- Office hours
- Beast Mode toggle: honor-system push-ups on each break (pick N, tap Done)
- Local only. No telemetry. No license.

## Out of v1

- Camera rep counting
- iPhone / iPad lock
- Screen Score and website stats
- Planned breaks
- AppleScript / Shortcuts
- Windows
- Localization beyond system language if free

## Defaults (correct these if wrong)

- Eyes: 20 min focused / 20 sec break (20-20-20)
- Long break: 5 min every 3rd short
- Beast Mode push-ups: 10
- License: MIT
