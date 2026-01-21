# Vehicle Maintenance Tracker - Design System

> Design guidelines for a clean, elegant, utilitarian iOS app with a focus on clarity and calm confidence.

---

## Design Philosophy

### "Confident Calm"

The app should feel like everything is under control. Not anxious, not clinical — quietly competent.

**Core Principles:**

- **Clarity over decoration** — Every element earns its place
- **Information hierarchy** — The most important thing is always obvious
- **Functional color** — Color communicates status, not style
- **Warmth within utility** — Clean doesn't mean cold
- **Restraint** — When in doubt, leave it out

**Inspiration:**

- Tesla's UI philosophy: clean, elegant, utilitarian, UX-first
- Not a clone — takes the principles, not the skin

---

## Color System

### Dark Mode (Primary Experience)

Dark mode is the hero. Most users check car info in garages, parking lots, and low-light environments.

| Token                 | Hex       | Usage                                    |
| --------------------- | --------- | ---------------------------------------- |
| `background-primary`  | `#121212` | Main app background                      |
| `background-elevated` | `#1C1C1C` | Cards, sheets, elevated surfaces         |
| `background-subtle`   | `#252525` | Subtle differentiation, hover states     |
| `text-primary`        | `#FFFFFF` | Headlines, primary content               |
| `text-secondary`      | `#A0A0A0` | Supporting text, labels                  |
| `text-tertiary`       | `#666666` | Disabled, placeholder text               |
| `border-subtle`       | `#2A2A2A` | Dividers, subtle borders (use sparingly) |

### Light Mode

Light mode is fully supported but follows dark mode's lead. Same structure, inverted values, consistent accent.

| Token                 | Hex       | Usage                                |
| --------------------- | --------- | ------------------------------------ |
| `background-primary`  | `#F8F7F4` | Main app background (warm off-white) |
| `background-elevated` | `#FFFFFF` | Cards, sheets, elevated surfaces     |
| `background-subtle`   | `#EFEEEB` | Subtle differentiation               |
| `text-primary`        | `#121212` | Headlines, primary content           |
| `text-secondary`      | `#666666` | Supporting text, labels              |
| `text-tertiary`       | `#A0A0A0` | Disabled, placeholder text           |
| `border-subtle`       | `#E0DFDC` | Dividers, subtle borders             |

### Accent Color

| Token          | Hex                      | Usage                                             |
| -------------- | ------------------------ | ------------------------------------------------- |
| `accent`       | `#E89B3C`                | Primary accent, interactive elements, brand color |
| `accent-muted` | `#E89B3C` at 20% opacity | Backgrounds, subtle highlights                    |

Amber is the signature color — warm, automotive (evokes indicator lights), distinctive without being aggressive. Consistent across both light and dark modes.

### Status Colors

Functional colors that communicate maintenance status at a glance.

| Token             | Hex       | Meaning                            |
| ----------------- | --------- | ---------------------------------- |
| `status-overdue`  | `#E85C4C` | Coral red — service is past due    |
| `status-due-soon` | `#E89B3C` | Amber (accent) — service coming up |
| `status-good`     | `#4CABA8` | Soft teal — no action needed       |
| `status-neutral`  | `#666666` | Gray — informational, no urgency   |

**Usage rules:**

- Status colors appear as dots, pills, or text color — not large fills
- Never use status colors for decoration
- Red is reserved for overdue items only — don't dilute its meaning

---

## Typography

### Font Family

**Primary:** SF Pro (iOS system font) — native feel, excellent readability, automatic Dynamic Type support.

SF Pro provides:
- Optimal rendering on all iOS devices
- Built-in support for all weights and optical sizes
- Automatic adaptation for accessibility settings
- Monospaced variants for numerical data (SF Mono)
- Rounded variants for friendly number displays

### Type Scale

| Name             | Size | Weight        | Design    | Usage                           |
| ---------------- | ---- | ------------- | --------- | ------------------------------- |
| `display-large`  | 34pt | Bold          | Rounded   | Hero numbers, large displays    |
| `headline-large` | 28pt | Bold          | Default   | Screen titles, vehicle name     |
| `headline`       | 24pt | Semibold      | Default   | Service names in hero card      |
| `title`          | 17pt | Semibold      | Default   | Card titles, list item names    |
| `body`           | 17pt | Regular       | Default   | Primary content                 |
| `body-secondary` | 15pt | Regular       | Default   | Supporting content              |
| `caption`        | 14pt | Regular       | Default   | Labels, due date text           |
| `caption-small`  | 12pt | Semibold      | Default   | Section headers, metadata       |
| `mono-large`     | 42pt | Light         | Monospace | Mileage displays (deprecated)   |
| `mono-body`      | 15pt | Medium/Semibold | Rounded | Inline mileage numbers          |

### Typography Rules

