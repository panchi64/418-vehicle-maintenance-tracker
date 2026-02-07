# PostHog Dashboard Setup Guide

Step-by-step instructions for creating analytics dashboards from Checkpoint's event taxonomy.

## How to Create an Insight

1. Go to **Dashboards** in the left sidebar
2. Open your dashboard (or create one with **+ New dashboard**)
3. Click **+ Add insight**
4. Select the insight type (Trends, Funnels, Retention, Stickiness, or User Paths)
5. Configure the event, aggregation, breakdown, and filters as described below
6. Title and save

---

## Dashboard 1: Engagement & Retention

### DAU / WAU / MAU

> Daily, weekly, and monthly active users. The DAU/MAU ratio is your stickiness — above 20% is strong for a utility app.

| Field          | Value        |
| -------------- | ------------ |
| Type           | Trends       |
| Date range     | Last 90 days |
| Chart interval | Day          |

Add three graph series, all using `app_opened`:

| Series | Aggregation                                  |
| ------ | -------------------------------------------- |
| A      | Unique users (this is DAU)                   |
| B      | Weekly active users (rolling 7-day unique)   |
| C      | Monthly active users (rolling 30-day unique) |

### Daily Sessions

> Total app opens per day. Spikes may correlate with notification sends or service due dates.

| Field          | Value               |
| -------------- | ------------------- |
| Type           | Trends              |
| Event          | `app_session_start` |
| Aggregation    | Total count         |
| Chart interval | Day                 |
| Date range     | Last 30 days        |

### Stickiness

> Of users active this month, how many days did they open the app? A flat curve means most users only open once. A long tail means power users.

| Field | Value        |
| ----- | ------------ |
| Type  | Stickiness   |
| Event | `app_opened` |

### Weekly Retention

> Of users who first appeared in a given week, what percentage returned in following weeks? Week 1 retention above 30% is a strong signal for a maintenance tracker.

| Field                   | Value        |
| ----------------------- | ------------ |
| Type                    | Retention    |
| Performed event (start) | `app_opened` |
| Came back and performed | `app_opened` |
| Retention period        | Week         |

### Fleet Size Distribution

> How many vehicles each user tracks. Single-vehicle users are the majority — multi-vehicle users are power users worth retaining.

| Field       | Value               |
| ----------- | ------------------- |
| Type        | Trends              |
| Event       | `app_session_start` |
| Aggregation | Unique users        |
| Breakdown   | `vehicle_count`     |
| Chart type  | Bar                 |
| Date range  | Last 30 days        |

---

## Dashboard 2: Feature Adoption

### Tab Usage

> Which tabs users navigate to. High Costs tab usage signals engagement with the analytics value prop.

| Field          | Value          |
| -------------- | -------------- |
| Type           | Trends         |
| Event          | `tab_switched` |
| Aggregation    | Total count    |
| Breakdown      | `tab`          |
| Chart interval | Week           |
| Date range     | Last 30 days   |

### Screen Flow

> Navigation paths through the app. Identifies common workflows and dead ends where users drop off.

| Field                      | Value      |
| -------------------------- | ---------- |
| Type                       | User Paths |
| Starting from event        | `$screen`  |
| Starting screen (optional) | `home`     |

### Mileage Entry Method

> How users update mileage: manual entry, OCR camera, or quick update card. OCR adoption validates the camera feature investment.

| Field       | Value             |
| ----------- | ----------------- |
| Type        | Trends            |
| Event       | `mileage_updated` |
| Aggregation | Total count       |
| Breakdown   | `source`          |
| Chart type  | Bar (stacked)     |
| Date range  | Last 30 days      |

### Attachment Usage

> Percentage of completed services that include photo attachments. Low adoption may signal the feature is hard to discover.

| Field       | Value                 |
| ----------- | --------------------- |
| Type        | Trends                |
| Event       | `service_marked_done` |
| Aggregation | Total count           |
| Breakdown   | `has_attachments`     |
| Chart type  | Bar (stacked)         |
| Date range  | Last 30 days          |

### Search & Export Usage

> Weekly usage of service search and PDF export. These are power-user features — growth here signals deepening engagement.

| Field          | Value        |
| -------------- | ------------ |
| Type           | Trends       |
| Chart interval | Week         |
| Date range     | Last 30 days |

Two series on the same chart:

| Series | Event                      | Aggregation |
| ------ | -------------------------- | ----------- |
| A      | `services_search_used`     | Total count |
| B      | `service_history_exported` | Total count |

---

## Dashboard 3: Core Funnels

### Vehicle Onboarding Funnel

> Completion rate from starting vehicle entry to saving. Drop-off between steps signals friction in the form.

| Field             | Value   |
| ----------------- | ------- |
| Type              | Funnels |
| Conversion window | 1 hour  |

Steps (in order):

| Step | Event           | Filter                                      |
| ---- | --------------- | ------------------------------------------- |
| 1    | `$screen`       | `$screen_name` equals `add_vehicle_basics`  |
| 2    | `$screen`       | `$screen_name` equals `add_vehicle_details` |
| 3    | `vehicle_added` | —                                           |

### Service Completion Funnel

> Of services scheduled, what percentage get marked done within 30 days. This is the core app loop — low conversion means users schedule but don't return.

| Field             | Value   |
| ----------------- | ------- |
| Type              | Funnels |
| Conversion window | 30 days |

Steps:

