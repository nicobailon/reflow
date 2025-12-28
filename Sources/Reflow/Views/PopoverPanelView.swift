import SwiftUI
import ReflowCore
import Sparkle

struct PopoverPanelView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var historyManager: ClipboardHistoryManager
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var accessibilityManager: AccessibilityManager
    @ObservedObject var statisticsManager: StatisticsManager
    let updater: SPUUpdater
    let dismiss: () -> Void
    
    @Environment(\.openSettings) private var openSettings
    @State private var selectedItemId: UUID?
    @FocusState private var searchFieldFocused: Bool
    
    private var selectedItem: ClipboardHistoryItem? {
        guard let id = selectedItemId else { return nil }
        return historyManager.items.first { $0.id == id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainContent
            Divider()
            bottomToolbar
        }
        .frame(width: 650, height: 420)
        .onAppear {
            searchFieldFocused = true
            if selectedItemId == nil, let first = historyManager.filteredItems.first {
                selectedItemId = first.id
            }
        }
        .onExitCommand {
            dismiss()
        }
    }
    
    private var mainContent: some View {
        HStack(spacing: 0) {
            detailPanel
            Divider()
            listPanel
        }
    }
    
    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let item = selectedItem {
                ScrollView {
                    Text(item.content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxHeight: .infinity)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: item.isFromTerminal ? "terminal" : "app")
                            .foregroundStyle(item.isFromTerminal ? .blue : .secondary)
                        Text("Application: ")
                            .foregroundStyle(.secondary)
                        Text(item.sourceDisplayName)
                        if item.isFromTerminal {
                            Text("(recognized)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text("First copy time:")
                            .foregroundStyle(.secondary)
                        Text(item.firstCopyDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    HStack {
                        Text("Last copy time:")
                            .foregroundStyle(.secondary)
                        Text(item.lastCopyDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    HStack {
                        Text("Number of copies:")
                            .foregroundStyle(.secondary)
                        Text("\(item.copyCount)")
                    }
                    
                    Divider()
                    
                    HStack(spacing: 16) {
                        Text("Press Delete to remove.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("Right-click for more options.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.caption)
                .padding()
                .background(.ultraThinMaterial)
            } else {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("Select an item to preview")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 280)
    }
    
    private var listPanel: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            
            if historyManager.filteredItems.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search history...", text: $historyManager.searchQuery)
                .textFieldStyle(.plain)
                .focused($searchFieldFocused)
            if !historyManager.searchQuery.isEmpty {
                Button {
                    historyManager.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            if historyManager.searchQuery.isEmpty {
                Text("No clipboard history")
                    .font(.headline)
                Text("Items you copy will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No results")
                    .font(.headline)
                Text("No items match \"\(historyManager.searchQuery)\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        List(selection: $selectedItemId) {
            ForEach(Array(historyManager.filteredItems.enumerated()), id: \.element.id) { index, item in
                PopoverHistoryItemRow(
                    item: item,
                    index: index,
                    isSelected: selectedItemId == item.id,
                    onPaste: { reflow in
                        monitor.pasteFromHistory(item: item, reflow: reflow)
                        dismiss()
                    },
                    onTogglePin: {
                        historyManager.togglePin(item.id)
                    },
                    onDelete: {
                        historyManager.removeItem(item.id)
                    }
                )
                .tag(item.id)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .onKeyPress(.return) {
            if let item = selectedItem {
                monitor.pasteFromHistory(item: item, reflow: item.isReflowCandidate)
                dismiss()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.delete) {
            if let id = selectedItemId {
                historyManager.removeItem(id)
                if let first = historyManager.filteredItems.first {
                    selectedItemId = first.id
                } else {
                    selectedItemId = nil
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: .decimalDigits) { press in
            guard press.modifiers.contains(.command),
                  let char = press.characters.first,
                  let digit = Int(String(char)),
                  digit >= 1 && digit <= 9 else {
                return .ignored
            }
            let itemIndex = digit - 1
            if itemIndex < historyManager.filteredItems.count {
                let item = historyManager.filteredItems[itemIndex]
                monitor.pasteFromHistory(item: item, reflow: item.isReflowCandidate)
                dismiss()
                return .handled
            }
            return .ignored
        }
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            Toggle("Auto-Reflow", isOn: $settings.autoReflowEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
            
            Picker("", selection: $settings.aggressiveness) {
                Text("Conservative").tag(Aggressiveness.conservative)
                Text("Normal").tag(Aggressiveness.normal)
                Text("Aggressive").tag(Aggressiveness.aggressive)
            }
            .pickerStyle(.menu)
            .frame(width: 130)
            
            Toggle("Markdown", isOn: $settings.markdownAware)
                .toggleStyle(.checkbox)
                .controlSize(.small)
            
            Spacer()
            
            if !accessibilityManager.isTrusted {
                Button {
                    accessibilityManager.requestPermission()
                } label: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.borderless)
            }
            
            Menu {
                Button("Clear History") {
                    historyManager.clear()
                }
                Button("Reset Statistics") {
                    statisticsManager.resetSession()
                }
                Divider()
                Button("Settings...") {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                Button("Check for Updates...") {
                    updater.checkForUpdates()
                }
                Divider()
                Button("Quit Reflow") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

struct PopoverHistoryItemRow: View {
    let item: ClipboardHistoryItem
    let index: Int
    let isSelected: Bool
    let onPaste: (Bool) -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 10) {
            Group {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.orange)
                } else {
                    Color.clear
                }
            }
            .font(.caption)
            .frame(width: 14)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if item.isFromTerminal {
                        Image(systemName: "terminal")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    Text(item.preview)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                HStack(spacing: 8) {
                    Text(item.sourceDisplayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.relativeTimestamp)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    if item.copyCount > 1 {
                        Text("(\(item.copyCount)x)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            if index < 9 {
                Text("Cmd+\(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering && !isSelected ? Color.primary.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button("Paste Reflowed") {
                onPaste(true)
            }
            .disabled(!item.isReflowCandidate)
            
            Button("Paste Original") {
                onPaste(false)
            }
            
            Divider()
            
            Button(item.isPinned ? "Unpin" : "Pin") {
                onTogglePin()
            }
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}
