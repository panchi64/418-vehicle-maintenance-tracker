import Foundation

enum LaunchArg {
    static let skipOnboarding = "-UITestSkipOnboarding"

    static var isPresent: (String) -> Bool = { CommandLine.arguments.contains($0) }
}
