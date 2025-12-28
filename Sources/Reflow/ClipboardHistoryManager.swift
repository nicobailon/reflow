import SwiftUI
import ReflowCore

struct ClipboardHistoryItem: Codable, Identifiable, Sendable {
    let id: UUID
    let content: String
    let sourceAppBundleId: String?
    let sourceAppName: String?
    let firstCopyDate: Date
    var lastCopyDate: Date
    var copyCount: Int
    let isFromTerminal: Bool
    let isMixedSourceApp: Bool
    var isPinned: Bool = false
    
    init(
        content: String,
        sourceApp: SourceAppInfo?,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.content = content
        self.sourceAppBundleId = sourceApp?.bundleIdentifier
        self.sourceAppName = sourceApp?.appName
        self.firstCopyDate = date
        self.lastCopyDate = date
        self.copyCount = 1
        self.isFromTerminal = sourceApp?.isRecognizedTerminal ?? false
        self.isMixedSourceApp = sourceApp?.isMixedSourceApp ?? false
    }
    
    var preview: String {
        let singleLine = content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        if singleLine.count <= 60 {
            return singleLine
        }
        return String(singleLine.prefix(57)) + "..."
    }
    
    var relativeTimestamp: String {
        let interval = Date().timeIntervalSince(lastCopyDate)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return days == 1 ? "yesterday" : "\(days)d ago"
        }
    }
    
    var sourceDisplayName: String {
        sourceAppName ?? "Unknown"
    }
    
    var isReflowCandidate: Bool {
        isFromTerminal || (isMixedSourceApp && ReflowEngine.looksLikeTerminalOutput(content))
    }
}

@MainActor
final class ClipboardHistoryManager: ObservableObject {
    @AppStorage("clipboardHistory") private var historyData: Data = Data()
    @AppStorage("historyEnabled") var historyEnabled: Bool = true
    
    @Published private(set) var items: [ClipboardHistoryItem] = []
    @Published var searchQuery: String = ""
    
    private let maxItems = 10
    
    init() {
        load()
    }
    
    var filteredItems: [ClipboardHistoryItem] {
        guard !searchQuery.isEmpty else { return items }
        let query = searchQuery.lowercased()
        return items.filter { item in
            item.content.lowercased().contains(query) ||
            item.sourceAppName?.lowercased().contains(query) == true
        }
    }
    
    func addItem(_ text: String, source: SourceAppInfo?) {
        guard historyEnabled else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if let existingIndex = items.firstIndex(where: { $0.content == text }) {
            var item = items[existingIndex]
            item.lastCopyDate = Date()
            item.copyCount += 1
            items[existingIndex] = item
        } else {
            let newItem = ClipboardHistoryItem(content: text, sourceApp: source)
            items.append(newItem)
        }
        
        sortItems()
        
        let pinnedCount = items.filter { $0.isPinned }.count
        let unpinnedLimit = maxItems - pinnedCount
        var unpinnedCount = 0
        items = items.filter { item in
            if item.isPinned { return true }
            unpinnedCount += 1
            return unpinnedCount <= unpinnedLimit
        }
        
        save()
    }
    
    func removeItem(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }
    
    func togglePin(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isPinned.toggle()
        sortItems()
        save()
    }
    
    private func sortItems() {
        items.sort { a, b in
            if a.isPinned != b.isPinned {
                return a.isPinned
            }
            return a.lastCopyDate > b.lastCopyDate
        }
    }
    
    func clear() {
        items.removeAll()
        save()
    }
    
    func item(at index: Int) -> ClipboardHistoryItem? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }
    
    func save() {
        guard let encoded = try? JSONEncoder().encode(items) else { return }
        historyData = encoded
    }
    
    func load() {
        guard let decoded = try? JSONDecoder().decode([ClipboardHistoryItem].self, from: historyData) else {
            items = []
            return
        }
        items = decoded
    }
}
