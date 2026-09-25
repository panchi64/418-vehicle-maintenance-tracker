# DesignSystem — Tokens and Modifiers

The **current implementation** of Checkpoint's visual language: tokens, fonts, and view modifiers as they exist in code.

This file describes *what is available*. It deliberately does not describe when to use which — that's a structural question and it lives in [`docs/SURFACE_DOCTRINE.md`](../../../../../docs/SURFACE_DOCTRINE.md). Identity and brand rules live in [`docs/AESTHETIC.md`](../../../../../docs/AESTHETIC.md).

**This file is expected to change.** Values here are implementation choices, not principles. If you find it disagreeing with the code, the code is right — fix this file.

## Colors are theme-driven

Every color token is a computed property resolving through the active theme's
**resolved palette**, not a literal:

```swift
static var accent: Color { ThemeManager.shared.palette.accent }
```

`ThemeDefinition` stores hex *strings*; `ThemePalette` parses them into
`Color`s once, and `ThemeManager` rebuilds it only in `activateTheme(_:)`. Read
colors through `Theme.*`. Don't parse hex in a view body — a screenful of rows
touches tokens hundreds of times.

`ThemeManager.current` is `private(set)`: change themes with `activateTheme(_:)`
so the palette can't go stale.

Themes are `ThemeDefinition` values loaded from `Resources/Themes.json`. **Eight ship today** — `default`, `clean_slate`, `red_line`, `blueprint`, `terra`, `midnight_oil`, `garage_day`, `stealth` — some unlocked via tips. Each defines every token, so **never assume a specific hue**. Write against the token, verify against more than one theme.

### Every theme has four appearances; the app follows the system

The app sets no `.preferredColorScheme`. Each theme defines a palette for
light, dark, and Settings › Accessibility › **Increase Contrast** on each:

```jsonc
"colors": {
  "light": { /* all 16 tokens */ },
  "dark":  { /* all 16 tokens */ },
  "lightHighContrast": { /* overrides on light — only what changes */ },
  "darkHighContrast":  { /* overrides on dark */ }
}
```

Decoding (`ThemeAppearances`) rejects a base set missing a token and any
unknown token name, and merges each high-contrast set over its base. Every
`ThemePalette` color is a DesignKit adaptive color
(`Color(light:dark:lightHighContrast:darkHighContrast:)`), so it resolves from
`\.colorScheme` / `\.colorSchemeContrast` at render time — call sites never
branch on appearance, and `UIColor(Theme.x)` stays adaptive in UIKit too. To pin
one appearance (e.g. a PDF on white paper), resolve it explicitly:
`UIColor(Theme.accent).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))`.

**Run the contrast gate after any palette change:**
`uv run tools/theme-contrast/check_contrast.py`. It fails on text below 7:1
(primary) / 4.5:1 (secondary, tertiary), status or accent below 3:1, a primary
button label below 4.5:1, status colors too close to tell apart, and — in the
high-contrast sets — anything below 7:1 text / 4.5:1 status and accent / 3:1
grid lines, or anything *lower* than its base appearance. `textTertiary` is not
a decorative opacity: it carries real labels and must pass 4.5:1.

`previewColors` are identity swatches for the picker and don't vary by appearance.

### Token inventory

| Group | Tokens |
|---|---|
| Backgrounds | `backgroundPrimary`, `backgroundElevated`, `backgroundSubtle` |
| Surfaces | `surfaceInstrument`, `glow`, `gridLine` |
| Text | `textPrimary`, `textSecondary`, `textTertiary` |
| Borders | `borderSubtle` |
| Accent | `accent`, `accentMuted` |
| Status | `statusOverdue`, `statusDueSoon`, `statusGood`, `statusNeutral` |

### The default theme, for orientation only

The `default` theme ("Checkpoint") is AESTHETIC.md's two colors in either order — **cerulean ground with off-white ink** in dark, **off-white ground with cerulean ink** in light. It is not a dark-neutral theme:

- dark: `backgroundPrimary #0033BE` · `textPrimary #F5F0DC` · `accent #F5F0DC` · `statusOverdue #FF8F8F` · `statusDueSoon #F7AD55` · `statusGood #38D9A9` · `statusNeutral #B4BBC2`
- light: `backgroundPrimary #F5F0DC` · `textPrimary #0033BE` · `accent #0033BE` · `statusOverdue #C62D2D` · `statusDueSoon #A65800` · `statusGood #0A7A55` · `statusNeutral #5F6873`

Other themes diverge substantially, including in `fontDesign`.

### Adding a token

