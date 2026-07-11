import SwiftUI
import DynamicNotchKit

@MainActor
class NotchController {
    private var notch: DynamicNotch<NotchScoreView, EmptyView, EmptyView>?

    func show(match: Match) {
        let scoreView = NotchScoreView(match: match)
        notch = DynamicNotch(style: .floating) {
            scoreView
        }
        Task { await notch?.expand() }
    }

    func hide() {
        Task { await notch?.hide() }
        notch = nil
    }

    func update(match: Match) {
        let scoreView = NotchScoreView(match: match)
        notch = DynamicNotch(style: .floating) {
            scoreView
        }
        Task { await notch?.expand() }
    }
}

struct NotchScoreView: View {
    let match: Match

    var body: some View {
        HStack(spacing: 10) {
            Text(match.homeTeam.displayName)
                .font(.system(size: 13, weight: .semibold))

            Text(scoreString)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(match.isLive ? Color.red : Color.secondary.opacity(0.6))
                .cornerRadius(8)

            Text(match.awayTeam.displayName)
                .font(.system(size: 13, weight: .semibold))

            if match.isLive, let m = match.minute, !m.isEmpty {
                Text("\(m)'")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.red)
            } else if match.isFinished {
                Text("FT")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var scoreString: String {
        if let h = match.score.fullTime?.home, let a = match.score.fullTime?.away {
            return "\(h)-\(a)"
        }
        return "vs"
    }
}
