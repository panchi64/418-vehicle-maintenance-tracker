# Checkpoint — Market Gap Analysis

> Cross-referencing market research against Checkpoint's current state, planned features, and roadmap to identify high-impact improvements.

_Based on competitive analysis of 20+ apps, user sentiment from forums/reviews, and fuel tracking viability research. February 2026._

---

## How to Read This Document

- **Already shipping** = built and in the current codebase
- **Planned** = in FEATURES.md roadmap with a version target
- **Gap** = market demands it, Checkpoint doesn't address it yet
- **Signal strength** = how loud the market demand is (strong / moderate / niche)

---

## 1. Where Checkpoint Already Wins

These are areas where Checkpoint is already well-positioned against market demand. No action needed — just protect these advantages.

| Market Demand | Checkpoint Status | Competitive Edge |
|---|---|---|
| Privacy-first architecture (iCloud-only, no 3rd-party data) | ✅ Shipping | Beats CARFAX (data monetization concerns), FIXD (BBB complaints), Drivvo (aggressive upsell) |
| No ads, ever | ✅ Shipping | Beats Drivvo (screen-hijacking video ads), Simply Auto, most freemium apps |
| Unlimited vehicles, no login required | ✅ Shipping | Beats CARFAX (8 vehicle limit), AUTOsist (per-vehicle pricing) |
| Dual-trigger reminders (time + mileage) | ✅ Shipping | Beats CARFAX (rigid, non-customizable intervals) |
| Custom service types | ✅ Shipping | Addresses "apps don't support people who really work on their cars" complaint |
| VIN decoding (NHTSA) | ✅ Shipping | On par with CARFAX; better than most indie apps |
| Recall alerts | ✅ Shipping | Only CARFAX and FIXD do this consistently |
| Smart mileage estimation | ✅ Shipping | Unique — no competitor extrapolates mileage from driving patterns |
| Odometer OCR | ✅ Shipping | Only AUTOsist and emerging apps attempt this |
| Service clustering | ✅ Shipping | No competitor bundles nearby services into one visit suggestion |
| Seasonal reminders | ✅ Shipping | No competitor does location-aware seasonal prompts |
| Apple ecosystem depth (Widgets, CarPlay, Watch, Siri) | ✅ Shipping | Deepest Apple integration in the category — nobody else has all four |
| Cost tracking with analytics | ✅ Shipping | Competitive with Simply Auto, Drivvo |
| PDF service history for resale | ✅ Shipping | Addresses "resale-ready documentation" gap — only AUTOsist does this well |
| Honest pricing (free core + optional paid) | ✅ Shipping | Validated by research: users strongly prefer this model |
| Dark mode first | ✅ Shipping | Expected but many competitors still lack it |
| Data export | ✅ Shipping | Trust builder — "users own their data" |
| Guided onboarding | ✅ Shipping | Addresses onboarding friction complaints about competitors |

**Summary:** Checkpoint's v1.0 already covers the majority of table-stakes features. The foundation is strong. The improvements below are about closing remaining gaps and pulling ahead.

---

## 2. High-Impact Gaps — Should Address

Features where market demand is strong and Checkpoint either doesn't plan to address them, or plans to address them too late.

### 2a. Factory Maintenance Schedules — Reprioritize from v2.0

**Signal strength:** Strong
**Current plan:** v2.0 (Q4 2026)
**Market evidence:** Called the #1 feature gap in both competitive analyses. Forum users explicitly describe wanting "scan your VIN, get a complete maintenance timeline pre-built." This is the single feature most likely to convert spreadsheet holdouts.

**Recommendation:** Move to v1.5 (Q2-Q3 2026), at least for the top 20-30 vehicles. The LLM extraction pipeline from owner's manuals is already designed in FEATURES.md. Starting with a curated set of popular vehicles (Civic, Camry, F-150, RAV4, CR-V, Corolla) provides outsized value because these vehicles represent a huge share of the US fleet.

**Why not wait:** Every month without this is a month users must manually research their owner's manual. CARFAX does it partially but with rigid intervals users can't customize. Checkpoint can do it better: VIN scan → auto-populated schedule → fully customizable intervals.

**Suggested scope for v1.5:**
- Top 20-30 vehicles by US sales volume (covers ~40% of users)
- LLM extraction from owner's manuals (pipeline already designed)
- Fallback: sensible defaults + manual entry (already shipping)
- Crowdsource contribution flow (already designed in FEATURES.md)

---

### 2b. Fuel & Energy Tracking — Add as Lightweight Module

