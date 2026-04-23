@testable import checkpoint
import Testing
import Foundation

@MainActor
@Suite("ToastService Tests")
struct ToastServiceTests {

    @Test("Show toast sets currentToast")
    func showToastSetsCurrentToast() {
        let service = ToastService.shared
        service.show("Test message", icon: "checkmark", style: .success)
        #expect(service.currentToast != nil)
        #expect(service.currentToast?.message == "Test message")
        #expect(service.currentToast?.icon == "checkmark")
        #expect(service.currentToast?.style == .success)
        service.dismiss()
    }

    @Test("Show toast without icon")
    func showToastWithoutIcon() {
        let service = ToastService.shared
        service.show("No icon toast")
        #expect(service.currentToast?.icon == nil)
        #expect(service.currentToast?.style == .info)
        service.dismiss()
    }

    @Test("Dismiss clears currentToast")
    func dismissClearsCurrentToast() {
        let service = ToastService.shared
        service.show("Test message")
        service.dismiss()
        #expect(service.currentToast == nil)
    }

    @Test("Show replaces existing toast")
    func showReplacesExistingToast() {
        let service = ToastService.shared
        service.show("First")
        service.show("Second")
        #expect(service.currentToast?.message == "Second")
        service.dismiss()
    }

    @Test("Toast styles have correct icon colors")
    func toastStyleIconColors() {
        #expect(ToastService.ToastStyle.success.iconColor == Theme.statusGood)
        #expect(ToastService.ToastStyle.error.iconColor == Theme.statusOverdue)
        #expect(ToastService.ToastStyle.info.iconColor == Theme.accent)
    }

    @Test("Auto-dismiss after delay")
    func autoDismissAfterDelay() async throws {
        let service = ToastService.shared
        service.show("Auto dismiss")
        #expect(service.currentToast != nil)

        // Wait for auto-dismiss (3 seconds for non-action toasts + buffer)
        try await Task.sleep(for: .seconds(3.5))
        #expect(service.currentToast == nil)
    }
}
