# Vehicle Maintenance Tracker - Version Roadmap

> A comprehensive overview of planned releases and feature milestones for Checkpoint, the iOS vehicle maintenance companion app.

---

## Vision Statement

Checkpoint aims to be the **definitive iOS vehicle maintenance companion** — an app that respects users' time, protects their data, and surfaces the right information at the right moment. We prioritize Apple ecosystem integration, bulletproof reliability, and a subscription-free core experience.

---

## Release Timeline Overview

| Version | Theme | Target | Status |
|---------|-------|--------|--------|
| **v1.0** | Core Experience | Q1 2026 | 🚧 In Development |
| **v1.5** | EV & Cloud | Q2-Q3 2026 | 📋 Planned |
| **v2.0** | Intelligence & Insights | Q4 2026 | 📋 Planned |
| **v2.5** | Education & DIY | 2027 | 🔮 Future |

---

## v1.0 — Core Experience

> The foundation: a fully-featured, local-first maintenance tracker with deep Apple integration.

### Philosophy

- **"What's next?" first** — The app immediately shows the most urgent item on launch
- **Glanceable, not a chore** — Quick look, done. No data entry burden.
- **The app comes to you** — Widgets, notifications, CarPlay — surface info where users already are
- **Zero-friction data entry** — Smart defaults, OCR, confirm/correct flows
- **Free with premium options** — Full-featured free app, no ads

### Core Features

| Category | Features | Status |
|----------|----------|--------|
| **Dashboard** | "Next Up" card, quick-add button, vehicle selector, maintenance timeline | ✅ |
| **Service Logging** | Manual entry, service type presets, custom types, attachments, service details | ✅ |
| **Vehicles** | Multi-vehicle support, VIN decoding (NHTSA), odometer tracking, distance units, vehicle notes | ✅ |
| **Schedules** | Manual schedule entry, mileage-based reminders, date-based reminders, smart notifications, custom intervals | ✅ |
| **Mileage** | Driving rate calculation, estimated current mileage, predictive notifications, dashboard OCR, biweekly prompts, EWMA recency weighting | ✅ |
| **Costs** | Per-service costs, cost categorization, monthly/yearly summaries, cost-per-mile calculation | ✅ |

### Platform Integrations

| Integration | Description | Status |
|-------------|-------------|--------|
| **Home Screen Widget** | Small/medium widgets showing "Next Up" service | ✅ |
| **Lock Screen Widget** | Glance at what's due without unlocking | ✅ |
| **Widget Vehicle Selection** | Long-press to choose which vehicle to display | ✅ |
| **CarPlay Dashboard** | Compact widget on CarPlay home screen | ✅ |
| **Dynamic App Icon** | Icon changes based on service urgency | ✅ |
| **One-tap Notifications** | "Did you do your oil change?" → Yes/No buttons | ✅ |

### Smart Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Recall Alerts** | NHTSA recall notifications for safety-critical issues | ✅ |
| **Yearly Cost Roundup** | Annual summary push notification (January 2nd) | ✅ |

### v1.0 Remaining Work

| Feature | Priority | Status |
|---------|----------|--------|
| Apple Watch Complication | High | ⏳ In Progress |
| Siri Integration | Medium | ⏳ Planned |
| Receipt/Invoice OCR (Basic) | High | ⏳ Planned |
| Pre-loaded Factory Schedules | High | ⏳ Planned |
| Service Clustering | High | ⏳ Planned |

### Data Reliability (Non-Negotiable)

- Local-first architecture — device is source of truth
- Automatic local backups (7 daily, 4 weekly)
- Never delete without confirmation
- Export everything, anytime (JSON/CSV)
- Migration safety with rollback paths

---

## v1.5 — EV & Cloud

> Extending Checkpoint to electric vehicles while adding cloud infrastructure for sync and sharing.

### EV & Hybrid Support

#### Market Opportunity

- EV maintenance market: $18B (2023) → $84B projected (2033)
- Existing apps designed for ICE vehicles — EV owners underserved
- Different maintenance cadence requires dedicated attention

