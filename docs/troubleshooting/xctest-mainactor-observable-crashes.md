# Troubleshooting Guide

## XCTest Crashes with @MainActor and @Observable Classes

### Problem

Tests that create instances of `@Observable` `@MainActor` classes (like `AppState`) crash with errors like:

```
Simulator device failed to launch com.418-studio.checkpoint
Error Domain=FBProcessExit Code=64 "The process failed to launch."
```

The crash report shows:
```
malloc_report: ___BUG_IN_CLIENT_OF_LIBMALLOC_POINTER_BEING_FREED_WAS_NOT_ALLOCATED
AppState.__deallocating_deinit
```

### Symptoms

- Tests that **don't** create `AppState()` instances pass
- Tests that **do** create `AppState()` instances fail with app launch crashes
- Each failing test spawns a new process (different PIDs in test output)
- Non-`@MainActor` tests in the same class pass fine
- Crash occurs during deallocation of the `@Observable` class

### Root Cause

This is a Swift concurrency issue involving the interaction between:

1. **`@Observable` macro** - Swift's modern observation system
2. **`@MainActor` annotation** - Ensures class runs on main thread
3. **SwiftData `@Model` references** - When an `@Observable` class holds references to SwiftData models
4. **XCTest execution model** - How tests are run and objects are deallocated

When a test class is marked with `@MainActor`, XCTest runs each test method in a way that can cause the test host app to relaunch. If the `@Observable` class's destructor runs in an unexpected context (after the SwiftData model context is gone), it causes memory corruption.

The specific crash happens in `swift::TaskLocal::StopLookupScope::~StopLookupScope()` during the deallocation of the `@Observable` object, indicating the Swift concurrency runtime is in an inconsistent state.

### Solution

**Use async test methods with `@MainActor` on individual methods, NOT on the entire class.**

#### Before (Crashes)

```swift
@MainActor  // DON'T do this
final class AppStateTests: XCTestCase {

    func testSomething() {  // Crashes
        let appState = AppState()
        // ...
    }
}
```

#### After (Works)

```swift
final class AppStateTests: XCTestCase {  // No @MainActor on class

    @MainActor
    func testSomething() async {  // async keyword is key
        let appState = AppState()
        // ...
    }
}
```

### Key Changes

1. **Remove `@MainActor` from the test class declaration**
2. **Add `@MainActor` to individual test methods that need it**
3. **Make those test methods `async`** - This is critical; it allows Swift's concurrency runtime to properly manage the MainActor context
4. **Use local variables** for `ModelContainer` and `ModelContext` instead of instance properties
5. **Clear SwiftData model references** before test ends when assigning models to `@Observable` properties:

```swift
@MainActor
func testSelectedVehicle_CanBeSet() async throws {
    let modelContainer = try ModelContainer(...)
    let modelContext = modelContainer.mainContext

    let appState = AppState()
    let vehicle = Vehicle(...)
    modelContext.insert(vehicle)

    appState.selectedVehicle = vehicle
    XCTAssertNotNil(appState.selectedVehicle)

    // IMPORTANT: Clear reference before test ends
    appState.selectedVehicle = nil
}
```

### Why This Works

- Async test methods allow XCTest to properly integrate with Swift's structured concurrency
- The `@MainActor` annotation on individual methods ensures proper actor isolation without forcing XCTest to relaunch the app for each test
- Local variables ensure the ModelContainer stays alive for the duration of the test
- Clearing model references prevents the `@Observable` object from holding stale SwiftData references during deallocation

### Tests That Don't Need @MainActor

Tests that only interact with non-actor-isolated types (like testing an enum's properties) don't need `@MainActor`:

```swift
// These can remain synchronous and non-actor-isolated
func testTab_AllCases() {
    XCTAssertEqual(AppState.Tab.allCases.count, 3)
}

func testTab_Titles() {
    XCTAssertEqual(AppState.Tab.home.title, "HOME")
}
```

### Related Issues

- Tests crash after running for 0.000 seconds
- "Simulator device failed to launch" errors during test runs
- Memory corruption in Swift concurrency runtime during test teardown
- SwiftData models causing crashes when used in tests

### References

- Swift Forums: Actor isolation and XCTest
- Apple Developer Forums: @Observable with @MainActor testing issues
- SwiftData testing best practices
