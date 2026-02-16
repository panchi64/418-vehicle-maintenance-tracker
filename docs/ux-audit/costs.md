# Costs Tab & Analytics -- UX Audit

## Executive Summary

The Costs Tab is one of Checkpoint's strongest features. The progressive data reveal pattern, dual-filter system, and layered analytics cards create a genuinely useful financial dashboard. The brutalist aesthetic is well applied across charts and cards, and the information hierarchy is logical. However, several issues ranging from inconsistent currency formatting to confusing stat definitions and missing interactivity prevent it from reaching world-class status. The biggest UX gap is that charts are view-only with no tap-to-inspect behavior, meaning users cannot drill into the data they are staring at. Additionally, the "SERVICES" stat counts all filtered logs (including $0 entries) while the rest of the tab operates on `logsWithCosts` -- a subtle but misleading inconsistency.

---

## Strengths

1. **Strong information hierarchy.** The tab flows logically: filters at top, hero total, supporting stats, charts, then raw expense list. Users can answer "how much?" within one second.

2. **Progressive data reveal.** Charts require minimum data thresholds (3+ for cumulative, 2+ for monthly trend). Placeholder cards with clear messaging ("3+ entries needed") prevent confusing partial charts. This is a good pattern.

3. **Dual-axis filtering.** Period and category filters are both visible at once via segmented controls. No hidden menus or modal filter sheets. The `InstrumentSegmentedControl` pattern is discoverable and fast.

4. **CostSummaryCard hero number.** The large amber formatted total with `.contentTransition(.numericText())` provides satisfying animated feedback when switching filters. The `.minimumScaleFactor(0.5)` prevents text overflow for large amounts.

5. **Consistent brutalist aesthetic.** Zero corner radius on bars (`.cornerRadius(0)`), monospace ALL CAPS labels, 2px line weights, 0.5px grid lines, area chart gradient from 0.15 to 0.02 opacity -- all adhere to the design system spec.

6. **Accessibility.** Most cards have `.accessibilityElement(children: .combine)` or `.accessibilityLabel()` annotations. `ExpenseRow` includes `.accessibilityHint` for tappable rows. The `CategoryBreakdownCard` has per-row accessibility combining icon, name, amount, and percentage.

7. **Category color consistency.** `CostCategory.color` mapping (maintenance=green, repair=red, upgrade=amber) is used uniformly across every card, chart legend, expense row, and proportion bar.

8. **Stacked vs. simple bar intelligence.** The monthly trend chart automatically switches between stacked (category="All") and single-color bars (specific category selected). The legend only appears when stacked. This is a thoughtful detail.

9. **Empty state handling.** Two distinct empty states: "No Expenses" (vehicle selected, no data) and "No Vehicle" (no vehicle selected). Both use `EmptyStateView` with appropriate icons and messaging.

10. **Year-over-year comparison.** The `YearlyCostRoundupCard` shows percentage change with color-coded up/down arrows (red for increase, green for decrease), correctly mapping "spending more = bad."

---

## Issues Found

### Critical

**C1. "SERVICES" stat counts $0 entries -- misleading metric**
- **File:** `CostsTab+Analytics.swift:57-59`
- `serviceCount` uses `filteredLogs.count` which includes logs where `cost == nil` or `cost == 0`. But `logsWithCosts` (which drives every other metric including total, average, and all charts) filters these out. A user with 10 services, 3 of which have $0 cost, sees "10 SERVICES" but "$X AVG COST" computed over only 7. The math does not add up from the user's perspective. Either count only paid services (consistent) or clarify the label (e.g., "ALL SERVICES" vs "PAID SERVICES").

**C2. Cost per mile ignores $0 logs in spending but counts their mileage -- potentially skewed**
- **File:** `CostsTab+Analytics.swift:74-88`
- `costPerMile` divides `totalSpent` (from `logsWithCosts`) by mileage range from `filteredLogs` (which includes $0 entries). If a user's oldest log is a $0 entry at 20,000 miles and newest paid entry is at 30,000, the denominator is 10,000 miles but the numerator excludes the $0 log's contribution. This is mathematically correct (cost per mile driven) but could confuse users who see "10 services / $500 total / $0.05/mi" and wonder why the per-mile cost seems low. More importantly, if only 1 log has cost but 2 have mileage, the costPerMile guard `logsWithCosts.count >= 2` fails and shows "-" even though valid mileage range data exists.