- **Hierarchy through weight and size only** — no italics, no decorative treatments
- **Sentence case for UI text** — "Oil change due" not "Oil Change Due"
- **All-caps for section headers** — "NEXT UP", "UPCOMING" with letter-spacing
- **Negative tracking on headlines** — -0.5pt for tighter, more confident feel
- **Numbers: use rounded design** — for friendlier mileage displays

---

## Spacing System

Consistent spacing creates visual rhythm without explicit grids.

### Base Unit

`4pt` base unit. All spacing derives from this.

| Token       | Value | Usage                              |
| ----------- | ----- | ---------------------------------- |
| `space-xs`  | 4pt   | Tight gaps, icon-to-text           |
| `space-sm`  | 8pt   | Related elements                   |
| `space-md`  | 16pt  | Standard padding, between sections |
| `space-lg`  | 24pt  | Section separation                 |
| `space-xl`  | 32pt  | Major sections, between cards      |
| `space-2xl` | 48pt  | Hero spacing, bottom padding       |

### Layout Guidelines

- **Screen horizontal padding:** 20pt
- **Card internal padding:** 20pt (increased from 16pt)
- **Between list items:** 14pt vertical padding
- **Between sections:** 32pt
- **Divider inset:** 56pt from leading edge (aligns with text after status dot)

---

## Components

### Cards

Cards are used sparingly — not everything needs a container.

**When to use a card:**

- To group related actions (e.g., "Next Up" service)
- To create a tappable surface
- To elevate content in a sheet or modal

**Card styling:**

- Background: `background-elevated` with subtle top gradient (white at 3% opacity)
- Corner radius: **20pt** with continuous corners (`.continuous`)
- Border: Gradient stroke from `border-subtle` at 50% to 20% opacity (top-left to bottom-right)
- Shadow: None
- Padding: **20pt** internal

**When NOT to use a card:**

- Simple lists of information
- Single-value displays
- When content can stand alone on the background

### Buttons

**Primary button:**

