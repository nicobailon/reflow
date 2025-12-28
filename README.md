# Reflow

A macOS menu bar utility that unwraps hard-wrapped terminal text.

When you copy text from a terminal, it often contains hard line breaks at 80 or 120 characters. Reflow detects terminal copies and lets you paste the text with line wrapping removed, while preserving paragraph breaks, code blocks, and lists.

## Features

- **Auto-detection** - Recognizes copies from Terminal.app, iTerm2, Ghostty, Warp, Kitty, Alacritty, Hyper, and WezTerm
- **Smart heuristics** - Detects terminal output from VS Code, Cursor, and Zed integrated terminals
- **Markdown-aware** - Preserves headers, code fences, blockquotes, and tables
- **Custom patterns** - Define regex patterns to preserve specific lines
- **Statistics** - Track lines joined and paste counts (session + all-time)
- **Global hotkeys** - Configurable keyboard shortcuts
- **CLI tool** - Full-featured command-line interface

## Usage

### Menu Bar

Click the Reflow icon in the menu bar to:
- Toggle auto-reflow on/off
- Choose aggressiveness level (Conservative, Normal, Aggressive)
- Toggle markdown-aware mode
- View source app detection
- Access paste actions
- View statistics

### Keyboard Shortcuts

Default shortcuts (configurable in Settings):
- **Cmd+Ctrl+V** - Paste Reflowed
- **Cmd+Ctrl+Shift+V** - Paste Original
- **Cmd+Ctrl+R** - Toggle Auto-Reflow

### CLI

```bash
# Basic usage (stdin)
pbpaste | reflow-cli

# From file
reflow-cli --file input.txt

# With options
reflow-cli -a conservative --stats

# Markdown mode
reflow-cli --no-markdown

# Custom patterns
reflow-cli --pattern "^TODO:" --pattern "^FIXME:"

# Analysis tools
reflow-cli --analyze-width
reflow-cli --check-terminal
```

## Aggressiveness Levels

- **Conservative** - Preserves lines ending with punctuation. Best for mixed content.
- **Normal** - Joins most lines, preserves obvious boundaries. Default.
- **Aggressive** - Joins everything except blank lines and special patterns.

## Build

```bash
swift build
swift test
```

## Requirements

- macOS 15.0+
- Accessibility permission (for paste injection)

## License

MIT
