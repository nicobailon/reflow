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
            
            Section("History") {
                KeyboardShortcuts.Recorder("Show History:", name: .showHistory)
                
                DisclosureGroup("Quick Paste from History") {
                    ForEach(0..<9, id: \.self) { index in
                        KeyboardShortcuts.Recorder("Paste #\(index + 1):", name: HotkeyManager.historyShortcutNames[index])
                    }
                }
            }
            
            Section {
                Button("Reset to Defaults") {
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteReflowed, for: .pasteReflowed)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteOriginal, for: .pasteOriginal)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.toggleAutoReflow, for: .toggleAutoReflow)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteConservative, for: .pasteConservative)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.pasteAggressive, for: .pasteAggressive)
                    KeyboardShortcuts.setShortcut(DefaultShortcuts.showHistory, for: .showHistory)
                }
            }
        }
        .formStyle(.grouped)
    }
}