Add a case to `ThemeToken`, add it to `ThemePalette`, add it to `ThemeProviding` and implement it on every provider, and add it to the `light` and `dark` sets of all eight entries in `Themes.json` (plus the high-contrast overrides if it should change there). Add it to `TOKENS` in `tools/theme-contrast/check_contrast.py`. See [`packages/DesignKit/CLAUDE.md`](../../../../../packages/DesignKit/CLAUDE.md).

Then add the key to `COLOR_KEYS` in [`tools/sketchpad/src/theme/themes.ts`](../../../../../tools/sketchpad/src/theme/themes.ts). The sketchpad imports `Themes.json` directly rather than copying it, so hues never drift — but that one array is the list of keys it exposes as CSS variables, and a token missing from it simply won't render there.

## Typography

Monospaced themes use bundled JetBrains Mono via DesignKit; other themes fall back to `.system(textStyle, design:)` with the theme's `fontDesign`. All accessors are `@MainActor` because they read `ThemeManager`.

**Every token scales with Dynamic Type.** The size below holds at the default text setting and follows the listed text style's curve from there (`Font.custom(_:size:relativeTo:)`). SF themes use the text style directly, so their sizes are Apple's. Never use `.system(size:)` or a fixed `.custom(size:)` for UI text or SF Symbols — map to a token or a text style.

| Font | Size / Weight | Scales as | Role |
|---|---|---|---|
| `brutalistHero` | 56 Light | `.largeTitle` | Hero data displays |
| `brutalistTitle` | 32 Medium | `.title` | Primary headings (uppercased by its style modifier) |
| `brutalistHeading` | 20 Medium | `.title3` | Service names, sheet headings |
| `brutalistSectionTitle` | 15 Bold | `.headline` | Section titles — **Title Case, untracked, `textPrimary`** (`InstrumentSectionHeader` uses it). Uppercase stays for status tags and field labels only |
| `brutalistBodyEmphasis` | 15 Medium | `.body` | **The one primary datum** of a section or form |
| `brutalistBody` | 15 Regular | `.body` | Ordinary values, body text |
| `brutalistSecondary` | 13 Regular | `.footnote` | Supporting text |
| `brutalistLabel` | 11 Medium | `.caption2` | Labels, uppercased + tracked |
| `brutalistLabelBold` | 11 Bold | `.caption2` | Emphasized labels |

Horizontal arrangements of text must survive accessibility sizes: use `AdaptiveStack` (an `HStack` that becomes a leading `VStack` at AX sizes, via `AnyLayout`; `spacing:` or separate `horizontalSpacing:`/`verticalSpacing:`) with `AdaptiveSpacer()` in place of `Spacer()`, or `ViewThatFits`. Don't hand-roll another `isAccessibilitySize` switch.

### The four-step working hierarchy

For readouts and forms, the usable range is:

**15 Medium** (primary) → **15 Regular** (values) → **13 Regular** (support) → **11 Medium caps** (labels)

`brutalistHero` and `brutalistTitle` are reserved for genuine hero elements — a single dominant number, a status headline. They are not a substitute for having a hierarchy in the rest of the screen.

`brutalistBodyEmphasis` was added because the scale previously jumped 15 Regular → 11 Medium, leaving **color as the only channel for importance** — and color is already carrying status meaning. Without it, hierarchy was not expressible. Don't remove it without replacing the capability.

### Style modifiers

`.brutalistHeroStyle(color:)` · `.brutalistTitleStyle()` · `.brutalistHeadingStyle()` · `.brutalistBodyEmphasisStyle(color:)` · `.brutalistBodyStyle()` · `.brutalistSecondaryStyle()` · `.brutalistLabelStyle(color:)`

## Spacing (`Spacing`, 4pt base)

| Token | Value | Use |
|---|---|---|
| `xs` | 4 | Tight gaps, icon-to-text |
| `sm` | 8 | Related elements |
| `listItem` | 12 | Between list items |
| `md` | 16 | Standard padding |
| `screenHorizontal` | 20 | Screen edge padding |
| `lg` | 24 | Section separation |
| `xl` | 32 | Major sections |
| `xxl` | 48 | Hero spacing |

No tab-bar clearance token: the system `TabView` insets scroll content itself.

⚠️ **Known inconsistency:** `Theme.screenHorizontalPadding` is **16** while `Spacing.screenHorizontal` is **20**. Prefer `Spacing.screenHorizontal`; the `Theme` constant should be retired.

## Layout constants (`Theme`)

