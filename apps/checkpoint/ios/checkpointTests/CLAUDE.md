# checkpointTests - Unit Test Suite

This directory contains unit tests for the Checkpoint app.

## Directory Structure

```
checkpointTests/
├── checkpointTests.swift    # Base test class (template)
├── Models/                  # Model tests
├── Views/                   # View tests
├── Services/                # Service tests
├── State/                   # AppState tests
├── Utilities/               # Utility tests
├── Insights/                # Contextual insights tests
├── Vehicle/                 # Vehicle feature tests
└── Widget/                  # Widget tests
```

## Test Setup Pattern

All tests build their store with `ModelContainer.inMemoryForTesting()` (`Helpers/ModelContainer+Testing.swift`): in-memory, full app schema, CloudKit off. Never hand-roll `ModelConfiguration(isStoredInMemoryOnly: true)` — the iCloud entitlement makes it mirror to CloudKit, which traps on the first save on iOS 27 simulators.

```swift
import XCTest
import SwiftData
@testable import checkpoint

final class VehicleTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        modelContainer = .inMemoryForTesting()
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
}
```

## Store fixtures

`Fixtures/` holds on-disk stores written by shipped app versions (`CheckpointV1.store`, from a Simulator, rollback-journal mode so it is one file). `CheckpointMigrationTests` copies one to a temp directory and opens it with `CheckpointMigrationPlan`, which proves the frozen schema versions still match real stores. Add a fixture for each schema version you ship.

## Test Naming Convention

Use descriptive names following the pattern:
```
test_[method/property]_[scenario]_[expectedResult]
```

## Running Tests

```bash
# All tests
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17'

# Unit tests only
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:checkpointTests

# Specific test class
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:checkpointTests/VehicleTests
```
