import SwiftUI
import KeyboardShortcuts
import ReflowCore

struct MenuContentView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var settings: AppSettings
    @ObservedObject var accessibilityManager: AccessibilityManager
    @ObservedObject var statisticsManager: StatisticsManager
    @Environment(\.openSettings) private var openSettings
    
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