**C3. No chart tap interactions -- data is untouchable**
- **Files:** `CumulativeCostChartCard.swift`, `MonthlyTrendChartCard.swift`
- Neither chart supports `.chartOverlay` or `.chartSelection` for tap-to-inspect. Users cannot tap a bar to see exact monthly total, or tap a point on the cumulative chart to see the running total at that date. For a cost tracking app, this is a significant gap. Users see approximate values from axis labels but cannot get precise figures.

### Major

**M1. Inconsistent currency formatting between expense list and summary cards**
- **Files:** `ServiceLog.swift:26-29` vs `Formatters.swift:53-54`
- `ServiceLog.formattedCost` uses `Formatters.currency` (with cents: "$125.50"), while all analytics cards use `Formatters.currencyWhole` (no cents: "$126"). A user sees "$125.50" in the expense list but the same entry contributes to a "$126" total. The total for a single entry does not visually match the line item. This breaks user trust in the numbers.

**M2. MonthlyBreakdownCard appears dead code -- confusing maintenance burden**
- **File:** `MonthlyBreakdownCard.swift` (entire file)
- This 115-line component is never used. `CostsTab.swift:162` comments "// Monthly trend chart (replaces MonthlyBreakdownCard)" and uses `MonthlyTrendChartCard` exclusively. The dead file adds confusion for developers and should be removed or archived.

**M3. Monthly trend text rows duplicate chart information**
- **File:** `MonthlyTrendChartCard.swift:152-185`
- The `textRows` section below the chart repeats the exact same month/amount data as the bar chart above it, but in reverse order (most recent first). The chart reads left-to-right chronologically while the text reads top-to-bottom newest-first. This is disorienting. Users see the same data twice with opposite ordering. The text rows should either be removed (the chart is sufficient) or sorted to match the chart's chronological order.

**M4. Category filter label "Maint" is cryptic**
- **File:** `CostsTab.swift:43`
- `CategoryFilter.maintenance` has rawValue `"Maint"`. While space constraints in a segmented control are real, this abbreviation is not immediately obvious to all users. "Maint" could mean "Maintain", "Maintained", or something else. Consider "Care" or just "Maint." with a period to signal abbreviation.

**M5. Yearly roundup always shows current year, regardless of filter**
- **File:** `CostsTab+Analytics.swift:213-215, 227-229`
- `currentYear` is always `Calendar.current.component(.year, from: Date.now)`. When the "Year" filter is selected (last 12 months), the yearly roundup card always shows the current calendar year -- not the 12-month rolling window the user selected. If a user selects "Year" in March 2026, they see a yearly roundup for 2026 (3 months of data) while the rest of the tab shows 12 months. This mismatch is confusing.

**M6. No sorting controls on expense list**
- **File:** `CostsTab.swift:178-202`
- The expense list is always sorted by date (newest first, inherited from `vehicleServiceLogs`). Users cannot sort by cost amount, category, or service name. For a financial view, sorting by amount (highest first) is a common and expected operation.

**M7. Proportion bar in CategoryBreakdownCard lacks interactivity and labels**
- **File:** `CategoryBreakdownCard.swift:24-43`
- The horizontal proportion bar has no labels, no tap target, and no percentage text. While the row items below show percentages, the bar itself is a colored stripe with no direct information. For very small categories (e.g., 3%), the bar segment is nearly invisible. Consider minimum width or tooltip-on-tap.

### Minor

**m1. ChartPlaceholderCard message is generic -- does not tell user what specific data is needed**
- **File:** `ChartPlaceholderCard.swift:11`, `Localizable.strings:136`
- The message "3+ entries needed" appears for the cumulative cost chart. But the monthly trend placeholder also shows this same message even though it needs 2+ months of data, not 3+ entries. The placeholder should distinguish: "3+ expenses to show spending pace" vs "Expenses in 2+ months to show trends."