**Signal strength:** Moderate (passionate minority, not mass market)
**Current plan:** Not on roadmap
**Market evidence:** The fuel tracking research reveals a nuanced picture — dedicated trackers are intensely loyal but represent maybe 8-9M downloads total vs CARFAX's 50M+ maintenance-focused users. However, there are three compelling product reasons to include it:

1. **Engagement cadence.** Maintenance events happen every 3-6 months. Fill-ups happen weekly. Without fuel tracking, users might open the app a handful of times per year. Fuel logging creates a natural engagement rhythm.
2. **Mileage accuracy.** Every fuel entry records an odometer reading, which directly feeds the smart mileage estimation system that's already built. This makes maintenance reminders more accurate without requiring the user to think about "updating mileage."
3. **Total cost of ownership.** Fuel is 28-38% of vehicle operating costs. Adding it completes the cost picture and makes the Costs tab significantly more valuable.

**Recommendation:** Add to v1.5 as a secondary module — not a primary feature, not heavily marketed, but present for users who want it.

**Suggested scope:**
- Minimal required fields: odometer, gallons/liters, total cost (3 fields)
- Optional fields: station, octane, partial fill flag
- MPG/L100km calculation and trend chart
- kWh tracking for EVs (pairs with planned v1.5 EV support)
- Feed odometer readings into existing mileage estimation system
- Cost data flows into existing Costs tab analytics
- No GPS tracking, no fuel price lookup, no station database — keep it simple

**What NOT to build:**
- No GasBuddy-style price comparison (different product entirely)
- No fuel brand tracking (unnecessary friction)
- No elaborate fuel analytics dashboard (diminishing returns)
- No location-based features (privacy concern, complexity)

**Design consideration:** The brutalist aesthetic actually lends itself well to a fuel logging quick-entry screen — think instrument panel readout, monospace numbers, minimal fields.

---

### 2c. Live Activities & Dynamic Island — Add to v1.0 or v1.5

**Signal strength:** Moderate (zero competition = first-mover advantage)
**Current plan:** Not on roadmap
**Market evidence:** "Completely untapped" in the category. No maintenance app uses Live Activities. This is a low-effort, high-visibility differentiator.

**Recommendation:** Add to v1.5. Two use cases:

1. **Overdue service alert.** When a service crosses its due date/mileage, show a persistent Live Activity on the Lock Screen: "Oil change overdue — 200 miles past due." Dismiss by logging the service.
2. **Approaching service countdown.** When a service is within its final warning window (e.g., 7 days or 500 miles), show a compact countdown: "Tire rotation — 3 days / 340 mi."

**Why it matters:** This makes Checkpoint feel genuinely native to iOS in a way no competitor does. It surfaces the app's core value proposition ("what's next?") in the most visible real estate on the phone.

**Scope:**
- Lock Screen Live Activity with compact and expanded views
- Dynamic Island compact/minimal for active alerts
- Trigger: service enters "due soon" or "overdue" state
- Dismiss: user logs the service or manually dismisses

---

### 2d. Interactive Widgets — Mark Service Complete from Home Screen

**Signal strength:** Moderate
**Current plan:** Widgets exist but are read-only
**Market evidence:** iOS 17+ interactive widgets are highlighted as a gap. "Mark a service complete or log a fuel fill-up without opening the app."

**Recommendation:** Added to v1.0. Extends existing widget infrastructure with an interactive button.

**Scope:**
- Medium widget: add "Done" button next to the most urgent service
- Tapping "Done" logs the service with today's date and estimated mileage (user can edit details later in-app)
- Confirmation via haptic feedback

---

### 2e. Data Import from Competing Apps

**Signal strength:** Moderate
**Current plan:** Not on roadmap
**Market evidence:** Users switching from Fuelly, Drivvo, Simply Auto, aCar need to bring years of data. Import capability reduces switching cost dramatically.

**Recommendation:** Added to v1.0. CSV import with column mapping.

**Scope:**
- CSV import with configurable column mapping
- Support common export formats from Fuelly, Drivvo, Simply Auto
- Preview before import (show what will be created)
- Map imported data to Checkpoint's service types

---

## 3. Medium-Impact Opportunities — Consider for Roadmap

Features where demand exists but impact is more incremental.

### 3a. Connected Car API (Smartcar)

**Signal strength:** Moderate (growing)
**Current plan:** Not on roadmap
**Market evidence:** Smartcar API covers 40+ automakers. Auto-reads odometer, fuel level, tire pressure via vehicle's built-in modem — no OBD-II hardware needed. Would eliminate manual mileage entry entirely.

**Assessment:** High technical value but adds complexity: API costs, vehicle compatibility matrix, authentication flows, subscription justification. Best suited for v2.0+ as a premium/subscription feature. Monitor Smartcar pricing and adoption before committing.

