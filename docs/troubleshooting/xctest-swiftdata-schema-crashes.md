# Troubleshooting Guide

## XCTest Crashes When SwiftData Schema Changes

### Problem

Tests crash during bootstrap with errors like:

```
Testing failed:
    checkpoint (43233) encountered an error (Early unexpected exit, operation never finished bootstrapping - no restart will be attempted.
    (Underlying Error: The test runner crashed while preparing to run tests: checkpoint at <external symbol>))
```

This typically occurs after adding new properties to a `@Model` class (SwiftData entity).

### Symptoms

- Tests that previously passed now crash before any test methods execute
- The error mentions "operation never finished bootstrapping"
- Crash occurs even with in-memory model containers
- Multiple test runs fail with different PIDs

### Root Cause

When you add new properties to a SwiftData `@Model` class:

1. The simulator may have cached data from a previous schema version
2. SwiftData's lightweight migration cannot always handle the schema mismatch
3. The test runner crashes during app initialization before tests can run

This is distinct from the `@MainActor` / `@Observable` crash - this is about **schema incompatibility in the simulator's persistent state**.

### Solution

**Erase the simulator state before running tests.**

```bash
# Shutdown all running simulators
xcrun simctl shutdown all

# Erase the specific simulator
xcrun simctl erase "iPhone 17"

# Wait for simulator to reset
sleep 2

# Run tests
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:checkpointTests/YourTests
```

### Alternative: Use `xcrun simctl boot` Before Tests

If you don't want to erase, you can try booting the simulator fresh:

```bash
xcrun simctl shutdown all
sleep 2
xcrun simctl boot "iPhone 17"
sleep 3
xcodebuild test ...
```

### Prevention Tips

1. **Use in-memory model containers in tests** - This avoids persistent storage issues:

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: Vehicle.self, configurations: config)
```

2. **Clean build folder** when schema changes are significant:

```bash
xcodebuild clean build -scheme checkpoint ...
```

3. **Add default values** for new optional properties:

```swift
// Good - explicit default
var marbeteExpirationMonth: Int? = nil

// Better - in init with default
init(..., marbeteExpirationMonth: Int? = nil) {
    self.marbeteExpirationMonth = marbeteExpirationMonth
}
```

4. **Don't run multiple xcodebuild commands in parallel** - This spawns multiple simulators and causes crashes (see CLAUDE.md for details)

### Related Issues

- Tests crash with "Early unexpected exit"
- SwiftData lightweight migration failures
- Simulator state corruption after model changes
- "operation never finished bootstrapping" errors

### When This Happens

Most commonly occurs when:

- Adding new properties to `@Model` classes
- Changing property types or optionality
- Renaming properties without migration
- After a `git checkout` to a branch with different schema
- Running tests on a simulator that was used with a different branch

### Quick Fix Checklist

1. ✅ `xcrun simctl shutdown all`
2. ✅ `xcrun simctl erase "iPhone 17"` (or your simulator name)
3. ✅ Wait 2-3 seconds
4. ✅ Run tests again

This typically resolves the issue immediately.