**m2. DateFormatter created inside `formatDate()` on every row render**
- **File:** `ExpenseRow.swift:92-96`
- A new `DateFormatter` is allocated per call to `formatDate()`. With 50+ expense rows, this creates 50+ formatter instances. Should use `Formatters.mediumDate` which already exists and matches the same "MMM d, yyyy" format.

**m3. DateFormatter created inside `formatMonthYear()` on every cell render**
- **File:** `MonthlyTrendChartCard.swift:222-226`
- Same issue. A new `DateFormatter` is created per call. Should be a static property.

**m4. `lifetimeCostPerMile` is computed but never displayed**
- **File:** `CostsTab+Analytics.swift:91-108`
- This computed property exists in the analytics extension but is never referenced in any view. Either it is dead code or represents an incomplete feature.

**m5. Expense list has no "load more" or pagination**
- **File:** `CostsTab.swift:184`
- All `logsWithCosts` are rendered in a single `ForEach`. For users with 100+ expenses, this creates significant view hierarchy. Consider lazy loading or limiting to 20 with a "Show All" button.

**m6. No visual distinction between $0 periods and no-data periods**
- When a user has service logs in a month but all at $0 cost, that month is invisible in all charts and the expense list. There is no indication that maintenance happened but was free (e.g., warranty work). The user might think they forgot to log services.

**m7. Category breakdown disappears when a specific category is selected**
- **File:** `CostsTab.swift:142`
- When `categoryFilter != .all`, the `CategoryBreakdownCard` is hidden. This makes sense (there is only one category to show), but there is no feedback explaining why the card vanished. A brief "showing only [Category]" indicator would help.

**m8. StatsCard "PER MILE" formatting is inconsistent with other cards**
- **File:** `CostsTab+Analytics.swift:110-113`
- `formattedCostPerMile` returns `"$0.15/mi"` using `String(format:)` while all other currency values use `Formatters.currencyWhole`. The "/mi" suffix is hardcoded and does not respect the user's distance unit preference (`DistanceSettings.shared.unit`). Should use the user's abbreviation (e.g., "$0.15/km").

**m9. Stacked bar chart ID is `\.month` which drops category dimension**
- **File:** `MonthlyTrendChartCard.swift:59`
- `Chart(byCategory, id: \.month)` uses only the month as the ID. Since multiple entries share the same month (one per category), Swift Charts may deduplicate or misrender. The `id` should combine month and category. This may not cause visual bugs today due to how Charts handles stacking, but it is technically incorrect.

**m10. YearlyCostRoundupCard "MILES DRIVEN" label uses `DistanceSettings.shared.unit`**
- **File:** `YearlyCostRoundupCard.swift:234-237`
- The label correctly reads `DistanceSettings.shared.unit.fullName.uppercased()` (e.g., "KILOMETERS"), but the value formatter `formatMiles` is `@MainActor` and creates the tilde prefix manually. This is fine but worth noting that the parameter name `miles` is misleading when the unit is kilometers -- the internal value is still in miles, converted at display time.

**m11. Expense row chevron appears even when navigation may be broken**
- **File:** `ExpenseRow.swift:78-82`
- The chevron only appears when `onTap != nil`, which is correct. But `appState.selectedServiceLog = log` in `CostsTab.swift:186` sets the selected log -- if no sheet or navigation is wired to respond to this, the tap does nothing visible. Verify that setting `selectedServiceLog` actually presents a detail view.

---

## Detailed Findings

### 1. Chart Readability

**Cumulative Cost Chart (Spending Pace):**
- The line + area combination reads well. Linear interpolation is correct for financial data (no smoothing that implies intermediate values).
- Point marks are square (`.symbol(.square)`) aligning with brutalist aesthetic.
- X-axis uses "MMM d" format, Y-axis uses abbreviated currency ("$1.2K"). Both are readable.
- The gradient fill (0.15 to 0.02 opacity) acts as a visual "area under curve" indicator. It communicates magnitude effectively without overwhelming.
- **Issue:** With only 3 data points, the chart looks sparse. The minimum threshold of 3 is correct but the chart area is 160pt tall for just a few points.

