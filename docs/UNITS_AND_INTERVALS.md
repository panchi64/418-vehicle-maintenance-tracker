# Units & Intervals — UX Specification

> How Checkpoint displays maintenance tracking units across every surface. Every display decision answers: **"What does the driver need to know right now to take action?"**

---

## Unit Types

### Distance

- **Miles** and **Kilometers** — user selects preference in Settings
- Stored internally as miles; converted at display time only
- User preference applies globally across all vehicles and surfaces

### Time

- **Months** — used for interval configuration ("Every 6 months")
- **Days** — used for urgency communication ("Due in 12 days")
- Intervals are set in months (how people think about maintenance schedules); days are derived from due dates to communicate urgency

---

## Priority Setting

Users can configure which metric the app emphasizes when a service has both time and distance tracking.

**Setting:** Display Priority
**Options:**

| Option | Behavior | Best For |
|--------|----------|----------|
| **Mileage** (default) | Distance metrics shown as primary; time shown as secondary | Daily drivers, commuters, high-mileage vehicles |
| **Time** | Date/days metrics shown as primary; distance shown as secondary | Low-mileage vehicles, seasonal cars, time-oriented users |
| **Auto** | Whichever metric is closer to being due takes primary position | Users who want the app to decide based on real urgency |

This is a global setting. The primary metric gets visual prominence (larger, bolder); the secondary metric appears smaller/muted underneath or beside it.

### Fallback Behavior

When a vehicle has no current mileage entered, distance-based display is impossible. In this case:
- **Silently fall back to time-based display** — don't break the experience
- Show a subtle prompt on the vehicle or service: "Enter current mileage to enable distance tracking"
- Once mileage is entered, distance tracking activates automatically

---

## Dual-Interval Services

Many services have both a time and distance interval (e.g., oil change: every 6 months or 5,000 miles). The principle is **whichever comes first.**

### How It Works

1. **When a service is completed:** Both `dueDate` (now + months) and `dueMileage` (current + miles) are set
2. **Overdue:** Triggers if **either** threshold is exceeded — one is enough
3. **Due Soon:** Determined by **whichever metric is closer to being due**, not both independently
4. **Sorting/urgency:** Both metrics converted to days (distance via driving pace), most urgent wins

### Visual Communication

