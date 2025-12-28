# Reflow — Product Requirements Document

> **"Copy once, read anywhere."** — Reflow unwraps hard-wrapped terminal output so it pastes as flowing prose.

---

## Executive Summary

Reflow is a lightweight macOS menu bar utility that solves a common annoyance for developers and power users: when you copy text from a terminal, it often contains hard line breaks at the terminal's column width (typically 80 or 120 characters). When pasted into documents, emails, or notes, this produces choppy, hard-to-read paragraphs instead of flowing text.

Reflow watches the clipboard and intelligently removes these artificial line breaks while preserving intentional paragraph boundaries.

---

## Problem Statement

### The Pain Point

When copying text output from terminal applications:
- Text is hard-wrapped at the terminal's column width
- Line breaks occur mid-sentence, mid-word, or at arbitrary positions
- Pasting into word processors, notes apps, or emails produces fragmented paragraphs
- Manual cleanup is tedious: find-and-replace newlines, then re-add paragraph breaks

### Example

**Copied from terminal (80-column width):**
```
The quick brown fox jumps over the lazy dog. This sentence continues
on the next line because the terminal window was only 80 characters
wide when this text was displayed.

This is a new paragraph that should remain separate.
```

**Desired output:**
```
The quick brown fox jumps over the lazy dog. This sentence continues on the next line because the terminal window was only 80 characters wide when this text was displayed.

This is a new paragraph that should remain separate.
```

### Target Users

- Developers copying AI agent output, logs, or documentation
- Writers and researchers copying text from terminal-based tools
- Anyone who regularly copies prose from terminal applications
- Users of CLI coding agents (Claude Code, Cursor, Copilot CLI, aider, etc.)

### Relationship to Trimmy

