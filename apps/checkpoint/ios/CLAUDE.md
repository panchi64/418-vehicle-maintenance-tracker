# Checkpoint iOS App

SwiftUI + SwiftData iOS app for vehicle maintenance tracking. See sibling `CLAUDE.md` files under `checkpoint/Models/`, `checkpoint/Views/`, `checkpoint/Services/`, `checkpoint/DesignSystem/`, `CheckpointWidget/`, and `checkpointTests/` for scoped guidance.

## Before building UI

Read [`docs/SURFACE_DOCTRINE.md`](../../../docs/SURFACE_DOCTRINE.md) — surface classes, visual hierarchy, disclosure order, advisory severity, and the `F*` invariants that this app's form components cite in their comments. [`docs/AESTHETIC.md`](../../../docs/AESTHETIC.md) covers visual identity, with each rule tagged `[REQUIREMENT]` or `[PREFERENCE]`.

Short version: every section gets exactly one primary element distinguished on two or more channels (never color alone — status owns color), and anything a feature needs in order to *function* stays on the default path rather than inside a disclosure drawer.

**Sketch the layout before you build it.** [`tools/sketchpad/`](../../../tools/sketchpad/CLAUDE.md) is a SolidJS recreation of this app's UI running against the real `Themes.json` and JetBrains Mono. Iterating there is ~1 second versus ~40 for a `xcodebuild` → launch → screenshot cycle, and it audits the one-primary rule, blurs for the squint test, counts taps against a budget, and switches all eight themes and Dynamic Type. Settle the arrangement there, implement it here, then verify on the Simulator — the sketchpad cannot see keyboard avoidance, VoiceOver, or scroll physics.

## Security Posture

These invariants were validated in the pre-launch security audit. Preserve them as the app evolves:

- **No deep links / custom URL schemes.** The app declares no `CFBundleURLTypes` and registers no `onOpenURL` / `onContinueUserActivity` handlers. If you add either, treat every parameter as untrusted and validate against an allowlist at the handler boundary before it touches models, queries, or networking.
- **SwiftData queries stay compile-checked.** Use `#Predicate` exclusively. Do not introduce `NSPredicate(format:)` with string interpolation, even for dynamic-shape queries.
- **Untrusted input must be parsed into typed fields.** CSV imports, OCR (Vision) output, and any future file imports must flow through strict types (`Int`, `Decimal`, `Date`, `Codable` DTOs) before reaching the model layer. No raw strings into queries, shells, URLs, or HTML.
- **Network input validation.** External API parameters (VIN, make/model, etc.) must be allowlist-validated or percent-encoded with `.urlQueryAllowed` before URL interpolation. Today only NHTSA endpoints are used over HTTPS — keep ATS strict (no `NSAllowsArbitraryLoads`).
- **WatchConnectivity payloads stay typed.** Decode peer messages into strict `Codable` DTOs. Avoid `Any` / `[String: Any]`-shaped messages — a malformed peer payload should fail decoding, not reach business logic.
- **Future backend (when one exists).** When introducing your own backend (sync, auth, telemetry POSTs), apply server-side authorization, structured logging without PII, and consider TLS cert pinning. Client-side checks are not a substitute.
