# Changelog

## 0.1.1 — 2025-12-28

### Clipboard History
- Maccy-style popover panel as the primary interface (click menu bar icon to open)
- Split-view layout: detail preview on left, searchable history list on right
- Pin/unpin items to keep them at the top (pinned items never get evicted)
- Collapsible details section showing source app, timestamps, and copy count
- Hover highlighting on history items
- Context menu with Paste Reflowed, Paste Original, Pin/Unpin, Delete
- Keyboard navigation: arrow keys to select, Return to paste, Delete to remove, Escape to close
- Cmd+1-9 global hotkeys for quick paste (configurable in Settings)
- Search filters history in real-time with auto-selection
- Non-terminal items visually dimmed; option to hide them entirely

### Core Features
- Menu bar app with no Dock icon (LSUIElement)
- Clipboard monitoring with terminal source detection
- Recognized terminals: Terminal.app, iTerm2, Ghostty, Warp, Kitty, Alacritty, Hyper, WezTerm
- Mixed-source detection: VS Code, Cursor, Zed (integrated terminals)
- ReflowEngine: markdown-aware text unwrapping with custom regex patterns
- Three aggressiveness levels: Conservative, Normal, Aggressive
- Statistics tracking (session + all-time lines joined and paste counts)
- Proper focus restoration when pasting from panel (activates previous app)

### Keyboard Shortcuts
- Cmd+Ctrl+V: Paste Reflowed
- Cmd+Ctrl+Shift+V: Paste Original
- Cmd+Ctrl+R: Toggle Auto-Reflow
- Cmd+Ctrl+H: Show/Hide History Panel

### CLI Tool
- `reflow-cli` command-line interface
- Supports stdin, file input, and various options
- Analysis tools: `--analyze-width`, `--check-terminal`

### Settings
- Accessibility section with "Grant Access" button
- Configurable global hotkeys
- Launch at login option
- Aggressiveness level selection
- Markdown-aware mode toggle
- Show Only Terminal Items toggle
- Sparkle auto-updates (placeholder, requires signing)
