import SwiftUI
import Sparkle

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let updater: SPUUpdater
    
    var body: some View {
        TabView {
            SettingsGeneralPane(settings: settings, updater: updater)
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
