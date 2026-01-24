# Vehicle Maintenance Tracker - Feature Ideas

> A modern iOS app for tracking vehicle maintenance with a focus on simplicity, smart automation, and iOS 26 Liquid Glass design.

---

## Core Philosophy

- **"What's next?" first** — The app should immediately show the most urgent/relevant item on launch
- **Glanceable, not a chore** — User opens app to refresh their memory on what needs doing, not to input data. Quick look, done.
- **The app comes to you** — Widgets, notifications, Siri — surface info where the user already is
- **Zero-friction data entry** — Minimize manual typing at every opportunity. Smart defaults, OCR, confirm/correct flows.
- **Modern, native feel** — Leverage iOS 26 Liquid Glass for a premium UI
- **One-time purchase** — No subscriptions (major differentiator)

---

## Feature Categories

### 1. Dashboard / Home Screen

| Feature              | Priority | Status | Notes                                                                                                   |
| -------------------- | -------- | ------ | ------------------------------------------------------------------------------------------------------- |
| "Next Up" card       | High     | ✅     | Single most important upcoming service, smart prioritization: overdue > safety-critical > mileage-based |
| Quick-add button     | High     | ✅     | One tap to log a service                                                                                |
| Vehicle selector     | High     | ✅     | Easy switching for multi-vehicle households                                                             |
| Maintenance timeline | Medium   | ⏳     | Visual timeline of past/upcoming services                                                               |

---

### 2. Service Logging

| Feature                | Priority | Status | Notes                                                |
| ---------------------- | -------- | ------ | ---------------------------------------------------- |
| Manual entry           | High     | ✅     | Basic form: service type, date, mileage, cost, notes |
| Receipt/invoice OCR    | High     | ⏳     | Photo → auto-populate fields (date, cost, services)  |
| Service type presets   | High     | ✅     | Oil change, tire rotation, brakes, etc.              |
| Custom service types   | Medium   | ✅     | User-defined categories                              |
| Attachments            | Medium   | ⏳     | Photos, PDFs, receipts                               |
| Mechanic/shop tracking | Low      | ⏳     | Build history with specific shops                    |

#### On-Device Document Intelligence

> Use Apple's on-device ML to parse receipts, invoices, and service documents — then contextually prompt the user based on what was detected.

| Feature                | Priority | Notes                                                   |
| ---------------------- | -------- | ------------------------------------------------------- |
| Document scanning      | High     | VisionKit for clean document capture                    |
| On-device OCR          | High     | Vision framework, no cloud dependency                   |
| Smart field extraction | High     | Date, vendor, line items, costs, vehicle info           |
| Contextual prompts     | High     | Different flows for service receipts vs parts purchases |
| Confidence indicators  | Low      | Show extraction confidence, let user correct errors     |

**Contextual prompt logic:**

| Document Type   | Detected Signals                                 | App Response                               |
| --------------- | ------------------------------------------------ | ------------------------------------------ |
| Service invoice | Shop name, labor charges, "installed" language   | "Log as completed service?"                |
| Parts receipt   | AutoZone/O'Reilly/Amazon, part numbers, no labor | "Log as DIY service?"                      |
| Ambiguous       | Mixed signals or unclear                         | "What is this?" → Service / Something else |

**Apple technologies:**

- **VisionKit** — Document scanner UI with auto-capture
- **Vision framework** — OCR text recognition
- **Core ML** — Custom model for receipt classification & field extraction
- **Apple Intelligence** — Advanced document understanding (iOS 18+)

**Privacy benefit:** All processing on-device. No receipts or personal data leave the phone.

---

### 3. Maintenance Schedules & Reminders

| Feature                      | Priority | Status | Notes                                                           |
| ---------------------------- | -------- | ------ | --------------------------------------------------------------- |
| Pre-loaded factory schedules | High     | ⏳     | VIN decode → manufacturer intervals (see Data Strategy section) |
| Manual schedule entry        | High     | ✅     | User inputs their own schedule from their owner's manual        |
| Mileage-based reminders      | High     | ✅     | "500 miles remaining" (primary method)                          |
| Date-based reminders         | High     | ✅     | Fallback for non-mileage services (battery, wipers)             |
| Smart notifications          | High     | ✅     | Configurable timing (1 week before, day of, etc.)               |
| Service clustering           | High     | ⏳     | Bundle nearby services into one visit                           |
| Seasonal reminders           | Medium   | ⏳     | Location + season → contextual alerts                           |
| Severe vs normal schedules   | Medium   | ⏳     | Different intervals based on driving conditions                 |
| Custom reminder intervals    | Medium   | ✅     | User-defined schedules                                          |

