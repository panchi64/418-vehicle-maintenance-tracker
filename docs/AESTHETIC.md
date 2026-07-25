# Aesthetic Philosophy — 418 Studio

This document defines the **visual identity** shared across 418 Studio products: the Checkpoint website, the Checkpoint iOS app, and Biombo.

It covers what things *look* like. It does **not** cover how screens are structured, how information is ranked, or how forms behave — those are usability concerns and they live in [`SURFACE_DOCTRINE.md`](SURFACE_DOCTRINE.md). Read that one before designing any screen.

## How to read this document

Every rule below is tagged:

- **[REQUIREMENT]** — breaking it costs the *user* something: legibility, comprehension, accessibility, or the ability to complete a task. Not negotiable per-surface.
- **[PREFERENCE]** — breaking it costs *brand consistency*. Deliberate exceptions are allowed when a surface has a reason; say what the reason is.

**This distinction is load-bearing.** The app previously accumulated a large class of usability problems because a preference — "every character occupies equal space, this is typographic brutalism" — was applied as though it were a requirement, producing screens where every datum carried identical visual weight and nothing could be scanned. A monospace typeface is a *typeface choice*. It is not a mandate to render all content at one size and weight, and it never was.

When you cite this document to justify a decision, cite the tag too.

---

## Core Identity

**Brutalist-Tech-Modernist** — merging three philosophies: **[PREFERENCE]**

- **Brutalism**: unadorned, structural honesty, confidence through restraint
- **Tech/Developer culture**: monospace typography, terminal aesthetics, technical precision
- **Modernism**: grid-based layouts, geometric clarity, functional purity

The result should feel **technical without being cold**, **minimal without being sparse**, and **confident without being aggressive**.

---

## Color

### The house palette **[PREFERENCE]**

- **Cerulean Blue `#0033BE`** — a saturated, electric royal blue. Bold and unapologetic, nearly aggressive in intensity, sophisticated in saturation.
- **Off-White `#F5F0DC`** — a warm, cream-toned beige with paper-like qualities. Not stark white; aged, analog, tactile.

Depth comes from opacity levels of the off-white (100%, 90%, 70%, 40%) rather than new hues. Inversions (off-white ground with cerulean text) are for high-impact moments only.

### Where the two-color rule applies, and where it doesn't

The two-color palette is the **418 house default** — it governs the website and Biombo's default provider (`AestheticBrutalistTheme`). It is **not** a platform-wide constraint:

- **Semantic status color is a [REQUIREMENT], not an exception to apologize for.** Overdue / due-soon / good / neutral must be distinguishable, and the default Checkpoint theme defines `#FF6B6B` / `#F7AD55` / `#38D9A9` / `#A5ADB5` for exactly that. Maintenance urgency is the product's core signal; it outranks palette purity.
- **Checkpoint is themed.** `Resources/Themes.json` ships **eight** themes with eight different accents, some unlocked via tips. "Never introduce color variations outside these two values" describes the *default* theme, not the app.
- **Never encode meaning in color alone. [REQUIREMENT]** Status must also carry a label, a shape, or a position. Color-blind users and sunlight both defeat hue-only signals.

Any new color token goes through `ThemeProviding` so every theme answers for it — see [`packages/DesignKit/CLAUDE.md`](../packages/DesignKit/CLAUDE.md).

### Gradients and shadows **[PREFERENCE]**

Avoid. The exceptions that exist (glass effects, status glows) are deliberate and named in `DesignSystem/Theme.swift`; don't add more without a reason.

---

## Typography

### Font **[PREFERENCE]**

**JetBrains Mono** across the interface, bundled in DesignKit. Non-monospace themes fall back to SF with the matching design — see `DesignSystem/Typography.swift`.

Monospace signals developer culture, terminal aesthetics, precision, and a rejection of corporate sans-serifs. It creates rhythm and structure.

### Hierarchy **[REQUIREMENT]**

**Scale and weight must do real work.** Move confidently between large and small; the monospace foundation keeps extreme scales cohesive. But the requirement is not "use a wide range somewhere on the screen" — it is:

- **Adjacent levels of importance must be visually distinguishable on at least two channels** (size, weight, color, spacing, position, enclosure). One channel is not enough, and color alone is never enough.
- **A screen where all content sits within one or two adjacent steps of the scale is a defect**, regardless of how large its largest element is. A 56pt hero above a wall of uniform 11pt text is still a wall.

