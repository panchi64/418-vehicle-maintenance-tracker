# Vehicle Maintenance Tracker - Monetization Strategy

> Guiding principles for pricing and feature tiers. The goal is a sustainable business model that respects users while funding ongoing development.

---

## Core Philosophy

- **Free should feel complete** — Users get a fully functional app, not a crippled trial
- **No ads, ever** — Ads degrade the experience and erode trust
- **Pay for value, not access** — Premium features provide genuine extra value, not artificial gates
- **Server costs justify subscriptions** — Only charge recurring fees for features with ongoing infrastructure costs
- **Support the developer** — Offer a way for happy users to contribute beyond purchases

---

## Pricing Tiers

### Free Tier

> The full app experience for most users. No artificial limits, no ads.

**Included:**

| Category | Features |
| -------- | -------- |
| **Vehicles** | Unlimited vehicles |
| **Core Features** | Service logging, reminders, mileage tracking, cost tracking |
| **Widgets** | Home Screen, Lock Screen, CarPlay Dashboard |
| **Apple Watch** | Complication and Watch app |
| **OCR** | Basic on-device OCR (Vision framework) |
| **Notifications** | Full reminder system (30/7/1-day defaults) |
| **Export** | Basic data export |

**Why unlimited vehicles free:**
- No server cost to us — it's all local storage
- Strong differentiator vs competitors who limit to 2-8 vehicles
- Families are exactly the users who'd value Family Sharing (paid)

**Why no ads:**
- Ads feel cheap and erode premium positioning
- Users hate them — it's a top complaint in competitor reviews
- The freemium model works without them

---

### Pro Bundle (One-Time Purchase)

> Advanced features for power users. Pay once, own forever.

**Price point:** TBD (research suggests $7.99–$14.99 range)

**Included:**

| Feature | Description |
| ------- | ----------- |
| **Advanced Reports** | Detailed analytics, spending trends, cost breakdowns |
| **PDF Export** | Professional vehicle history documents with optional receipt attachments |
| **Theme Customization** | Custom colors, app icons, personalization options |

**Why one-time:**
- These features have no ongoing server cost
- Users strongly prefer one-time purchases over subscriptions
- Builds goodwill and trust

**Conversion triggers:**
- User generates their first report and sees the preview
- User tries to export PDF and sees Pro badge
- User explores settings and discovers themes

---

### Subscription Tier

> Server-based features with ongoing infrastructure costs. Recurring revenue justified.

**Price point:** TBD (research suggests $9.99–$14.99/year)

**Included:**

| Feature | Description |
| ------- | ----------- |
| **AI-Powered OCR** | Server-side smart extraction with high accuracy |
| **Account Sync** | Cross-device sync via cloud infrastructure |
| **Family Sharing** | Multi-user access to shared vehicles across Apple IDs |
| **Desktop/Web Access** | Browser-based access (future feature) |

**Why subscription:**
- AI OCR requires server infrastructure and API costs
- Sync requires cloud storage and real-time database
- Family Sharing requires multi-user infrastructure
- Ongoing costs = ongoing revenue

**Conversion triggers:**
- User scans a receipt and basic OCR misses fields → "Want better accuracy?"
- User gets a new phone and wants to transfer data → "Enable cloud sync?"
- User mentions spouse's car → "Share vehicles with family?"

---

### Tip Jar

> For users who love the app and want to support development beyond purchases.

**Implementation:**
- Simple one-time donations ($2.99, $4.99, $9.99 options)
- Located in Settings under "Support the Developer"
- No extra features — purely gratitude-based
- Thank you message after purchase

**Why offer this:**
- Some users genuinely want to support indie developers
- Low friction way to contribute
- Builds community and loyalty

---

## Pricing Principles

### What We Charge For

| Charge | Reasoning |
| ------ | --------- |
| Server-based features | Real ongoing costs |
| Advanced analysis | Significant development effort, power user value |
| Premium exports | Professional output, resale/warranty value |
| Customization | Nice-to-have, not need-to-have |

### What We Don't Charge For

| Free | Reasoning |
| ---- | --------- |
| Core tracking | The app's primary purpose should work for everyone |
| Basic reminders | Safety-critical — don't paywall maintenance alerts |
| Unlimited vehicles | No marginal cost, strong differentiator |
| Widgets | Part of the core "app comes to you" philosophy |
| Basic OCR | On-device processing has no ongoing cost |

---

## Upgrade Flows

### Principles

- **Show value before asking** — Let users see what they're getting
- **No dark patterns** — Clear pricing, easy cancellation, no tricks
- **Contextual prompts** — Offer upgrades when features are relevant, not randomly
- **Graceful degradation** — If subscription lapses, data remains accessible

### Example Flows

**PDF Export (Pro):**
1. User taps "Export PDF"
2. Preview generates with watermark: "Pro feature"
3. "Unlock PDF Export with Pro Bundle — $X.XX one-time"
4. Purchase → watermark removed, PDF ready to share

**AI OCR (Subscription):**
1. User scans receipt with basic OCR
2. Some fields extracted, others missed
3. "Want better accuracy? AI-Powered OCR catches more details."
4. Subscribe → receipt re-processed with AI, fields populated

**Family Sharing (Subscription):**
1. User adds second vehicle
2. Later, mentions in notes or service: "Sarah's car"
3. "Share this vehicle with family members?"
4. Subscribe → invite flow begins

---

## Revenue Considerations

### Target Mix

| Source | Estimated % of Revenue |
| ------ | ---------------------- |
| Pro Bundle | 40-50% |
| Subscription | 40-50% |
| Tip Jar | 5-10% |

### Key Metrics to Track

- Free → Pro conversion rate
- Free → Subscription conversion rate
- Subscription retention rate
- Average revenue per user (ARPU)
- Tip jar contribution rate

---

## Competitive Positioning

| Competitor Approach | Our Approach |
| ------------------- | ------------ |
| Free with intrusive ads | Free with no ads |
| 2-vehicle limit on free | Unlimited vehicles |
| Everything behind subscription | Core app fully free, subscription only for server features |
| Monthly subscription ($5+/mo) | Annual subscription, reasonable price |
| No one-time option | Pro bundle for non-server features |

---

## Open Questions

- [ ] Exact price points for Pro bundle and Subscription
- [ ] Should Pro bundle be included in Subscription, or separate?
- [ ] Family Sharing: free read-only access for invited members?
- [ ] Regional pricing considerations?
- [ ] Launch pricing vs long-term pricing?

---

_Last updated: January 2026_
