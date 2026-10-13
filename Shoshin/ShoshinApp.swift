import SwiftUI
import AppKit

// Explicit @MainActor: Swift 5.9 (Xcode 15.2, which CI uses) does not infer it
// on App, so the @State initializers below would be nonisolated without it.
@main
@MainActor
struct ShoshinApp: App {
    @State private var focus = FocusTimer.shared
    @State private var measuredSize: CGSize = .zero

    var body: some Scene {
        MenuBarExtra {
            ToolPanel()
                .frame(width: Theme.panelWidth)
                .fixedSize()
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: PanelSizeKey.self, value: proxy.size)
                    }
                )
                // AppKit grows the panel but never shrinks it; the accordion
                // needs both. See PanelSizer and CLAUDE.md "Panel sizing".
                .background(PanelSizer(size: measuredSize, isPinned: false))
                .onPreferenceChange(PanelSizeKey.self) { measuredSize = $0 }
        } label: {
            MenuBarLabel(focus: focus)
        }
        .menuBarExtraStyle(.window)
    }
}

/// The enso, plus the focus countdown while a block runs.
struct MenuBarLabel: View {
    let focus: FocusTimer

    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: Theme.enso)
            if focus.isRunning {
                Text(FocusTimer.format(focus.remaining)).monospacedDigit()
            }
        }
    }
}

/// Accordion: every tool is a row. Choosing one collapses the others and opens
/// it in place. The choice persists, so the panel reopens on the same tool.
struct ToolPanel: View {
    @AppStorage("selectedTool") private var selectedID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(ToolRegistry.all.indices, id: \.self) { i in
                let tool = ToolRegistry.all[i]
                if selectedID.isEmpty || selectedID == tool.id {
                    ToolRow(tool: tool, isSelected: selectedID == tool.id) {
                        select(selectedID == tool.id ? "" : tool.id)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    if selectedID == tool.id {
                        tool.makeView()
                            .padding(.horizontal, 6)
                            .transition(.opacity)
                    }
                }
            }

            Divider().padding(.top, 4)
            footer
        }
        .padding(6)
        .focusEffectDisabled()
    }

    private var footer: some View {
        HStack {
            if selectedID.isEmpty {
                Text("Shoshin").foregroundStyle(.secondary)
            } else {
                Button { select("") } label: { Label("All tools", systemImage: "chevron.left") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
    }

    private func select(_ id: String) {
        withAnimation(.easeInOut(duration: 0.28)) { selectedID = id }
    }
}

struct ToolRow: View {
    let tool: any ShoshinTool
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tool.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(RoundedRectangle(cornerRadius: 6).fill(tool.tint))
                VStack(alignment: .leading, spacing: 1) {
                    Text(tool.title).font(.system(size: 13, weight: .medium))
                    Text(tool.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isSelected ? 90 : 0))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 7).fill(hovering ? Theme.rowFill : .clear))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .accessibilityLabel(tool.title)
        .accessibilityHint(isSelected ? "Return to all tools" : "Open")
    }
}
