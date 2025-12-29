import Foundation

public struct TerminalWidthAnalysis: Sendable {
    public let detectedWidth: Int?
    public let confidence: Double
    public let lineLengthDistribution: [Int: Int]
    
    public init(detectedWidth: Int?, confidence: Double, lineLengthDistribution: [Int: Int]) {
        self.detectedWidth = detectedWidth
        self.confidence = confidence
        self.lineLengthDistribution = lineLengthDistribution
    }
}

public struct ReflowEngine: Sendable {
    
    public static let commonTerminalWidths = [80, 120, 132, 100, 160]
    
    public static func analyzeTerminalWidth(_ text: String) -> TerminalWidthAnalysis {
        let lines = text.components(separatedBy: "\n")
        var lengthCounts: [Int: Int] = [:]
        var contentLines = 0
        
        for line in lines {
            let length = line.count
            if length > 0 {
                lengthCounts[length, default: 0] += 1
                contentLines += 1
            }
        }
        
        guard contentLines >= 3 else {
            return TerminalWidthAnalysis(detectedWidth: nil, confidence: 0, lineLengthDistribution: lengthCounts)
        }
        
        var bestWidth: Int?
        var bestScore = 0.0
        
        for targetWidth in commonTerminalWidths {
            let nearTargetCount = lengthCounts.filter { abs($0.key - targetWidth) <= 2 }.values.reduce(0, +)
            let score = Double(nearTargetCount) / Double(contentLines)
            
            if score > bestScore && score >= 0.3 {
                bestScore = score
                bestWidth = targetWidth
            }
        }
        
        return TerminalWidthAnalysis(
            detectedWidth: bestWidth,
            confidence: bestScore,
            lineLengthDistribution: lengthCounts
        )
    }
    
    public static func looksLikeTerminalOutput(_ text: String) -> Bool {
        let lines = text.components(separatedBy: "\n")
        guard lines.count >= 2 else { return false }
        
        var terminalSignals = 0
        
        let widthAnalysis = analyzeTerminalWidth(text)
        if widthAnalysis.detectedWidth != nil && widthAnalysis.confidence >= 0.3 {
            terminalSignals += 2
        }
        
        let hasPromptPattern = lines.contains { line in
            line.hasPrefix("$ ") || line.hasPrefix("% ") || line.hasPrefix("> ") ||
            line.contains("@") && line.contains(":") && (line.contains("$") || line.contains("%"))
        }
        if hasPromptPattern { terminalSignals += 1 }
        
        let hasPathPattern = lines.contains { line in
            line.contains("/usr/") || line.contains("/home/") || line.contains("/var/") ||
            line.contains("/Users/") || line.contains("/opt/") ||
            line.hasPrefix("./") || line.hasPrefix("../")
        }
        if hasPathPattern { terminalSignals += 1 }
        
        let hasErrorPattern = lines.contains { line in
            let lower = line.lowercased()
            return lower.contains("error:") || lower.contains("warning:") ||
            lower.contains("fatal:") || line.contains("]: ") || 
            (line.hasPrefix("[") && line.contains("]"))
        }
        if hasErrorPattern { terminalSignals += 2 }
        
        return terminalSignals >= 2
    }
    
    public static func reflow(
        _ text: String,
        aggressiveness: Aggressiveness = .normal
    ) -> ReflowResult {
        reflow(text, options: ReflowOptions(aggressiveness: aggressiveness))
    }
    
    public static func reflow(
        _ text: String,
        options: ReflowOptions
    ) -> ReflowResult {
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var currentParagraph: [String] = []
        var totalLinesJoined = 0
        var inCodeFence = false
        
        let compiledPatterns = options.customPatterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [])
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if options.markdownAware && isCodeFenceDelimiter(trimmed) {
                if !currentParagraph.isEmpty {
                    result.append(joinParagraphLines(currentParagraph))
                    totalLinesJoined += currentParagraph.count - 1
                    currentParagraph = []
                }
                result.append(line)
                inCodeFence.toggle()
                continue
            }
            
