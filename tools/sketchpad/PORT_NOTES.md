# Port notes — iOS 26 overhaul (Sep 2026)

What the SwiftUI port still has to change to match the resolved sketches. Rationale lives in each screen's header comment; this is the checklist. Delete an item once it ships.

Shop visits and vehicle notes (sketched Sep 2026; rationale in `ShopVisitSection.tsx`, `AppointmentForm.tsx`, `NotesList.tsx`, `NoteSheet.tsx`):

- Home: Shop Visit section after Next Up, before Suggestions — see `ShopVisitSection.tsx` for the resolved layout.
- Appointment sheet: services as check rows (not chips); Shop autofocused on a new booking (the tap budget depends on it); reminder readout explains a dropped day-before reminder.
- `QuickSpecsCard`: VIN as the panel's primary (20pt, own line); Documents and Notes rows share one shape — count + label on one baseline, chevron, optional one-line preview (Notes: newest pinned title).
- Notes list + note sheet as sketched; note titles `lineLimit(1)`, `2` at accessibility sizes.
- Service form: the receipt Shop field wraps (`TextField(axis: .vertical)`); `FormToolbar` title truncates with an ellipsis rather than clamping between words.
