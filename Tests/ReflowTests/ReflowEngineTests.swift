import Testing
@testable import ReflowCore

@Suite("ReflowEngine")
struct ReflowEngineTests {
    
    @Test("joins hard-wrapped prose in normal mode")
    func joinsHardWrappedProse() {
        let input = """
        The quick brown fox jumps over the lazy dog. This sentence continues
        on the next line because the terminal window was only 80 characters
        wide when this text was displayed.
        """
        
        let result = ReflowEngine.reflow(input, aggressiveness: .normal)
        
        #expect(result.wasTransformed)
        #expect(result.linesJoined == 2)
        #expect(!result.reflowed.contains("\n"))
    }
    
    @Test("preserves paragraph breaks")
    func preservesParagraphBreaks() {
        let input = """
        First paragraph that wraps
        to a second line.
        
        Second paragraph here.
        """
        
        let result = ReflowEngine.reflow(input, aggressiveness: .normal)
        
        #expect(result.reflowed.contains("\n\n"))
        #expect(result.paragraphsDetected == 2)
    }
    
    @Test("preserves indented lines as code")
    func preservesIndentedLines() {
        let input = """
        Some prose here
            indented code
            more code
        back to prose
        """
        
        let result = ReflowEngine.reflow(input, aggressiveness: .normal)
        
        #expect(result.reflowed.contains("    indented code"))
        #expect(result.reflowed.contains("    more code"))
    }
    
    @Test("preserves bullet lists")
    func preservesBulletLists() {
        let input = """
        List items:
        - First item
        - Second item
        - Third item
        """
        
        let result = ReflowEngine.reflow(input, aggressiveness: .normal)
        
        #expect(result.reflowed.contains("- First item\n"))
        #expect(result.reflowed.contains("- Second item\n"))
    }
    
    @Test("preserves numbered lists")
    func preservesNumberedLists() {
        let input = """
        Steps:
        1. First step
        2. Second step
        3. Third step
        """
        
        let result = ReflowEngine.reflow(input, aggressiveness: .normal)
        
        #expect(result.reflowed.contains("1. First step\n"))
    }
    
    @Test("returns wasTransformed=false when no change needed")
    func noTransformationNeeded() {
        let input = "Single line of text."
        
        let result = ReflowEngine.reflow(input, aggressiveness: .normal)
        
        #expect(!result.wasTransformed)
        #expect(result.linesJoined == 0)
    }
    
    @Test("detects 80-column terminal width")
    func detects80ColumnWidth() {
        let line80 = String(repeating: "x", count: 80)
        let input = """
        \(line80)
        \(line80)
        \(line80)
        \(line80)
        """
        
        let analysis = ReflowEngine.analyzeTerminalWidth(input)
        
        #expect(analysis.detectedWidth == 80)
        #expect(analysis.confidence >= 0.5)
    }
    
    @Test("detects 120-column terminal width")
    func detects120ColumnWidth() {
        let line120 = String(repeating: "y", count: 120)
        let input = """
        \(line120)
        \(line120)
        \(line120)
        """
        
        let analysis = ReflowEngine.analyzeTerminalWidth(input)
        
        #expect(analysis.detectedWidth == 120)
        #expect(analysis.confidence >= 0.5)
    }
    
    @Test("returns nil for mixed line lengths")
    func mixedLineLengths() {
        let input = """
        Short line
        A bit longer line here
        Even longer line with more content
        Tiny
        """
        
        let analysis = ReflowEngine.analyzeTerminalWidth(input)
        
        #expect(analysis.detectedWidth == nil)
    }
    
    @Test("detects terminal-like output with multiple signals")
    func detectsTerminalOutput() {
        let input = """
        $ ls -la /usr/local/bin
        total 16
        drwxr-xr-x  5 user  staff  160 Dec 27 10:00 .
        drwxr-xr-x  3 user  staff   96 Dec 27 09:00 ..
        -rwxr-xr-x  1 user  staff  1024 Dec 27 10:00 node
        """
        
        #expect(ReflowEngine.looksLikeTerminalOutput(input))
    }
    
    @Test("detects terminal-like output with error messages")
    func detectsTerminalErrors() {
        let input = """
        error: cannot find 'foo' in scope
        warning: unused variable 'bar'
        /Users/test/src/main.swift:10:5: error: expected declaration
        """
        
        #expect(ReflowEngine.looksLikeTerminalOutput(input))
    }
    
    @Test("rejects non-terminal content")
    func rejectsNonTerminalContent() {
        let input = """
        Hello, this is a regular document.
        It has some text in it.
        Nothing terminal-like here.
        """
        
        #expect(!ReflowEngine.looksLikeTerminalOutput(input))
    }
    
    @Test("preserves markdown headers")
    func preservesMarkdownHeaders() {
        let input = """
        # Header 1
        Some text that wraps
        to the next line.
        ## Header 2
        More text here.
        """
        
        let options = ReflowOptions(markdownAware: true)
        let result = ReflowEngine.reflow(input, options: options)
        
        #expect(result.reflowed.contains("# Header 1\n"))
        #expect(result.reflowed.contains("## Header 2\n"))
    }
    
    @Test("preserves code fences")
    func preservesCodeFences() {
        let input = """
        Some text before.
        ```swift
        let x = 1
        let y = 2
        ```
        Some text after.
        """
        
        let options = ReflowOptions(markdownAware: true)
        let result = ReflowEngine.reflow(input, options: options)
        
        #expect(result.reflowed.contains("```swift\n"))
        #expect(result.reflowed.contains("let x = 1\n"))
        #expect(result.reflowed.contains("```\n"))
    }
    
    @Test("preserves blockquotes")
    func preservesBlockquotes() {
        let input = """
        Normal text here.
        > This is a quote
        > that spans lines.
        Back to normal.
        """
        
        let options = ReflowOptions(markdownAware: true)
        let result = ReflowEngine.reflow(input, options: options)
        
        #expect(result.reflowed.contains("> This is a quote\n"))
        #expect(result.reflowed.contains("> that spans lines.\n"))
    }
    
    @Test("applies custom patterns")
    func appliesCustomPatterns() {
        let input = """
        Normal line one
        Normal line two
        IMPORTANT: Keep this line
        Normal line three
        """
        
        let options = ReflowOptions(customPatterns: ["^IMPORTANT:"])
        let result = ReflowEngine.reflow(input, options: options)
        
        #expect(result.reflowed.contains("IMPORTANT: Keep this line\n"))
    }
}