No explicit "whichever comes first" text. Instead:
- **Primary metric** displayed prominently (determined by user's priority setting, or by urgency if set to Auto)
- **Secondary metric** displayed smaller/muted alongside
- **Status color** (overdue/due soon/good) reflects the most urgent metric regardless of preference
- The visual hierarchy makes the relationship intuitive without explanation

---

## Display Rules by Surface

### Dashboard / Home Tab

The dashboard is about **actionable urgency.** Scannable, one primary metric per service.

**Dual-interval service (both time and distance):**
- Primary: Determined by priority setting (or whichever is closer in Auto mode)
- Secondary: Shown muted, smaller, below or beside primary
- Example (mileage priority): **"1,200 mi remaining"** with ^"or 45 days"^ underneath
- Example (time priority): **"Due in 45 days"** with ^"or 1,200 mi"^ underneath
- Example (auto, mileage closer): **"1,200 mi remaining"** with ^"or 45 days"^ underneath

**Distance-only service:**
- Show distance remaining: **"1,200 mi remaining"**
- If pace data available, optionally show estimated date in secondary position: ^"~Feb 28"^

**Time-only service:**
- Within 60 days: **"Due in 12 days"**
- Beyond 60 days: **"Due Mar 15"**

**No tracking configured:**
- Show **"No schedule"** — neutral, not alarming
- Don't hide these; they still have value as records

**Overdue:**
- Show the more overdue metric as primary (larger magnitude = more urgent)
- Distance: **"800 mi overdue"**
- Time: **"12 days overdue"**

### Service Cards (List Views)

Cards need to be scannable. One line of status, tight.

| Status | What to Show |
|--------|-------------|
| Overdue | Most overdue metric with urgency color |
| Due Soon | Closest-to-due metric with warning color |
| Good | Next milestone (per priority setting) |
| Neutral | Last performed date, or "No schedule" |

### Service Detail View

Detail is comprehensive — show **everything available.**

```
SCHEDULE
─────────────────────────────
Due Date          Mar 15, 2026
Due Mileage       33,000 mi
Repeat            Every 6 months
                  Every 5,000 mi

STATUS
─────────────────────────────
Days remaining    45 days
Miles remaining   1,200 mi
```

When pace data is available, add:

```
Estimated pace    ~40 mi/day
Predicted due     ~Feb 28 (by mileage)
```

Both metrics shown at equal visual weight here. The detail view is for understanding, not quick scanning.

### Notifications

Lead with the metric that triggered the notification.

- **Mileage-triggered:** "Oil Change — approaching 33,000 mi (est. 5 days away)"
- **Date-triggered:** "Oil Change — due in 7 days (Mar 15)"
- **Both close:** Lead with whichever is closer, mention the other in parentheses

### Widgets

Minimal space — only what matters.

- **Small:** Service name + single status line (primary metric only)
- **Medium:** Service name + primary metric + secondary metric if space allows

---

## Status Determination

### Status Levels

| Status | Meaning | Visual |
|--------|---------|--------|
| **Overdue** | Past due date OR exceeded due mileage | Red/urgent color |
| **Due Soon** | Within threshold of either metric (whichever is closer) | Warning/amber color |
| **Good** | Has due info but not within thresholds | Default/green |
| **Neutral** | No due date or mileage set | Muted/gray |

### "Due Soon" Thresholds

| Metric | Default | User-Configurable Options |
|--------|---------|--------------------------|
| Distance | 750 mi | 500 / 750 / 1,000 / 1,500 |
| Time | 30 days | 14 / 30 / 45 / 60 |

**Evaluation logic for dual-interval services:**
- Compute how close each metric is to its threshold
- The **closer** metric determines status
- This prevents a service from being marked "good" when one metric is nearly due but the other is far away

### Urgency Scoring (Sort Order)

Both thresholds are converted to days for comparison:
- **Time urgency** = days until due date
- **Distance urgency** = miles remaining ÷ daily driving pace
- **Effective urgency** = minimum of the two

When pace data is unavailable, only time urgency is used for sorting.

---

## Service Creation & Editing

### Progressive Disclosure

Don't overwhelm users with fields they may not need. Show what's relevant, let them add more.

**Default state (based on priority setting):**

- **Mileage priority:** Show distance interval field first
  - "Every `[____]` mi"
  - Link below: "+ Add time interval"
  - Tapping reveals: "or every `[____]` months"

- **Time priority:** Show time interval field first
  - "Every `[____]` months"
  - Link below: "+ Add distance interval"
  - Tapping reveals: "or every `[____]` mi"

- **Auto:** Show both fields (since the user has expressed no preference)

**Presets auto-fill both fields** when a preset has both `defaultIntervalMonths` and `defaultIntervalMiles`. In this case, both fields are visible regardless of priority setting.

### Due Date / Due Mileage

Same progressive pattern:
- Priority metric's "due" field shown by default
- Secondary field available via "+ Add due [date/mileage]"
- If both are set (e.g., from preset or edit), both are visible

---

## Display Formatting

### Distance Values

| Context | Format | Example |
|---------|--------|---------|
| Remaining / overdue | Number + unit abbreviation | "1,200 mi" / "1,931 km" |
| Absolute due mileage | Number + unit abbreviation | "33,000 mi" |
| Estimated mileage | Tilde prefix | "~32,847 mi" |
| Interval | "Every" + number + unit | "Every 5,000 mi" |

### Time Values

| Context | Format | Example |
|---------|--------|---------|
| Due today | Explicit | "Due today" |
| Due tomorrow | Explicit | "Due tomorrow" |
| Within 60 days | Days remaining | "Due in 12 days" |
| Beyond 60 days | Date | "Due Mar 15, 2026" |
| Overdue ≤7 days | Days | "3 days overdue" |
| Overdue >7 days | Date it was due | "Overdue since Jan 28" |
| Interval | Months | "Every 6 months" |

### Combined Intervals

| Scenario | Format |
|----------|--------|
| Both set | "Every 6 months or 5,000 mi" |
| Months only | "Every 6 months" |
| Distance only | "Every 5,000 mi" |
| Neither (one-time) | No interval shown |

The word **"or"** communicates the "whichever comes first" semantic naturally.

---

## Edge Cases

### Vehicle with No Mileage Data
- Distance-based display falls back to time silently
- Subtle prompt to enter mileage (not blocking)
- Once mileage is entered, distance tracking activates

### No Pace Data (New Vehicle or Insufficient Snapshots)
- Don't show estimated dates for distance-based services — avoid false precision
- Show distance and time metrics independently without converting between them
- Once 7+ days of snapshots exist, pace estimation activates

### User Changes Distance Unit Preference
- All displayed values update immediately (conversion from stored miles)
- Interval descriptions update: "Every 5,000 mi" → "Every 8,047 km"
- No data migration needed

### Service with Only One Interval Type
- Works normally — only that metric is shown, no secondary
- No "missing" state; a time-only or distance-only service is perfectly valid

### Very Long Intervals
- Services like timing belt (100,000 mi) may not be "due soon" for years
- Show as "Good" with the absolute due mileage/date
- Don't suppress — the user set them up intentionally

### Newly Created Service with No History
- If due date/mileage set but no `lastPerformed`: show schedule as-is
- If intervals set but no due point: prompt to either set an initial due date/mileage or log a completion to start the cycle

---

## Future Considerations

### Additional Time Intervals
- **Weeks:** Fleet vehicles, commercial use (may need `intervalDays` field since weeks don't map cleanly to months)
- **Years:** Cleaner for long-interval services ("Every 2 years" instead of "Every 24 months")

### Seasonal / Calendar-Anchored Services
- "Every October" (winter tires), "Every May" (AC service)
- Anchored to calendar months rather than intervals — different data model
- Would need a `targetMonth: Int?` or similar field

### Severe vs Normal Schedules
- Manufacturers define different intervals for severe driving conditions
- Could offer a per-vehicle or per-service toggle
- Example: Oil change — Normal: 7,500 mi / Severe: 5,000 mi

### Engine Hours
- Relevant for boats, ATVs, generators, lawn equipment
- Same dual-interval pattern applies (hours OR months)
- Would need `engineHours`, `dueHours`, `intervalHours` fields

### Smart Interval Adjustment
- If a user consistently services earlier than the interval, suggest shortening
- If pace is very low, highlight that time-based due dates may be more relevant than distance

### Per-Vehicle Priority Override
- Allow priority to be set per vehicle instead of only globally
- Daily commuter → mileage priority; weekend car → time priority

---

_Last updated: February 2026_