#### Features

| Feature | Priority | Description |
|---------|----------|-------------|
| **EV Maintenance Schedules** | High | Battery health checks, coolant, brake fluid, cabin filter intervals |
| **Battery Health Tracking** | High | Log degradation over time, charging habits impact |
| **EV-Specific Service Types** | High | Presets: battery conditioning, thermal system, HV cables |
| **Software Update Logging** | Medium | Track OTA updates as "maintenance" events |
| **Regenerative Braking Notes** | Medium | Affects brake pad wear — surface in brake service reminders |

#### Technical Considerations

- VIN decoding must identify EV/hybrid powertrains
- Battery health metrics require different UI treatment
- Software updates are a new category of "service"
- Integration with manufacturer APIs (Tesla, Rivian, etc.) as future possibility

### Cloud & Family

#### Subscription Tier Features

These features require ongoing infrastructure and justify a subscription model ($9.99–$14.99/year).

| Feature | Priority | Description |
|---------|----------|-------------|
| **AI-Powered OCR** | High | Server-side smart extraction for receipts/invoices with high accuracy |
| **Account Sync** | High | Cross-device sync via cloud infrastructure |
| **Family Sharing** | High | Multi-user access to shared vehicles across Apple IDs |

#### Family Sharing Details

**Use Cases:**
- Couples sharing household vehicles
- Parents tracking teen driver's car maintenance
- Families coordinating who handles which service

**Permission Levels:**

| Level | View | Log Services | Edit Vehicle | Delete |
|-------|------|--------------|--------------|--------|
| Owner | ✅ | ✅ | ✅ | ✅ |
| Editor | ✅ | ✅ | Limited | ❌ |
| Viewer | ✅ | ❌ | ❌ | ❌ |

**Architecture:**
- CloudKit sharing for real-time sync
- Subscription required for write access
- Read-only access potentially free tier

#### AI-Powered OCR

**Basic OCR (Free):**
- On-device Vision framework
- Text extraction with manual field selection
- Privacy-preserving, no cloud dependency

**AI-Powered OCR (Subscription):**
- Server-side smart extraction
- Automatic field detection
- High accuracy parsing of mechanic invoices
- Contextual prompts (service invoice vs parts receipt)

---

## v2.0 — Intelligence & Insights

> Crowd-sourced data, predictive maintenance, and professional tools.

### Crowd-Sourced Reliability Data (Opt-In)

| Feature | Priority | Description |
|---------|----------|-------------|
| **Opt-in Data Sharing** | High | Clear consent, off by default |
| **Anonymized Collection** | High | Strip PII, aggregate to make/model/year level |
| **Common Issues by Vehicle** | Medium | "RAV4 owners often report AC issues around 80K" |
| **Regional Reliability Factors** | Low | Rust belt vs dry climates patterns |

**Data Points (Structured):**
- Vehicle: make/model/year/engine (from VIN)
- Service type: predefined dropdown
- Category: Scheduled | Unplanned | Recall
- Mileage at service
- Cost and severity

### Advanced Analytics

| Feature | Description |
|---------|-------------|
| **Predicted Issues** | Based on crowd-sourced data, only when confidence is high |
| **Vehicle Health Diagram** | Visual schematic with color-coded areas by status |
| **Repair History View** | Areas with most unplanned repairs, highlighting chronic problems |
| **Seasonal Reminders** | Location + season → contextual alerts (winter tires, AC check) |

### Professional Features

| Feature | Description |
|---------|-------------|
| **Desktop/Web Access** | Browser-based access for users managing multiple vehicles |
| **Advanced Reports** | Detailed analytics, spending trends, cost breakdowns |
| **PDF Export** | Professional vehicle history documents with receipt attachments |
| **Fleet Management** | For small business with 10+ vehicles |

---

## v2.5 — Education & DIY

> Empowering first-time car owners and DIY enthusiasts with knowledge and tools.

### Market Opportunity

