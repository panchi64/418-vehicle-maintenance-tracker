# Troubleshooting Guide

## XCTest Parallel Testing Causes Simulator Launch Failures

### Problem

When running unit tests with Xcode's default parallel testing enabled, some tests randomly fail with 0.000 second execution time and simulator launch errors:

```
Simulator device failed to launch com.418-studio.checkpoint.
Error Domain=FBSOpenApplicationServiceErrorDomain Code=1
"The request to open 'com.418-studio.checkpoint' failed."
NSLocalizedFailureReason=The request was denied by service delegate (SBMainWorkspace).
```

### Symptoms

- Tests fail in **0.000 seconds** (indicating they never actually ran)
- Different tests fail on each run (non-deterministic)
- Test output shows multiple simulator clones: `Clone 1 of iPhone 17 - checkpoint (PID1)`, `(PID2)`, etc.
- Tests that fail with parallel testing **pass when run sequentially**
- The actual test code is correct - the failure is infrastructure-related

### Root Cause

Xcode's parallel testing spawns multiple simulator instances to run tests concurrently. This can cause:

1. **Simulator resource contention** - Multiple simulators competing for system resources
2. **App launch failures** - The app fails to launch on some simulator clones
3. **State contamination** - Shared state (like UserDefaults) can leak between parallel test processes

The issue is more common when:
- Running on machines with limited resources
- Tests access shared singletons or App Groups
- Tests involve `@MainActor` or `@Observable` classes

### Diagnosis

To confirm this is a parallel testing issue (not an actual test bug):

```bash
# Run tests WITHOUT parallel testing
xcodebuild test -scheme checkpoint \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO \
  -only-testing:checkpointTests/YourFailingTestClass
```

If tests pass with `-parallel-testing-enabled NO`, the issue is parallel testing instability.

### Solutions

#### Option 1: Disable Parallel Testing (Recommended for CI)

For consistent CI builds, disable parallel testing:

```bash
xcodebuild test -scheme checkpoint \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO \
  -only-testing:checkpointTests
```

#### Option 2: Shutdown Simulators Before Running Tests

Always shutdown existing simulators before running tests:

```bash
xcrun simctl shutdown all && sleep 2 && xcodebuild test ...
```

#### Option 3: Add Proper Test Isolation

Ensure tests don't depend on or contaminate shared state:

```swift
override func setUp() {
    super.setUp()
    // Clear any shared state before each test
    UserDefaults.standard.removeObject(forKey: "yourKey")
    DistanceSettings.shared.unit = .miles  // Reset to default
}

override func tearDown() {
    // Clean up after test
    UserDefaults.standard.removeObject(forKey: "yourKey")
    super.tearDown()
}
```

For App Group UserDefaults:

```swift
override func setUp() {
    super.setUp()
    if let userDefaults = UserDefaults(suiteName: "group.com.your.app.shared") {
        userDefaults.removeObject(forKey: "widgetData")
        userDefaults.synchronize()
    }
}
```

### Tests That Are Most Affected

Tests most likely to hit this issue:

1. **Tests creating `@Observable @MainActor` singletons**
2. **Tests reading/writing to App Groups**
3. **Tests that depend on specific UserDefaults values**
4. **Tests running early in the test suite** (before simulators stabilize)

### Build Configuration

In your Xcode scheme, you can also configure test parallelization:

1. Edit Scheme > Test > Info
2. Under "Options", uncheck "Execute in parallel"

Or in `xcodebuild`:

```bash
# Limit number of parallel simulators
xcodebuild test -maximum-concurrent-test-simulator-destinations 1 ...
```

### Related Issues

- Tests crash after running for 0.000 seconds
- "Clone X of iPhone" appearing in test output
- Non-deterministic test failures
- "RequestDenied" errors from FBSOpenApplicationService

### When to Ignore

If a test fails with 0.000 seconds execution time during parallel testing but passes when run:
- Individually
- With `-parallel-testing-enabled NO`
- After `xcrun simctl shutdown all`

Then the test code is correct and the failure can be attributed to simulator instability.

### References

- Apple Developer Forums: Parallel testing simulator issues
- Xcode Release Notes: Known issues with parallel test execution
- CLAUDE.md: "Never run multiple xcodebuild commands in parallel"