**If pursued:** This would be the strongest subscription justification — ongoing API costs for a feature that genuinely requires infrastructure.

---

### 3b. Part Number & Warranty Tracking

**Signal strength:** Niche (DIY enthusiasts)
**Current plan:** Tangentially in v2.5 (DIY mechanic mode)
**Market evidence:** "DIY mechanics want to log specific parts, brands, and warranty periods." Currently no app does this well.

**Recommendation:** Consider adding part tracking to service logs in v1.5 as an optional field, rather than waiting for full DIY mode in v2.5. Simple implementation: optional "parts" section on service log entry with part name, part number, brand, cost, warranty expiration.

---

### 3c. Face ID / Touch ID Lock

**Signal strength:** Moderate
**Current plan:** Not on roadmap
**Market evidence:** Privacy-conscious users want biometric lock on the app. Easy to implement, builds trust.

**Recommendation:** Low-effort addition for v1.5. Standard iOS biometric authentication on app launch, togglable in Settings.

---

### 3d. Business vs Personal Trip Categorization

**Signal strength:** Niche (gig economy, self-employed)
**Current plan:** Not on roadmap
**Market evidence:** Gig economy drivers want to separate business mileage for tax deductions. Simply Auto has this.

**Assessment:** Outside Checkpoint's core value proposition. If fuel tracking is added, mileage categorization could be an optional tag. Don't build a full trip tracker — that's a different product.

---

### 3e. Vehicle Transfer / Data Handoff

**Signal strength:** Niche but delightful
**Current plan:** Not on roadmap
**Market evidence:** Loggy earns praise for vehicle transfer between users. When selling a car, transfer the complete maintenance history to the buyer (who also uses the app).

**Assessment:** Builds brand virality (buyer downloads app to receive data). Could be a simple "export vehicle package" feature that generates a shareable link/file. Consider for v2.0.

---

## 4. Deprioritize or Skip

Features the market mentions but that don't align with Checkpoint's positioning or have poor ROI.

| Feature | Market Demand | Why Skip/Deprioritize |
|---|---|---|
| Desktop/web access | Moderate ("I want to access data on my laptop") | High infrastructure cost, low user volume. iCloud sync + PDF export covers 80% of the need. Keep as v2.0+ aspiration. |
| OBD-II integration | Niche (hardware-dependent users) | Requires hardware purchase, complex pairing, limited vehicle compatibility. FIXD/Carly own this space. Don't compete. |
| Gamification / badges | Niche (Gen Z) | Risks feeling patronizing. Checkpoint's brutalist aesthetic is anti-gamification. |
| Insurance integration | Low (Jerry owns this) | Completely different business model. Would dilute focus. |
| Social features / community | Low | Forum users exist on Reddit/enthusiast forums. Don't try to replace them. |
| Fuel price lookup / GasBuddy-style features | Low | Different product. GasBuddy has 90M downloads — don't compete on their turf. |
| GPS mileage tracking | Moderate | Privacy concern, battery drain, complexity. Smart mileage estimation is the better approach. |
| Predictive maintenance via ML | Futuristic | Crowd-sourced data (v2.0) is the better path. ML needs massive datasets Checkpoint doesn't have yet. |

---

## 5. Monetization Alignment Check

The market research validates Checkpoint's current monetization model but suggests refinements.

### What the research confirms:
- Free full-featured core is the right call (CARFAX proves scale, Road Trip proves loyalty)
- One-time Pro purchase ($7.99-$14.99) is the sweet spot
- Annual subscription only for genuine server costs is accepted
- No ads is a meaningful differentiator
- Tip jar resonates with indie app supporters

### Suggested refinements:

| Current Plan | Suggested Change | Reasoning |
|---|---|---|
| PDF export behind Pro | Keep — validated | "Resale-ready documentation" is a real gap users will pay for |
| Advanced reports behind Pro | Keep — validated | Power users want deeper analytics |
| AI OCR behind subscription | Keep — validated | Server costs justify recurring fee |
| Family sharing behind subscription | Consider free read-only tier | Research shows couples want shared access; free read-only reduces friction, paid write access still justified |
| Basic export is free | Keep — critical for trust | "User owns their data" is a trust builder that drives adoption |
| Pro included in subscription? | Yes — bundle them | Simplifies messaging. Subscription = everything. Pro = one-time for users who don't need server features. |

### New monetization consideration — Fuel tracking:
- **Keep it free.** Fuel tracking creates engagement (more app opens → more conversion opportunities). Paywalling it would undercut the engagement benefit and feel petty for what's essentially a data entry form.

