# UX Audit — April 2026 (archived)

**Historical record. Do not treat as current guidance.** For live UX rules see [`docs/SURFACE_DOCTRINE.md`](../../SURFACE_DOCTRINE.md).

## What this audit did well

It graded **component-level correctness** thoroughly and its findings there were real: dead code (`AddVehicleView.swift`), VIN validation duplicated four times, design-system violations (rounded corners in the vehicle picker), missing haptic/toast feedback on the wizard save path, unused components. Much of that was acted on, and the parts that weren't are still worth reading.

## Why it did not prevent the problems that followed

The audit had **no lens for information architecture.** It evaluated how well each screen executed its existing structure, never whether that structure was the right one. Eight files, 2,547 lines, organized by tab — with no file for forms or decision flows, so the surfaces that turned out to be the worst offenders fell between its categories entirely.

The clearest symptom: it lists the two-step add-vehicle wizard under **Strengths** —

> "The `AddVehicleFlowView` splits vehicle creation into Basics (required fields + VIN) and Details (optional fields). The step indicator, animated transitions, and disabled 'Next' button until basics are valid all provide clear guidance."

Every observation there is accurate. The conclusion is wrong, because the question "is splitting it this way correct?" was never asked. That wizard put the odometer — the value every reminder, projection, and status color in the app computes from — on step 2 behind an unconditionally-valid Next button, while gating step 1 on make/model/year, which are labels nothing computes from. A screen can execute a bad decomposition flawlessly.

Similar pattern elsewhere: the VIN value-prop banner is called "excellent" progressive disclosure, and taken on its own it is. But it sits *below* the three fields VIN lookup exists to fill, and the lookup skips any field already populated — so it could only ever help users who scrolled past fields they'd been told were required.

## Superseded verdicts

Treat these as reversed:

- The two-step add-vehicle wizard is not a strength. It is replaced by a single-scroll form matching `EditVehicleView`.
- The VIN section's placement is not good progressive disclosure. VIN moves above the fields it fills.
- Per-tab organization is not a sufficient audit structure. Decision surfaces need their own evaluation.

## The lesson, recorded

An audit that only asks "is this implemented well?" will confirm whatever structure it finds. `SURFACE_DOCTRINE.md` adds the missing questions — what is the primary element, what is the default path, what is the tap budget, is anything load-bearing hidden — and its pre-flight checklist puts those answers where a reviewer sees them.
