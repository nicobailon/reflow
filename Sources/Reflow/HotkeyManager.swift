import SwiftUI
@preconcurrency import KeyboardShortcuts

extension Notification.Name {
    static let togglePopover = Notification.Name("togglePopover")
}

extension KeyboardShortcuts.Name {
    @MainActor static let pasteReflowed = Self("pasteReflowed")
    @MainActor static let pasteOriginal = Self("pasteOriginal")
    @MainActor static let toggleAutoReflow = Self("toggleAutoReflow")
    @MainActor static let pasteConservative = Self("pasteConservative")
    @MainActor static let pasteAggressive = Self("pasteAggressive")
    @MainActor static let showHistory = Self("showHistory")
    @MainActor static let pasteHistory1 = Self("pasteHistory1")
    @MainActor static let pasteHistory2 = Self("pasteHistory2")
    @MainActor static let pasteHistory3 = Self("pasteHistory3")
    @MainActor static let pasteHistory4 = Self("pasteHistory4")
    @MainActor static let pasteHistory5 = Self("pasteHistory5")
    @MainActor static let pasteHistory6 = Self("pasteHistory6")
    @MainActor static let pasteHistory7 = Self("pasteHistory7")
    @MainActor static let pasteHistory8 = Self("pasteHistory8")
    @MainActor static let pasteHistory9 = Self("pasteHistory9")
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
    
    static let historyShortcutNames: [KeyboardShortcuts.Name] = [
        .pasteHistory1, .pasteHistory2, .pasteHistory3,
        .pasteHistory4, .pasteHistory5, .pasteHistory6,
        .pasteHistory7, .pasteHistory8, .pasteHistory9
    ]
    
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
                NotificationCenter.default.post(name: .togglePopover, object: nil)
            }
        }
        
        for (index, name) in Self.historyShortcutNames.enumerated() {
            KeyboardShortcuts.onKeyUp(for: name) { [weak self] in
                Task { @MainActor in
                    self?.monitor.pasteFromHistoryIndex(index)
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