**Monthly Trend Chart:**
- Stacked bars correctly use per-category colors. The custom legend at bottom is clean.
- X-axis stride logic (`count > 8 ? 3 : 1`) prevents label overcrowding.
- January labels include year suffix ("JAN '26") -- helpful for multi-year views.
- **Issue:** Bar width is not explicitly set, so Swift Charts auto-sizes. With 12+ months, bars become very thin and hard to distinguish stacked segments.

**Category Breakdown:**
- The proportion bar is 12pt tall -- readable but thin. Color segments are clear for 2-3 categories.
- Below the bar, each category row shows icon, name, percentage, and amount. Excellent information density.
- **Issue:** No hover/tap to highlight a segment in the proportion bar.

### 2. Period and Category Filter UX

- Both filters are always visible (no expandable panel or hidden menu). This is good for discoverability.
- Period options: Month, YTD, Year, All. These cover the most common use cases.
- Category options: All, Maint, Repair, Upgrade. Direct mapping to `CostCategory`.
- **Issue:** "YTD" defaults on tab load but may confuse users early in January (shows very little data). Consider defaulting to "Year" or "All" if YTD period contains fewer than 3 entries.
- **Issue:** No visual indicator of active filter state beyond the segmented control selection. When scrolled down past the filters, users lose context of what period/category they are viewing.

### 3. Cost Summary

- The `CostSummaryCard` answers "how much" immediately. Large amber number, "Total Spent" label, period context below.
- `.contentTransition(.numericText())` provides smooth animation when switching filters.
- **Issue:** When total is $0, the card shows "$0" in large amber text. This is technically correct but an empty state might be more appropriate (or dim the color).

### 4. Empty States

**No expenses (vehicle selected):**
- Shows `EmptyStateView` with dollar icon, "No Expenses" title, "Record service costs when completing maintenance" message.
- No action button to add an expense directly from this state. Users must navigate to Services tab to log a service with a cost. This is a missed opportunity.

**No vehicle:**
- Shows "No Vehicle" with car icon and "Select or add a vehicle to view costs."
- Also lacks an action button to add a vehicle.

**Single entry:**
- Shows CostSummaryCard (correct total), StatsCard row (1 service, that cost as avg, "-" per mile), a ChartPlaceholderCard ("3+ entries needed"), and the single expense in the list.
- This is a reasonable progressive state but the placeholder is the dominant visual element, making the tab feel empty even though there is data.

### 5. Stats Row

- **SERVICES:** Count of all filtered logs (including $0). See C1.
- **AVG COST:** `totalSpent / logsWithCosts.count`. Correct math but paired with the wrong denominator visually (SERVICES count differs).
- **PER MILE:** Shows "-" until 2+ logs with costs exist AND mileage range > 0. The hint text "LOG 2+ SERVICES WITH MILEAGE TO CALCULATE" appears contextually -- good.
- **Issue:** The three stats cards are equally sized in an HStack. "PER MILE" values like "$0.15/mi" are wider than "12" or "$87", causing the card to truncate with `.minimumScaleFactor(0.7)`. This can make the per-mile value harder to read.

### 6. Expense List Scannability

- Each row shows: category icon (colored), service name, date + category tag, cost (colored), chevron.
- The `//` separator between date and category tag is a nice brutalist touch.
- Rows are tappable (sets `appState.selectedServiceLog`).
- **Issue:** No mileage shown on expense rows. For a vehicle maintenance app, knowing "Oil Change at 45,000 mi - $85" is more useful than just "Oil Change - Jan 5 // MAINTENANCE - $85".
- **Issue:** Rows have no swipe actions (delete, edit). All editing requires navigating into the detail view.

### 7. Chart Interactions

- No tap-to-select on any chart.
- No tooltip or callout for data points.
- No chart selection binding.
- Charts are purely visual -- users must estimate values from axis labels.
- This is the single biggest interactivity gap in the tab.

### 8. Yearly Roundup

- Shows year header, total spent (with hero number), YoY percentage change, category breakdown, and footer stats (services count + miles driven).
- YoY change correctly colors red for increase, green for decrease.
- **Issue:** When no previous year data exists, `yearOverYearChange` returns `nil` and the change indicator is hidden. No explanation for why -- "First year of tracking" or similar would help.
- **Issue:** The roundup duplicates data already visible in the summary card and category breakdown above it. With "All" filter, the yearly roundup shows current-year data, the summary card shows all-time data, and the category breakdown shows all-time data. Three different scopes visible simultaneously without clear differentiation.

