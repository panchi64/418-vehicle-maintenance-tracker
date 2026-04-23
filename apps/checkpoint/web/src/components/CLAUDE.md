# Components — Landing Page Sections

Each component is a self-contained section of the homepage. They are composed in order in `routes/index.tsx`.

## Section Order (Homepage)

```
Navbar          — Fixed top nav with anchor links + mobile hamburger
Hero            — Full-screen hero with tagline, App Store badge, phone mockup
ValueProps      — Three-column value proposition cards
FeatureShowcase — Feature grid with screenshots
ThemesGallery   — App theme preview tiles
Pricing         — Free vs Pro pricing cards
ImportSection   — Competitor import callout
Privacy         — Privacy-first messaging
FAQ             — Accordion-style Q&A
FinalCTA        — Bottom call-to-action with App Store link
Footer          — Site links, legal links, copyright
```

## Standalone Page Component

- `Privacy.tsx` — Also used as a section on the homepage (distinct from `routes/privacy-policy.tsx`)

## Patterns

- Components are plain functions (no props) — they own their content and layout
- Scroll animation: Add `fade-in-on-scroll` class to elements; `useScrollFade()` in the parent route handles the rest
- Color references use inline `style={{ color: "var(--token)" }}` rather than Tailwind color classes
- Responsive layout via Tailwind grid/flex utilities (`grid-cols-1 lg:grid-cols-2`, etc.)
- In-page navigation uses `document.getElementById().scrollIntoView()` with smooth behavior
