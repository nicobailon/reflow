import SwiftUI
import ReflowCore

struct SettingsSourceAppsPane: View {
    @ObservedObject var settings: AppSettings
    
    private let defaultTerminals: [(name: String, bundleId: String)] = [
        ("Terminal", "com.apple.Terminal"),
        ("iTerm2", "com.googlecode.iterm2"),
        ("Ghostty", "com.mitchellh.ghostty"),
        ("Warp", "dev.warp.Warp-Stable"),
        ("Alacritty", "org.alacritty"),
        ("Kitty", "net.kovidgoyal.kitty"),
        ("Hyper", "co.zeit.hyper"),
        ("WezTerm", "com.github.wez.wezterm"),
    ]
    
    var body: some View {
        Form {
            Section("Recognized Terminals") {
                ForEach(defaultTerminals, id: \.bundleId) { terminal in
                    HStack {
                        Image(systemName: "terminal")
                            .foregroundStyle(.secondary)
                        Text(terminal.name)
                        Spacer()
                        if isTerminalEnabled(terminal.bundleId) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            
            Section("Mixed Source Apps") {
                Text("These apps may contain both terminal and non-terminal content:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ForEach(mixedSourceApps, id: \.bundleId) { app in
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundStyle(.secondary)
                        Text(app.name)
                        Spacer()
                        Text("Heuristic")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Text("Custom terminal apps coming in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
    
    private func isTerminalEnabled(_ bundleId: String) -> Bool {
        TerminalRegistry.isTerminal(bundleId)
    }
    
    private var mixedSourceApps: [(name: String, bundleId: String)] {
        [
            ("VS Code", "com.microsoft.VSCode"),
            ("Cursor", "com.todesktop.230313mzl4w4u92"),
            ("Zed", "dev.zed.Zed"),
        ]
    }
}
