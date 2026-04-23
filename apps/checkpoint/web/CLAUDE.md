# Checkpoint Website — Marketing Site

Marketing and landing page for the Checkpoint iOS app.

**Tech Stack:** SolidJS, Solid Start (Vinxi), Tailwind CSS v4, TypeScript
**Deployment:** Cloudflare Pages (`cloudflare-pages` preset in `app.config.ts`)
**Package Manager:** Bun
**Node Requirement:** >=22

## Commands

```bash
# Dev server
bun run dev

# Production build
bun run build

# Start production server
bun run start
```

## Architecture

- **Framework:** Solid Start with file-based routing via `@solidjs/router`
- **SSR:** Server-side rendered with `entry-server.tsx` / `entry-client.tsx`
- **Meta tags:** `@solidjs/meta` (`<Title>`, `<Meta>`) for SEO — set per-route
- **Routing:** File-based — each file in `src/routes/` becomes a page

### Directory Structure

```
checkpoint-website/
├── src/
│   ├── components/     # Landing page sections (see components/CLAUDE.md)
│   ├── hooks/          # useScrollFade — IntersectionObserver scroll animation
│   └── routes/         # File-based pages (index, privacy, terms, support, press-kit)
├── public/             # Static assets (screenshots, favicons, App Store badge)
└── app.config.ts       # Solid Start + Tailwind + Cloudflare config
```

## Design Language

Brutalist aesthetic matching the iOS app — but with a different color palette:

- **Primary background:** `--bg-primary: #0033BE` (deep blue)
- **Text:** `--text-primary: #F5F0DC` (warm off-white)
- **Frame:** 35px off-white border around viewport (16px on mobile)
- **Font:** JetBrains Mono (monospace everywhere)
- **Zero corner radius:** Enforced globally via `border-radius: 0 !important` in `app.css`
- **Labels:** ALL CAPS, 0.12em letter-spacing, 12px monospace

### CSS Conventions

All design tokens live in `app.css` as CSS custom properties. Styles use a mix of:
- Tailwind utility classes (layout, spacing, responsive)
- Custom CSS classes in `app.css` (`.btn-primary`, `.label`, `.section-padding`, `.pricing-card`, etc.)
- Inline `style={{ }}` for color token references (`var(--text-primary)`)

### Responsive Breakpoints

- Desktop: default
- Tablet: `max-width: 1199px`
- Mobile: `max-width: 768px` (also `md:` Tailwind prefix)

## Important Notes

- Images use AVIF format for optimization
- `useScrollFade()` must be called in each page that uses `.fade-in-on-scroll` elements
- The homepage composes all section components in order inside a `.frame` wrapper
- Legal pages (privacy, terms) use the `.legal-prose` class for consistent typography
