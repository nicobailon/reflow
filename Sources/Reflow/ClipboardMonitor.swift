import AppKit
import Carbon.HIToolbox
import Foundation
import ReflowCore

@MainActor
final class ClipboardMonitor: ObservableObject {
    private let settings: AppSettings
    private let statisticsManager: StatisticsManager
    private let historyManager: ClipboardHistoryManager
    private let pasteboard: NSPasteboard
    private let reflowMarker = NSPasteboard.PasteboardType("com.reflow.marker")
    private let accessibilityPermission: AccessibilityPermissionChecking
    private var timer: DispatchSourceTimer?
    private var lastSeenChangeCount: Int
    private let pollInterval: DispatchTimeInterval = .milliseconds(150)
    private let pollLeeway: DispatchTimeInterval = .milliseconds(50)
    private let graceDelay: DispatchTimeInterval = .milliseconds(80)
    private let pasteRestoreDelay: DispatchTimeInterval
    private let pasteIntoFrontmostApp: () -> Void
    private var ignoredChangeCounts: Set<Int> = []
    private var lastOriginalText: String?
    private var lastReflowedText: String?
    
    @Published var lastSummary: String = ""
    @Published var frontmostAppName: String = "current app"
    @Published var reflowPulseID: Int = 0
    @Published private(set) var lastCopySource: SourceAppInfo?
    
    private var currentFrontmostApp: (bundleId: String?, appName: String?)?
    
