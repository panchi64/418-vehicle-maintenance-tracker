# Biombo — Salvage audit

Audited 2026-09-27. The old app was a gas-price-only scaffold of about 4,100 lines. It never worked end to end:
- the DACO scraper is a stub
- the app never fetched prices
- confirm and flag had no UI
- there was no offline queue

The rebuild keeps ideas more than code. The old `ios/` and `backend/` were deleted; they were last present at commit `b5feb5f` (`git show b5feb5f:apps/biombo/<path>`). Port only what this table keeps.

| Candidate | Verdict | Why |
|---|---|---|
| Backend stack (Fastify, Drizzle, Postgres, zod, vitest) | **Keep** | It fits. Add PostGIS for polygons, object storage for images, and CDN-cacheable snapshots for the crisis read path (`PRODUCT.md` §8). The dashboard shares the API. |
| `ImageCompressionService` | **Keep** | Its re-render strips EXIF and GPS by design, but the tests check size only: add an EXIF/GPS-absent test. Its 400 px longest edge is likely too small to read a price sign; review the target size. |
| `NetworkMonitor` | **Keep** | It becomes the outbox replay trigger and the offline banner. |
| `packages/VehicleSharing` | **Keep** (package) | Checkpoint depends on it. Its idempotent queue is the template for Biombo's outbox. Biombo's odometer screens are dropped. |
| `FuelOCRService` | **Rewrite** | Keep `parsePrices`, the range filter and comma decimals. Move to `RecognizeDocumentsRequest` + `DetectLensSmudgeRequest` and add grade association. OCR is optional evidence only. |
| DACO scraper | **Rewrite** | Keep only the snapshot seam. Rebuild it as one adapter of a generic official-feed ingester (DACO, LUMA, AAA, NWS). A plain GET works, so Playwright is not needed. |
| API / DB schema | **Rewrite** (ideas only) | Keep:<br>• TTL per row<br>• one vote per device<br>• the per-device rate limit<br>• zod validation<br>• `medianSmooth`<br>• the DACO-delta idea<br>Drop:<br>• the gas-only columns<br>• lat/lng without PostGIS<br>• `bytea` images<br>• the non-atomic counters<br>• the absolute "3 flags" hide rule |
| `BiomboAPIService` | **Rewrite** | Keep the actor, the injectable session, the typed errors and the multipart builder. Add:<br>• bbox and `since` queries<br>• attestation<br>• the offline outbox |
| `LocationService` | **Rewrite** | Move to a one-shot `CLLocationUpdate` fix. The current accuracy is too coarse for road and outage reports. Whether intents and Controls can get a fix outside the foreground is `PRODUCT.md` open decision 16. |
| `DeviceTokenService` | **Rewrite** | The keychain id stays. Add App Attest (deferred when Apple is unreachable), optional Sign in with Apple, and an id reset for "Borrar mis datos". |
| Localization setup | **Rewrite** | Make `es` the source, with full-sentence plural templates and Siri phrases in `AppShortcuts.xcstrings`. The shared package has one consumer (see the open item below). |
| `BrandDetectionService` | **Drop** | False matches, and brand now comes from the station directory. |
| SwiftData cache models | **Drop** | Gas-only and never filled. Their fixed buckets conflict with per-layer freshness. |
| DesignKit `ThemeProviding` / `AestheticBrutalistTheme` | **Drop** for Biombo | These are Checkpoint's tokens and the brutalist look the owner rejected. DesignKit stays as is for Checkpoint. |
| Views, Xcode project | **Drop** (recreate) | Brutalist, gas-only, iOS 17 and Swift 5. Recreate for iOS 26, Swift 6 and default MainActor isolation, matching Checkpoint. |
| Tests | **Drop the suites, port the cases** | Carry over the price-parse, compression and `medianSmooth` cases. |
| `docs/legacy/` | **Keep** as reference | Superseded by `PRODUCT.md`. |

**Port from Checkpoint (copy the pattern, don't import):**
- **App Intents architecture:**
  - `@Dependency` container
  - `PendingRoute` navigation
  - Sendable snapshot entities
  - donations from in-app saves only
  - `AppShortcutsProvider`
  - `SnippetIntent` confirmations
- **Controls:** `ControlWidget`.
- **Intelligence:** `IntelligenceAvailability` + `LanguageModelSessioning` for summaries that degrade gracefully.
- **Receipt and odometer OCR:** candidate scoring.
- **Directions:** the `AppointmentDirections` hand-off for Apple Maps.
- **Official-feed clients:** the swappable static-client pattern from `NHTSAService`.

**Stale Checkpoint-design references to clean up** when the Biombo app is recreated:
- `packages/DesignKit/CLAUDE.md` and the `ThemeProviding.swift` doc comment call `AestheticBrutalistTheme` and `docs/AESTHETIC.md` Biombo's.
- The old `ios/Biombo/BiomboApp.swift` applied that theme; the app is now deleted.

**Open item** (engineering; product decisions are in `PRODUCT.md` §16): the Localization package has one consumer. Fold its 11 keys into Biombo's catalog, or keep the shared package? *Default:* fold them in.