Reflow is the conceptual sibling of [Trimmy](https://github.com/steipete/Trimmy):

| Aspect | Trimmy | Reflow |
|--------|--------|--------|
| **Direction** | Outside → Terminal | Terminal → Outside |
| **Problem** | Multi-line commands don't execute | Hard-wrapped text doesn't read |
| **Solution** | Flatten commands to one line | Unwrap prose to flowing paragraphs |
| **Detection** | Look for shell command patterns | Look for hard-wrap patterns |

---

## Product Requirements

### Core Functionality

#### 1. Source App Detection (Primary Signal)

Rather than relying solely on content heuristics (which are "surprisingly difficult" per Trimmy's author), Reflow uses **source app detection** as its primary signal for when to process clipboard content.

**How it works:**

macOS clipboard (`NSPasteboard`) includes metadata about the source application via the `NSPasteboard.Name` and bundle identifier. Reflow checks this to determine if the copied text came from a terminal emulator.

**Supported terminal apps (auto-detected):**

| App | Bundle Identifier |
|-----|-------------------|
| Terminal.app | `com.apple.Terminal` |
| iTerm2 | `com.googlecode.iterm2` |
| Ghostty | `com.mitchellh.ghostty` |
| Warp | `dev.warp.Warp-Stable` |
| Alacritty | `org.alacritty` |
| Kitty | `net.kovidgoyal.kitty` |
| Hyper | `co.zeit.hyper` |
| VS Code (terminal) | `com.microsoft.VSCode` * |
| Cursor (terminal) | `com.todesktop.230313mzl4w4u92` * |
| WezTerm | `com.github.wez.wezterm` |

*\* VS Code and Cursor copy from both editor and terminal; may need content heuristics as secondary signal.*

**Benefits of source-app-first approach:**
- Dramatically reduces false positives
- Enables auto-reflow ON by default (safe because we know it's terminal text)
- Simpler logic than pure content analysis
- Aligns with Peter Steinberger's experimental direction for Trimmy

**User-configurable app list:**
- Settings allows adding/removing apps from the detection list
- "Treat as terminal" toggle for edge cases
- Option to process ALL clipboard content (ignore source app)

#### 2. Text Unwrapping Engine

Once source app detection confirms terminal origin, the unwrapping engine processes the text:

**Primary transformation:**
- Join lines that were split due to terminal width
- Preserve blank lines as paragraph separators
- Handle common terminal column widths (80, 120, 132, or auto-detect)

**Detection heuristics (when to unwrap):**
- Lines ending without sentence-terminal punctuation (`.`, `!`, `?`, `:`)
- Consistent line lengths suggesting hard-wrapping
- Lines ending mid-word or with hyphenation
- Absence of structural markers (bullets, numbers, code indentation)

**Preservation rules (when NOT to join):**
- Blank lines (paragraph boundaries)
- Lines ending with sentence-terminal punctuation followed by blank line
- Indented lines (likely code or structured data)
- Lines starting with bullets (`-`, `*`, `•`) or numbers (`1.`, `2)`)
- Lines that look like headers (short, possibly capitalized)
- Lines containing only whitespace

#### 3. Aggressiveness Levels

**Conservative (default):**
- Only unwrap when highly confident text is hard-wrapped prose
- Require consistent line lengths within ~5 characters of detected width
- Skip anything that might be code, logs, or structured data

**Normal:**
- Unwrap text that appears to be prose with moderate confidence
- Handle slightly inconsistent line lengths
- Still preserve obvious structure (indentation, bullets)

**Aggressive:**
- Unwrap almost any multi-line text
- Useful for manual "Paste Reflowed" action
- May mangle code or structured data

#### 4. Menu Bar Interface

**Menu structure:**
```
[Reflow Icon ¶]
├── Auto-Reflow: ✓ On / Off
├── ─────────────────────────
├── Source: iTerm2 ✓ (recognized)
├── ─────────────────────────
├── Aggressiveness ▸
│   ├── ✓ Conservative
│   ├── Normal
│   └── Aggressive
├── ─────────────────────────
├── Paste Reflowed          ⌘⇧V
│   └── "The quick brown fox jumps..." (42 lines joined)
├── Paste Original          ⌘⌥V
│   └── "The quick brown fox..." (847 chars)
├── ─────────────────────────
├── Last action: Reflowed 12 lines → 3 paragraphs
├── ─────────────────────────
├── Settings...             ⌘,
├── Check for Updates...
└── Quit Reflow             ⌘Q
```

**Status indicators:**
- Menu bar icon changes when clipboard contains reflowable text from a terminal
- "Source: AppName ✓" shows which app the clipboard came from
- Preview shows first ~100 characters of transformed text
- Badge shows "X lines joined" or similar
- If source app is unrecognized: "Source: Unknown App (click to add)"

#### 5. Hotkey Actions

| Action | Default Hotkey | Behavior |
|--------|---------------|----------|
| Paste Reflowed | ⌘⇧V | Transform clipboard, paste, restore original |
| Paste Original | ⌘⌥V | Paste untransformed clipboard |
| Toggle Auto-Reflow | ⌘⌥R | Enable/disable automatic clipboard watching |

#### 6. Settings Window

**General tab:**
- Launch at login (via SMAppService)
- Show in Dock: Never (LSUIElement)
- Menu bar icon style (monochrome, color, text "¶")
- Check for updates automatically

**Source Apps tab:**
- List of recognized terminal apps (with toggle for each)
- "Add Custom App" button (select from running apps or enter bundle ID)
- "Process all clipboard content" override checkbox
- "Learn" button: copies from any app in next 30 seconds are added to list

**Behavior tab:**
- Auto-Reflow: On/Off (default: ON when source app detection is enabled)
- Default aggressiveness level
- Maximum lines to auto-process (safety valve, default: 500)
- Preserve trailing whitespace: On/Off

**Shortcuts tab:**
- Customizable hotkeys for Paste Reflowed, Paste Original, Toggle

**Advanced tab:**
- Assumed terminal width (Auto-detect / 80 / 120 / Custom)
- Paragraph detection sensitivity
- Debug logging
- "Ignore source app, use content heuristics only" mode

---

## Technical Architecture

### Inspiration from Trimmy

Adopt these patterns from Trimmy's codebase:

**Clipboard handling:**
- Poll-based clipboard watching (~150ms interval with leeway)
- Grace delay (~80ms) for promised pasteboard data
- Marker pasteboard type to avoid reprocessing own writes
- Use `NSPasteboard.general` with change count tracking

**App structure:**
- LSUIElement (no Dock icon)
- MenuBarExtra with SwiftUI
- Swift Package Manager + Xcode project hybrid
- Sparkle for auto-updates
- SwiftFormat + SwiftLint for code quality

**Build & release:**
- Swift 6, macOS 15+ target
- Notarization via `notarytool`
- Homebrew cask distribution
- GitHub Releases with appcast.xml

### New Components

**SourceAppDetector.swift:**
```swift
import AppKit

struct SourceAppInfo {
    let bundleIdentifier: String?
    let appName: String?
    let isRecognizedTerminal: Bool
}

class SourceAppDetector {
    
    static let knownTerminalBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "dev.warp.Warp-Stable",
        "org.alacritty",
        "net.kovidgoyal.kitty",
        "co.zeit.hyper",
        "com.github.wez.wezterm",
        // Note: VS Code and Cursor need special handling
    ]
    
    /// Apps that have both editor and terminal (need content heuristics too)
    static let mixedSourceApps: Set<String> = [
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92", // Cursor
        "dev.zed.Zed",
    ]
    
    func getSourceApp(from pasteboard: NSPasteboard) -> SourceAppInfo {
        // Method 1: Check pasteboard items for source
        // The source app info may be in various pasteboard types
        
        // Try to get the source bundle ID
        // This involves checking NSPasteboard metadata
        
        // Fallback: Check frontmost app at time of copy (less reliable)
        
        return SourceAppInfo(
            bundleIdentifier: detectedBundleID,
            appName: detectedAppName,
            isRecognizedTerminal: knownTerminalBundleIDs.contains(detectedBundleID ?? "")
        )
    }
    
    func isMixedSourceApp(_ bundleID: String) -> Bool {
        return Self.mixedSourceApps.contains(bundleID)
    }
}
```

**ReflowEngine.swift:**
```swift
struct ReflowResult {
    let original: String
    let reflowed: String
    let linesJoined: Int
    let paragraphsDetected: Int
    let wasTransformed: Bool
    let sourceApp: SourceAppInfo?
}

enum Aggressiveness {
    case conservative
    case normal
    case aggressive
}

func reflow(
    _ text: String, 
    aggressiveness: Aggressiveness,
    sourceApp: SourceAppInfo?
) -> ReflowResult
```

**Detection heuristics:**
```swift
func looksLikeHardWrappedProse(_ text: String) -> Bool {
    // Check for:
    // - Multiple lines of similar length
    // - Lines not ending in punctuation
    // - Absence of code/structure markers
}

func detectTerminalWidth(_ text: String) -> Int? {
    // Analyze line lengths to guess original terminal width
}
```

### CLI Tool (ReflowCLI)

Mirror Trimmy's CLI design:

```bash
# Basic usage
pbpaste | reflow

# With options
reflow --file input.txt --aggressiveness normal --json

# Pipe-friendly
cat terminal-output.txt | reflow > cleaned.txt
```

**Options:**
- `--aggressiveness {conservative|normal|aggressive}`
- `--width {auto|80|120|N}` — assumed terminal width
- `--preserve-indentation` / `--no-preserve-indentation`
- `--json` — output `{original, reflowed, linesJoined, paragraphs}`
- `--force` / `-f` — use aggressive mode

**Exit codes:**
- 0: Success (text was transformed)
- 1: Error (no input, file not found)
- 2: No transformation needed (already flowing)

---

## User Experience

### First Launch

1. App opens with brief onboarding overlay
2. Requests Accessibility permission (for paste injection)
3. Shows list of detected terminal apps on system, asks user to confirm
4. Shows menu bar icon with "Ready" status
5. Default: Auto-Reflow ON (safe because source app detection limits scope)

### Typical Workflow

1. User copies text from terminal (iTerm2, Terminal.app, Ghostty, etc.)
2. Reflow detects source app is a recognized terminal emulator
3. Reflow analyzes text and detects hard-wrapped prose
4. Menu bar icon subtly indicates "reflowable content from iTerm2"
5. User presses ⌘⇧V (Paste Reflowed) in their document
6. Flowed text is pasted; original clipboard preserved

**Alternative: Unknown source app**
1. User copies from unrecognized terminal (e.g., custom electron app)
2. Menu bar shows "Source: MyApp (not recognized)"
3. User can still manually use ⌘⇧V to force reflow
4. User can click "Add to recognized apps" to remember for future

### Edge Cases

**Code blocks:**
- Indented lines are never joined
- Lines starting with common code patterns (`{`, `}`, `//`, `#`, `def `, etc.) are preserved

**Mixed content:**
- Prose paragraphs are reflowed
- Code blocks within are preserved
- Blank lines remain as separators

**Very long text:**
- Safety valve: skip auto-reflow for text > 500 lines
- Manual "Paste Reflowed" still works
- Warn user in menu if skipped

---

## Success Metrics

### Qualitative

- Users report "it just works" for terminal prose
- No complaints about mangled code or structured data
- Positive comparison to manual cleanup workflows

### Quantitative

- < 50ms processing time for typical clipboard (< 1000 lines)
- < 1% false positive rate (unwrapping text that shouldn't be)
- < 5MB memory footprint while idle

---

## Development Phases

### Phase 1: MVP (v0.1.0)

- [ ] Basic menu bar app structure (fork Trimmy patterns)
- [ ] Source app detection (read bundle ID from clipboard)
- [ ] Hardcoded list of known terminal apps
- [ ] Simple unwrap algorithm (join lines not ending in `.!?:`)
- [ ] Paste Reflowed hotkey
- [ ] Conservative mode only
- [ ] Auto-reflow ON by default (gated by source app)

### Phase 2: Smart Detection (v0.2.0)

- [ ] Auto-detect terminal width from line lengths
- [ ] Improved prose vs. code detection (secondary heuristic)
- [ ] Aggressiveness levels
- [ ] Settings window with source app management
- [ ] "Add this app" quick action from menu
- [ ] Handle VS Code/Cursor mixed-source edge case

### Phase 3: Polish (v0.3.0)

- [ ] CLI tool (ReflowCLI)
- [ ] Sparkle auto-updates
- [ ] Homebrew cask
- [ ] Notarization and signing
- [ ] Comprehensive test suite
- [ ] "Learn" mode for discovering new terminal apps

### Phase 4: Advanced (v1.0.0)

- [ ] Markdown-aware mode (preserve `#` headers, code fences)
- [ ] Configurable patterns (user-defined "don't join" rules)
- [ ] Statistics (lines reflowed this session/all-time)
- [ ] Potential collaboration with Trimmy (shared detection, complementary tools)
- [ ] Possible unified "Terminal Clipboard Tools" suite

---

## Open Questions

1. **Should auto-reflow be on by default?**
   - ~~Trimmy defaults to ON for commands~~
   - ~~Prose unwrapping is more likely to have false positives~~
   - ✅ **RESOLVED:** With source app detection, auto-reflow ON is safe by default
   - Only processes clipboard from recognized terminal apps

2. **How to handle mixed prose/code?**
   - Option A: Detect code blocks and skip them entirely
   - Option B: Process paragraph-by-paragraph
   - Recommendation: Start with Option A (simpler, safer)

3. **~~Should we detect the source app?~~**
   - ✅ **RESOLVED:** Yes, this is now the primary detection mechanism
   - Per Peter Steinberger: "Yes - something I started experimenting with"
   - Clipboard metadata includes source app bundle identifier

4. **How to handle VS Code / Cursor?**
   - These apps have both editor and integrated terminal
   - Copies from editor should NOT be reflowed
   - Copies from terminal SHOULD be reflowed
   - May need secondary content heuristics for these apps
   - Or: don't auto-process, but allow manual ⌘⇧V

5. **Relationship with Trimmy?**
   - Separate app (cleaner, no conflicts)
   - PR to Trimmy (shared infrastructure, potential confusion)
   - Recommendation: Separate app, possibly reach out to steipete about collaboration
   - Could share source app detection code/approach

---

## Appendix: Algorithm Sketch

```swift
func reflow(_ text: String, aggressiveness: Aggressiveness) -> ReflowResult {
    let lines = text.components(separatedBy: "\n")
    var result: [String] = []
    var currentParagraph: [String] = []
    var linesJoined = 0
    
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Blank line = paragraph boundary
        if trimmed.isEmpty {
            if !currentParagraph.isEmpty {
                result.append(currentParagraph.joined(separator: " "))
                currentParagraph = []
            }
            result.append("") // preserve blank line
            continue
        }
        
        // Check if line should NOT be joined
        if shouldPreserveLine(line, aggressiveness: aggressiveness) {
            if !currentParagraph.isEmpty {
                result.append(currentParagraph.joined(separator: " "))
                currentParagraph = []
            }
            result.append(line)
            continue
        }
        
        // Add to current paragraph
        currentParagraph.append(trimmed)
        if currentParagraph.count > 1 {
            linesJoined += 1
        }
    }
    
    // Flush remaining paragraph
    if !currentParagraph.isEmpty {
        result.append(currentParagraph.joined(separator: " "))
    }
    
    let reflowed = result.joined(separator: "\n")
    return ReflowResult(
        original: text,
        reflowed: reflowed,
        linesJoined: linesJoined,
        paragraphsDetected: result.filter { !$0.isEmpty }.count,
        wasTransformed: text != reflowed
    )
}

func shouldPreserveLine(_ line: String, aggressiveness: Aggressiveness) -> Bool {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    
    // Always preserve indented lines (likely code)
    if line.hasPrefix("  ") || line.hasPrefix("\t") {
        return true
    }
    
    // Always preserve bullet points
    if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
        return true
    }
    
    // Always preserve numbered lists
    if trimmed.range(of: #"^\d+[\.\)]\s"#, options: .regularExpression) != nil {
        return true
    }
    
    // In conservative mode, preserve lines ending with punctuation
    if aggressiveness == .conservative {
        if let last = trimmed.last, ".!?:".contains(last) {
            return true
        }
    }
    
    return false
}
```

---

## References

- [Trimmy](https://github.com/steipete/Trimmy) — Inspiration for architecture and UX patterns
- [Peter Steinberger on source app detection](https://x.com/steipete) — "Yes - something I started experimenting with" (Dec 2025)
- [fmt](https://en.wikipedia.org/wiki/Fmt_(Unix)) — Unix text reformatter
- [par](http://www.nicemice.net/par/) — Paragraph reformatter by Adam M. Costello
- [Pastemagic](https://pastemagic.com/) — Web-based line break removal tool
- [NSPasteboard documentation](https://developer.apple.com/documentation/appkit/nspasteboard) — macOS clipboard API

---

*Document version: 1.1*  
*Last updated: December 27, 2025*  
*Changelog: Added source app detection as primary signal per steipete's experimental direction*
