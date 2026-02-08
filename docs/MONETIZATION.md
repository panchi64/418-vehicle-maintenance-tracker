# Checkpoint — Monetization Strategy

> Finalized pricing, tiers, and implementation details for Checkpoint's monetization model. This is the source of truth for what's free, what's paid, and how the payment flows work.

---

## Core Philosophy

- **Free should feel complete** — Users get a fully functional app, not a crippled trial
- **No ads, ever** — Ads degrade the experience and erode trust
- **Pay for value, not access** — Premium features provide genuine extra value, not artificial gates
- **Server costs justify subscriptions** — Only charge recurring fees for features with ongoing infrastructure costs
- **Support the developer** — Offer a way for happy users to contribute beyond purchases
- **No surprises** — Price increases are communicated upfront; early adopters are rewarded

---

## Pricing Tiers

### Free Tier ($0, forever)

> The full app experience for most users. Everything currently implemented ships free.

| Category | Features |
|----------|----------|
| **Vehicles** | Up to 3 vehicles |
| **Core Features** | Service logging, reminders, mileage tracking, cost tracking, service clustering, seasonal reminders |
| **Cost Analytics** | Total/YTD/monthly spending, category breakdowns, cost-per-mile, trend charts |
| **iCloud Sync** | Native CloudKit sync across iOS devices — no account needed |
| **Widgets** | Home Screen (small/medium), Lock Screen (inline/circular/rectangular), interactive "Done" button |
| **Apple Watch** | Full watch app, complications, mileage update, mark service done |
| **Siri** | "What's due?", "List upcoming services", "Update mileage" voice commands |
| **OCR** | On-device Vision framework for odometer reading and receipt text extraction |
| **VIN Decode** | NHTSA VIN lookup, on-device VIN OCR, auto-populate vehicle details |
| **Recall Alerts** | NHTSA recall detection with safety-critical flags |
| **Notifications** | Full reminder system (30/7/1-day), mileage-based, service clustering, marbete, yearly roundup |
| **Export** | PDF service history, CSV import (Fuelly, Drivvo, Simply Auto, custom) |
| **Dynamic App Icon** | Icon changes based on service urgency |
| **Theme** | Default dark mode with amber accent |

**Why 3 vehicles free (not unlimited):**
- Covers single-car owners and most couples — the majority of users
- No marginal server cost, but provides a natural upgrade path for multi-vehicle households and enthusiasts
- Still more generous than competitors who limit to 1-2 vehicles

