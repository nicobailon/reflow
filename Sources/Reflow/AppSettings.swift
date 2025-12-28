import SwiftUI
import ServiceManagement
import ReflowCore

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("autoReflowEnabled") var autoReflowEnabled: Bool = true
    @AppStorage("aggressiveness") var aggressiveness: Aggressiveness = .normal
    @AppStorage("markdownAware") var markdownAware: Bool = true
    @AppStorage("customPatterns") var customPatternsData: Data = Data()
    @AppStorage("showOnlyTerminalItems") var showOnlyTerminalItems: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { updateLaunchAtLogin() }
    }
    
    var customPatterns: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: customPatternsData)) ?? []
        }
        set {
            customPatternsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    var reflowOptions: ReflowOptions {
        ReflowOptions(
            aggressiveness: aggressiveness,
            markdownAware: markdownAware,
            customPatterns: customPatterns
        )
    }
    
    private func updateLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if launchAtLogin {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}
