# App Store Connect — Setup Guide for Checkpoint

> Comprehensive guide for filling out App Store Connect fields. Covers everything needed for TestFlight and eventual App Store launch.

---

## 1. New App Creation

**Apps → + → New App**

| Field | What to enter |
|-------|--------------|
| **Platform** | iOS |
| **Name** | `Checkpoint - Car Maintenance` (30 char max — App Store display name) |
| **Primary Language** | English (U.S.) |
| **Bundle ID** | Select your registered bundle ID from the dropdown |
| **SKU** | `checkpoint-ios-v1` (internal only, never shown to users) |
| **User Access** | Full Access (unless you have specific team roles) |

**On the name:** 30 character limit. "Checkpoint - Car Maintenance" (28 chars) puts the brand first and tells people what it does. Alternatives:
- `Checkpoint: Vehicle Tracker` (27 chars)
- `Checkpoint - Mileage & Service` (31 — too long)

---

## 2. App Information

**General → App Information**

| Field | What to enter |
|-------|--------------|
| **Subtitle** | `Vehicle Service & Cost Tracker` (30 char max — appears below name in search results) |
| **Category** | Primary: **Utilities**. Secondary: **Productivity** |
| **Content Rights** | "Does not contain third-party content" — app is original |
| **Age Rating** | Fill out the questionnaire — result will be **4+** (no objectionable content) |

**On categories:** Utilities is where maintenance/tracker apps live. Avoid "Lifestyle" — too broad and competitive. Productivity as secondary helps discoverability.

---

## 3. Pricing and Availability

| Field | What to enter |
|-------|--------------|
| **Price** | Free |
| **Availability** | All territories (or select specific ones if preferred) |
| **Pre-Orders** | Skip for now — go straight to TestFlight |