**Why iCloud sync is free:**
- Uses Apple's CloudKit — zero server cost
- Essential for data safety (the #1 user anxiety in the category)
- Strong differentiator vs competitors who paywall basic sync

**Why no ads:**
- Ads feel cheap and erode premium positioning
- Top complaint in competitor reviews
- A tip jar with a gentle modal is less annoying and likely generates more long-term revenue

---

### Pro (One-Time Purchase)

> Power user features. Pay once, own forever. All future Pro features included at no extra cost.

**Pricing:** ~~$14.99~~ **$9.99** (launch price)

The app displays the full $14.99 price crossed out with the $9.99 launch price. This sets honest expectations — users know the price will increase, and early adopters feel rewarded. Price rises to $14.99 when AI-powered OCR ships.

| Feature | Description | Status |
|---------|-------------|--------|
| **Unlimited Vehicles** | 4+ vehicles (free tier allows 3) | v1 |
| **Basic Theme Collection** | 4-6 unlockable themes (typography, layout density, color schemes, light mode) | v1 |
| **AI Receipt Auto-Fill** | Server-side smart extraction from receipt/invoice photos — auto-populates date, cost, vendor, services | Future |
| **Deeper Vehicle Insights** | Advanced analytics, predictive maintenance trends, health scoring | Future |

**Why one-time:**
- No ongoing server cost for current Pro features
- Users strongly prefer one-time purchases — subscription fatigue is severe in this category
- Builds goodwill and trust; early adopters become advocates

**Conversion flow:**
1. User tries to add a 4th vehicle → paywall sheet appears
2. Sheet shows ~~$14.99~~ $9.99 launch pricing with feature list
3. StoreKit 2 purchase flow → vehicle unlocked immediately

**Price increase trigger:**
- When AI receipt auto-fill ships, Pro price moves to $14.99
- Existing Pro owners get the new feature automatically at no extra charge

---

### Tip Jar ($1.99 / $4.99 / $9.99)

> For users who love the app and want to support development. Tips unlock exclusive themes.

**Tip Tiers:**

| Tier | Price | You Keep (after Apple 15%) |
|------|-------|---------------------------|
| Small | $1.99 | $1.69 |
| Medium | $4.99 | $4.24 |
| Large | $9.99 | $8.49 |

No custom amounts — StoreKit does not support arbitrary pricing. Three fixed tiers only.

**Tip jar is NOT Pro.** A $9.99 tip does not unlock Pro features. Tips and Pro are separate purchases with separate value propositions.

#### Tip Jar Surfaces

**1. Settings (passive, always available):**
- "Support Checkpoint" row in Settings, visible to all users including Pro owners
- Shows the three tip tiers with a brief thank-you message
- Always accessible, never removed

**2. Modal prompt (active, conditional):**
- Appears once per session, triggered only after the user completes a meaningful action (logging a service, updating mileage, marking a service done)
- **Suppressed permanently** if the user has purchased Pro
- If dismissed, does not appear again until the next app session (next app launch from cold/background)
- Gentle tone — "Enjoying Checkpoint? Help keep it going." Not guilt-tripping

#### Theme Gacha System

Each tip unlocks **one random theme** from the exclusive tip-only collection:

| Theme Source | How to Unlock |
|-------------|---------------|
| Default (dark/amber) | Free — ships with the app |
| Basic collection (4-6 themes) | Buy Pro |
| Rare/exclusive themes | Tip (any amount) — one random theme per tip |

- **Rare themes are tip-exclusive** — they cannot be unlocked by purchasing Pro. This gives Pro owners a reason to tip.
- If the user already owns all available tip themes, the tip still processes (it's a tip, not a purchase), but no new theme is unlocked. Show a "You've collected them all — thank you!" message.
- Themes are dramatic: different typography, layout density, color palettes, light/dark variants — not just accent color swaps.
- Each tip surfaces a reveal animation showing which theme was unlocked.

---

### Subscription (Future — NOT in v1)

> Server-based features with genuine ongoing infrastructure costs. Not mentioned anywhere in the v1 UI.

**Price point:** TBD (~$9.99–$14.99/year based on market research)

**Planned features:**

| Feature | Description | Server Cost Justification |
|---------|-------------|--------------------------|
| **AI-Powered OCR** | High-accuracy server-side receipt/invoice extraction | LLM API costs per scan |
| **Cloud Account Sync** | Cross-platform sync via cloud infrastructure | Database hosting, real-time sync |
| **Family Sharing** | Multi-user access to shared vehicles across Apple IDs | Multi-tenant infrastructure |
| **Desktop/Web Access** | Browser-based access to vehicle data | Web hosting, API server |

**Why not in v1:**
- None of these features exist yet
- Mentioning future paid features to new users risks souring first impressions
- Subscription should only appear when the features are ready to deliver value on day one

**Graceful degradation:** If a subscription lapses, data remains accessible (read-only). No data hostage situations.

---

## Revenue Model

### Apple's Cut

Checkpoint qualifies for Apple's **Small Business Program** (under $1M/year revenue): **15% commission** on all transactions.

### Projected Revenue (per 10,000 downloads)

| Source | Conservative (low conversion) | Moderate | Optimistic |
|--------|-------------------------------|----------|------------|
| Pro at $9.99 (2-4% conversion) | $1,698 | $2,548 | $3,397 |
| Tips at avg $4 net (0.5-1.5% of users) | $170 | $425 | $764 |
| **Total net revenue** | **$1,868** | **$2,973** | **$4,161** |

Revenue scales linearly with downloads. At 50,000 downloads, moderate scenario = ~$14,800/year.

### Target Revenue Mix (at maturity, post-subscription launch)

| Source | Estimated % |
|--------|-------------|
| Pro Bundle | 35-45% |
| Subscription | 40-50% |
| Tip Jar | 5-15% |

---

## Implementation Requirements (v1)

### StoreKit 2 Infrastructure

| Component | Description |
|-----------|-------------|
| **Product IDs** | `pro.unlock`, `tip.small`, `tip.medium`, `tip.large` |
| **StoreManager** | Singleton class handling product loading, purchases, entitlement state |
| **Entitlement checks** | `isPro` boolean gating vehicle limit and basic themes |
| **Receipt validation** | On-device via StoreKit 2 (no server needed) |
| **Transaction listener** | Background listener for purchases completed on other devices |
| **Restore purchases** | Required by App Store — button in Settings |

### UI Components

| Component | Description |
|-----------|-------------|
| **Pro paywall sheet** | Triggered when adding 4th vehicle. Shows ~~$14.99~~ $9.99, feature list, purchase button |
| **Tip jar view** | Settings row → detail view with 3 tiers and theme reveal |
| **Tip modal** | Post-action modal, once per session, suppressed for Pro owners |
| **Theme picker** | Settings view showing owned themes, locked themes with unlock method |
| **Theme reveal animation** | Shown after tip purchase — reveals which theme was unlocked |

### Theme System

| Requirement | Detail |
|-------------|--------|
| **Theme model** | Name, preview, colors, typography, layout properties, rarity tier (basic/rare), unlock method |
| **Theme storage** | UserDefaults or SwiftData for owned themes and active theme |
| **Theme application** | Environment-based injection so all views respond to theme changes |
| **Minimum themes for v1** | 1 default + 4-6 basic (Pro) + 3-5 rare (tip gacha) |

---

## What We Charge For vs. What's Free

### Paid

| Feature | Why it's paid |
|---------|---------------|
| 4+ vehicles | Natural upgrade path, funds development |
| Custom themes | Nice-to-have, not need-to-have |
| AI OCR (future) | Real server/API costs |
| Cloud sync (future) | Real infrastructure costs |
| Family sharing (future) | Real multi-tenant costs |

### Free

| Feature | Why it's free |
|---------|---------------|
| Core tracking & reminders | The app's primary purpose — never paywalled |
| Cost analytics & charts | Part of the core value proposition |
| Basic OCR | On-device, zero ongoing cost |
| iCloud sync | Apple's CloudKit, zero server cost |
| Widgets, Watch, Siri | Platform integration is core, not premium |
| PDF export & CSV import | Data portability builds trust |
| Recall alerts | Safety-critical — never paywalled |
| 3 vehicles | Covers the vast majority of users |

---

## Upgrade Flow Principles

- **Show value before asking** — Let users experience the app before any paywall appears
- **No dark patterns** — Clear pricing, easy cancellation, no tricks, no hidden charges
- **Contextual prompts** — Offer upgrades when relevant (adding 4th vehicle), not randomly
- **Honest pricing** — Launch discount shown with original price, no bait-and-switch
- **Graceful limits** — Free users never lose access to data they've already entered

---

## Competitive Positioning

| Competitor Approach | Checkpoint's Approach |
|--------------------|-----------------------|
| Free with intrusive ads | Free with no ads, ever |
| 1-2 vehicle limit on free | 3 vehicles free |
| Everything behind subscription | Core app fully free; subscription only for server features |
| Monthly subscription ($5+/mo) | One-time Pro purchase ($9.99) |
| Surprise price increases | ~~$14.99~~ $9.99 launch price shown upfront |
| Tips give nothing | Tips unlock exclusive themes |
| Generic "premium" paywall | Specific, justified feature gates |

---

## Key Metrics to Track

| Metric | What it tells you |
|--------|-------------------|
| Free → Pro conversion rate | Is the 3-vehicle limit an effective gate? |
| Tip jar contribution rate | Is the modal timing/tone right? |
| Tip repeat rate | Is the gacha system encouraging repeat tips? |
| Theme collection completion | Do you need more rare themes? |
| 4th vehicle attempt rate | How many users hit the gate? |
| Pro purchase → tip rate | Are Pro users still tipping for rare themes? |

---

## Open Questions (Post-v1)

- [ ] Exact subscription price point ($9.99 or $14.99/year)
- [ ] Should Pro be included in subscription, or separate?
- [ ] Family Sharing: free read-only access for invited members?
- [ ] Regional pricing adjustments?
- [ ] When to raise Pro price to $14.99 (tied to AI OCR ship date)
- [ ] How many rare themes to ship at launch vs. add over time?

---

_Last updated: February 2026_
