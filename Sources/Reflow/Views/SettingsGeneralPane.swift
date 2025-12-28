import SwiftUI
import ReflowCore
import Sparkle

struct SettingsGeneralPane: View {
    @ObservedObject var settings: AppSettings
    let updater: SPUUpdater
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Toggle("Auto-Reflow Enabled", isOn: $settings.autoReflowEnabled)
                Toggle("Markdown-Aware Mode", isOn: $settings.markdownAware)
            }
            
            Section {
                Text("Markdown mode preserves headers (#), code fences (```), blockquotes (>), and tables.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Aggressiveness") {
                Picker("Mode", selection: $settings.aggressiveness) {
                    ForEach(Aggressiveness.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(aggressivenessDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Updates") {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                ))
                
                Toggle("Automatically download updates", isOn: Binding(
                    get: { updater.automaticallyDownloadsUpdates },
                    set: { updater.automaticallyDownloadsUpdates = $0 }
                ))
            }
        }
        .formStyle(.grouped)
    }
    
    private var aggressivenessDescription: String {
        switch settings.aggressiveness {
        case .conservative:
            "Preserves lines ending with punctuation. Best for mixed content."
        case .normal:
            "Joins most lines, preserves lists and code blocks. Recommended."
        case .aggressive:
            "Joins all lines except blank lines. Best for heavily wrapped text."
        }
    }
}