### New monetization consideration — Connected Car API (if built):
- **Subscription-only.** Smartcar API has per-vehicle costs. This is the clearest subscription justification in the entire app — ongoing API costs for automatic mileage that genuinely requires infrastructure.

---

## 6. Priority Stack Rank — What to Build Next

Ordered by impact × feasibility, considering Checkpoint's current position and the v1.0 → v1.5 timeline.

### v1.0 additions — Ship with launch

| # | Feature | Why |
|---|---|---|
| 1 | Interactive widgets (mark service done) | Low effort extension of existing widget infrastructure. |
| 2 | CSV import from competing apps | Reduces switching cost. Important for acquisition from day one. |

### Tier 1 — High impact, address in v1.5

| # | Feature | Why |
|---|---|---|
| 3 | Factory maintenance schedules (top 20-30 vehicles) | #1 market gap. Converts spreadsheet holdouts. Pipeline already designed. |
| 4 | Fuel/energy tracking (lightweight module) | Engagement cadence + mileage accuracy + total cost of ownership. Pairs with EV support. |
| 5 | Live Activities & Dynamic Island | Zero competition. Makes Checkpoint feel native in a way nobody else does. |
| 6 | EV/Hybrid support | Already planned for v1.5. Market growing fast. Pairs with fuel/energy tracking. |

### Tier 2 — Medium impact, address in v1.5 or v2.0

| # | Feature | Why |
|---|---|---|
| 7 | Part number tracking on service logs | Low effort, high value for DIY users. Don't wait for full DIY mode. |
| 8 | Face ID / Touch ID lock | Easy win for privacy-conscious users. |
| 9 | Vehicle transfer / data handoff | Virality mechanism. Buyer downloads app to receive history. |

### Tier 3 — Lower impact, v2.0+

| # | Feature | Why |
|---|---|---|
| 10 | Connected car API (Smartcar) | High value but high complexity. Monitor pricing first. |
| 11 | Crowd-sourced reliability data | Already planned for v2.0. Needs user base first. |
| 12 | DIY mechanic mode | Already planned for v2.5. Niche but growing. |

---

## 7. Updated Competitive Gaps Table

Replacing the current table in FEATURES.md with market-research-backed positioning.

| Gap in Market | Checkpoint's Answer | Who We Beat |
|---|---|---|
| Manual data entry fatigue | OCR receipts, VIN decode, smart mileage estimation, fuel-fed odometer updates | Simply Auto (10+ fields per fuel entry), all manual-only apps |
| Outdated UI | Native iOS 26 Liquid Glass, brutalist design language | aCar ("UI from the early 2000s"), Fuelly (stale development) |
| Subscription burnout | Free full-featured app, no ads, pay only for server features | FIXD ($99/yr), AUTOsist ($5/vehicle/mo), Drivvo (400% price hikes) |
| No "what's next" view | Dashboard prioritizes urgency, Live Activities surface deadlines | Every app that requires opening to check status |
| Limited Apple integration | Widgets + CarPlay + Watch + Siri + Live Activities + Interactive Widgets | Nobody has all six |
| Data loss anxiety | Local-first architecture, iCloud sync, automatic backups, free export | Simply Auto (data loss reports), abandoned apps (Car Minder) |
| No factory schedules | VIN → auto-populated manufacturer intervals (customizable) | CARFAX (rigid intervals), everyone else (manual only) |
| No smart scheduling | Service clustering, seasonal reminders, predictive mileage | No competitor bundles these together |
| DIY mechanics ignored | Custom service types, part tracking, freeform notes | CARFAX (only counts dealer service), most preset-only apps |
| No engagement between services | Fuel tracking creates weekly touchpoint, mileage prompts | Apps users forget about between oil changes |
| EV owners underserved | Native EV/hybrid maintenance schedules, kWh tracking, battery health | Every ICE-first competitor |
| App abandonment fear | 5-year support commitment, open export, responsive developer | Car Minder (abandoned), aCar (stale), Fuelly (stagnant) |

---

## 8. Open Questions

- [ ] Should factory schedules be a free or Pro feature? (Leaning free — it's a core value proposition that drives adoption)
- [ ] Fuel tracking: separate tab or integrated into existing Costs tab?
- [ ] Live Activities: what triggers the start/end of an activity? Pure time/mileage threshold, or user-configurable?
- [ ] Connected car API: what's Smartcar's pricing model for indie apps? Is there a free tier?
- [ ] Vehicle transfer: should it require both users to have Checkpoint, or generate a standalone PDF/JSON?
- [ ] Part tracking: optional fields on existing service log form, or separate "parts" section?

---

_Last updated: February 2026_
