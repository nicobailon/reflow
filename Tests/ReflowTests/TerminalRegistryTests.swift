import Testing
@testable import ReflowCore

@Suite("TerminalRegistry")
struct TerminalRegistryTests {
    
    @Test("recognizes known terminals")
    func recognizesKnownTerminals() {
        #expect(TerminalRegistry.isTerminal("com.apple.Terminal"))
        #expect(TerminalRegistry.isTerminal("com.mitchellh.ghostty"))
        #expect(TerminalRegistry.isTerminal("com.googlecode.iterm2"))
    }
    
    @Test("identifies mixed source apps")
    func identifiesMixedSourceApps() {
        #expect(TerminalRegistry.isMixedSource("com.microsoft.VSCode"))
        #expect(TerminalRegistry.isMixedSource("com.todesktop.230313mzl4w4u92"))
    }
    
    @Test("rejects unknown apps")
    func rejectsUnknownApps() {
        #expect(!TerminalRegistry.isTerminal("com.apple.Safari"))
        #expect(!TerminalRegistry.isTerminal("com.apple.Notes"))
    }
}
