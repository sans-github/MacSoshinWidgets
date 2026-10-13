import SwiftUI
import AppKit
import Observation

/// A timed block of deep work. The countdown lives in `FocusTimer.shared`, not
/// in the view, so it keeps running with the panel closed and drives the menu
/// bar label too.
struct FocusTool: ShoshinTool {
    let id = "focus"
    let title = "Focus Block"
    let subtitle = "Timed deep work"
    let symbol = "timer"
    let tint = Theme.amber

    func makeView() -> AnyView { AnyView(FocusView(timer: FocusTimer.shared)) }
}

@MainActor
@Observable
final class FocusTimer {
    static let shared = FocusTimer()
    static let presets = [15, 25, 50, 90]

    /// Persisted, so a block survives a relaunch. Stored as seconds since 1970
    /// because UserDefaults has no optional Date; 0 means no block running.
    private(set) var endDate: Date? {
        didSet { defaults.set(endDate?.timeIntervalSince1970 ?? 0, forKey: "focusEnd") }
    }
    var minutes: Int {
        didSet { defaults.set(minutes, forKey: "focusMinutes") }
    }
    /// Ticks once a second while a block runs; views read it to redraw.
    private(set) var now = Date()

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var ticker: Timer?

    private init() {
        let stored = defaults.integer(forKey: "focusMinutes")
        minutes = stored > 0 ? stored : 25
        let end = defaults.double(forKey: "focusEnd")
        if end > 0, Date(timeIntervalSince1970: end) > Date() {
            endDate = Date(timeIntervalSince1970: end)
            startTicking()
        }
    }

    var isRunning: Bool { endDate != nil }

    var remaining: TimeInterval { max(0, (endDate ?? now).timeIntervalSince(now)) }

    /// 0...1 through the current block.
    var progress: Double {
        guard isRunning else { return 0 }
        return min(1, max(0, 1 - remaining / Double(minutes * 60)))
    }

    func start() {
        now = Date()
        endDate = now.addingTimeInterval(Double(minutes * 60))
        startTicking()
    }

    func end() {
        ticker?.invalidate()
        ticker = nil
        endDate = nil
    }

    private func startTicking() {
        ticker?.invalidate()
        // .common, so the countdown keeps moving while a menu is tracking.
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        now = Date()
        if let endDate, now >= endDate {
            NSSound(named: "Glass")?.play()
            end()
        }
    }

    static func format(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

struct FocusView: View {
    let timer: FocusTimer
    private let segments = 24

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(FocusTimer.format(timer.isRunning ? timer.remaining : Double(timer.minutes * 60)))
                    .font(.system(size: 30, weight: .light, design: .monospaced))
                    .monospacedDigit()
                    .opacity(timer.isRunning ? 1 : 0.4)
                    .lineLimit(1)
                    .fixedSize()

                VStack(alignment: .leading, spacing: 6) {
                    if timer.isRunning { segmentBar }
                    caption
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(timer.isRunning ? "end focus" : "start focus") {
                    timer.isRunning ? timer.end() : timer.start()
                }
                .controlSize(.large)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.rowFill))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.separator))

            if !timer.isRunning { presets }
        }
        .padding(.vertical, 4)
    }

    private var segmentBar: some View {
        let filled = Int((Double(segments) * timer.progress).rounded())
        return HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < filled ? Theme.amber : Color.primary.opacity(0.12))
                    .frame(height: 9)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(timer.progress * 100)) percent")
    }

    private var caption: some View {
        var text = Text("focus block").foregroundColor(.primary)
            + Text(" · \(timer.minutes) min")
        if let end = timer.endDate {
            text = text + Text(" · ends \(end.formatted(date: .omitted, time: .shortened).lowercased())")
        }
        return text
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .lineLimit(1)
    }

    private var presets: some View {
        HStack(spacing: 6) {
            ForEach(FocusTimer.presets, id: \.self) { m in
                Button("\(m)m") { timer.minutes = m }
                    .buttonStyle(.bordered)
                    .tint(m == timer.minutes ? Theme.amber : nil)
            }
        }
    }
}
