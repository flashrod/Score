import Cocoa
import SwiftUI

@MainActor
class NotchController {
    private let panel: NSPanel
    private let hostingView: NSHostingView<NotchScoreView>
    private let data = NotchMatchData()

    init() {
        let view = NotchScoreView(data: data)
        hostingView = NSHostingView(rootView: view)

        let size = NSSize(width: 240, height: 50)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let screenWidth = NSScreen.main?.frame.width ?? 800
        let x = (screenWidth - size.width) / 2
        let y = screenFrame.maxY - size.height + 4

        panel = NSPanel(
            contentRect: NSRect(x: x, y: y, width: size.width, height: size.height),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hostingView
        panel.alphaValue = 0
    }

    func show(match: Match) {
        data.match = match
        guard panel.alphaValue < 1 else { return }
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard panel.alphaValue > 0 else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        } completionHandler: {
            self.panel.orderOut(nil)
        }
    }

    func update(match: Match) {
        data.match = match
    }
}

@MainActor
class NotchMatchData: ObservableObject {
    @Published var match: Match? {
        didSet {
            guard let match else { return }
            let h = match.score.fullTime?.home.flatMap(String.init) ?? "–"
            let a = match.score.fullTime?.away.flatMap(String.init) ?? "–"
            let status = match.isLive ? (match.minute.flatMap { "\($0)'" } ?? "LIVE") : match.statusDisplay
            label = "\(match.homeTeam.displayName)  \(h)-\(a)  \(match.awayTeam.displayName)  \(status)"
        }
    }
    @Published var label: String = ""
}

struct NotchScoreView: View {
    @ObservedObject var data: NotchMatchData

    var body: some View {
        HStack(spacing: 8) {
            if let match = data.match {
                Text(match.homeTeam.displayName)
                    .font(.system(size: 12, weight: .semibold))

                Text(scoreString(match))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(match.isLive ? Color.red : Color.gray.opacity(0.5)))

                Text(match.awayTeam.displayName)
                    .font(.system(size: 12, weight: .semibold))

                if let m = match.minute, !m.isEmpty, match.isLive {
                    Text("\(m)'")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.red)
                } else if match.isFinished {
                    Text("FT")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal, 8)
    }

    private func scoreString(_ match: Match) -> String {
        if let h = match.score.fullTime?.home, let a = match.score.fullTime?.away {
            return "\(h)-\(a)"
        }
        return "vs"
    }
}