Guidelines: **[PREFERENCE]**
- Uppercase for labels, metadata, and system information — but **not** for long user-authored content, where it destroys word-shape recognition and slows reading.
- Sentence case for body copy and conversational content.
- Never italics (monospace italics break the mechanical rhythm).

### Dynamic Type **[REQUIREMENT]**

Text must survive the user's chosen text size. Use the `textStyle:` font accessors where scaling matters. A layout that only works at the default size is broken.

---

## Spatial Design

### The grid **[PREFERENCE]**

Everything aligns to an invisible grid: multi-column layouts, precise gutters, mathematical spacing relationships. Use the 4pt `Spacing` scale; never hardcode values.

### Whitespace **[REQUIREMENT]**

Generous, intentional negative space. The design must breathe.

This is a requirement rather than taste because **proximity communicates grouping**: elements packed together read as related whether or not they are. Spacing is how a screen tells the user what belongs with what, so under-spacing actively misinforms.

### Touch targets **[REQUIREMENT]**

Minimum 44×44pt for anything tappable, with `contentShape` set so the whole area responds. See `DesignSystem/TouchTarget.swift`.

### Unconventional positioning **[PREFERENCE — web only]**

On the **website**, break conventions deliberately: logo top-right, navigation bottom-right, content vertically centered and floating. This creates an inverted hierarchy where chrome hugs the edges and content occupies the center, like a gallery exhibition.

**Do not carry this to the apps.** iOS users navigate by platform convention; relocating standard controls costs comprehension for no brand gain. Native placement wins.

---

## Interface Language

### Borders and dividers **[PREFERENCE]**

2px solid lines at ~20% opacity for section breaks. Architectural — defining space without clutter.

### Corners **[PREFERENCE]**

Sharp 90° edges. No `cornerRadius`.

### Metadata and system information **[PREFERENCE]**

Treat the interface as a technical readout — version numbers, status indicators, timestamps, numeric data in monospace. The product is a machine and we don't hide it.

Caveat: this is a *styling* preference for genuine metadata. It is not a reason to present a user's car, cost, or maintenance history as a spec sheet when a clearer structure exists.

### Motion **[REQUIREMENT]**

**Motion must be informative, never decorative.**

- Collapsible and accordion content uses **fade-only** transitions (`.transition(.opacity)`), never slide (`.move(edge:)`). Content appears and disappears in place.
- Prefer instant state changes over smooth ones for anything the user is waiting on.
- Micro-interactions (opacity, rotation) only.

Motion is a requirement because animation that doesn't explain a state change is noise the user has to filter — and on a maintenance app, attention spent filtering is attention not spent on the task.

---

## Content

### Voice and tone **[PREFERENCE]**

- **Direct and confident** — no marketing fluff
- **Technical but accessible** — precision without pretension
- **Short sentences** — clarity over cleverness

### Information architecture **[PREFERENCE]**

Present information in discrete, labeled blocks: section numbers (01, 02, 03), uppercase field labels (STATUS, VERSION, COORDS), data in monospace. Think specification sheets and technical documentation.

**Requirement that overrides it:** discrete labeled blocks are a *presentation* of a hierarchy, never a substitute for having one. Every block still needs a single most-important element. See `SURFACE_DOCTRINE.md`.

### Localization **[REQUIREMENT]**

All user-facing strings go through the string catalog (`L10n` in Checkpoint), in EN and ES. **Never build a display string by concatenation** — use format keys, so grammar and word order survive translation.

---

## What to avoid

**[PREFERENCE] — brand consistency:**
- Rounded corners or soft edges
- Gradients or shadows beyond the named exceptions
- Script or serif fonts
- Decorative elements or ornamentation
- Skeuomorphic textures
- Photographic imagery unless necessary
- Marketing language or superlatives

**[REQUIREMENT] — these cost the user:**
- Meaning carried by color alone
- Uniform visual weight across content of differing importance
- Uppercase applied to long-form or user-authored text
- Layouts that break at larger Dynamic Type sizes
- Tap targets under 44pt
- Decorative motion
- Hardcoded, unlocalized strings

---

## The Overall Mood

The aesthetic should feel **confident** (we don't need flashy design to convince you), **technical** (made by people who understand systems), **intentional** (every decision deliberate), **focused** (clarity and function over decoration), and **warm-but-minimal** (the off-white keeps it from feeling cold).

**Brutalism with a soul.** The design says: "We know our craft. We don't need to impress you with complexity. The work speaks for itself."

And the work speaking for itself requires that it can be *read*. Restraint is not the same as flatness — the most restrained thing a screen can do is make one thing obviously matter most.