    init(
        settings: AppSettings,
        statisticsManager: StatisticsManager,
        historyManager: ClipboardHistoryManager,
        pasteboard: NSPasteboard = .general,
        pasteRestoreDelay: DispatchTimeInterval = .milliseconds(200),
        pasteAction: (() -> Void)? = nil,
        accessibilityPermission: AccessibilityPermissionChecking? = nil
    ) {
        self.settings = settings
        self.statisticsManager = statisticsManager
        self.historyManager = historyManager
        self.pasteboard = pasteboard
        self.pasteRestoreDelay = pasteRestoreDelay
        self.pasteIntoFrontmostApp = pasteAction ?? ClipboardMonitor.sendPasteCommand
        self.accessibilityPermission = accessibilityPermission ?? AccessibilityManager()
        self.lastSeenChangeCount = pasteboard.changeCount
        self.updateFrontmostAppName(NSWorkspace.shared.frontmostApplication)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppActivation(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    func start() {
        stop()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: pollInterval, leeway: pollLeeway)
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        timer = t
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
    }
    
    private func tick() {
        let current = pasteboard.changeCount
        guard current != lastSeenChangeCount else { return }
        
        if ignoredChangeCounts.remove(current) != nil {
            lastSeenChangeCount = current
            return
        }
        
        captureSourceOnClipboardChange()
        addToHistoryIfNeeded()
        
        let observed = current
        DispatchQueue.main.asyncAfter(deadline: .now() + graceDelay) { [weak self] in
            guard let self, observed == pasteboard.changeCount else { return }
            _ = reflowClipboardIfNeeded()
            lastSeenChangeCount = pasteboard.changeCount
        }
    }
    
    private func addToHistoryIfNeeded() {
        guard let text = readTextFromPasteboard(ignoreMarker: true) else { return }
        historyManager.addItem(text, source: lastCopySource)
    }
    
    @discardableResult
    func reflowClipboardIfNeeded(force: Bool = false) -> Bool {
        let changeCount = pasteboard.changeCount
        lastSeenChangeCount = changeCount
        
        guard let text = readTextFromPasteboard(ignoreMarker: force) else {
            if force, let raw = readTextFromPasteboard(ignoreMarker: true) {
                updateSummary(with: raw)
                return true
            }
            cache(original: nil, reflowed: nil)
            return false
        }
        
        let sourceApp = lastCopySource
        let isFromTerminal = sourceApp?.isRecognizedTerminal == true
        let isMixedSource = sourceApp?.isMixedSourceApp == true
        
        guard settings.autoReflowEnabled || force else {
            cache(original: text, reflowed: nil)
            return false
        }
        
        let shouldProcess: Bool
        if force {
            shouldProcess = true
        } else if isFromTerminal {
            shouldProcess = true
        } else if isMixedSource {
            shouldProcess = ReflowEngine.looksLikeTerminalOutput(text)
        } else {
            shouldProcess = false
        }
        
        guard shouldProcess else {
            cache(original: text, reflowed: nil)
            return false
        }
        
        var options = settings.reflowOptions
        if force { options.aggressiveness = .aggressive }
        let result = ReflowEngine.reflow(text, options: options)
        
        guard result.wasTransformed else {
            cache(original: text, reflowed: nil)
            if force { updateSummary(with: text) }
            return false
        }
        
        cache(original: text, reflowed: result.reflowed)
        updateSummary(with: result.reflowed)
        registerReflowEvent()
        return true
    }
    
    private func readTextFromPasteboard(ignoreMarker: Bool = false) -> String? {
        if !ignoreMarker, pasteboard.types?.contains(reflowMarker) == true { return nil }
        
        guard let text = pasteboard.string(forType: .string) else { return nil }
        return normalizeLineEndings(text)
    }
    
    func clipboardText() -> String? {
        readTextFromPasteboard(ignoreMarker: true)
    }
    
    var currentClipboard: ClipboardState? {
        guard let text = lastOriginalText ?? clipboardText() else { return nil }
        let sourceApp = lastCopySource
        let isFromTerminal = sourceApp?.isRecognizedTerminal == true
        let isMixedSource = sourceApp?.isMixedSourceApp == true
        
        let shouldAnalyze: Bool
        if isFromTerminal {
            shouldAnalyze = settings.autoReflowEnabled
        } else if isMixedSource && settings.autoReflowEnabled {
            shouldAnalyze = ReflowEngine.looksLikeTerminalOutput(text)
        } else {
            shouldAnalyze = false
        }
        
        let reflowResult = shouldAnalyze ? ReflowEngine.reflow(text, options: settings.reflowOptions) : nil
        
        return ClipboardState(
            text: text,
            sourceApp: sourceApp,
            reflowResult: reflowResult,
            isReflowable: reflowResult?.wasTransformed == true
        )
    }
    
    struct ClipboardState: Sendable {
        let text: String
        let sourceApp: SourceAppInfo?
        let reflowResult: ReflowResult?
        let isReflowable: Bool
    }
    
    private func updateSummary(with text: String) {
        let singleLine = text.replacingOccurrences(of: "\n", with: " ")
        lastSummary = Self.ellipsize(singleLine, limit: 90)
    }
    
    static func ellipsize(_ text: String, limit: Int) -> String {
        guard limit >= 5, text.count > limit else { return text }
        let available = limit - 3
        let headCount = available / 2
        let tailCount = available - headCount
        let head = text.prefix(headCount)
        let tail = text.suffix(tailCount)
        return "\(head)…\(tail)"
    }
    
    private func normalizeLineEndings(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
    
    private func cache(original: String?, reflowed: String?) {
        lastOriginalText = original
        lastReflowedText = reflowed
    }
    
    private func registerReflowEvent() {
        reflowPulseID &+= 1
    }
    
    @objc private func handleAppActivation(_ notification: Notification) {
        let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        updateFrontmostAppName(app)
    }
    
    private func updateFrontmostAppName(_ app: NSRunningApplication?) {
        guard let app else {
            frontmostAppName = "current app"
            return
        }
        if app.bundleIdentifier == Bundle.main.bundleIdentifier { return }
        
        currentFrontmostApp = (bundleId: app.bundleIdentifier, appName: app.localizedName)
        frontmostAppName = app.localizedName ?? "current app"
    }
    
    private func captureSourceOnClipboardChange() {
        lastCopySource = SourceAppInfo(
            bundleIdentifier: currentFrontmostApp?.bundleId,
            appName: currentFrontmostApp?.appName,
            isRecognizedTerminal: TerminalRegistry.isTerminal(currentFrontmostApp?.bundleId),
            isMixedSourceApp: TerminalRegistry.isMixedSource(currentFrontmostApp?.bundleId)
        )
    }
}

extension ClipboardMonitor {
    private static let accessibilityPermissionMessage = 
        "Enable Accessibility to let Reflow paste (System Settings -> Privacy & Security -> Accessibility)."
    
    @discardableResult
    func pasteReflowed(aggressiveness: Aggressiveness? = nil) -> Bool {
        guard accessibilityPermission.isTrusted else {
            lastSummary = Self.accessibilityPermissionMessage
            return false
        }
        
        guard let original = lastOriginalText ?? clipboardText() else {
            lastSummary = "Nothing to paste."
            return false
        }
        
        var options = settings.reflowOptions
        if let aggressiveness {
            options.aggressiveness = aggressiveness
        }
        let result = ReflowEngine.reflow(original, options: options)
        guard result.wasTransformed else {
            performPaste(with: original)
            return true
        }
        
        cache(original: original, reflowed: result.reflowed)
        updateSummary(with: result.reflowed)
        registerReflowEvent()
        statisticsManager.recordPaste(linesJoined: result.linesJoined)
        performPaste(with: result.reflowed)
        return true
    }
    
    @discardableResult
    func pasteOriginal() -> Bool {
        guard accessibilityPermission.isTrusted else {
            lastSummary = Self.accessibilityPermissionMessage
            return false
        }
        
        guard let original = lastOriginalText ?? clipboardText() else {
            lastSummary = "Nothing to paste."
            return false
        }
        
        lastOriginalText = original
        lastReflowedText = nil
        updateSummary(with: original)
        performPaste(with: original)
        return true
    }
    
    func reflowedPreviewText() -> String {
        if let reflowed = lastReflowedText {
            return Self.ellipsize(reflowed.replacingOccurrences(of: "\n", with: " "), limit: 100)
        }
        return lastSummary.isEmpty ? "No reflowed text yet" : lastSummary
    }
    
    func originalPreviewSource() -> String? {
        lastOriginalText
    }
    
    @discardableResult
    func pasteFromHistory(item: ClipboardHistoryItem, reflow: Bool) -> Bool {
        guard accessibilityPermission.isTrusted else {
            lastSummary = Self.accessibilityPermissionMessage
            return false
        }
        
        if reflow && item.isReflowCandidate {
            let result = ReflowEngine.reflow(item.content, options: settings.reflowOptions)
            if result.wasTransformed {
                cache(original: item.content, reflowed: result.reflowed)
                updateSummary(with: result.reflowed)
                registerReflowEvent()
                statisticsManager.recordPaste(linesJoined: result.linesJoined)
                performPaste(with: result.reflowed)
                return true
            }
        }
        
        cache(original: item.content, reflowed: nil)
        updateSummary(with: item.content)
        performPaste(with: item.content)
        return true
    }
    
    @discardableResult
    func pasteFromHistoryIndex(_ index: Int, reflow: Bool = true) -> Bool {
        guard let item = historyManager.item(at: index) else {
            lastSummary = "No item at index \(index + 1)"
            return false
        }
        return pasteFromHistory(item: item, reflow: reflow)
    }
    
    private func performPaste(with text: String) {
        let previousString = clipboardText()
        
        ignoreChangeWhile {
            pasteboard.declareTypes([.string, reflowMarker], owner: nil)
            pasteboard.setString(text, forType: .string)
            pasteboard.setData(Data(), forType: reflowMarker)
        }
        
        let changeCountAtPaste = pasteboard.changeCount
        
        NSApp.deactivate()
        pasteIntoFrontmostApp()
        
        guard let previousString else { return }
        restorePasteboard(string: previousString, expectedChangeCount: changeCountAtPaste)
    }
    
    private func ignoreChangeWhile(_ work: () -> Void) {
        let before = pasteboard.changeCount
        work()
        let after = pasteboard.changeCount
        if after != before {
            ignoredChangeCounts.insert(after)
            lastSeenChangeCount = after
        }
    }
    
    private func restorePasteboard(string: String, expectedChangeCount: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + pasteRestoreDelay) { [weak self] in
            guard let self, pasteboard.changeCount == expectedChangeCount else { return }
            ignoreChangeWhile {
                pasteboard.clearContents()
                pasteboard.setString(string, forType: .string)
            }
        }
    }
    
    fileprivate static func sendPasteCommand() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let keyCode = CGKeyCode(kVK_ANSI_V)
        
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)
    }
}
