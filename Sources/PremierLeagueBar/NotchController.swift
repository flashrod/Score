import SwiftUI
import DynamicNotchKit

@MainActor
class NotchController: ObservableObject {
    @Published var homeTeam = ""
    @Published var awayTeam = ""
    @Published var homeScore: Int?
    @Published var awayScore: Int?
    @Published var minute = ""
    @Published var isLive = false
    @Published var isFinished = false

    private var notch: DynamicNotch<ExpandedScoreView, CompactScoreLeading, CompactScoreTrailing>?

    func show(match: Match) {
        apply(match)
        if notch == nil {
            notch = DynamicNotch(hoverBehavior: .all, style: .notch) {
                ExpandedScoreView(controller: self)
            } compactLeading: {
                CompactScoreLeading(controller: self)
            } compactTrailing: {
                CompactScoreTrailing(controller: self)
            }
            notch?.transitionConfiguration.skipIntermediateHides = true
        }
        Task { await notch?.compact() }
    }

    func update(match: Match) {
        let oldHome = homeScore
        let oldAway = awayScore
        apply(match)
        if isLive, let newH = homeScore, let newA = awayScore,
           newH > (oldHome ?? -1) || newA > (oldAway ?? -1) {
            Task { await goalScored() }
        }
    }

    func hide() {
        Task { await notch?.hide() }
    }

    private func goalScored() async {
        await notch?.expand()
        try? await Task.sleep(for: .seconds(2))
        await notch?.compact()
    }

    private func apply(_ match: Match) {
        homeTeam = match.homeTeam.shortDisplayName
        awayTeam = match.awayTeam.shortDisplayName
        homeScore = match.score.fullTime?.home
        awayScore = match.score.fullTime?.away
        minute = match.minute ?? ""
        isLive = match.isLive
        isFinished = match.isFinished
    }
}

struct CompactScoreLeading: View {
    @ObservedObject var controller: NotchController

    var body: some View {
        HStack(spacing: 2) {
            Text(controller.homeTeam)
                .fontWeight(.medium)
            if let h = controller.homeScore, let a = controller.awayScore {
                Text("\(h)-\(a)")
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
        }
        .font(.system(size: 10))
        .foregroundColor(.white)
    }
}

struct CompactScoreTrailing: View {
    @ObservedObject var controller: NotchController

    var body: some View {
        HStack(spacing: 4) {
            Text(controller.awayTeam)
                .fontWeight(.medium)
            if controller.isLive, !controller.minute.isEmpty {
                Text(controller.minute)
                    .fontWeight(.bold)
                    .monospacedDigit()
            } else if controller.isFinished {
                Text("FT")
                    .fontWeight(.bold)
            }
        }
        .font(.system(size: 10))
        .foregroundColor(.white)
    }
}

struct ExpandedScoreView: View {
    @ObservedObject var controller: NotchController

    var body: some View {
        VStack(spacing: 4) {
            Text("\(controller.homeTeam) \(controller.homeScore ?? 0) - \(controller.awayScore ?? 0) \(controller.awayTeam)")
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
            if controller.isLive, !controller.minute.isEmpty {
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 6, height: 6)
                    Text("\(controller.minute)'")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
        }
        .foregroundColor(.white)
        .padding(.vertical, 4)
    }
}
