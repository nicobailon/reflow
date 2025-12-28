import SwiftUI
import Sparkle

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var historyManager: ClipboardHistoryManager
    @ObservedObject var accessibilityManager: AccessibilityManager
    let updater: SPUUpdater
    
    var body: some View {
        TabView {
            SettingsGeneralPane(settings: settings, historyManager: historyManager, accessibilityManager: accessibilityManager, updater: updater)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            SettingsShortcutsPane()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            SettingsSourceAppsPane(settings: settings)
                .tabItem {
                    Label("Source Apps", systemImage: "terminal")
                }
        }
        .frame(width: 450, height: 380)
    }
}
