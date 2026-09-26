# Intelligence — on-device reading

Receipt reading and document typing. On-device only (never Private Cloud Compute) and free (no Pro gate). `docs/APP_INTENTS.md` has the SDK-verified tiers; re-check the SDK before using a FoundationModels or Vision API not already used here.

## Layout

```
Intelligence/
├── IntelligenceAvailability.swift   # the one availability check (SystemLanguageModel.default)
├── LanguageModelSessioning.swift    # protocol the pipeline talks to; tests pass a fake
├── OnDeviceLanguageModel.swift      # the real session: @Generable types, ServiceNameTool,
│                                    #   Attachment + OCRTool on iOS 27, context budget
├── ServiceReceiptDraft.swift        # the draft: fields, per-field confidence, issues; ReceiptContext
├── ReceiptTextParser.swift          # rule-based reader (the fallback, and the model's cross-check);
│                                    #   +LineItems (items, kinds), +Values (money, dates)
├── ReceiptDraftValidator.swift      # arithmetic/date/odometer checks + merging model with rules
├── ReceiptExtractionService.swift   # photo → Vision → rules (+ model) → validated draft
├── ServiceNameMatcher.swift         # receipt wording (EN/ES) → the vehicle's service or preset name
├── ServiceNameTool.swift            # the matcher as a FoundationModels Tool
├── DocumentClassifier.swift         # DocumentType from text: model, else keywords, else filename
└── L10n+Receipt.swift               # receipt.*, visual.*, lineItem.* strings
```

Vision reading lives in `Services/OCR/ReceiptOCRService.swift` (`RecognizeDocumentsRequest` + `DetectLensSmudgeRequest` → `ReceiptScan`).

## Rules

- **Always run the rules.** `ReceiptTextParser` reads every scan, model or not. With a model, its answer is merged with the rules' (`ReceiptDraftValidator.merge`: agreement = high confidence, model-only = medium) and then validated. Any model error falls back to the rules' draft — never to nothing.
- **Validation is code, not prompt.** Line items ≈ total, plausible date, odometer ≥ the reading on file. A failed check lowers confidence and records an `Issue`; the form shows it as `.caution` beside the field.
- **One cost rule.** The receipt total is the cost; line items are a breakdown stored as `VisitLineItem`s on a visit (`ServiceVisitWriter.wrap` / `Details.lineItems`) and never added on top (`ExpenseEvent`).
- **Drafts are suggestions.** Nothing here writes. The form (`ServiceLogFormModel+Receipt`) and `LogReceiptIntent` show the values and the user confirms.
- **Test through the seams.** `LanguageModelSessioning` for the model, `ReceiptExtractionService(readImage:)` for Vision, `ReceiptFixtures` transcripts for the rules. Receipt images never go in the repo.
- **Simulator gaps.** The Simulator SDK has no `_Vision_FoundationModels` (`OCRTool`) and no `VisualIntelligence`; both are behind `#if canImport`. `DetectLensSmudgeRequest` needs an A14+, so a failing check passes the photo.
- **Isolation.** Draft/scan/parser types are `nonisolated` value types (the `@Generable` ones must be); services are main-actor classes. Don't put main-actor expressions in default arguments — they're evaluated nonisolated (use an optional and resolve inside).
