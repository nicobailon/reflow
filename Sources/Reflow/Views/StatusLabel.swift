import SwiftUI

struct StatusLabel: View {
    @ObservedObject var monitor: ClipboardMonitor
    var isEnabled: Bool
    
    var body: some View {
        Label("Reflow", systemImage: "text.justify.left")
            .symbolRenderingMode(.hierarchical)
            .symbolEffect(.pulse, options: .repeat(1).speed(1.15), value: monitor.reflowPulseID)
            .foregroundStyle(isEnabled ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            .opacity(isEnabled ? 1.0 : 0.45)
    }
}
