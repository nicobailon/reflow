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
            PopoverPanelView(
                settings: settings,
                historyManager: historyManager,
                monitor: monitor,
                accessibilityManager: accessibilityManager,
                statisticsManager: statisticsManager,
                updater: updaterController.updater,
                dismiss: { isMenuPresented = false }
            )
            .onReceive(NotificationCenter.default.publisher(for: .togglePopover)) { _ in
                isMenuPresented.toggle()
                if isMenuPresented {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
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
        .menuBarExtraStyle(.window)
        .onChange(of: settings.autoReflowEnabled) { _, _ in
            applyStatusItemAppearance()
        }
        
        Settings {
            SettingsView(settings: settings, historyManager: historyManager, updater: updaterController.updater)
        }
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
