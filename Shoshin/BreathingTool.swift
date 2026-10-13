import SwiftUI

/// Box breathing, 4 seconds per side: in, hold, out, hold.
struct BreathingTool: ShoshinTool {
    let id = "breathing"
    let title = "Box Breathing"
    let subtitle = "4 in · 4 hold · 4 out · 4 hold"
    let symbol = "wind"
    let tint = Theme.breath

    func makeView() -> AnyView { AnyView(BreathingView()) }
}

enum BreathPhase: Int, CaseIterable {
    case inhale, holdFull, exhale, holdEmpty

    static let seconds: Double = 4
    static let cycle = seconds * Double(allCases.count)

    var label: String {
        switch self {
        case .inhale: return "Breathe in"
        case .exhale: return "Breathe out"
        case .holdFull, .holdEmpty: return "Hold"
        }
    }

    /// How full the lungs are, 0...1, at `progress` (0...1) through this phase.
    /// Cosine easing, so the wave slows into each turn instead of snapping.
    func fullness(at progress: Double) -> Double {
        let eased = 0.5 - 0.5 * cos(.pi * progress)
        switch self {
        case .inhale: return eased
        case .holdFull: return 1
        case .exhale: return 1 - eased
        case .holdEmpty: return 0
        }
    }
}

struct BreathingView: View {
    /// Reset on every appearance, so opening the tool always starts on an inhale.
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = max(0, context.date.timeIntervalSince(start))
            let inCycle = elapsed.truncatingRemainder(dividingBy: BreathPhase.cycle)
            let phase = BreathPhase(rawValue: Int(inCycle / BreathPhase.seconds)) ?? .inhale
            let inPhase = inCycle.truncatingRemainder(dividingBy: BreathPhase.seconds)
            let fullness = phase.fullness(at: inPhase / BreathPhase.seconds)

            VStack(spacing: 6) {
                Canvas { gc, size in
                    gc.stroke(wave(in: size, fullness: fullness, time: elapsed),
                              with: .color(Theme.breath),
                              style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
                .frame(height: 120)

                HStack(spacing: 6) {
                    Text(phase.label)
                        .font(.system(size: 15, weight: .medium))
                    Text("\(Int(BreathPhase.seconds) - Int(inPhase))")
                        .font(.system(size: 15).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text("Cycle \(Int(elapsed / BreathPhase.cycle) + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .onAppear { start = Date() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Box breathing guide")
    }

    /// A single arch that rises with the inhale and sinks with the exhale. The
    /// small travelling ripple keeps the holds visibly alive; it is dropped
    /// under Reduce Motion.
    private func wave(in size: CGSize, fullness: Double, time: Double) -> Path {
        let inset: CGFloat = 10
        let span = size.width - inset * 2
        let amplitude = (size.height - 24) * CGFloat(fullness - 0.5)
        let ripple: CGFloat = reduceMotion ? 0 : 4
        var path = Path()
        for x in stride(from: inset, through: size.width - inset, by: 2) {
            let u = (x - inset) / span
            let y = size.height / 2
                - amplitude * sin(.pi * u)
                + ripple * sin(x / 15 + CGFloat(time) * 2)
            if x == inset { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }
}