`cardCornerRadius` / `buttonCornerRadius` / `instrumentCornerRadius` are all **0** (sharp corners). `borderWidth` 2 · `cardPadding` 16 · `buttonHeight` 48 · `frameWidth` 35 (web-parity frame, rarely used on iOS).

## Animation

`animationFast` 0.1 · `animationMedium` 0.2 · `animationSlow` 0.3 · `revealStagger` 0.05 · `pulseAnimationDuration` 1.5

Odometer roll (see `RollingNumberText`): `odometerRollDuration` 0.65 · `odometerRollStagger` 0.06 · `odometerRollMaxDelay` 0.24

Glow: `glowRadius` 8 / `glowOpacity` 0.3 · `statusGlowRadius` 12 / `statusGlowOpacity` 0.4 · `focusGlowRadius` 6 / `focusGlowOpacity` 0.5

## View modifiers

**Surfaces** — `.brutalistBorder(color:)`, `.cardStyle(padding:)`, `.instrumentCardStyle(padding:)`, `.glassCardStyle(intensity:padding:)`, `.screenPadding()`

**Effects** — `.statusGlow(color:isActive:)`, `.focusGlow(color:isActive:)`, `.pulseAnimation(isActive:)`

**Entrance** — `.revealAnimation(delay:animation:)`, `.staggeredReveal(index:baseDelay:)`

**Buttons** — `.buttonStyle(.primary)` (filled), `.buttonStyle(.secondary)` (outlined), `.buttonStyle(.instrument)`, `.toolbarButtonStyle(isDisabled:)`

**Status** — `StatusTag(status:)` (shape + word; the default) and `StatusMark(status:)` (shape only, when the word is already adjacent). Overdue = filled square, due soon = outlined square, good = short rule. Never draw status as a bare colored dot.

**Structural components** — `InstrumentSection`, `InstrumentSectionHeader`, `BrutalistDataRow`, `AtmosphericBackground`, `AdaptiveStack` + `AdaptiveSpacer` (AX-size stacking)

## `RollingNumberText`

Drop-in replacement for `Text` on a **numeric readout that changes in place**. Its digits roll like odometer wheels, passing through the intermediate digits rather than cutting to the new one. Takes the environment font and foreground style, so adopting it is a one-word change:

```swift
RollingNumberText(Formatters.mileage(vehicle.currentMileage))
    .font(.brutalistBody)
    .foregroundStyle(Theme.accent)
```

Already adopted by the header odometer, `QuickMileageUpdateCard`, `CostHeadlineCard`, `NextUpCard`, and `StatsCard`. **Don't add another hand-rolled digit animation** — extend this one.

- **Formatting stays the caller's job.** It takes a finished string, so `Formatters` and locale rules remain the only place a number's appearance is decided.
- **`.minimumScaleFactor` is a parameter, not a modifier** — each digit is its own `Text`, so the modifier would scale neighbours independently. Passing it also makes the view width-greedy; it has to know the width to pick a scale.
- **`.tracking()` does not carry across cells.** Readouts don't track; labels do, and labels don't roll.
- **Use it only for quantities.** Identifiers that happen to contain digits — a plate, `0W-20`, a VIN — must stay plain `Text`. `VehicleSummaryBand`'s `SummaryCell` gates this behind `rollsDigits:` for exactly that reason.
- **Pass `resetToken:` wherever one readout is reused across subjects.** Rolling asserts *this number moved*. The header and both tabs are reused across vehicles, so without a token, selecting a different car spins the odometer 120,000 → 8,000 as though it had un-driven 112,000 miles. When the token changes the next value is set, not rolled; a same-subject change still rolls. Every adopter passes one (`vehicle.id`, `service.id`, or a `subjectID:` parameter threaded from `CostsTab`).
- Reduce Motion falls back to `.contentTransition(.numericText())`, as does any value with no ASCII digits in it; the first appearance sets rather than rolls.

## Rules

1. **Always use tokens.** Never hardcode a color, font, or spacing value.
2. **Zero corner radius.** No `cornerRadius()` modifiers.
3. **Never assume a hue or an appearance.** Eight themes × light/dark × Increase Contrast; verify in both appearances and more than one theme. No `.preferredColorScheme` outside `#Preview`s.
4. **Status colors carry meaning, and never carry it alone.** Pair with a label, shape, or position.
5. **Hierarchy is expressed with weight and spacing, not color.** Color is spoken for.
6. **Use the `textStyle:` font accessors where Dynamic Type scaling matters.**

For *when* to reach for each of these — section structure, disclosure, advisory severity, required/optional — see `docs/SURFACE_DOCTRINE.md`.