### 9. Monthly Trend

- Bar chart + text rows below.
- Text rows are sorted newest-first (reversed from the chart which is oldest-to-newest).
- **Issue:** The text rows are visually disconnected from the chart. They sit in a separate card-like container. A user might not realize they correspond to the chart above.

### 10. Cumulative Cost Chart

- Area fill helps communicate magnitude and pace.
- Linear interpolation is correct (no false smoothing).
- **Issue:** For long time ranges (multi-year), x-axis labels may overcrowd. There is no stride logic like in the monthly trend chart.

### 11. Category Breakdown

- Horizontal proportion bar + itemized list below.
- Sorted by amount descending (largest first). Good.
- Percentages rounded to whole numbers (`%.0f%%`). Fine for the display.
- **Issue:** Very small percentages (e.g., 2%) produce visually invisible bar segments. No minimum width is enforced.

### 12. Progressive Data Reveal

| Data State | What Shows |
|---|---|
| 0 expenses | Empty state ("No Expenses") |
| 1 expense | Summary card, stats row (avg = total), 1 chart placeholder, 1 expense row |
| 2 expenses | Summary card, stats row (may have per-mile), 1 chart placeholder, 2 expense rows |
| 3+ expenses | Full cumulative chart unlocks, expense list |
| 2+ months | Monthly trend chart unlocks |
| Year/All filter | Yearly roundup card unlocks |

This progression is logical and well-implemented. The placeholders bridge the gap between empty and full states.

### 13. Chart Placeholder Cards

- Generic message for all chart types ("3+ entries needed").
- Uses chart icon and tertiary text.
- Height matches `ChartConstants.chartHeight` (160pt) -- maintains layout stability.
- **Issue:** As noted in m1, the message should be chart-specific.

### 14. Number Formatting Consistency

| Location | Format | Example |
|---|---|---|
| CostSummaryCard | `currencyWhole` | "$1,234" |
| StatsCard (AVG COST) | `currencyWhole` | "$87" |
| StatsCard (PER MILE) | `String(format:)` | "$0.15/mi" |
| CategoryBreakdownCard | `currencyWhole` | "$450" |
| MonthlyTrendChartCard | `currencyWhole` | "$350" |
| YearlyCostRoundupCard | `currencyWhole` | "$1,234" |
| ExpenseRow | `Formatters.currency` | "$125.50" |
| Y-axis labels | `ChartFormatting.abbreviatedCurrency` | "$1.2K" |

The expense row using cents while everything else uses whole dollars is the key inconsistency (M1).

### 15. Brutalist Chart Aesthetic Adherence

| Requirement | Status |
|---|---|
| Zero corner radius on bars | Pass (`.cornerRadius(0)`) |
| 2px line width | Pass (`ChartConstants.chartLineWidth = 2`) |
| 0.5px grid lines | Pass (`ChartConstants.chartGridLineWidth = 0.5`) |
| Monospace ALL CAPS labels | Pass (`.font(.brutalistLabel)` + `.uppercased()`) |
| 160pt chart height | Pass (`ChartConstants.chartHeight = 160`) |
| No gradients except structural area fills | Pass (only cumulative chart has area gradient) |
| Square point markers | Pass (`.symbol(.square)`) |
| Area gradient 0.15 to 0.02 | Pass |
| Card borders with `Theme.gridLine` | Pass |

Full compliance with the design system.

---

## Code Quality Issues

**CQ1. Dead file: `MonthlyBreakdownCard.swift`**
- 115 lines of unused code. Comment in `CostsTab.swift:161` confirms it was replaced.

**CQ2. Dead computed property: `lifetimeCostPerMile`**
- `CostsTab+Analytics.swift:91-108` is never referenced in any view.

**CQ3. DateFormatter allocation per render in `ExpenseRow.formatDate()`**
- `ExpenseRow.swift:92-96` creates a new formatter per call. `Formatters.mediumDate` already provides the identical "MMM d, yyyy" format.

