import SwiftUI
import ReflowCore

struct HistoryPanelView: View {
    @ObservedObject var historyManager: ClipboardHistoryManager
    @ObservedObject var monitor: ClipboardMonitor
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItemId: UUID?
    @FocusState private var searchFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            
            if historyManager.filteredItems.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .frame(width: 400, height: 450)
        .onAppear {
            searchFieldFocused = true
        }
        .onExitCommand {
            dismiss()
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
        ScrollViewReader { proxy in
            List(selection: $selectedItemId) {
                ForEach(Array(historyManager.filteredItems.enumerated()), id: \.element.id) { index, item in
                    HistoryItemRow(
                        item: item,
                        index: index,
                        isSelected: selectedItemId == item.id,
                        onPaste: { reflow in
                            monitor.pasteFromHistory(item: item, reflow: reflow)
                            dismiss()
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
        }
    }
}

struct HistoryItemRow: View {
    let item: ClipboardHistoryItem
    let index: Int
    let isSelected: Bool
    let onPaste: (Bool) -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 10) {
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
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture(count: 2) {
            onPaste(item.isReflowCandidate)
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
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

struct HistoryWindow: View {
    @ObservedObject var historyManager: ClipboardHistoryManager
    @ObservedObject var monitor: ClipboardMonitor
    
    var body: some View {
        HistoryPanelView(historyManager: historyManager, monitor: monitor)
    }
}
