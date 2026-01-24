# CLAUDE.md

## Project Documentation

### Feature Tracking

Feature implementation status is tracked in `docs/FEATURES.md`. When implementing new features:
1. Mark the feature as ✅ (implemented) in the Status column
2. Add corresponding tests for the new functionality
3. Commit both the implementation and the status update together

## Development Guidelines

### Testing

After building features, create corresponding tests to ensure consistency of functionality as the app grows. Tests should cover the new functionality and help catch regressions in future changes.

Ensure tests correctly verify the actual functionality. Avoid hacky workarounds or tricks that circumvent proper testing. Tests should validate real behavior, not just pass artificially.
