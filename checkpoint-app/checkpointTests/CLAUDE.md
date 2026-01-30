# checkpointTests - Unit Test Suite

This directory contains unit tests for the Checkpoint app.

## Directory Structure

```
checkpointTests/
├── checkpointTests.swift    # Base test class (template)
├── Models/                  # Model tests
│   ├── CostCategoryTests.swift
│   ├── MarbeteTests.swift
│   ├── MileageSnapshotTests.swift
│   ├── ServiceAttachmentTests.swift
│   ├── ServiceLogTests.swift
│   ├── ServicePresetTests.swift
│   ├── ServiceTests.swift
│   └── VehicleTests.swift
├── Views/                   # View tests
├── Services/                # Service tests
├── State/                   # AppState tests
├── Utilities/               # Utility tests
└── Widget/                  # Widget tests
```

## Test Setup Pattern

All tests use in-memory ModelContainer to avoid disk I/O:

```swift
import XCTest
import SwiftData
@testable import checkpoint

final class VehicleTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: Vehicle.self, Service.self, ServiceLog.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
}
```

## Test Naming Convention

Use descriptive names following the pattern:
```
test_[method/property]_[scenario]_[expectedResult]
```

Examples:
```swift
func test_status_pastDueDate_returnsOverdue()
func test_urgencyScore_noDueDateOrMileage_returnsMaxInt()
func test_dailyMilesPace_lessThan7Days_returnsNil()
```

## Model Test Coverage

### VehicleTests
- Vehicle creation and properties
- Relationship management (services, logs, snapshots)
- `displayName` computation
- `effectiveMileage` calculation
- `dailyMilesPace` and confidence
- Marbete expiration logic

### ServiceTests
- Service status computation
- Urgency scoring
- Due date/mileage thresholds
- Status edge cases

### MileageSnapshotTests
- EWMA pace calculation
- Recency weighting
- Minimum data requirements (7 days)
- Confidence levels

### ServiceLogTests
- Log creation
- Relationship to Service and Vehicle
- Attachment handling

### ServiceAttachmentTests
- Attachment creation
- Thumbnail generation
- MIME type handling

### MarbeteTests
- Expiration date calculation
- Status computation
- Days remaining calculation

## Async Test Pattern

For async operations:
```swift
func test_fetchRecalls_validVIN_returnsRecalls() async throws {
    let recalls = try await NHTSAService.shared.fetchRecalls(vin: "1HGCM82633A123456")
    XCTAssertFalse(recalls.isEmpty)
}
```

## Mocking Services

For service tests that need mocking:
```swift
class MockNotificationService: NotificationServiceProtocol {
    var scheduledNotifications: [String] = []

    func schedule(_ service: Service) async throws {
        scheduledNotifications.append(service.id.uuidString)
    }
}
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

# Specific test method
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:checkpointTests/VehicleTests/test_status_pastDueDate_returnsOverdue
```

## Coverage Targets

| Category | Target |
|----------|--------|
| Models | 90%+ |
| Services | 80%+ |
| Utilities | 80%+ |
| Views | Key interactions |

## Best Practices

1. **Isolate tests** - Each test should be independent
2. **Use in-memory storage** - Avoid disk I/O in tests
3. **Test edge cases** - nil values, empty arrays, boundary conditions
4. **Descriptive assertions** - Include messages in XCTAssert calls
5. **Clean up** - Reset state in tearDown

## Common Test Helpers

```swift
extension XCTestCase {
    func createTestVehicle(
        name: String = "Test Car",
        mileage: Int = 50000
    ) -> Vehicle {
        Vehicle(
            name: name,
            make: "Test",
            model: "Model",
            year: 2020,
            currentMileage: mileage
        )
    }

    func createTestService(
        name: String = "Oil Change",
        dueDate: Date? = nil,
        dueMileage: Int? = nil
    ) -> Service {
        Service(
            name: name,
            dueDate: dueDate,
            dueMileage: dueMileage
        )
    }
}
```