            if inCodeFence {
                result.append(line)
                continue
            }
            
            if trimmed.isEmpty {
                if !currentParagraph.isEmpty {
                    result.append(joinParagraphLines(currentParagraph))
                    totalLinesJoined += currentParagraph.count - 1
                    currentParagraph = []
                }
                result.append("")
                continue
            }
            
            if shouldPreserveLine(line, options: options, compiledPatterns: compiledPatterns) {
                if !currentParagraph.isEmpty {
                    result.append(joinParagraphLines(currentParagraph))
                    totalLinesJoined += currentParagraph.count - 1
                    currentParagraph = []
                }
                result.append(line)
                continue
            }
            
            currentParagraph.append(trimmed)
        }
        
        if !currentParagraph.isEmpty {
            result.append(joinParagraphLines(currentParagraph))
            totalLinesJoined += currentParagraph.count - 1
        }
        
        let reflowed = result.joined(separator: "\n")
        let paragraphs = result.filter { !$0.isEmpty }.count
        
        return ReflowResult(
            original: text,
            reflowed: reflowed,
            linesJoined: totalLinesJoined,
            paragraphsDetected: paragraphs
        )
    }
    
    private static func isCodeFenceDelimiter(_ line: String) -> Bool {
        line.hasPrefix("```") || line.hasPrefix("~~~")
    }
    
    private static func joinParagraphLines(_ lines: [String]) -> String {
        guard !lines.isEmpty else { return "" }
        guard lines.count > 1 else { return lines[0] }
        
        var result = lines[0]
        
        for i in 1..<lines.count {
            let prevLine = lines[i - 1]
            let currentLine = lines[i]
            
            let separator = shouldJoinWithoutSpace(prevLine: prevLine, nextLine: currentLine) ? "" : " "
            result += separator + currentLine
        }
        
        return result
    }
    
    private static func shouldJoinWithoutSpace(prevLine: String, nextLine: String) -> Bool {
        guard let lastChar = prevLine.last, let firstChar = nextLine.first else {
            return false
        }
        
        let continuationChars = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "/-_.:~@"))
        
        let lastIsContinuation = lastChar.unicodeScalars.allSatisfy { continuationChars.contains($0) }
        let firstIsContinuation = firstChar.unicodeScalars.allSatisfy { continuationChars.contains($0) }
        
        if !lastIsContinuation || !firstIsContinuation {
            return false
        }
        
        let combined = prevLine + nextLine
        let looksLikePath = combined.contains("/") && 
            (combined.hasPrefix("/") || combined.hasPrefix("./") || combined.hasPrefix("../") || combined.contains("://"))
        let looksLikeUrl = combined.contains("://") || combined.hasPrefix("www.")
        let looksLikeLongToken = !prevLine.contains(" ") && !nextLine.contains(" ")
        
        return looksLikePath || looksLikeUrl || looksLikeLongToken
    }
    
    private static func shouldPreserveLine(
        _ line: String,
        options: ReflowOptions,
        compiledPatterns: [NSRegularExpression] = []
    ) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if line.hasPrefix("  ") || line.hasPrefix("\t") {
            return true
        }
        
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
            return true
        }
        
        if trimmed.range(of: #"^\d+[\.\)]\s"#, options: .regularExpression) != nil {
            return true
        }
        
        if options.markdownAware {
            if trimmed.hasPrefix("#") {
                return true
            }
            
            if trimmed.hasPrefix(">") {
                return true
            }
            
            if trimmed.hasPrefix("|") || trimmed.hasPrefix("|-") || trimmed.hasPrefix("| -") {
                return true
            }
            
            if trimmed.hasPrefix("---") || trimmed.hasPrefix("***") || trimmed.hasPrefix("___") {
                return true
            }
        }
        
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        for regex in compiledPatterns {
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return true
            }
        }
        
        if options.aggressiveness == .conservative {
            if let last = trimmed.last, ".!?:".contains(last) {
                return true
            }
        }
        
        return false
    }
}
