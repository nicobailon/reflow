import SwiftUI
import KeyboardShortcuts
import ReflowCore

struct MenuContentView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var settings: AppSettings
    @ObservedObject var accessibilityManager: AccessibilityManager
    @ObservedObject var statisticsManager: StatisticsManager
    @ObservedObject var historyManager: ClipboardHistoryManager
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Toggle("Auto-Reflow", isOn: $settings.autoReflowEnabled)
        
        Menu("Aggressiveness") {
            ForEach(Aggressiveness.allCases, id: \.self) { level in
                Button {
                    settings.aggressiveness = level
                } label: {
                    HStack {
                        Text(level.displayName)
                        if settings.aggressiveness == level {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        
        Toggle("Markdown-Aware", isOn: $settings.markdownAware)
        
        Divider()
        
        if let source = monitor.currentClipboard?.sourceApp {
            if source.isRecognizedTerminal {
                Text("Source: \(source.appName ?? "Unknown") (recognized)")
            } else {
                Text("Source: \(source.appName ?? "Unknown")")
            }
        }
        
        Divider()
        
        if let state = monitor.currentClipboard {
            if state.isReflowable {
                Button("Paste Reflowed") {
                    monitor.pasteReflowed()
                }
                .keyboardShortcut("V", modifiers: [.command, .control])
                
                if let result = state.reflowResult {
                    Text("\(result.linesJoined) lines joined")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Menu("Paste As...") {
                    Button("Conservative") {
                        monitor.pasteReflowed(aggressiveness: .conservative)
                    }
                    Button("Normal") {
                        monitor.pasteReflowed(aggressiveness: .normal)
                    }
                    Button("Aggressive") {
                        monitor.pasteReflowed(aggressiveness: .aggressive)
                    }
                }
            }
            
            Button("Paste Original") {
                monitor.pasteOriginal()
            }
            .keyboardShortcut("V", modifiers: [.command, .control, .shift])
        } else {
            Text("No clipboard content")
                .foregroundStyle(.secondary)
        }
        
        Divider()
        
        if historyManager.historyEnabled {
            Menu("History") {
                if historyManager.items.isEmpty {
                    Text("No history yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(historyManager.items.prefix(9).enumerated()), id: \.element.id) { index, item in
                        Button {
                            monitor.pasteFromHistory(item: item, reflow: item.isReflowCandidate)
                        } label: {
                            HStack {
                                if item.isFromTerminal {
                                    Image(systemName: "terminal")
                                }
                                Text(item.preview)
                                Spacer()
                                Text(item.relativeTimestamp)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                    }
                    Divider()
                    Button("Show All History...") {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "history")
                    }
                    .keyboardShortcut("h", modifiers: [.command, .control])
                    Divider()
                    Button("Clear History") {
                        historyManager.clear()
                    }
                }
            }
        }
        
        Menu("Statistics") {
            Text("Session: \(statisticsManager.sessionLinesJoined) lines, \(statisticsManager.sessionPastes) pastes")
            Text("All Time: \(statisticsManager.allTimeLinesJoined) lines, \(statisticsManager.allTimePastes) pastes")
            Divider()
            Button("Reset Session") {
                statisticsManager.resetSession()
            }
            Button("Reset All Time") {
                statisticsManager.resetAllTime()
            }
        }
        
        Divider()
        
        if !accessibilityManager.isTrusted {
            Button("Grant Accessibility Permission...") {
                accessibilityManager.requestPermission()
            }
        }
        
        Button("Settings...") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)
    }
}