- 40% of Gen Z learns car care from YouTube — knowledge gap is real
- 47% of US car owners now do basic DIY maintenance (up from 34% in 2019)
- $49.2 billion DIY auto maintenance market growing at 5.8% annually
- Cost savings of $800–$1,200 annually drives DIY adoption

### Education Features

| Feature | Priority | Description |
|---------|----------|-------------|
| **First-Time Owner Education** | High | "What does this mean?" explainers for every service type |
| **Video Tutorial Links** | Medium | Curated YouTube links for common DIY tasks |
| **Gamified Progress** | Low | "First Oil Change Complete!" badges — subtle, not annoying |

### DIY Mechanic Mode

| Feature | Priority | Description |
|---------|----------|-------------|
| **Parts Inventory** | High | Track parts purchased, where stored, compatibility |
| **Projects in Progress** | High | Multi-day repairs with step tracking |
| **Tool Checklists** | High | Per-task tool requirements |
| **DIY vs Shop Cost Comparison** | Medium | Show savings from doing it yourself |

### User Experience

- Optional "Enthusiast Mode" toggle for data-dense dashboard
- Parts purchase logging distinct from service logging
- Time-to-complete estimates for DIY jobs
- Difficulty ratings for each service type

---

## Monetization Strategy Alignment

### Free Tier (v1.0+)

- Unlimited vehicles
- Full core functionality
- All widgets (Home, Lock Screen, CarPlay, Watch)
- Basic on-device OCR
- Complete reminder system
- Basic data export

### Pro Bundle — One-Time Purchase ($7.99–$14.99)

- Advanced reports and analytics
- Professional PDF export
- Theme customization

### Subscription ($9.99–$14.99/year)

- AI-Powered OCR (v1.5+)
- Cloud sync (v1.5+)
- Family Sharing (v1.5+)
- Desktop/Web access (v2.0+)

### Philosophy

- Free should feel complete
- No ads, ever
- Pay for value, not access
- Server costs justify subscriptions
- Support the developer (tip jar)

---

## Data Strategy: Factory Maintenance Schedules

### Approach

1. **Source PDFs** from free online databases (CarManualsOnline, MyCarUserManual, etc.)
2. **Extract schedules** using LLM from owner's manuals
3. **Store as structured data** in app database
4. **Crowdsource gaps** — users submit/verify schedules

### Prioritization

1. Top 50 vehicles by popularity (Civic, Camry, F-150, RAV4, etc.)
2. Expand based on user demand
3. Support both "Normal" and "Severe" driving condition schedules

### Fallback

- Sensible defaults if vehicle not in database
- User can manually input from their owner's manual
- Contribution option to help other owners

---

## Competitive Positioning

| Gap in Market | Our Solution |
|---------------|--------------|
| Manual data entry fatigue | OCR receipts, VIN decode, smart mileage estimation |
| Outdated UI | Native iOS 26 Liquid Glass design |
| Subscription burnout | Free full-featured app, no ads, pay only for extras |
| No smart scheduling | Factory intervals pre-loaded |
| Abandoned apps | Commitment to 5+ year support |
| No "what's next" view | Dashboard prioritizes urgency |
| Limited Apple integration | Widgets, CarPlay, Watch, Siri |
| EV owners ignored | Dedicated EV support in v1.5 |
| DIY mechanics underserved | Full DIY mode in v2.5 |

---

## Guiding Principles

1. **Never lose user data** — This is non-negotiable
2. **Work offline** — Cloud is a bonus, not a requirement
3. **User owns their data** — Export always available
4. **Fail gracefully** — Errors don't cascade to data loss
5. **Communicate clearly** — Users know what's happening
6. **Ship small, iterate fast** — Get feedback early

---

## Open Questions

- [ ] How accurate can on-device OCR/ML be for mechanic invoices?
- [ ] Should we support iPad / Mac via Catalyst?
- [ ] How many vehicles should we seed the schedule database with before launch?
- [ ] What's the review/verification process for crowdsourced schedules?
- [ ] Regional pricing considerations for Pro and Subscription?
- [ ] Should Pro bundle be included in Subscription, or separate?

---

_Last updated: January 2026_
