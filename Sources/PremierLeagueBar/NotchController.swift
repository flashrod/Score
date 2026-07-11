import Cocoa
import SwiftUI

@MainActor
class NotchController: NSObject {
    private var window: NSWindow?
    private var hostView: NSHostingView<NotchScoreView>?
    private var isVisible = false

    func show(match: Match) {
        if window != nil, isVisible {
            withAnimation(.easeInOut(duration: 0.2)) {
                hostView?.rootView = NotchScoreView(match: match)
            }
            return
        }
        createWindow(match: match)
    }

    func hide() {
        guard isVisible else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window?.animator().alphaValue = 0
        } completionHandler: {
            self.window?.orderOut(nil)
            self.window = nil
            self.hostView = nil
            self.isVisible = false
        }
    }

    func update(match: Match) {
        guard isVisible, let hostView else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            hostView.rootView = NotchScoreView(match: match)
        }
    }

    private func createWindow(match: Match) {
        let view = NotchScoreView(match: match)
        hostView = NSHostingView(rootView: view)

        let size = NSSize(width: 200, height: 44)
        hostView?.frame = NSRect(origin: .zero, size: size)

        let screenFrame = NSApp.mainWindow?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let screenWidth = NSApp.mainWindow?.screen?.frame.width ?? NSScreen.main?.frame.width ?? 800
        let x = (screenWidth - size.width) / 2
        let y = screenFrame.maxY - size.height + 4

        let win = NSWindow(
            contentRect: NSRect(x: x, y: y, width: size.width, height: size.height),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.level = .statusBar
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.contentView = hostView
        win.alphaValue = 0

        window = win
        win.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            win.animator().alphaValue = 1
        }

        isVisible = true
    }
}

struct NotchScoreView: View {
    let match: Match

    var body: some View {
        HStack(spacing: 8) {
            Text(match.homeTeam.displayName)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)

            Text(scoreString)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(match.isLive ? Color.red : Color.secondary.opacity(0.6))
                .cornerRadius(6)

            Text(match.awayTeam.displayName)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)

            if match.isLive, let m = match.minute, !m.isEmpty {
                Text("\(m)'")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.red)
            } else if match.isFinished {
                Text("FT")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private var scoreString: String {
        if let h = match.score.fullTime?.home, let a = match.score.fullTime?.away {
            return "\(h)-\(a)"
        }
        return "vs"
    }
}
