import AppKit
@testable import ReflowCore

func makeTestPasteboard() -> NSPasteboard {
    let name = NSPasteboard.Name("com.reflow.tests-\(UUID().uuidString)")
    let board = NSPasteboard(name: name)
    board.clearContents()
    return board
}
