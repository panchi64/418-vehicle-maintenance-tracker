# Surface Doctrine

How screens are **structured**: how information is ranked, how decisions are asked for, and what must be true before a surface ships.

[`AESTHETIC.md`](AESTHETIC.md) covers what things look like. This document covers whether they can be used. When the two conflict, check the tag: an aesthetic **[PREFERENCE]** never overrides a usability **[REQUIREMENT]** here.

**Read Part 1 before designing any screen.** Read Part 2 to classify the screen you're building. Read Part 3 before opening a PR.

---

# Part 1 — Foundations

Generic principles. They would hold for any application in any visual style, and they are deliberately written so they cannot be read as endorsing one particular look.

## Visual hierarchy

**Rank before you style.** Sort the content into primary / secondary / tertiary *before* choosing a single font or color. The ranking is a product decision — "what is this screen for?" — not a visual one. Styling is how you express a ranking you already made; it cannot substitute for making one.

**Every view and every section has exactly one primary element.** Not two. If two things seem equally important, the section is doing two jobs and should be split.

**Distinguish adjacent levels on at least two independent channels.** The channels are size, weight, color, spacing, position, and enclosure. One channel is fragile — it fails under Dynamic Type, dark mode, sunlight, or color blindness. And color alone is never sufficient here, because color is already carrying status semantics.

**Contrast must survive the real usage context.** For Checkpoint that means outdoors, in bright sunlight, one-handed, possibly at a shop counter with someone waiting. A distinction that only reads on a desk monitor in a dark room does not count as a distinction.

**Emphasis is a budget, not a resource.** Every element promoted to primary devalues every other primary. If everything is emphasized, nothing is.

**Proximity and whitespace communicate grouping before borders do.** Elements packed together read as related whether or not they are, so under-spacing doesn't merely look cramped — it actively misinforms.

**Position carries meaning.** What comes first in reading order should be what matters most — not what was implemented first, not what the data model happens to list first, and not what was easiest to compute.

**A wall is a defect.** A screen whose content all sits within one or two adjacent steps of the type scale has no reading order, regardless of how large its largest element is. A 56pt hero above thirty lines of uniform 11pt text is still a wall.

## UX practice

**Defaults do the work.** The common case requires no configuration. If the most frequent path needs the user to make a choice the system could have made correctly, the system should make it.

**Recognition over recall.** Show the options. Never require the user to remember prior state, a previous screen's value, or anything about how the system works internally.

**One concept, one name, everywhere.** The same underlying thing never gets two labels. Two names for one switch forces the user to learn the implementation.

**The system says what it did** — especially when it changed something the user did not explicitly ask it to change. Silent side effects are the fastest way to lose trust, and the loss is discovered later, at the worst moment.

**Ask only what cannot be inferred.** If there is exactly one correct answer, don't pose it as a question — act, and state what you did. Reserve interruptions for genuine ambiguity the system cannot resolve.

**Advisories appear next to the control that resolves them**, at a moment the user can act. A warning about state you must open a drawer to fix is not a warning, it's a complaint.

**Never block on data the user may not have.** A required field the user cannot fill is a dead end. Required-ness must be justified per item, not applied per form.

**Every lossy or hard-to-reverse action is confirmed or reversible.** Prefer reversible: undo is cheaper for the user than a confirmation dialog on every action.

**Every wait is visible. Every failure states the next step.** "Something went wrong" is not a failure message.

**Accessibility is not a level of polish.** Dynamic Type support, ≥44pt targets, VoiceOver labels that describe the *datum* rather than the layout, and no meaning carried by color alone. These are requirements at the same tier as correctness.

**Motion is informative, never decorative.** Animation that doesn't explain a state change is noise the user must filter, and filtering costs the attention the task needed.

---

# Part 2 — Surface classes

Every surface is exactly one of three classes. Classify it before you build it; the class determines the rules.

| Class | What it does | Examples |
|---|---|---|
| **Readout** | Presents information for scanning | Home, Costs, Services, all detail views |
| **Switchboard** | Offers independent, order-free controls | Settings, threshold pickers |
| **Decision** | Asks the user to make a compound, sequenced choice | Service form, completion sheets, vehicle add/edit |

**How to classify:** does the user *read* (Readout), *toggle one thing and leave* (Switchboard), or *build up an answer across several interdependent inputs* (Decision)? If a surface does two of these, split it.

## Readout rules

1. **One primary per section.** Name the single most important datum; everything else steps down at least one level. There is a component for this — `ReadoutSection` — so the correct shape is the path of least resistance.
2. **Sections have a fixed, learnable order.** A screen may not silently reorder or omit sections based on data availability alone. A screen whose shape is never the same twice cannot be learned.
3. **Never render a card whose only content is absence.** "Not enough data yet" collapses to one quiet line (`InsufficientDataNote`), never a full-size card. A new user's screen should not be mostly apologies.
4. **"View All" lands on the list the section actually shows.** A history section must not link to a financial view.

