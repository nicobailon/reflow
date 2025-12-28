import SwiftUI
@preconcurrency import KeyboardShortcuts

extension Notification.Name {
    static let showHistoryPanel = Notification.Name("showHistoryPanel")
}

extension KeyboardShortcuts.Name {
    @MainActor static let pasteReflowed = Self("pasteReflowed")
    @MainActor static let pasteOriginal = Self("pasteOriginal")
    @MainActor static let toggleAutoReflow = Self("toggleAutoReflow")
    @MainActor static let pasteConservative = Self("pasteConservative")
    @MainActor static let pasteAggressive = Self("pasteAggressive")
    @MainActor static let showHistory = Self("showHistory")
}

enum DefaultShortcuts {
    @MainActor static let pasteReflowed = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .control])
    @MainActor static let pasteOriginal = KeyboardShortcuts.Shortcut(.v, modifiers: [.command, .control, .shift])
    @MainActor static let toggleAutoReflow = KeyboardShortcuts.Shortcut(.r, modifiers: [.command, .control])
    @MainActor static let pasteConservative: KeyboardShortcuts.Shortcut? = nil
    @MainActor static let pasteAggressive: KeyboardShortcuts.Shortcut? = nil
    @MainActor static let showHistory = KeyboardShortcuts.Shortcut(.h, modifiers: [.command, .control])
}

@MainActor
final class HotkeyManager: ObservableObject {
    private let monitor: ClipboardMonitor
    private let settings: AppSettings
    private var handlersRegistered = false
    
    init(settings: AppSettings, monitor: ClipboardMonitor) {
        self.settings = settings
        self.monitor = monitor
        ensureDefaultShortcuts()
        registerHandlers()
    }
    
    private func ensureDefaultShortcuts() {
        if KeyboardShortcuts.getShortcut(for: .pasteReflowed) == nil {
            KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteReflowed, for: .pasteReflowed)
        }
        if KeyboardShortcuts.getShortcut(for: .pasteOriginal) == nil {
            KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteOriginal, for: .pasteOriginal)
        }
        if KeyboardShortcuts.getShortcut(for: .toggleAutoReflow) == nil {
            KeyboardShortcuts.setShortcut(DefaultShortcuts.toggleAutoReflow, for: .toggleAutoReflow)
        }
        if KeyboardShortcuts.getShortcut(for: .showHistory) == nil {
            KeyboardShortcuts.setShortcut(DefaultShortcuts.showHistory, for: .showHistory)
        }
    }
    
    private func registerHandlers() {
        guard !handlersRegistered else { return }
        
        KeyboardShortcuts.onKeyUp(for: .pasteReflowed) { [weak self] in
            Task { @MainActor in
                self?.monitor.pasteReflowed()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .pasteOriginal) { [weak self] in
            Task { @MainActor in
                self?.monitor.pasteOriginal()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleAutoReflow) { [weak self] in
            Task { @MainActor in
                self?.settings.autoReflowEnabled.toggle()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .pasteConservative) { [weak self] in
            Task { @MainActor in
                self?.monitor.pasteReflowed(aggressiveness: .conservative)
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .pasteAggressive) { [weak self] in
            Task { @MainActor in
                self?.monitor.pasteReflowed(aggressiveness: .aggressive)
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .showHistory) {
            Task { @MainActor in
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "history" }) {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    NotificationCenter.default.post(name: .showHistoryPanel, object: nil)
                }
            }
        }
        
        handlersRegistered = true
    }
    
    @discardableResult
    func pasteReflowedNow() -> Bool {
        monitor.pasteReflowed()
    }
    
    @discardableResult
    func pasteOriginalNow() -> Bool {
        monitor.pasteOriginal()
    }
}
