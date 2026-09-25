# tools/sketchpad

A SolidJS recreation of Checkpoint's UI, used to **settle layout decisions before writing any SwiftUI**. It ships nothing. It is a design instrument.

## Why it exists

Iterating on a SwiftUI screen through `xcodebuild` → install → launch → screenshot is a ~40 second loop, and a layout question usually needs ten of them. That cost changed *how design decisions got made*: it encouraged committing to the first arrangement that compiled, and it made "let me see three versions of this" impractical. A wall of equal-weight monospace is partly the residue of that.

Here the loop is about one second. The point is not that the web is a better place to build this app — [see below](#what-this-is-not) — it is that **the cheapest place to be wrong about a layout should not be the shipping codebase.**

## Run

```bash
./dev.sh
# http://localhost:5273
```

Or `bun run dev`. `bun run typecheck` before committing.

**If a control stops responding, hard-reload before debugging it.** Solid's HMR sometimes fails to swap a module (the console says `[hmr] Failed to reload …`) and leaves the DOM on screen with a **disposed reactive root**. Clicks land, handlers run, and nothing updates — including `aria-expanded`, so it looks exactly like a broken event binding. This cost real time once; a hard reload is the first thing to try, not the last.

## It reads the real design system

Nothing here re-declares a token. The sketchpad is only useful if it renders what the app renders, so:

| Thing | Source |
|---|---|
| Colors, all 8 themes | `apps/checkpoint/ios/checkpoint/Resources/Themes.json`, imported directly via the `@checkpoint` Vite alias |
| JetBrains Mono | `packages/DesignKit/Sources/DesignKit/Resources/Fonts/*.ttf`, referenced by relative path from `src/styles/base.css` |
| Type scale, spacing, layout constants | transcribed in `src/styles/base.css` with the Swift source named in comments |

Sizes are **1:1 with iOS points** — the frame renders at logical size, so 15pt in `Typography.swift` is 15px here.

Themes.json and the fonts are read, never copied. A copy would drift, and a sketchpad that renders colors the app doesn't ship would validate layouts against fiction. **If you add a token to `Themes.json`, add it to `COLOR_KEYS` in `src/theme/themes.ts`** — that array is the one place the two must agree.

## The harness is the actual feature

Anyone can mock a screen in HTML. What makes this worth keeping is that it turns three of the doctrine's acceptance tests into instruments:

- **One-primary audit.** `SURFACE_DOCTRINE` requires exactly one primary element per section. Normally that is checked by eye in review, which is precisely how thirty data points at one weight got shipped. Here it is a DOM query: every `[data-section]` is checked for exactly one primary among its own descendants. **Zero primaries means the section has no reading order; two or more means a declared rank is a lie.** It found two real bugs within a minute of first working.
- **Squint test.** Blurs the frame. If you can no longer tell what the screen is for, the hierarchy is carried by the words rather than by the layout — a stand-in for the real context: outdoors, one-handed, at arm's length.
- **Tap budget.** Counts taps inside the frame against the budget declared for that screen in `SCREENS` (`src/App.tsx`). The doctrine's tap-budget test stops being an assertion and becomes a number.

Plus a theme switcher over all eight themes, a light/dark + Increase Contrast switch, and a Dynamic Type slider to 2×, because both are `[REQUIREMENT]`s that are easy to skip and expensive to discover late.

## Declaring hierarchy

Two things are deliberately **separate props**:

```tsx
<Heading rank="primary">Oil & Filter Change</Heading>
//  ^ how it renders   ^ what rank it holds
```

The doctrine says rank content *before* styling it, because ranking is a product decision and styling is how you express it. Keeping them as one prop is what lets a screen end up with five things at heading size and no answer to "which one matters."

`ReadoutSection` takes `primary` as a **required slot**, so a section cannot be built without deciding its most important element — mirroring `ReadoutSection.swift`. Content placed in that slot must **not** also carry `rank="primary"`; the slot already declares it, and doubling up is how a section claims two primaries.

## Three label levels, not one

A form has section titles, field labels, and subgroup labels. Rendering all three as 11pt tracked caps — which is what happened once the enclosures came off — leaves a screen that is a sequence rather than a structure. `SERVICE`, `COMMON`, `WHEN`, `COST` and `CATEGORY` all looked identical while meaning three different things, and the whole form melded together.

| Level | Treatment | Component |
|---|---|---|
| Section | 11 Bold caps, secondary, **+ a full-width rule** | `FormSection` |
| Field | 11 Medium caps, tertiary, no rule | `Field`, `InlinePicker` |
| Subgroup | 13 Regular sentence case, tertiary | `FormSubgroup` |

The rule marks the boundary; the spacing is what makes it read as one at a glance.

### Spacing is 8 / 16 / 32 — and the ratio is the point

| Step | Gap | |
|---|---|---|
| Header → its own content | **8px** | the label belongs to what follows |
| Field → field | **16px** | siblings inside one group |
| Section → section | **32px** | different groups |

A clean 1:2:4, so each step is unambiguous. This went wrong twice in opposite directions before landing here, and both failures are instructive:

- At 32px between sections with 16px inside them, the last field fell below the fold, so it was cut to 24px.
- At **24-vs-16** the sections stopped reading as separate at all. A 1.5:1 ratio is not a signal — and worse, `FormSection` used one `gap` for everything, so a header sat 16px from its own content and 24px from the section above it. **Nearly equidistant between the group it labels and the one before it**, which is why nothing looked grouped.

The resolution wasn't "more space", it was *tightening the inner steps to pay for the outer one*. Binding the header to its content at 8px and widening sections to 32px made the form marginally **shorter** than the 24px version while finally reading as three blocks. Whenever separation feels weak, check the ratio between adjacent steps before adding height.

When a `FormSection` header already names its single field, that field takes no label. Two identical labels stacked on one input is worse than none.

## Measure the type distribution, don't eyeball it

"Does this have hierarchy?" is answerable with a DOM query, and the answer is often not what looking at it suggests. Paste this in the console:

```js
const b = {}; const app = document.querySelector('.hz-app');
(function walk(el){ for (const c of el.children) {
  if ([...c.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())) {
    const s = getComputedStyle(c);
    const k = `${Math.round(parseFloat(s.fontSize))}px/${s.fontWeight}${s.textTransform!=='none'?' CAPS':''}`;
    b[k] = (b[k]||0)+1;
  } walk(c); } })(app);
console.table(b)
```

On the service form this returned **25 of 36 elements at 11pt — 69% of the screen in one size**, and showed that the timing chips (the decision the form exists to capture) were set in 11pt Medium caps at 1.5 tracking: *the exact field-label treatment*. Only their border said they were anything more. That is invisible by eye because each group looks locally fine; it is obvious in a histogram.

The fix was to give the decision the type it deserves — 15 Medium sentence case, which the scale defines as "the one primary datum" — and to stop caps-and-tracking making offers read as metadata (`PICK A DATE…` is shouted; `Pick a date…` is offered). 11pt went to 54%, and the form now has four legible tiers: 20 title → 15 decisions and values → 13 subgroups and support → 11 labels and shortcuts.

**Watch for accent-equals-primary.** In the default theme `accent` (#F5F0DC) *is* `textPrimary`, so colouring something `accent` buys no differentiation — it just renders at full brightness. A `REQUIRED` note tinted accent was outshining the section title it annotated. This is why the app leans on bracket notation for affordances rather than colour, and it is a good reason to check any colour-based hierarchy in a second theme.

## Check for overflow, don't trust your eyes

A layout can overflow without looking broken — text just gets clipped somewhere you aren't looking. One query, worth running at every width and type size:

```js
const app = document.querySelector('.hz-app');
[...app.querySelectorAll('*')]
  .filter(e => e.scrollWidth > e.clientWidth + 1 && getComputedStyle(e).overflowX !== 'auto')
  .map(e => ({ text: (e.value || e.textContent || '').trim().slice(0, 26), s: e.scrollWidth, c: e.clientWidth }))
```

Two traps it caught, both of which apply equally to SwiftUI:

**`min-width: 0` on anything holding an input.** A flex item defaults to `min-width: auto`, which resolves to its content's min-content width — and an `<input>` has a wide intrinsic minimum. Add Vehicle's Year/Make row was 381px inside 333px because the wrapper refused to shrink. This is on `Field`'s root now, so it can't recur per call site.

**A fixed two-column split cannot survive Dynamic Type.** `min-width: 0` lets a *box* shrink, but a one-word label like `MAKE` still can't go below its word width — at 375pt and 1.5× it was crushed into 28px against a 46px word. The row has to be allowed to become two rows: `flex-wrap: wrap` with the flex bases multiplied by `var(--type-scale)`, so the wrap point tracks the type size. Applied to Year/Make and to the reminder's interval pair.

Verified: zero overflow on both forms at 375/393pt × 1.0/1.5/2.0×.

## Support lines truncate; they never re-wrap

A metadata line ("3 days ago // 33,290 mi // Toyota de Puerto Rico") must be **one line with `nowrap` and ellipsis**, ordered so the least important fact falls off the end. Built as a wrapping flex row of separate items it shattered on a 375pt screen into `3 / days / ago` and `Toyota / de / Puerto / Rico` — each item shrank to min-content and wrapped internally.

Related: in a row with a trailing amount, put the amount on the **title's** line rather than vertically centred beside the whole block. Centred, it steals width from the support line too, which is exactly where width is scarcest.

## Advisory or readout?

Both are quiet 13pt lines, so it is easy to reach for the wrong one. The severity ladder is for things that need **attention or resolution**. A projected outcome is a **value**, and gets a label plus emphasis weight.

The reminder's fire time was an `.info` advisory, which made the most important line on the screen — the proof the reminder will actually fire — the quietest thing on it. Odometer adoption stays `.info`, correctly: that one is the app telling you it will change something you did not ask it to change.

## Layout

```
src/
  styles/base.css     tokens, @font-face, reset
  theme/themes.ts     reads the real Themes.json, applies as CSS variables
  data/fixtures.ts    sample data — deliberately not a happy path
  ui/                 primitives: Text, Controls, ReadoutSection, FormAdvisory, FormActionBar
  components/         VehicleHeader, Rows, Cards, TabBar
  screens/            HomeTab, ServicesTab, CostsTab, ServiceForm, AddVehicle
  harness/            Inspector (audit), harness.css — chrome around the frame
```

Fixtures include an overdue item, a due-soon item, a healthy item, a **date-only item with no odometer relationship**, a long service name, an empty nickname, and a very long nickname. Seed new fixtures the same way: tidy data proves nothing, and every one of those cases has broken a real layout.

Harness chrome is styled deliberately unlike Checkpoint. The controls around the frame must never be mistaken for the app inside it.

## Screens model the target

**Everything below now ships in the iOS app.** The sketchpad is no longer ahead of it, so where the two disagree, treat that as drift and work out which one is wrong — do not assume the sketchpad leads.

Each screen file opens with a comment stating the problem it solves. Those comments are the durable part: they record what was tried and why it failed, and several of them were expensive to learn. The SwiftUI files carry the same reasoning at their own call sites, so the rationale survives even if this directory is eventually retired.

The resolved decisions:

- `ServiceForm` — **enclosure is a budget.** The form once rendered every control as an outlined rectangle: eight quick-service chips, seven timing chips, six category chips, three boxed fields — twenty-four identical enclosures, so nothing read as the decision. Now only the timing chips are outlined, because that choice derives the intent and every user must answer it. Fields are a single bottom rule (accent on focus), shortcut chips are plain text with an underline when active, and category is an `InlinePicker` since it has a working default most users never change. Same information, seven rectangles instead of twenty-four, and the form fits one screen. This follows the doctrine's own "proximity and whitespace communicate grouping before borders do" — it is not a style preference.
- `ServiceForm` — one unified form with **derived intent**. No Record/Remind mode switch: the user answers "when", and a past answer means logging while a future answer means scheduling. The repeat interval is on the default path because it is what makes a reminder fire; notes and receipts are in depth because they only make an entry complete.
- `TabBar` — a single `[+]`, not the two-way `[LOG]`/`[SCHEDULE]` expansion.
- `ServicesTab` / `CostsTab` — **one** control row instead of two-to-four. A segmented control for the dimension that changes what the screen *is* (mode, period), and a `FilterControl` for refinement. The scrolling chip rows they replace hid options off the right edge — "On track" was cut to "ON TR…", and three of six Costs categories were off-screen — which fails recognition-over-recall outright.
- `FilterControl` — the trigger is labelled with the **dimension**, never the selected value. Labelling it with the value widened it on selection and crushed the segmented control beside it until `ALL` collided with the trigger; any control whose width depends on its own value cannot share a fixed row. The active value gets `ActiveFilterBar`, a row that exists only while a filter is on — a consequence of the user's action rather than permanent chrome, and it replaces the old always-present filter-indicator row.
- `ServicesTab` — Documents is a destination, not a view mode.
- `CostsTab` — fixed card order; "not enough data" is one quiet line, never a card.
- `AddVehicle` — single scroll, VIN above the fields it fills, odometer required.
- `VehicleHeader` — the specs disclosure is a **full-width strip whose collapsed label is the specs themselves**. The version before it used a `[SPECS] ⌄` label, whose target was only as wide as the word and which showed nothing until tapped — so the reference data that used to be glanceable on Home became two taps away. The header comment records all five iterations and why each failed; read it before revisiting. (The sketchpad's fixture has a `trim` field and `Vehicle` does not, so the shipping strip pairs the plate with the oil or tire spec instead.)

### Where SwiftUI had to diverge

Two places where the port could not copy the sketchpad literally, both worth knowing before you compare screenshots:

- **Dropdowns are inline bands, not floating panels.** The sketchpad anchors an absolutely-positioned list under its trigger with a backdrop to dismiss. SwiftUI's nearest equivalent is `.popover`, which draws rounded, translucent system chrome that cannot be squared off — and this app draws no rounded corners anywhere. `FilterControl` and `InlinePicker` expand in place instead, which also makes the list full-width so no option label can truncate. This is why `FilterControlRow` owns the whole control row rather than just the trigger.
- **Wrapping rows use `ViewThatFits`, not flex-wrap.** CSS wraps per item; `ViewThatFits` picks one layout for the whole row. For two-field pairs (Year/Make, the interval fields) the result is the same, and it tracks Dynamic Type the same way. `WrappingChipRow` needs true per-item wrapping, so it uses a custom `Layout` (`FlowLayout`).

## What the sketchpad cannot answer

Take this seriously. A layout that looks resolved here can still be wrong on device, and these are exactly the failures a browser hides:

- **Keyboard avoidance.** There is no software keyboard, so invariant F3 ("the action bar never rides above the keyboard") will *always* appear satisfied here — including for a layout that breaks on device.
- **VoiceOver order and quality.** ARIA is a rough proxy for the accessibility tree, not the same thing.
- **Dynamic Type past the slider**, plus the accessibility sizes that reflow rather than scale.
- **Scroll physics, momentum, safe-area insets, the Home indicator, keyboard dismissal, sheet detents.**
- **Real font rasterization.** Core Text and the browser hint and space differently; two designs a hair apart here can differ on device.
- **Performance.** Nothing here says anything about SwiftUI view-update cost.

**The verification loop is: resolve the layout here → implement in SwiftUI → verify on the Simulator.** The sketchpad replaces the *exploration* iterations, not the final check.

## What this is not

Not a step toward shipping the UI in a webview. That was evaluated and rejected: forms are the single worst thing to put in an iOS webview, and forms are exactly what hurts. `FormActionBar`'s keyboard avoidance is ~4 centrally-solved lines natively and would be re-solved per-screen, badly, in a webview — and Dynamic Type and VoiceOver quality, both `[REQUIREMENT]`s, degrade.

Use the web for **exploration**, ship SwiftUI.

## Rules

1. **Never a hardcoded hue.** Use the CSS variables. If a color isn't a variable, it isn't in the design system.
2. **Spend enclosures deliberately.** A border is emphasis, and emphasis is a budget. Before adding one, name the control it is supposed to outrank. If a screen's controls all carry the same enclosure, none of them is the decision — see `ServiceForm`.
3. **Verify against more than one theme and both appearances**, including a non-monospaced theme, before calling a layout resolved. Eight themes ship, each in light, dark, and Increase Contrast — the harness's Appearance switch and contrast checkbox select among them, starting from the browser's own `prefers-color-scheme` / `prefers-contrast`.
4. **Every screen states its problem** in a header comment. A mock with no thesis cannot be reviewed.
5. **Don't let it rot into a second source of truth.** It models one screen's structure, not the app's behavior. No routing, persistence, or business logic beyond what a layout decision needs.
6. **When a decision is settled, port it and say so** in the SwiftUI implementation, then update the screen comment here.

Structure and disclosure rules: [`docs/SURFACE_DOCTRINE.md`](../../docs/SURFACE_DOCTRINE.md). Identity: [`docs/AESTHETIC.md`](../../docs/AESTHETIC.md). Current tokens: [`DesignSystem/CLAUDE.md`](../../apps/checkpoint/ios/checkpoint/DesignSystem/CLAUDE.md).
