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
    @State private var showDetails = false
    @FocusState private var isListFocused: Bool
    @State private var eventMonitor: Any?
    @State private var scrollProxy: ScrollViewProxy?
    
    private var selectedItem: ClipboardHistoryItem? {
        guard let id = selectedItemId else { return nil }
        return historyManager.filteredItems.first { $0.id == id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainContent
            Divider()
            bottomToolbar
        }
        .frame(width: 650, height: 420)
        .onAppear {
            if selectedItemId == nil, let first = historyManager.filteredItems.first {
                selectedItemId = first.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isListFocused = true
            }
            setupKeyboardMonitor()
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        .onExitCommand {
            dismiss()
        }
        .onChange(of: historyManager.searchQuery) { _, _ in
            let filtered = historyManager.filteredItems
            if let id = selectedItemId, !filtered.contains(where: { $0.id == id }) {
                selectedItemId = filtered.first?.id
            }
        }
        .onChange(of: selectedItemId) { _, newId in
            if let id = newId, let proxy = scrollProxy {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }
    
    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 36: // Return
                if let item = self.selectedItem {
                    self.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: .pasteHistoryItem,
                            object: nil,
                            userInfo: ["item": item, "reflow": item.isReflowCandidate]
                        )
                    }
                    return nil
                }
            case 51: // Delete
                if let id = self.selectedItemId {
                    let items = self.historyManager.filteredItems
                    let currentIndex = items.firstIndex { $0.id == id }
                    self.historyManager.removeItem(id)
                    let updatedItems = self.historyManager.filteredItems
                    if let idx = currentIndex, !updatedItems.isEmpty {
                        let nextIndex = min(idx, updatedItems.count - 1)
                        self.selectedItemId = updatedItems[nextIndex].id
                    } else {
                        self.selectedItemId = updatedItems.first?.id
                    }
                    return nil
                }
            default:
                break
            }
            return event
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
                
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDetails.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: showDetails ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 12)
                            Text("Details")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if item.isFromTerminal {
                                Image(systemName: "terminal")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            Text(item.sourceDisplayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if showDetails {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("First copied:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(item.firstCopyDate.formatted(date: .abbreviated, time: .shortened))
                            }
                            
                            HStack {
                                Text("Last copied:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(item.lastCopyDate.formatted(date: .abbreviated, time: .shortened))
                            }
                            
                            HStack {
                                Text("Copy count:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(item.copyCount)")
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
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
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(historyManager.filteredItems.enumerated()), id: \.element.id) { index, item in
                        PopoverHistoryItemRow(
                            item: item,
                            index: index,
                            isSelected: selectedItemId == item.id,
                            onPaste: { reflow in
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    monitor.pasteFromHistory(item: item, reflow: reflow)
                                }
                            },
                            onTogglePin: {
                                historyManager.togglePin(item.id)
                            },
                            onDelete: {
                                historyManager.removeItem(item.id)
                            }
                        )
                        .id(item.id)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .onTapGesture {
                            selectedItemId = item.id
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
        .focused($isListFocused)
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
                .fill(isSelected ? Color.accentColor.opacity(0.3) : (isHovering ? Color.primary.opacity(0.08) : Color.clear))
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