- Background: `accent` (#E89B3C) with subtle top gradient (white at 15% opacity)
- Text: `#121212` (dark text on amber)
- Corner radius: **14pt** with continuous corners
- Height: **52pt**
- Font: 16pt semibold
- Press state: Scale to 0.98, opacity 0.9

**Secondary button:**

- Background: `background-subtle`
- Border: `border-subtle` at 50% opacity
- Text: `text-primary`
- Same dimensions as primary

**Text button:**

- No background
- Text: `accent`
- Used for less prominent actions

### Status Indicators

**Status dot (in lists):**

- 10pt filled circle (status color)
- 7pt padding with 15% opacity background circle
- Total touch target: 24pt diameter
- Appears to the left of related text

**Status pill (in hero card):**

- Capsule shape
- Background: status color at 12% opacity
- 6pt filled dot + label text
- Text: status color at full opacity, 10pt bold, 1.2pt letter-spacing
- Padding: 10pt horizontal, 5pt vertical

---

## Signature Elements

### Dashboard Header

The header establishes context and allows vehicle switching.

**Anatomy:**

1. **Vehicle name** — 28pt bold, `text-primary`, -0.5pt tracking
2. **Info line** — Mileage • Year Make Model (15pt, mileage in `text-secondary`, model in `text-tertiary`)
3. **Chevron** — 14pt semibold, `text-tertiary`, right-aligned

**Behavior:**

- Entire header is tappable (opens vehicle picker sheet)
- No background — seamlessly integrated with screen
- No separate odometer display — mileage is inline with vehicle info

**Example:**
```
Daily Driver                                    ⌄
32,500 mi • 2022 Toyota Camry
```

### The "Next Up" Card

The centerpiece of the app. Shows the single most important upcoming service with vehicle visualization.

**Anatomy:**

1. **Status pill** — Top left, shows urgency (OVERDUE, DUE SOON, GOOD, SCHEDULED)
2. **Service name** — 24pt semibold, `text-primary`, -0.5pt tracking
3. **Countdown** — Large number (40pt light rounded) in status color + "days remaining/overdue" label
4. **Car silhouette** — Right side, `car.side.fill` SF Symbol (52pt) with gradient and status-colored glow
5. **Divider** — `border-subtle` at 50% opacity
6. **Mileage section** — "CURRENT" and "DUE AT" labels (10pt semibold, `text-tertiary`) with monospaced values

**Card styling:**

- Uses standard card styling (20pt padding, 20pt radius, gradient border)
- Car visualization has radial gradient glow matching status color

**Behavior:**

- Single tap opens service detail
- Visual weight draws eye immediately on app launch
- Status color propagates to pill, countdown number, due mileage, and car glow

### Service Row (Upcoming List)

Compact row for secondary services.

**Anatomy:**

1. **Status indicator** — 10pt dot with 24pt background circle
2. **Service info** — Name (17pt semibold) + due text (14pt regular)
3. **Miles remaining** — Right-aligned, 15pt semibold rounded
4. **Chevron** — 13pt medium, `text-tertiary` at 60% opacity

**Styling:**

- Horizontal padding: 16pt
- Vertical padding: 14pt
- Dividers: `border-subtle` at 30% opacity, 56pt leading inset

**Behavior:**

- Full row tappable
- Due text shows "In X days", "Due today", "Due tomorrow", or "X days overdue"
- Miles shows remaining miles or "Overdue" in status color

### Vehicle Selector (Sheet)

Bottom sheet for switching vehicles.

**Anatomy:**

1. **Vehicle list** — Each vehicle shows name and year/make/model
2. **Current vehicle** — Has checkmark indicator
3. **Add Vehicle** — Option at bottom

**Behavior:**

- Tap reveals vehicle list as sheet
- Current vehicle has checkmark
- "Add Vehicle" option at bottom
- Smooth transition when switching

---

## Section Headers

Small uppercase labels that organize content.

**Styling:**

- Font: 12pt semibold
- Color: `text-tertiary`
- Letter-spacing: 1.2pt
- Transform: Uppercase
- Margin bottom: 8pt

**Examples:** "NEXT UP", "UPCOMING"

---

## iOS 26 Liquid Glass

### Where to Apply Glass Effects

- **Navigation bar** — Standard glass treatment
- **Tab bar** — Standard glass treatment
- **Sheets/modals** — Glass background
- **Vehicle selector dropdown** — Glass container

### Where NOT to Apply Glass

- **Content cards** — Use solid `background-elevated`
- **Buttons** — Solid fills
- **Stacked elements** — Never glass on glass

### Glass Guidelines

- Use `GlassEffectContainer` to group elements sharing glass
- Apply `.glassEffect(.regular.interactive())` for tappable glass elements
- Let the system handle light/dark adaptation

---

## Motion & Animation

### Principles

- **Purposeful** — Animation communicates state change, not decoration
- **Quick** — 150-200ms for most transitions
- **Natural** — iOS spring curves, ease-out timing

### Key Moments

| Action             | Animation                                  |
| ------------------ | ------------------------------------------ |
| Screen transitions | Standard iOS push/present                  |
| Card press         | Scale to 0.98, opacity 0.9, 150ms ease-out |
| Button press       | Scale to 0.98, opacity 0.9, 150ms ease-out |
| Status change      | Color crossfade, 200ms                     |
| Service logged     | Checkmark + card dismissal                 |
| Vehicle switch     | Crossfade content, 250ms                   |

### What NOT to Animate

- Don't animate every element on screen load
- No bouncing, wobbling, or playful motion — keep it calm
- No loading spinners if avoidable (use skeleton states)

---

## Iconography

### Style

- **SF Symbols** as the primary icon set (native, consistent)
- Weight: Regular or Medium, matching text weight
- Size: Typically 13-17pt for UI, up to 52pt for hero elements

### Key Icons Used

| Icon               | Usage                          |
| ------------------ | ------------------------------ |
| `car.side.fill`    | Vehicle visualization, empty states |
| `chevron.down`     | Dropdown indicator             |
| `chevron.right`    | List disclosure                |
| `checkmark`        | Success states, selection      |

---

## Accessibility

### Minimum Requirements

- **Contrast ratios:** 4.5:1 for body text, 3:1 for large text
- **Touch targets:** Minimum 44pt x 44pt
- **Dynamic Type:** Support all iOS text sizes
- **VoiceOver:** All interactive elements labeled

### Color Independence

- Never use color alone to convey information
- Status always includes text label, not just colored dot
- Due dates shown as text alongside status indicator

---

## Implementation Notes

### Asset Catalog Colors

All colors are defined in `Assets.xcassets/Colors/` with light/dark variants:
- BackgroundPrimary
- BackgroundElevated
- BackgroundSubtle
- TextPrimary
- TextSecondary
- TextTertiary
- BorderSubtle
- Accent
- AccentMuted
- StatusOverdue
- StatusDueSoon
- StatusGood
- StatusNeutral

### Design System Files

Located in `checkpoint/DesignSystem/`:
- `Theme.swift` — Color references, layout constants, card/button styles
- `Typography.swift` — Font scale, text style modifiers
- `Spacing.swift` — Spacing tokens, screen padding modifier

---

## Summary

| Aspect         | Direction                                       |
| -------------- | ----------------------------------------------- |
| **Feeling**    | Confident calm — everything's handled           |
| **Mode**       | Dark-first, light fully supported               |
| **Accent**     | Amber (#E89B3C) — warm, automotive, distinctive |
| **Typography** | SF Pro, hierarchy through weight/size           |
| **Density**    | Generous but purposeful spacing                 |
| **Decoration** | None — every element earns its place            |
| **Animation**  | Subtle, quick, purposeful                       |

---

_Last updated: January 2026_
