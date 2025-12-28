import Foundation

public struct TerminalRegistry: Sendable {
    public static let knownTerminals: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "dev.warp.Warp-Stable",
        "org.alacritty",
        "net.kovidgoyal.kitty",
        "co.zeit.hyper",
        "com.github.wez.wezterm",
    ]
    
    public static let mixedSourceApps: Set<String> = [
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "dev.zed.Zed",
    ]
    
    public static func isTerminal(_ bundleId: String?) -> Bool {
        guard let bundleId else { return false }
        return knownTerminals.contains(bundleId)
    }
    
    public static func isMixedSource(_ bundleId: String?) -> Bool {
        guard let bundleId else { return false }
        return mixedSourceApps.contains(bundleId)
    }
}
