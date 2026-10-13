import SwiftUI

/// One tool in the panel. Adding a tool means one new file that conforms to
/// this, plus one line in `ToolRegistry.all`.
protocol ShoshinTool {
    /// Stable key, persisted as the selected tool. Never rename a shipped id.
    var id: String { get }
    var title: String { get }
    var subtitle: String { get }
    var symbol: String { get }
    var tint: Color { get }
    @MainActor func makeView() -> AnyView
}

enum ToolRegistry {
    /// Panel order, top to bottom.
    @MainActor static let all: [any ShoshinTool] = [
        BreathingTool(),
        FocusTool(),
    ]
}
