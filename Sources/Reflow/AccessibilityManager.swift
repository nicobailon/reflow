import AppKit

@MainActor
protocol AccessibilityPermissionChecking: AnyObject {
    var isTrusted: Bool { get }
}

@MainActor
final class AccessibilityManager: ObservableObject, AccessibilityPermissionChecking {
    @Published private(set) var isTrusted: Bool
    private var pollTask: Task<Void, Never>?
    private let pollInterval: TimeInterval
    
    init(pollInterval: TimeInterval = 2.0) {
        self.isTrusted = AXIsProcessTrusted()
        self.pollInterval = pollInterval
        startPolling()
    }
    
    deinit {
        pollTask?.cancel()
    }
    
    func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != isTrusted {
            isTrusted = trusted
        }
    }
    
    func requestPermission() {
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.openSystemSettings()
        }
    }
    
    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func startPolling() {
        pollTask?.cancel()
        let interval = pollInterval
        pollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                let delay = UInt64(interval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
                guard let self else { return }
                self.refresh()
            }
        }
    }
}
