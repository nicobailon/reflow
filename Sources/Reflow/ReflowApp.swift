import SwiftUI
import MenuBarExtraAccess
import Sparkle

@main
@MainActor
struct ReflowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings: AppSettings
    @StateObject private var accessibilityManager: AccessibilityManager
    @StateObject private var statisticsManager: StatisticsManager
    @StateObject private var historyManager: ClipboardHistoryManager
    @StateObject private var monitor: ClipboardMonitor
    @StateObject private var hotkeyManager: HotkeyManager
    @State private var isMenuPresented = false
    @State private var statusItem: NSStatusItem?
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        let settings = AppSettings()
        let accessibilityManager = AccessibilityManager()
        let statisticsManager = StatisticsManager()
        let historyManager = ClipboardHistoryManager()
        let monitor = ClipboardMonitor(
            settings: settings,
            statisticsManager: statisticsManager,
            historyManager: historyManager,
            accessibilityPermission: accessibilityManager
        )
        monitor.start()
        let hotkeyManager = HotkeyManager(settings: settings, monitor: monitor)
        
        _settings = StateObject(wrappedValue: settings)
        _accessibilityManager = StateObject(wrappedValue: accessibilityManager)
        _statisticsManager = StateObject(wrappedValue: statisticsManager)
        _historyManager = StateObject(wrappedValue: historyManager)
        _monitor = StateObject(wrappedValue: monitor)
        _hotkeyManager = StateObject(wrappedValue: hotkeyManager)
        
        updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuContentView(
                monitor: monitor,
                settings: settings,
                accessibilityManager: accessibilityManager,
                statisticsManager: statisticsManager,
                historyManager: historyManager
            )
            Divider()
            CheckForUpdatesView(updater: updaterController.updater)
            Button("Quit") { NSApplication.shared.terminate(nil) }
        } label: {
            StatusLabel(
                monitor: monitor,
                isEnabled: settings.autoReflowEnabled
            )
        }
        .menuBarExtraAccess(isPresented: $isMenuPresented) { item in
            statusItem = item
            applyStatusItemAppearance()
        }
        .menuBarExtraStyle(.menu)
        .onChange(of: settings.autoReflowEnabled) { _, _ in
            applyStatusItemAppearance()
        }
        
        Settings {
            SettingsView(settings: settings, historyManager: historyManager, updater: updaterController.updater)
        }
        
        Window("Clipboard History", id: "history") {
            HistoryPanelView(historyManager: historyManager, monitor: monitor)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
    
    private func applyStatusItemAppearance() {
        statusItem?.button?.appearsDisabled = !settings.autoReflowEnabled
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    
    init(updater: SPUUpdater) {
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button("Check for Updates...") {
            checkForUpdatesViewModel.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

@MainActor
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    
    private let updater: SPUUpdater
    private var cancellable: Any?
    
    init(updater: SPUUpdater) {
        self.updater = updater
        cancellable = updater.publisher(for: \.canCheckForUpdates)
            .assign(to: \.canCheckForUpdates, on: self)
    }
    
    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
