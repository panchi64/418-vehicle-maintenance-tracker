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

**Primary:** System San Francisco (SF Pro) for native iOS feel, or a custom font for more distinction.

**Recommended custom option:** Satoshi or General Sans

- Geometric, modern, highly readable
- Works at small sizes (data labels) and large sizes (headlines)
- Has enough character to not feel generic

### Type Scale

| Name             | Size | Weight         | Line Height | Usage                                   |
| ---------------- | ---- | -------------- | ----------- | --------------------------------------- |
| `headline-large` | 28pt | Semibold (600) | 34pt        | Screen titles                           |
| `headline`       | 22pt | Semibold (600) | 28pt        | Section headers, "Next Up" service name |
| `title`          | 17pt | Semibold (600) | 22pt        | Card titles, emphasis                   |
| `body`           | 17pt | Regular (400)  | 22pt        | Primary content                         |
| `body-secondary` | 15pt | Regular (400)  | 20pt        | Supporting content                      |
| `caption`        | 13pt | Regular (400)  | 18pt        | Labels, metadata                        |
| `caption-small`  | 11pt | Medium (500)   | 14pt        | Timestamps, tertiary info               |

### Typography Rules

- **Hierarchy through weight and size only** — no italics, no decorative treatments
- **Sentence case for UI text** — "Oil change due" not "Oil Change Due"
- **No all-caps** except for very short labels (e.g., "OVERDUE" status pill)
- **Numbers: tabular figures** — for alignment in data displays

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
| `space-xl`  | 32pt  | Major sections, screen padding     |
| `space-2xl` | 48pt  | Hero spacing, top of screen        |

### Layout Guidelines

- **Screen horizontal padding:** 20pt (allows content to breathe while maximizing space)
- **Card internal padding:** 16pt
- **Between list items:** 12pt
- **Between sections:** 32pt

---

## Components

### Cards

Cards are used sparingly — not everything needs a container.

**When to use a card:**

- To group related actions (e.g., "Next Up" service)
- To create a tappable surface
- To elevate content in a sheet or modal

**Card styling:**

- Background: `background-elevated`
- Corner radius: 16pt
- Border: None by default, or 1pt `border-subtle` if needed for definition
- Shadow: None (Liquid Glass handles elevation) or very subtle in light mode
- Padding: 16pt internal

**When NOT to use a card:**

- Simple lists of information
- Single-value displays
- When content can stand alone on the background

### Buttons

**Primary button:**

- Background: `accent` (#E89B3C)
- Text: `#121212` (dark text on amber)
- Corner radius: 12pt
- Height: 50pt
- Font: `body` weight semibold

**Secondary button:**

- Background: `background-subtle`
- Text: `text-primary`
- Same dimensions as primary

**Text button:**

- No background
- Text: `accent`
- Used for less prominent actions

### Status Indicators

**Status dot:**

- 8pt circle
- Filled with status color
- Appears to the left of related text

**Status pill:**

- Small rounded rectangle
- Background: status color at 15% opacity
- Text: status color at full opacity
- Font: `caption` or `caption-small`, medium weight
- Example: light coral background with coral "OVERDUE" text

---

## Signature Elements

### The "Next Up" Card

The centerpiece of the app. Shows the single most important upcoming service.

**Anatomy:**

1. **Status dot** — Color indicates urgency (top left)
2. **Service name** — Large, `headline` size (e.g., "Oil Change")
3. **Due indicator** — `body-secondary`, uses accent color (e.g., "Due in 12 days")
4. **Mileage context** — `caption`, secondary text (e.g., "or 500 miles")
5. **Quick action** — Subtle button or tap target to log completion

**Behavior:**

- Single tap opens service detail
- Visual weight draws eye immediately on app launch
- Animates subtly when status changes

### Vehicle Selector

Top-center dropdown showing current vehicle.

**Anatomy:**

1. **Vehicle name** — `title` weight, centered
2. **Dropdown indicator** — Subtle chevron
3. **Tap target** — Generous, full width of label area

**Behavior:**

- Tap reveals vehicle list (sheet or dropdown)
- Current vehicle has checkmark
- "Add Vehicle" option at bottom
- Smooth transition when switching

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
- **Quick** — 200-300ms for most transitions
- **Natural** — iOS spring curves, not linear

### Key Moments

| Action             | Animation                                           |
| ------------------ | --------------------------------------------------- |
| Screen transitions | Standard iOS push/present                           |
| Card press         | Subtle scale down (0.98) on press                   |
| Status change      | Color crossfade, 200ms                              |
| Service logged     | Checkmark + card dismissal, satisfying confirmation |
| Vehicle switch     | Crossfade content, 250ms                            |

### What NOT to Animate

- Don't animate every element on screen load
- No bouncing, wobbling, or playful motion — keep it calm
- No loading spinners if avoidable (use skeleton states)

---

## Iconography

### Style

- **SF Symbols** as the primary icon set (native, consistent)
- Weight: Regular or Medium, matching text weight
- Size: Typically 17-22pt, optically aligned with text

### Custom Icons

If custom icons are needed:

- Match SF Symbols stroke weight (~1.5pt at 24pt size)
- Simple, geometric forms
- No fill by default, filled variant for selected states

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
- Icons accompany color indicators where possible

---

## File & Asset Naming

### Convention

```
[component]-[variant]-[state].[extension]

Examples:
- button-primary-default.png
- icon-service-oil.svg
- card-next-up-overdue.png
```

---

## Summary

| Aspect         | Direction                                       |
| -------------- | ----------------------------------------------- |
| **Feeling**    | Confident calm — everything's handled           |
| **Mode**       | Dark-first, light fully supported               |
| **Accent**     | Amber (#E89B3C) — warm, automotive, distinctive |
| **Typography** | Clean sans-serif, hierarchy through weight/size |
| **Density**    | Generous but purposeful spacing                 |
| **Decoration** | None — every element earns its place            |
| **Animation**  | Subtle, quick, purposeful                       |

---

_Last updated: January 2026_