**CQ4. DateFormatter allocation per render in `MonthlyTrendChartCard.formatMonthYear()`**
- `MonthlyTrendChartCard.swift:222-226` same issue. Should be a `private static let`.

**CQ5. `categoryColorMapping` uses fragile switch-on-count pattern**
- `MonthlyTrendChartCard.swift:202-219` handles 1, 2, and "default" (3) categories. This works because `CostCategory` has exactly 3 cases, but adding a 4th category would silently truncate the mapping. A more robust approach or a comment explaining the coupling would help.

**CQ6. `categoryBreakdown` computed property duplicated between `CostsTab+Analytics.swift` and `YearlyCostRoundupCard.swift`**
- Both compute category breakdowns with identical logic. Per the architecture guidelines in CLAUDE.md ("extract it to one method on the model rather than duplicating across views"), this should be a shared utility or model method.

**CQ7. `BrutalistChartStyle` modifier sets axis marks that get overridden**
- `MonthlyTrendChartCard.swift:34` applies `.brutalistChartStyle()` which sets default x/y axis marks. But lines 69-92 immediately override both axes with custom marks. The modifier's axis configuration is wasted work. The modifier is only useful for its `.frame(height:)` and `.chartPlotStyle` in this context.

**CQ8. `costPerMile` mixes `filteredLogs` and `logsWithCosts`**
- `CostsTab+Analytics.swift:79` sorts `filteredLogs` for mileage range, but line 87 uses `totalSpent` from `logsWithCosts`. The two populations may have different date ranges, leading to subtle mismatches in extreme edge cases.

---

## Recommendations

### High Priority (address before next release)

1. **Unify `serviceCount` to use `logsWithCosts`** -- or relabel the SERVICES stat as "ALL LOGGED" and add a separate "PAID" stat. The current mismatch between the count and the average is the most user-facing bug.

2. **Add chart selection/overlay** -- at minimum, add `.chartOverlay` with a drag gesture that shows a tooltip with the exact value for the nearest data point. This transforms charts from passive visuals to interactive tools.

3. **Standardize currency formatting** -- decide whether the app shows cents or not, and apply consistently. Recommendation: use cents in detail/row contexts (`ExpenseRow`), whole dollars in summary/chart contexts. But clearly document this as an intentional design decision.

4. **Fix PER MILE unit hardcoding** -- replace `"/mi"` with `"/" + DistanceSettings.shared.unit.abbreviation` to respect the user's distance preference.

### Medium Priority (next iteration)

5. **Remove `MonthlyBreakdownCard.swift`** -- dead code adds maintenance burden and confusion.

6. **Remove or use `lifetimeCostPerMile`** -- if planned for future use, add a TODO comment. Otherwise delete.

7. **Make chart placeholder messages chart-specific** -- pass a custom message to `ChartPlaceholderCard` for each chart type explaining what data is needed and why.

8. **Add mileage to expense rows** -- show mileage as a secondary detail (e.g., "45,000 mi") to give cost-per-service more context.

9. **Fix text row sort order in MonthlyTrendChartCard** -- either sort chronologically to match the chart, or remove the text rows entirely since they duplicate the chart data.

10. **Cache DateFormatters in `ExpenseRow` and `MonthlyTrendChartCard`** -- use static properties instead of per-call allocation.

### Low Priority (polish)

11. **Add "Add Expense" action to empty state** -- the empty state could include a button that navigates to the log-service flow.

12. **Add sort controls to expense list** -- a small sort-by toggle (date, amount, category) above the list header.

13. **Extract shared `categoryBreakdown` logic** -- unify the duplicate computation between `CostsTab+Analytics` and `YearlyCostRoundupCard`.

14. **Add minimum width to proportion bar segments** -- enforce at least 4px for any non-zero segment so tiny categories remain visible.

15. **Consider sticky filters** -- when scrolled deep into the expense list, the period/category context is lost. A sticky header or floating filter chip would maintain context.

16. **Yearly roundup scope clarity** -- either filter the roundup by the selected period or add a clear label like "Calendar Year 2026" to distinguish it from the filtered view above.
