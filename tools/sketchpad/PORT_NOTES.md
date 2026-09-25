# Port notes — iOS 26 overhaul (Sep 2026)

What the SwiftUI port still has to change to match the resolved sketches. Rationale lives in each screen's header comment; this is the checklist. Delete an item once it ships.

## Vehicle forms
- **Split `EditVehicleView`.** It is ~450 lines holding identity, odometer, VIN, marbete, specs and delete. Extract the remaining sections the way `EditVehicleVINSection` / `EditVehicleOdometerSection` already are.
- **`ErrorMessageRow` → `FormAdvisory`.** The VIN and odometer sections (`EditVehicleVINSection`, `EditVehicleOdometerSection`) still render errors with `ErrorMessageRow` instead of the F12 severity ladder. Move them over, then delete `ErrorMessageRow`.