## Switchboard rules

Flat, equal-weight, independent rows are **correct** here — this is the one class where uniformity is right, because every row is genuinely independent and there is no reading order to establish. Settings is the reference implementation.

The trap: a Switchboard is not a place to hide load-bearing configuration. If a value in Settings changes what a word means elsewhere in the app, the surfaces using that word must say so. (Today "Due Soon" is user-configured via six threshold pickers, and the forms and rows that use the term treat it as absolute. Known gap.)

## Decision rules

5. **Disclosure order: default-disclose what makes the thing *work*; hide what makes it *complete*.** The interval that makes a reminder recur is load-bearing and belongs on the default path. Notes and attachments are completeness and belong in depth. Getting this backwards produces a form that can be filled out completely and still not function.
6. **Every Decision surface has a stated default path and a tap budget.** Write them down in the PR. For Checkpoint the everyday log-or-schedule path is 20–30 seconds; if you can't name the path, the surface doesn't have one.
7. **One value, one primary affordance.** Chips *and* a toggle *and* a picker *and* a field *and* a suggestion row for the same value means no affordance is *the* affordance.
8. **Ask once.** A decision asked twice — once to enter the surface, again inside it — is a decision the user could not make either time.
9. **Advisories use the severity ladder** (below). Four advisories rendered identically is the same defect as a flat readout.

## The advisory severity ladder

One component, `FormAdvisory`, with four levels. The level is not decoration — it determines whether the user can proceed and whether they must decide something.

| Level | Means | Behavior |
|---|---|---|
| `.blocking` | This will not work as configured | Unmissable; rendered adjacent to the control that resolves it |
| `.contradiction` | The system cannot determine which of two inputs is wrong | Two labeled outcome buttons — the user decides, in prose-free form |
| `.caution` | Probably a typo, possibly intentional | Dismissible; never blocks save |
| `.info` | Consequence or projection, no action needed | Quiet; includes "here is what saving will also change" |

**`.info` is how the system says what it did.** When a save will change something the user didn't ask about — adopting a service odometer reading as the vehicle's current mileage, for instance — that is an `.info` advisory shown *before* save, never a prompt and never silence.

## Required and optional

**One vocabulary: `FieldRequirement`.** Not an `isRequired:` parameter on some fields, a hand-rolled asterisk on others, an `[OPTIONAL]` section tag on a third set, and a validation row that only appears after tapping a disabled button. Four signals for one concept means none of them is trusted.

Required-ness is justified per item. "The form has always required it" is not a justification; "the app computes X from it and X is wrong without it" is.

**An `[OPTIONAL]` tag is a promise.** A field marked optional must not have side effects — it may not schedule notifications, alter other records, or change app behavior. If it does, it isn't optional; say so.

## Mileage, and values that mean two things

**Odometer readings come in two kinds and must never share a label:** a *past observation* ("odometer at service") and a *future target* ("remind me at"). They look identical — both are a number of miles — and labeling them identically makes questions like "should this update the current mileage?" unanswerable.

- A **past observation** newer than the vehicle's last reading is adopted automatically, and the adoption is stated via `.info` before save. It is better data than the app has; asking permission wastes a tap.
- A **past observation older than the last reading** is backfill. It never touches current mileage.
- A **future target** never touches current mileage under any circumstances.
- **All adoption routes through one commit path** (`MileageCommit` → `Vehicle.recordMileage`), so `mileageUpdatedAt` and the `MileageSnapshot` are always written. Adoption that skips them silently degrades the pace and estimate engine it was meant to feed.

## Presentation and storage

10. **Enums that reach the UI expose `displayName`. `rawValue` is storage only.** A `rawValue` used as on-screen text cannot be localized and welds presentation to persistence.
11. **No display string built by concatenation.** Use `L10n` format keys, so grammar and word order survive translation.

---

# Part 3 — Invariants and review

## The F-series

These are the invariants the code cites. They were previously referenced as `G*` and `R*` tags with **no definitions anywhere in the repository** — 16 citations pointing at nothing. They are consolidated here into one sequential family. Old references map as shown; the old numbering had gaps (`G4`, `G7`, `R1`–`R3`, `R7`, `R8` were never cited and their content, if any, is lost).