#### Setup: Schedule Source Choice

> During vehicle setup, let the user choose where their maintenance schedule comes from.

**Options presented:**

1. **"Use recommended schedule"** — Pre-populated from our database (extracted from owner's manuals online)
2. **"I'll enter my own"** — User inputs intervals manually based on their own owner's manual

**Why offer both:**

- Some users want zero effort → use our data
- Some users trust their own manual more → let them enter it
- We might not have data for their specific vehicle → manual entry is the fallback
- User can always edit/override later regardless of initial choice

#### Service Clustering

> Detect when multiple services are due around the same time and suggest bundling them into one shop visit.

**Example:**

- Oil change due at 52,000 miles
- Tire rotation due at 52,500 miles
- Air filter due at 53,000 miles

→ App suggests: "3 services coming up within 1,500 miles. Bundle them at your next visit?"

**Benefits:**

- Fewer trips to the shop
- Potentially save on labor (some shops discount bundled services)
- More convenient for the user

**Logic:**

- Configurable clustering window (e.g., "within 1,000 miles or 1 month")
- Prioritize safety-critical items if user delays

#### Seasonal Reminders

> Location-aware, time-of-year reminders for seasonal maintenance.

| Season        | Location Signal             | Reminder                                   |
| ------------- | --------------------------- | ------------------------------------------ |
| Fall → Winter | Northern US, temps dropping | "Check antifreeze levels before winter"    |
| Fall → Winter | Snow regions                | "Time to switch to winter tires?"          |
| Spring        | Post-winter                 | "Check for rust/undercarriage salt damage" |
| Summer        | Hot regions                 | "Check AC system before summer heat"       |
| Any           | Rainy season                | "Check wiper blades"                       |

**Implementation:**

- Use device location (coarse, e.g., state/region)
- Check local weather patterns or just use calendar season + region
- Only show if relevant (don't suggest winter tires in Florida)

---

### 4. Vehicle Management

| Feature               | Priority | Status | Notes                                                      |
| --------------------- | -------- | ------ | ---------------------------------------------------------- |
| Multi-vehicle support | High     | ✅     | Families, enthusiasts, collectors                          |
| VIN decoding          | High     | ⏳     | Auto-populate year/make/model/engine                       |
| Odometer tracking     | High     | ✅     | Manual entry + smart estimation                            |
| Vehicle notes         | Medium   | ✅     | Freeform notes area for quirks, history, or reminders      |

---

### 5. Smart Mileage Estimation

> Learn driving patterns from mileage entries over time. Predict current mileage and proactively notify users about upcoming services.

| Feature                          | Priority | Notes                                                 |
| -------------------------------- | -------- | ----------------------------------------------------- |
| Driving rate calculation         | High     | miles/month based on logged data points               |
| Estimated current mileage        | High     | Extrapolate between manual entries                    |
| Predictive service notifications | High     | "Oil change due in ~500 miles based on your driving"  |
| Dashboard OCR                    | High     | Photo of odometer → extract mileage automatically     |
| Recency weighting                | Medium   | Recent behavior weighted more heavily (habits change) |

#### Dashboard OCR for Mileage Capture

> Two options: scan your odometer with the camera OR just type it in manually. User's choice.

**Input options:**

1. **Camera scan** — Tap camera icon → snap photo of odometer → OCR extracts mileage → confirm or correct
2. **Manual entry** — Just type the number directly into an input field

**Camera scan flow:**

1. User taps camera icon next to mileage input
2. User snaps photo of odometer
3. On-device OCR extracts the number
4. App shows: "Is this correct? **51,247 miles**"
   - **Yes** → mileage logged
   - **No** → input field appears with extracted value pre-filled for easy correction
5. Store photo as attachment (optional, for reference)

**Technical notes:**

- Use Vision framework for OCR (on-device, private)
- Handle digital and analog odometers (different fonts/styles)
- Validate parsed number is reasonable (not wildly different from last entry)

**How it works:**

1. User starts account with 47K miles
2. Three months later, logs a service at 51K miles
3. App calculates: ~1,333 miles/month
4. App can now estimate current mileage without asking
5. Reminders become mileage-based: "Based on your driving, brake service is ~1,200 miles away"

**Data sources for mileage:**

- Service logs (always include mileage)
- Manual odometer updates
- Dashboard OCR captures

**Benefits:**

- Smarter, more accurate reminders
- Less manual entry over time
- Proactive instead of reactive notifications

---

### 6. Cost & Expense Tracking

| Feature                   | Priority | Status | Notes                  |
| ------------------------- | -------- | ------ | ---------------------- |
| Per-service costs         | High     | ✅     | Track what you spend   |
| Cost categorization       | Medium   | ✅     | Maintenance vs repairs vs upgrades |
| Monthly/yearly summaries  | Medium   | ✅     | Spending trends with monthly breakdown |
| Cost-per-mile calculation | Medium   | ✅     | True cost of ownership with period filtering |

---

### 7. Reports & Export

| Feature                  | Priority | Notes                                                    |
| ------------------------ | -------- | -------------------------------------------------------- |
| Service history PDF      | High     | Complete maintenance history for resale, warranty claims |
| Data backup              | High     | iCloud sync                                              |
| Shareable reports        | Medium   | Send to mechanic, buyer, etc.                            |
| Maintenance cost reports | Medium   | Graphs and breakdowns                                    |

#### Vehicle Maintenance History PDF

> Generate a professional PDF document with the complete service history. Perfect for selling the car, warranty claims, or personal records.

**Contents:**

- Vehicle info (year, make, model, VIN, current mileage)
- Complete chronological service history
- For each service: date, mileage, service performed, cost, shop/location
- Attached receipt images (optional — user can toggle on/off)
- Total maintenance spend (optional)

**Use cases:**

- **Selling the car** — Proves the vehicle was well-maintained, adds value
- **Warranty claims** — Shows service was performed on schedule
- **Insurance** — Documentation after incidents
- **Personal records** — Archive before switching apps or phones

**Format:**

- Clean, professional layout
- App branding subtle (not obnoxious)
- Shareable via iOS share sheet (AirDrop, email, Messages, Files, etc.)

---

### 8. Smart Features (Differentiators)

| Feature             | Priority | Notes                                                 |
| ------------------- | -------- | ----------------------------------------------------- |
| Recall alerts       | High     | NHTSA recall notifications — safety critical          |
| Yearly cost roundup | Medium   | Annual summary of what you spent maintaining your car |

#### Yearly Cost Roundup

> Once a year, surface a summary of what the user spent on their vehicle. Not intrusive — just a nice annual reflection.

**Content:**

- Total spent on maintenance/repairs this year
- Cost trajectory: "Up 20% from last year" or "Down 15% from last year"
- Breakdown by category (oil changes, tires, repairs, etc.)
- Optional: "You've driven ~14,000 miles this year"

**Tone:**

- Informational, not judgmental
- No comparisons to other users
- Helps inform keep vs sell decisions naturally over time

**Timing:**

- End of year (December/January) or on vehicle's anniversary in the app

#### Nice-to-Haves (Get Right or Don't Do)

> These could add value but need careful implementation. Better to skip than do poorly.

| Feature                | Notes                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Predicted issues       | Based on crowd-sourced data: "Civic owners often report X at your mileage." Only show when confidence is high. Don't cry wolf. |
| Service patterns       | Learn when user typically services (e.g., Saturdays, March). Use to pre-fill defaults, not to nag.                             |
| Vehicle health diagram | Visual schematic showing vehicle areas color-coded by status. Two toggleable views (see below).                                |

##### Vehicle Health Diagram

> A visual schematic of the vehicle with color-coded areas. Users can toggle between two views.

**Views:**

| View                        | Default | What it shows                                                                 |
| --------------------------- | ------- | ----------------------------------------------------------------------------- |
| **Health Status** (default) | Yes     | Current maintenance state per area: green = up-to-date, yellow = due soon, red = overdue |
| **Repair History**          | No      | Areas with most unplanned repairs, highlighting chronic problem spots         |

**Why two views:**

- Health Status is forward-looking and actionable ("what needs attention now")
- Repair History is backward-looking and informational ("where has money gone")
- Combining them into one view would be confusing (frequent maintenance ≠ problems)

**Implementation notes:**

- Generic vehicle schematic (not make/model specific) with labeled zones: engine, transmission, brakes, suspension, electrical, tires, body/exterior
- Services must map to zones (oil change → engine, brake pads → brakes, etc.)
- Only show Repair History view if there's enough data to be meaningful
- Best suited for enthusiast mode — casual users may find it overwhelming

**Philosophy:** These are v2+ features. Ship without them, add later when we have enough data and can do them well.

---

### 9. Crowd-Sourced Reliability Data (Opt-In)

> Users can opt in to anonymously contribute their maintenance/repair data. Over time, this builds a dataset that reveals real-world reliability patterns by make/model/year.

| Feature                      | Priority | Notes                                                                            |
| ---------------------------- | -------- | -------------------------------------------------------------------------------- |
| Opt-in data sharing toggle   | High     | Clear consent, off by default                                                    |
| Anonymized data collection   | High     | Strip PII, aggregate to make/model/year level                                    |
| Structured data only         | High     | No free-form text — dropdowns, predefined categories                             |
| Common issues by vehicle     | Medium   | "RAV4 owners often report AC issues around 80K" — informational, not comparative |
| Regional reliability factors | Low      | Rust belt vs dry climates, etc.                                                  |

**Data points collected (structured):**

- Vehicle: make/model/year/engine (from VIN)
- Service type: predefined dropdown
- Category: Scheduled maintenance | Unplanned repair | Recall
- Mileage at service
- Cost
- Severity (if repair): Minor | Moderate | Major
- Region (coarse, e.g., state or climate zone)

**Philosophy:**

- Core app provides full value without this feature
- Insights surface organically as data accumulates
- No "critical mass" requirement — the dataset just gets better over time
- **No empty states** — the feature simply doesn't appear until data exists for that vehicle. When it does, it feels like a natural discovery

**User incentive:** "Help other drivers by contributing anonymized data"

---

### 10. Platform Integrations (The App Comes to You)

> Surface information where the user already is — don't make them open the app for a quick glance.

| Feature                      | Priority | Status | Notes                                          |
| ---------------------------- | -------- | ------ | ---------------------------------------------- |
| Home Screen Widget           | High     | ✅     | Small/medium widget showing "Next Up" service  |
| Lock Screen Widget           | High     | ✅     | Glance at what's due without unlocking         |
| One-tap notification actions | High     | ✅     | "Did you do your oil change?" → Yes/No buttons |
| Siri integration             | Medium   | ⏳     | "Hey Siri, what's due on my car?"              |

**Notification philosophy:**

- **Notifications should be rare** — monthly at most, not weekly
- Only notify when something is actually due or overdue
- No digest spam, no "engagement" notifications
- If we're pinging more than once a month, we're doing it wrong

**Widget types:**

| Size        | Content                                               |
| ----------- | ----------------------------------------------------- |
| Small       | Single "Next Up" item with miles remaining            |
| Medium      | Next 2-3 upcoming services                            |
| Large       | Mini dashboard with vehicle photo + upcoming services |
| Lock Screen | Compact: icon + "Oil change: 500 mi"                  |

**One-tap notification flow:**

1. Service becomes due (not before — no premature pings)
2. Notification: "Oil change is due. Did you get it done?"
3. User taps "Yes" → Log screen with fields pre-filled, just confirm
4. User taps "Not yet" → Snooze options (remind in a week, remind in a month)

---

## UI/UX Principles

### App Navigation Structure

> Three-tab architecture with persistent vehicle context and global quick-add action.

| Tab | Purpose | Key Content | Status |
|-----|---------|-------------|--------|
| **Home** | Glanceable "what's next" | Next Up card, quick stats, recent activity summary (last 3) | ✅ |
| **Services** | Maintenance timeline & logging | Full service history, timeline view, search/filter, service details | ✅ |
| **Costs** | Expense tracking & analytics | Cost history, categories, monthly/yearly summaries, cost-per-mile | ✅ |

**Navigation Principles:**

| Element | Behavior | Status |
|---------|----------|--------|
| **Vehicle header** | Persistent at top of ALL tabs — vehicle selector always accessible | ✅ |
| **Quick-add button (+)** | Floating action button visible on ALL tabs — supersedes all views for consistent access | ✅ |
| **Tab switching** | Should feel fluid and intuitive, not disruptive to user flow | ✅ |
| **Recent Activity (Home)** | Glanceable summary only (last 3 items) — tapping navigates to Services tab for full history | ✅ |

**Tab Content Details:**

**Home Tab:**
- Vehicle header with mileage and specs
- "Next Up" hero card (most urgent service)
- Quick stats bar (year-to-date summary)
- Recent Activity feed (last 3 completed services, links to Services tab)
- Minimal, focused — answer "what needs attention?" at a glance

**Services Tab:**
- Vehicle header (same as Home)
- Full maintenance timeline (past and upcoming)
- Complete service history with search/filter capabilities
- Service logging and scheduling
- Detailed service views with full completion history

**Costs Tab:**
- Vehicle header (same as Home)
- Expense history list
- Cost categorization (maintenance vs repairs)
- Monthly/yearly spending summaries
- Cost-per-mile calculation
- Spending trends and analytics

**Implementation Considerations:**
- ✅ Use native iOS TabView for familiar navigation patterns
- ✅ Consider swipe gestures between tabs for fluid transitions (using `.page` style TabView)
- ✅ Custom BrutalistTabBar for consistent brutalist design aesthetic
- ✅ AppState with @Observable for centralized state management

---

### Adaptive Layouts by Persona

> Same features for everyone. Different layouts surface what's most relevant first. Users can switch modes anytime.

| Persona        | Layout Priority                                       | Default View         |
| -------------- | ----------------------------------------------------- | -------------------- |
| **Casual**     | "Next Up" prominent, history collapsed, minimal stats | Single card focus    |
| **Enthusiast** | Detailed logs, cost analytics expanded                | Data-dense dashboard |

**Implementation:**

- Onboarding asks: "How do you use your vehicles?" → sets initial layout
- Mode toggle in settings to switch anytime
- All features accessible in all modes — layout just changes priority/visibility

### iOS 26 Liquid Glass Guidelines

- **Navigation layer only** — Glass effects for nav bar, tab bar, sheets, not content
- **Never stack glass on glass** — Use `GlassEffectContainer` to group elements
- **Content sits below, controls float** — Clear visual hierarchy
- **Interactive glass** — Use `.glassEffect(.regular.interactive())` for touch feedback

### Design Goals

- [ ] Immediate clarity on launch — no digging for important info
- [ ] One-handed operation — thumb-friendly controls
- [ ] Dark mode first — most users check car stuff in garages/parking lots
- [ ] Minimal onboarding — VIN scan → ready to go

---

## Competitive Gaps to Exploit

| Gap                       | Our Solution                                       |
| ------------------------- | -------------------------------------------------- |
| Manual data entry fatigue | OCR receipts, VIN decode, smart mileage estimation |
| Outdated UI               | Native iOS 26 Liquid Glass                         |
| Subscription burnout      | One-time purchase                                  |
| No smart scheduling       | Factory intervals pre-loaded                       |
| Abandoned apps            | Commitment to long-term support                    |
| No "what's next" view     | Dashboard prioritizes urgency                      |

---

## Data Strategy: Factory Maintenance Schedules

> How we'll populate factory-recommended maintenance schedules without paying for expensive APIs.

### Approach: LLM Extraction from Owner's Manuals

1. **Source PDFs** from free online databases
2. **Extract maintenance schedules** using LLM
3. **Store as structured data** in our database
4. **Crowdsource gaps** — let users submit/verify schedules

### Free Manual Sources

| Source                                                         | Coverage                 | Notes                                       |
| -------------------------------------------------------------- | ------------------------ | ------------------------------------------- |
| [CarManualsOnline.info](https://www.carmanualsonline.info/)    | 80,000+ manuals          | Largest database, searchable online         |
| [MyCarUserManual.com](https://www.mycarusermanual.com/)        | Thousands of vehicles    | Free PDFs, all major brands                 |
| [Manual-Directory.com](https://manual-directory.com/)          | Global coverage          | Free forever, ad-supported                  |
| [Internet Archive](https://archive.org/details/owners_manuals) | Varies                   | Community-uploaded, good for older vehicles |
| Official manufacturer sites                                    | Current + ~10 years back | Most reliable, direct from OEM              |

### Extraction Workflow

1. **Prioritize by popularity** — Start with top 50 vehicles (Civic, Camry, F-150, RAV4, etc.)
2. **Download PDFs** from free sources
3. **LLM extraction** — Feed maintenance section → output structured JSON
4. **Human review** — Spot-check for accuracy before adding to DB
5. **Crowdsource gaps** — Let users submit/verify schedules for their vehicles
6. **Expand iteratively** — Add more vehicles based on user demand

### Known Issues & Caveats

| Issue                              | Description                                                                     | Mitigation                                                          |
| ---------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| **Format varies wildly**           | Tables, prose, bullet points — every manufacturer is different                  | LLM handles this well, but always validate output                   |
| **"Normal" vs "Severe" schedules** | Many vehicles have two schedules based on driving conditions                    | Extract BOTH, let user choose their driving conditions in settings  |
| **Info spread across sections**    | Maintenance info sometimes split across multiple chapters                       | May need to feed multiple pages/sections to LLM, not just one table |
| **Mileage AND time intervals**     | Schedules use both ("5,000 miles OR 6 months, whichever comes first")           | Capture both values, app logic handles whichever triggers first     |
| **Regional variations**            | US, EU, and other markets may have different schedules                          | Start with US market only, note regional gaps                       |
| **Older/obscure vehicles**         | Pre-1990s or rare vehicles may have incomplete/missing manuals                  | Accept gaps, let users manually input for these                     |
| **Copyright considerations**       | Extracting facts (schedules) should be fine, but we're not republishing manuals | Don't store/redistribute the PDFs themselves, only extracted data   |
| **LLM hallucinations**             | Model might invent intervals that don't exist                                   | Human review required before data goes live                         |
| **Model year variations**          | Same model may have different schedules across years                            | Always tie schedule to specific year, not just make/model           |

### Data Schema (Draft)

```json
{
  "vehicle": {
    "make": "Honda",
    "model": "Civic",
    "year": 2022,
    "engine": "2.0L 4-cyl"
  },
  "schedule_type": "normal", // or "severe"
  "services": [
    {
      "service": "Engine oil & filter",
      "interval_miles": 7500,
      "interval_months": 12,
      "notes": "Use 0W-20 oil"
    },
    {
      "service": "Tire rotation",
      "interval_miles": 7500,
      "interval_months": null,
      "notes": null
    },
    {
      "service": "Brake fluid",
      "interval_miles": null,
      "interval_months": 36,
      "notes": "Replace every 3 years regardless of mileage"
    }
  ],
  "source": "2022 Honda Civic Owner's Manual",
  "verified": true,
  "contributed_by": null // or user ID if crowdsourced
}
```

### Why Not Paid APIs?

| Provider                                   | Issue                                            |
| ------------------------------------------ | ------------------------------------------------ |
| Vehicle Databases, DataOne, CarMD, Edmunds | All require paid subscriptions or per-call fees  |
| NHTSA (free)                               | Only does VIN decoding, no maintenance schedules |

Decision: Build our own dataset to avoid ongoing API costs. Initial effort is higher, but no recurring expense and we control the data.

### Fallback Strategy

If a vehicle isn't in our database yet:

1. Use sensible defaults (5K oil change, 30K major service, etc.)
2. Prompt user: "We don't have factory schedules for your vehicle yet. Want to add them from your owner's manual?"
3. User inputs their schedule manually for their own use

**Contribution option:**

- After entering their schedule, ask: "Want to help other [Vehicle] owners? Share your manual's maintenance schedule with the community."
- If yes: user uploads photos of the maintenance pages from their manual
- Submission goes into a **developer review queue**
- Developer validates the information against the images
- Once approved, schedule is added to the database for all users with that vehicle
- Contributor gets a thank-you (maybe a small badge or acknowledgment in the app)

**Review queue process:**

1. User submits: schedule data + manual photos
2. Submission enters queue tagged by make/model/year
3. Developer reviews images, verifies data accuracy
4. Approved → added to database as verified
5. Rejected → user notified with reason (if fixable)

---

## Open Questions

- [ ] What's the MVP feature set for v1.0?
- [ ] Pricing strategy — what's the right one-time price point?
- [ ] How accurate can on-device OCR/ML be for mechanic invoices?
- [ ] Should we support iPad / Mac via Catalyst?
- [ ] How many vehicles should we seed the schedule database with before launch?
- [ ] What's the review/verification process for crowdsourced schedules?

---

## Research Sources

- [Car Maintenance App Features (carexcel.com)](https://carexcel.com/maintenance-tips/1767416-car-maintenance-app)
- [Tacoma Forum - App Recommendations](https://www.tacoma4g.com/forum/threads/vehicle-maintenance-records-app-recommendations.9942/)
- [SmartCar - Auto Repair Features Drivers Want](https://smartcar.com/blog/auto-repair-features)
- [Apple Developer - Liquid Glass](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [Liquid Glass SwiftUI Reference (GitHub)](https://github.com/conorluddy/LiquidGlassReference)

---

_Last updated: January 2026_