In-App Purchases are set up separately (see [section 8](#8-in-app-purchases)).

---

## 4. App Privacy

**General → App Privacy**

Required before submission. Based on the app's actual data usage:

**Privacy Policy URL:** Required. Host on your website or a GitHub Pages site.

**Data collection disclosure:**

| Data Type | Collected? | Purpose | Linked to Identity? | Tracking? |
|-----------|-----------|---------|---------------------|-----------|
| **Purchases** | Yes | StoreKit tips/Pro unlock | No | No |
| **Location (Coarse)** | Yes | Seasonal reminders use region | No | No |
| **Photos** | Yes | Receipt/odometer OCR capture | No | No |
| **Diagnostics** | Yes | PostHog analytics (opt-out available) | No | No |

**What is NOT collected:** Names, email, phone, contacts, browsing history, search history, identifiers, etc.

Mark everything as **"Used for App Functionality"** — not for tracking. PostHog is self-hosted and opt-out, so it qualifies as analytics, not tracking.

---

## 5. Version Information

The main page for the v1.0 submission.

### 5a. Screenshots (REQUIRED)

**Required device sizes:**

| Device | Resolution |
|--------|-----------|
| **6.9" display** (iPhone 16 Pro Max / 17 Pro Max) | 1320 x 2868 px |
| **6.7" display** (iPhone 16 Plus) | 1290 x 2796 px |
| **6.5" display** (iPhone 11 Pro Max) | 1242 x 2688 px (often optional) |
| **5.5" display** (iPhone 8 Plus) | 1242 x 2208 px (if supporting older devices) |

**Pro tip:** Only the 6.9" and 6.7" sets are strictly needed. Apple auto-scales the rest. Providing 6.9" screenshots covers 6.7" and 6.5" too.

**Recommended screenshot order (up to 10):**

1. **Home tab** — Next Up card, vehicle selector, glanceable dashboard
2. **Services tab** — Timeline view with upcoming/past services
3. **Costs tab** — Charts and spending analytics
4. **Service logging** — Quick-add flow / receipt OCR
5. **Widgets** — Home Screen + Lock Screen + Watch widgets
6. **Recall alerts** — Safety feature, builds trust
7. **Apple Watch** — Complication + watch app
8. **Settings/Themes** — Show the brutalist design language

**Apple Watch screenshots (optional):** 410 x 502 px (Series 10/11)

**Format:** PNG or JPEG, no transparency/alpha. Consider minimal text overlays ("Track what matters", "Know what's next") — most top apps use these.

### 5b. App Previews (Optional, HIGHLY recommended)

Up to 3 video previews per device size. 15-30 seconds each. Auto-play in search results and massively improve conversion.

**Suggested preview:** Quick flow showing add vehicle → VIN scan fills details → log a service → widgets show what's next. Keep it snappy.

### 5c. Description (4000 char max)

```
Your vehicle maintenance, simplified.

Checkpoint tells you what's due, what you've spent, and what's next — at a glance. No ads. No account required. Just a clean, focused tool for keeping your car on track.

WHAT'S NEXT — ALWAYS VISIBLE
• Dashboard shows your most urgent service front and center
• Smart mileage estimation learns your driving patterns
• Reminders that respect your time — monthly at most, never spammy

TRACK EVERYTHING THAT MATTERS
• Log services with date, mileage, cost, and notes
• Snap receipts and odometer readings with built-in OCR
• VIN scanning auto-fills your vehicle details
• Full cost analytics with category breakdowns and trends

APPLE ECOSYSTEM, FULLY INTEGRATED
• Home Screen & Lock Screen widgets
• Apple Watch app with complications
• Siri shortcuts — "Hey Siri, what's due on my car?"
• CarPlay dashboard widget
• Interactive widgets to mark services done

SMART SCHEDULING
• Service clustering bundles nearby maintenance into one visit
• Seasonal reminders based on your climate
• NHTSA recall alerts for safety-critical issues
• Dual-axis tracking: date AND mileage, whichever comes first

YOUR DATA, YOUR CONTROL
• Free iCloud sync across all your devices
• Export full service history as PDF
• Import from Fuelly, Drivvo, or Simply Auto
• Works fully offline — cloud is a bonus, not a requirement

Free for up to 3 vehicles with every feature unlocked. No ads, ever. Upgrade to Pro for unlimited vehicles and custom themes.
```

### 5d. Promotional Text (170 char max)

Appears above the description. Can be updated **without a new app version** — use for announcements:

```
Track services, costs, and mileage for your vehicles. Smart reminders, widgets, Apple Watch, and Siri — all free. No ads, no account required.
```

### 5e. Keywords (100 char max, comma-separated)

Don't repeat words from the app name (Apple already indexes those). Every character counts:

```
car,maintenance,mileage,tracker,oil change,vehicle,service,reminder,odometer,recall,VIN,cost,repair
```

(96 characters)

**Tips:**
- No spaces after commas
- Don't repeat app name words ("Checkpoint" is already indexed)
- Singular forms — Apple matches plurals automatically
- Mix specific ("oil change", "VIN") and broad ("tracker", "repair")

### 5f. URLs

| Field | What to enter |
|-------|--------------|
| **Support URL** (required) | Website, GitHub repo, or dedicated support page |
| **Marketing URL** (optional) | Landing page if you have one |

### 5g. What's New

Not shown for v1.0. For future updates, keep it concise and user-focused.

### 5h. Build

Select a TestFlight build here once uploaded via Xcode.

---

## 6. App Review Information

| Field | What to enter |
|-------|--------------|
| **Contact First/Last Name** | Your name |
| **Contact Phone** | Your phone number |
| **Contact Email** | Your email |
| **Demo Account** | Not needed — app doesn't require login |
| **Notes for Review** | See below |

**Review notes draft:**

```
Checkpoint is a vehicle maintenance tracker. No account or login is required.

To test the app:
1. Launch the app and follow the onboarding to add a vehicle
2. You can use VIN "1HGBH41JXMN109186" for testing VIN decode
3. The app uses location for seasonal maintenance reminders (optional)
4. Notifications require authorization — the app prompts on first relevant action
5. In-app purchases: Pro unlock ($9.99) and Tip Jar ($1.99/$4.99/$9.99) — these use StoreKit 2

The PostHog analytics SDK is self-hosted and opt-out (Settings → Privacy).
No data is shared with third parties.
```

---

## 7. TestFlight Setup

### Test Information

**TestFlight → Test Information**

| Field | What to enter |
|-------|--------------|
| **Beta App Description** | "Checkpoint helps you track vehicle maintenance, costs, and mileage. This is a TestFlight beta — please report any issues!" |
| **Feedback Email** | Your email |
| **Privacy Policy URL** | Same as App Store privacy policy URL |
| **Beta App Review Contact** | Your contact info |

### Internal Testing

- Create an internal testing group
- Add your Apple ID(s)
- Builds are available instantly (no review needed)

### External Testing

- Create a group, add testers by email or share the public link
- First build requires a brief Beta App Review (usually approved in <24 hours)

---

## 8. In-App Purchases

**Features → In-App Purchases**

| Product ID | Type | Display Name | Price |
|-----------|------|-------------|-------|
| `pro.unlock` | Non-Consumable | Checkpoint Pro | $9.99 |
| `tip.small` | Consumable | Small Tip | $1.99 |
| `tip.medium` | Consumable | Medium Tip | $4.99 |
| `tip.large` | Consumable | Large Tip | $9.99 |

**For each IAP, provide:**
- **Display Name** and **Description** (shown in purchase sheet)
- **Review Screenshot** (screenshot of the purchase UI in the app)
- **Review Notes** (e.g., "Pro unlock removes the 3-vehicle limit and unlocks basic themes")

IAPs must be in "Ready to Submit" state and attached to the app version before submission.

---

## 9. Things to Prepare Outside App Store Connect

| Item | Status | Notes |
|------|--------|-------|
| **Privacy Policy** | ❌ Needed before submission | Simple webpage — what you collect, how you use it, how to opt out |
| **App Icon** | ✅ Exists (`418-checkpoint-app-icon-v1.png`) | Must be 1024x1024, no alpha/transparency, no rounded corners (Apple adds those) |
| **PrivacyInfo.xcprivacy** | ❌ Missing from project | Apple requires this manifest — declare API usage reasons (UserDefaults, file timestamp, etc.) |
| **Screenshots** | ❌ Need to create | Use Xcode Simulator screen capture or Fastlane Snapshot |
| **Support website/page** | ❌ Needed | Even a simple GitHub Pages site works |

---

## 10. Priority Checklist

Order of operations:

- [ ] **Create the Privacy Policy** — blocker for everything
- [ ] **Add `PrivacyInfo.xcprivacy`** to the Xcode project — required for submission
- [ ] **Set up the app in App Store Connect** — name, bundle ID, categories
- [ ] **Configure IAPs** in App Store Connect
- [ ] **Fill in App Privacy** disclosures
- [ ] **Upload a build** via Xcode → TestFlight
- [ ] **Take screenshots** once happy with the build
- [ ] **Fill in description, keywords, promotional text**
- [ ] **Add review notes** and contact info
- [ ] **Submit to TestFlight external testing** (if you want outside testers)

---

_Last updated: February 2026_
