# Port notes — iOS 26 overhaul (Sep 2026)

What the SwiftUI port must change to match the resolved sketches. Rationale lives in each screen's header comment; this is the checklist. Delete an item once it ships.

## Shell (stand-ins only — build with system components)
- System `TabView` (Home, Services, Costs). Tab bar holds tabs only.
- Per tab `NavigationStack`: large title = vehicle name, `.toolbarTitleMenu` switches vehicles, Settings gear leading, one prominent `[+]` trailing. Services adds `Select` before `[+]` and uses `.searchable`.
- `VehicleHeader` is retired. Its odometer/specs band becomes `VehicleBand`, on Home only, inside the scroll.

## Forms — `FormToolbar` replaces `FormActionBar`
- Cancel `.cancellationAction`, Save `.confirmationAction` (prominent). Title + `.navigationSubtitle` (vehicle).
- **F2:** do not `.disabled()` Save. Style it dim, keep it tappable; the tap fires the error haptic, scrolls to the blocking field, and shows a `.blocking` `FormAdvisory` *at that field*.
- F1/F3 in `SURFACE_DOCTRINE.md` need rewording (Save is in the toolbar; no bottom bar to hide behind the keyboard). The Views/CLAUDE.md "do not put Save in the toolbar" rule is reversed.

## Unified service form (`ServiceForm.tsx`)
- Three doors: `log` ([+]), `complete` (Mark Done: service preselected and locked), `edit` (prefilled; Save dim until dirty; "Was …" hints per F6; Delete Entry last).
- Order: Service → When → Details (odometer, cost, shop) → Next Reminder → More details. "Not done yet" swaps Details + Next Reminder for **Due** (interval chip default, date, mileage; Fires readout; Repeat toggle).
- Service picker: text field, **Due now** rows (name + status tag with remaining), **Recent** rows (name + last date), Browse all. Picking collapses to one row with [Change].
- Defaults: When = Today; odometer = last *confirmed* reading with "est. now ~X [Use]"; Remind me = on.
- `.info`: "Completes X — 917 mi over" (marbete: "Renews …"), "Will update current mileage to X mi". Next Reminder is a readout, not an advisory.
- Cost field gets a leading currency symbol (`prefix`). Category moves into More details, its value named in the collapsed row.
- Budgets measured: Mark Done 2, log oil + cost 4, schedule 4.

## Home
- Order: VehicleBand → Next Up → Suggestions (≤1) → Upcoming (3) → Recent (3). Fixed; empty = `InsufficientDataNote`.
- `NextUpCard`: hero = whichever trigger is closer (miles vs days at pace), status tag, one-line due line, filled **Mark Done** (marbete: **Mark Renewed**, hero always days). Card body and button are separate targets.
- Removed: odometer caution advisory (stale tag moves onto the odometer cell as word + shape), Miles this year, separate cluster/seasonal sections.

## Services
- No mode switch, no status filter. Status groups (Overdue, Due Soon, On Track; empty groups omitted) then month groups of history, then Document library.
- Rows in status groups show shape only (the header carries the word). Actions: service Edit · Mark Done (full swipe); log Duplicate · Edit · Delete (full swipe, with undo). Edit mode = Select → bottom toolbar Mark Done (n) / Delete (n).

## Costs
- Period `30D / YTD / 12M / All` (90D removed). Hero total + monthly average secondary (30D shows the 12-month average). One chart section, Trend ↔ Category as plain chips, units in title, written summary line always. "2026 vs 2025" row. Month groups with totals.
- Removed: Category FilterControl, StatsGrid, Top Expenses, Yearly roundup hero.

## Components and tokens
- `ServiceRow` is two lines (15 Medium name + trailing remaining; status tag + due line). `ServiceEventRow` amount is 15 Medium, not 20.
- `StatusTag` / `StatusMark`: overdue filled square, due soon outlined square, on track short rule — always with the word.
- Section tier: **15 Bold Title Case, textPrimary, no tracking** (new `sectionTitle` type token; replaces 11 Bold caps in `InstrumentSectionHeader`/`ReadoutSection`). Status tags and field labels stay 11 caps.
- Plain chips are 13 sentence case (were 11 caps). Chips wrap text at large type.
- Hero numbers: `.lineLimit(1).minimumScaleFactor(0.5)`. VehicleBand stacks at accessibility sizes (`AdaptiveStack`).
- No new color tokens.
