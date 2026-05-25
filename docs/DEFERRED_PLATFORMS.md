# Deferred platforms

Checkpoint v1.0 ships **iPhone-only**. Apple Watch and iPad support exist in the codebase but are intentionally not shipped — they'll be re-enabled once each platform's UX is properly polished.

Last deferred: 2026-05-25 (between build 3 and build 4).

---

## What was deferred

### Apple Watch
- Companion watch app, watch widget extension, and watch tests targets exist in the Xcode project.
- The iOS app target **no longer embeds** the Watch app (build 4+), so the shipped binary contains no Watch content.
- `WatchSessionService` in the iOS app still compiles and activates `WCSession`; it just won't find a paired-and-installed Watch counterpart, so `isWatchReachable` stays `false` and outbound messages no-op. Guarded by `WCSession.isSupported()`.

### iPad
- All iPhone-side targets are set to `TARGETED_DEVICE_FAMILY = 1` (iPhone only).
- iPad users can still install via the "iPhone & iPad Apps" filter, but the App Store listing advertises iPhone only and no iPad-specific layouts are claimed.

---

## Why deferred

The user wants dedicated time to design each platform properly before shipping:
- **Watch:** the complication and watch app need a UX pass beyond "iPhone screens shrunk down."
- **iPad:** no iPad-specific layouts exist yet — running the iPhone binary in compatibility mode on an iPad would look unfinished.

Shipping v1.0 as iPhone-only avoids putting a half-finished experience on either platform.

---

## How to restore

### Restore Apple Watch embedding

Edit `apps/checkpoint/ios/checkpoint.xcodeproj/project.pbxproj`, find the `checkpoint` native target (search for `5AAAA9262F2084320002A8C6 /* checkpoint */`), and re-add two lines:

In `buildPhases`:
```
5ACB1F642F37C25D00714E55 /* Embed Watch Content */,
```
(insert after `5AB6697A2F2687FD0036D71B /* Embed Foundation Extensions */,`)

In `dependencies`:
```
5ACB1F932F37C5CA00714E55 /* PBXTargetDependency */,
```
(insert after `5AB669742F2687FD0036D71B /* PBXTargetDependency */,`)

The build-phase definition (lines ~101–110) and the orphan target dependency (lines ~800–804) were left intact in the file, so no other changes are needed.

On the ASC side: upload Apple Watch screenshots (410×502 px for Series 10/11), add Watch to the supported-devices listing, and update marketing copy.

### Restore iPad support

In the same `project.pbxproj`, replace all 8 iPhone-side target entries:
```
TARGETED_DEVICE_FAMILY = 1;
```
with:
```
TARGETED_DEVICE_FAMILY = "1,2";
```
(Some entries may currently render unquoted as `= 1;` after Xcode normalization — both forms are valid; the quoted form `"1,2"` is required when including iPad.)

Then audit every screen for iPad layout (sheet widths, split views, keyboard handling) and upload iPad-specific screenshots to ASC.

---

## Don't change while deferred

- `apps/checkpoint/ios/CheckpointWatch/` — Watch app source, leave intact.
- `apps/checkpoint/ios/CheckpointWatchWidget/` — Watch widget source, leave intact.
- `apps/checkpoint/ios/CheckpointWatchTests/` — Watch tests, leave intact.
- `apps/checkpoint/ios/checkpoint/Services/WatchConnectivity/WatchSessionService.swift` — iOS-side session service, leave intact (compiles fine standalone).

When re-enabling, do not touch the build-phase / dependency definitions — only the references in the `checkpoint` target's `buildPhases` / `dependencies` arrays.
