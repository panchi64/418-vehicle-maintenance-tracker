# DesignSystem - Visual Design Tokens

This directory contains the design system tokens and modifiers that define Checkpoint's visual language.

## Files

| File | Purpose |
|------|---------|
| `Theme.swift` | Colors, button styles, card modifiers |
| `Typography.swift` | Font definitions and text styles |
| `Spacing.swift` | Spacing constants (4pt base unit) |

## Design Philosophy

**Brutalist Aesthetic:**
- Zero corner radius (sharp edges)
- High contrast
- Bold typography
- Functional over decorative

**Dark Mode First:**
- Primary background: near-black
- Amber accent (#E89B3C)
- Status colors for urgency

## Color Tokens

### Backgrounds
```swift
Theme.backgroundPrimary    // Near-black base
Theme.backgroundElevated   // Slightly lighter for cards
Theme.backgroundSubtle     // Subtle differentiation
```

### Text
```swift
Theme.textPrimary          // White/near-white
Theme.textSecondary        // Muted text
Theme.textTertiary         // Very subtle text
```

### Accent
```swift
Theme.accent               // Amber #E89B3C
Theme.accentMuted          // Dimmed amber
```

### Status Colors
```swift
Theme.statusOverdue        // Red - immediate attention
Theme.statusDueSoon        // Yellow/amber - upcoming
Theme.statusGood           // Green - no action needed
Theme.statusNeutral        // Gray - no due date set
```

## Typography Scale

All fonts use SF Pro (system font):

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayLarge` | 34pt | Bold rounded | Hero numbers |
| `headlineLarge` | 28pt | Semibold | Screen titles |
| `headline` | 22pt | Semibold | Section headers |
| `title` | 17pt | Semibold | Card titles |
| `bodyText` | 17pt | Regular | Body copy |
| `bodySecondary` | 15pt | Regular | Secondary text |
| `caption` | 13pt | Medium | Labels, metadata |
| `captionSmall` | 11pt | Regular | Fine print |

Usage:
```swift
Text("Oil Change")
    .font(Typography.title)
```

## Spacing System

Base unit: 4pt

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Tight spacing |
| `sm` | 8pt | Component internal |
| `listItem` | 12pt | List item padding |
| `md` | 16pt | Standard spacing |
| `screenHorizontal` | 20pt | Screen edge padding |
| `lg` | 24pt | Section gaps |
| `xl` | 32pt | Major sections |
| `xxl` | 48pt | Hero spacing |

Usage:
```swift
VStack(spacing: Spacing.md) {
    // ...
}
.padding(.horizontal, Spacing.screenHorizontal)
```

## View Modifiers

### Card Style
```swift
.cardStyle()  // Elevated card with gradient overlay
```
Applies:
- Background color
- Zero corner radius
- Subtle gradient overlay
- Shadow

### Screen Padding
```swift
.screenPadding()  // Standard horizontal padding
```

### Button Styles
```swift
.buttonStyle(.primary)    // Amber filled button
.buttonStyle(.secondary)  // Outlined button
```

## Usage Guidelines

1. **Always use tokens** - Never hardcode colors, fonts, or spacing
2. **Zero corner radius** - No `cornerRadius()` modifiers
3. **Dark backgrounds** - Cards float on dark backgrounds
4. **Status colors for meaning** - Use status colors only for urgency indicators
5. **Typography hierarchy** - Use appropriate text styles for information hierarchy

## Example Component

```swift
struct ExampleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Title")
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)

            Text("Description")
                .font(Typography.bodySecondary)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Spacing.md)
        .cardStyle()
    }
}
```
