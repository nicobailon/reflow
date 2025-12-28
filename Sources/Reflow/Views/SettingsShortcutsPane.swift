import SwiftUI
import KeyboardShortcuts

struct SettingsShortcutsPane: View {
    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                KeyboardShortcuts.Recorder("Paste Reflowed:", name: .pasteReflowed)
                KeyboardShortcuts.Recorder("Paste Original:", name: .pasteOriginal)
                KeyboardShortcuts.Recorder("Toggle Auto-Reflow:", name: .toggleAutoReflow)
            }
            
            Section("Quick Paste (Override Aggressiveness)") {
                KeyboardShortcuts.Recorder("Paste Conservative:", name: .pasteConservative)
                KeyboardShortcuts.Recorder("Paste Aggressive:", name: .pasteAggressive)
            }
            
            Section {
                Button("Reset to Defaults") {
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteReflowed, for: .pasteReflowed)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteOriginal, for: .pasteOriginal)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.toggleAutoReflow, for: .toggleAutoReflow)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteConservative, for: .pasteConservative)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteAggressive, for: .pasteAggressive)
                }
            }
        }
        .formStyle(.grouped)
    }
}