| Step | Event                 |
| ---- | --------------------- |
| 1    | `service_scheduled`   |
| 2    | `service_marked_done` |

### Mileage Prompt Funnel

> When the app prompts for a mileage update, do users follow through? Low conversion means the prompt is ignorable rather than useful.

| Field             | Value     |
| ----------------- | --------- |
| Type              | Funnels   |
| Conversion window | 5 minutes |

Steps:

| Step | Event                  | Filter                         |
| ---- | ---------------------- | ------------------------------ |
| 1    | `mileage_prompt_shown` | —                              |
| 2    | `mileage_updated`      | `source` equals `quick_update` |

### OCR Recognition Rate

> Of camera OCR attempts, what percentage return a result (Vision framework didn't error). Broken down by type (odometer vs VIN). A low rate means users are getting camera/lighting failures.

| Field             | Value      |
| ----------------- | ---------- |
| Type              | Funnels    |
| Conversion window | 1 minute   |
| Breakdown         | `ocr_type` |

Steps:

| Step | Event           |
| ---- | --------------- |
| 1    | `ocr_attempted` |
| 2    | `ocr_succeeded` |

### OCR End-to-End Funnel

> Full pipeline from camera open to user accepting the result. Drop-off between succeeded → confirmed means users dismissed/cancelled the reading. Breakdown by type reveals which OCR mode has more friction.

| Field             | Value      |
| ----------------- | ---------- |
| Type              | Funnels    |
| Conversion window | 5 minutes  |
| Breakdown         | `ocr_type` |

Steps:

| Step | Event           |
| ---- | --------------- |
| 1    | `ocr_attempted` |
| 2    | `ocr_succeeded` |
| 3    | `ocr_confirmed` |

### OCR Reading Accuracy

> Of confirmed OCR readings, what percentage did the user accept without editing? This is the true measure of OCR usefulness — a high unedited rate means the Vision pipeline is returning values users trust. Broken down by type.

| Field       | Value          |
| ----------- | -------------- |
| Type        | Trends         |
| Event       | `ocr_confirmed`|
| Aggregation | Total count    |
| Breakdown   | `value_edited` |
| Chart type  | Bar (stacked)  |
| Date range  | Last 30 days   |

For a direct acceptance rate, add a second insight:

| Field       | Value          |
| ----------- | -------------- |
| Type        | Trends         |
| Event       | `ocr_confirmed`|
| Aggregation | Total count    |
| Date range  | Last 30 days   |

Two series with filters:

| Series | Filter                                    | Aggregation |
| ------ | ----------------------------------------- | ----------- |
| A      | `value_edited` equals `false`             | Total count |
| B      | `ocr_confirmed` (all, no filter)          | Total count |

Use a **Formula** insight: `A / B` to get the acceptance-without-edit rate. Break down by `ocr_type` to compare odometer vs VIN accuracy.

### Notification Permission Rate

> Grant vs deny rate for push notification permission. Notifications drive retention — a high deny rate limits re-engagement.

| Field      | Value         |
| ---------- | ------------- |
| Type       | Trends        |
| Chart type | Bar (stacked) |
| Date range | Last 30 days  |

Two series:

| Series | Event                             | Aggregation |
| ------ | --------------------------------- | ----------- |
| A      | `notification_permission_granted` | Total count |
| B      | `notification_permission_denied`  | Total count |

For a grant rate percentage, use a **Formula** insight: `A / (A + B)`.

---

## Dashboard 4: Power User Signals

### Preset vs Custom Services

> Whether users pick from the preset service library or create custom services. High custom usage may mean the preset library has gaps.

| Field       | Value               |
| ----------- | ------------------- |
| Type        | Trends              |
| Event       | `service_scheduled` |
| Aggregation | Total count         |
| Breakdown   | `is_preset`         |
| Date range  | Last 30 days        |

### Service Categories

> Most tracked maintenance categories. Guides which presets to expand and what content to prioritize.

| Field       | Value               |
| ----------- | ------------------- |
| Type        | Trends              |
| Event       | `service_scheduled` |
| Aggregation | Total count         |
| Breakdown   | `category`          |
| Chart type  | Bar or Pie          |
| Date range  | Last 30 days        |

### Service Detail Adoption

> Of completed services, how many include cost, notes, or attachments. Shows which optional fields users find valuable enough to fill in.

| Field      | Value        |
| ---------- | ------------ |
| Type       | Trends       |
| Date range | Last 30 days |

Three series, all using `service_marked_done`:

| Series | Filter                          | Aggregation |
| ------ | ------------------------------- | ----------- |
| A      | `has_cost` equals `true`        | Total count |
| B      | `has_notes` equals `true`       | Total count |
| C      | `has_attachments` equals `true` | Total count |

### Analytics Opt-Outs

> Cumulative users who disabled analytics. A spike after an update may signal a trust concern.

| Field       | Value                     |
| ----------- | ------------------------- |
| Type        | Trends                    |
| Event       | `analytics_opted_out`     |
| Aggregation | Unique users (cumulative) |
| Date range  | Last 90 days              |

---

## Priority Order

Set these up first for the most signal with least effort:

1. **DAU / WAU / MAU** — north star health metric
2. **Weekly Retention** — are users coming back?
3. **Service Completion Funnel** — is the core loop working?
4. **Mileage Entry Method** — is OCR worth the investment?
5. **Tab Usage** — where users spend their time
