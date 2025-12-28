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
    @State private var hasActivatedOnce = false
    @State private var previousApp: NSRunningApplication?
    
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
                if !isMenuPresented {
                    previousApp = NSWorkspace.shared.frontmostApplication
                }
                isMenuPresented.toggle()
                if isMenuPresented {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .pasteHistoryItem)) { notification in
                if let userInfo = notification.userInfo,
                   let item = userInfo["item"] as? ClipboardHistoryItem,
                   let reflow = userInfo["reflow"] as? Bool {
                    if let app = previousApp {
                        app.activate()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            monitor.pasteFromHistory(item: item, reflow: reflow)
                            previousApp = nil
                        }
                    } else {
                        monitor.pasteFromHistory(item: item, reflow: reflow)
                    }
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
            
            if !hasActivatedOnce {
                hasActivatedOnce = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isMenuPresented = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isMenuPresented = false
                    }
                }
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: settings.autoReflowEnabled) { _, _ in
            applyStatusItemAppearance()
        }
        .onChange(of: isMenuPresented) { wasPresented, isNowPresented in
            if !wasPresented && isNowPresented && previousApp == nil {
                let frontmost = NSWorkspace.shared.frontmostApplication
                if frontmost?.bundleIdentifier != Bundle.main.bundleIdentifier {
                    previousApp = frontmost
                }
            }
        }
        
        Settings {
            SettingsView(settings: settings, historyManager: historyManager, accessibilityManager: accessibilityManager, updater: updaterController.updater)
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
