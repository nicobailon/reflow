import ArgumentParser
import Foundation
import ReflowCore

@main
struct ReflowCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reflow",
        abstract: "Unwrap hard-wrapped terminal text",
        version: "0.2.0"
    )
    
    @Option(name: .shortAndLong, help: "Input file (reads from stdin if not specified)")
    var file: String?
    
    @Option(name: .shortAndLong, help: "Aggressiveness level: conservative, normal, aggressive")
    var aggressiveness: AggressivenessArg = .normal
    
    @Flag(name: .long, help: "Analyze terminal width without reflowing")
    var analyzeWidth: Bool = false
    
    @Flag(name: .long, help: "Check if input looks like terminal output")
    var checkTerminal: Bool = false
    
    @Flag(name: .shortAndLong, help: "Show statistics about the transformation")
    var stats: Bool = false
    
    @Flag(name: .long, inversion: .prefixedNo, help: "Enable/disable markdown-aware mode (default: enabled)")
    var markdown: Bool = true
    
    @Option(name: .long, help: "Custom regex pattern to preserve (can be repeated)")
    var pattern: [String] = []
    
    mutating func run() throws {
        let input = try readInput()
        
        guard !input.isEmpty else {
            throw ValidationError("No input provided")
        }
        
        if analyzeWidth {
            let analysis = ReflowEngine.analyzeTerminalWidth(input)
            if let width = analysis.detectedWidth {
                print("Detected terminal width: \(width) columns")
                print("Confidence: \(String(format: "%.1f%%", analysis.confidence * 100))")
            } else {
                print("No consistent terminal width detected")
            }
            return
        }
        
        if checkTerminal {
            let looksLikeTerminal = ReflowEngine.looksLikeTerminalOutput(input)
            print(looksLikeTerminal ? "yes" : "no")
            return
        }
        
        let options = ReflowOptions(
            aggressiveness: aggressiveness.toAggressiveness,
            markdownAware: markdown,
            customPatterns: pattern
        )
        let result = ReflowEngine.reflow(input, options: options)
        
        print(result.reflowed, terminator: "")
        
        if stats {
            fputs("\n--- Statistics ---\n", stderr)
            fputs("Lines joined: \(result.linesJoined)\n", stderr)
            fputs("Paragraphs: \(result.paragraphsDetected)\n", stderr)
            fputs("Transformed: \(result.wasTransformed ? "yes" : "no")\n", stderr)
        }
    }
    
    private func readInput() throws -> String {
        if let filePath = file {
            let url = URL(fileURLWithPath: filePath)
            return try String(contentsOf: url, encoding: .utf8)
        }
        
        if isatty(STDIN_FILENO) != 0 {
            return ""
        }
        
        let data = FileHandle.standardInput.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
}

enum AggressivenessArg: String, ExpressibleByArgument, CaseIterable {
    case conservative
    case normal
    case aggressive
    
    var toAggressiveness: Aggressiveness {
        switch self {
        case .conservative: .conservative
        case .normal: .normal
        case .aggressive: .aggressive
        }
    }
}