| ID | Was | Invariant |
|---|---|---|
| **F1** | G1 | One shared bottom action bar (`FormActionBar`) for every data-entry form: one primary action, an optional secondary, and a success flash for forms that stay open after saving. Save lives in the same place on every surface. |
| **F2** | G2 | Disabled-save feedback is uniform: error haptic plus a scroll to the field that blocks it. Callers supply only the scroll target, never their own feedback. |
| **F3** | G3 | The action bar never rides above the keyboard — it would eat number-pad space and invite accidental saves. Enforced centrally in `FormActionBar` via `KeyboardVisibility`, so no form can opt out. |
| **F4** | G5 | A projection preview must use the same calculation as the save path, and must not render when there is nothing computable. A preview that can disagree with what actually gets scheduled is worse than no preview. |
| **F5** | G6 | Optional-ness is communicated by one uppercase tracked tag in a section header's trailing slot — subject to the `[OPTIONAL]`-is-a-promise rule in Part 2. |
| **F6** | G8 | Change transparency: while editing, show a field's original value only for as long as the current value differs from it. Never a permanent badge. |
| **F7** | R4 | One history-reference artifact per form, shown once a service type is chosen. Informational when the entry is forward-looking; able to port prior values when it is a completed entry. |
| **F8** | R5 | Context lines omit halves that don't exist — the earliest or latest log for a vehicle has only one neighbor, and padding the absent side with a placeholder is noise. |
| **F9** | R6 | Impact preview: show how an edit shifts the next reminder *before* the user confirms, using null grammar (`MAR 12 → NONE`) so clearing a reminder reads as clearly as setting one. |
| **F10** | R9 | Form drafts persist so a form survives dismissal or the app being killed. Only real edits produce a draft — a pristine form never overwrites a stored one. Attachments are excluded; they live on disk already. |
| **F11** | *new* | One mileage-commit path. See Part 2. |
| **F12** | *new* | One advisory component with an explicit severity level. See Part 2. |

Cite these by ID in code comments, and add new ones here before citing them.

## Pre-flight checklist

Answer these in the PR description for any new or changed surface. They are short on purpose — the point is that a reviewer can see the answers without reverse-engineering them from a diff.

**All surfaces**
- [ ] Which class is this — Readout, Switchboard, or Decision?
- [ ] Are all user-facing strings localized (EN + ES), with no concatenated display strings?
- [ ] Does it hold up at large Dynamic Type sizes, and are tap targets ≥44pt?

**Readout**
- [ ] What is the primary element of each section?
- [ ] Is the section order fixed regardless of which data happens to be present?
- [ ] Does any "View All" land on a list containing the items its section showed?

**Decision**
- [ ] What is the default path, and how many taps is it?
- [ ] What is default-disclosed vs. hidden — and does the hidden set contain anything load-bearing?
- [ ] Which advisory severities appear, and does each one sit next to the control that resolves it?
- [ ] Is any decision asked more than once?

## Acceptance tests

**Reading-order test (Readout).** Show the screen to someone for two seconds. They must be able to name the single most important thing on it. If they can't, the hierarchy isn't there — regardless of how the screen looks.

**Tap-budget test (Decision).** From cold launch, complete the default path. Count the taps and check them against the budget stated in the PR. No drawer expansion permitted on the default path.

**Squint test (any surface).** Blur the screen until the words are unreadable. The primary element must still be identifiable. If it isn't, the hierarchy is carried by the content rather than the layout — which reads fine at a desk and fails in a parking lot.

### Run them before implementing, not after

[`tools/sketchpad/`](../tools/sketchpad/CLAUDE.md) recreates the UI in SolidJS against the real `Themes.json` and fonts, and implements three of these as instruments: it audits every section for exactly one primary, blurs on demand, and counts taps against a declared budget. It also switches all eight themes and scales Dynamic Type to 2×.

A SwiftUI iteration costs ~40 seconds; the sketchpad costs about one. **Resolve the layout there, port it, then verify on the Simulator** — the sketchpad is blind to keyboard avoidance (so invariant F3 always looks satisfied), VoiceOver order, scroll physics, and real font rasterization.

## Known open items

Recorded so they are not rediscovered as though they were new:

- `ServicesTab` treats Documents as a view mode that then offers "OPEN LIBRARY" to leave for the real documents screen — a content type masquerading as a mode.
- A skipped service cannot be dismissed without fabricating a log entry, so a returning lapsed user faces permanent red rows.
- "Due Soon" is user-configured in Settings but treated as absolute wherever it is displayed.

## How to extend this document

Four constraints, so it does not become the thing it was written to prevent:

1. **State invariants and acceptance tests, not recipes.** "Primary must be distinguishable from secondary on two channels" — never "primary is 15pt Medium." Recipes freeze one solution and get followed long after they stop being right.
2. **Every rule carries its why.** A rule without a rationale can only be obeyed or ignored, never correctly overridden.
3. **Keep durable principles separate from current implementation.** Principles live here. Specific tokens, weights, and component names live in [`DesignSystem/CLAUDE.md`](../apps/checkpoint/ios/checkpoint/DesignSystem/CLAUDE.md), which is expected to change.
4. **Mark preference vs. requirement**, matching `AESTHETIC.md`. This document is almost entirely requirements; if you add a preference here, label it, or it will be defended as though the user's comprehension depended on it.
