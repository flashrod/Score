import SwiftUI
import DynamicNotchKit

@MainActor
class NotchController: ObservableObject {
    @Published var homeTeam = ""
    @Published var awayTeam = ""
    @Published var homeCrest: String?
    @Published var awayCrest: String?
    @Published var homeScore: Int?
    @Published var awayScore: Int?
    @Published var minute = ""
    @Published var isLive = false
    @Published var isFinished = false
    @Published var subtitle = ""

    private var notch: DynamicNotch<ExpandedScoreView, CompactScoreLeading, CompactScoreTrailing>?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM · HH:mm"
        return f
    }()

    private let isoFormatter = ISO8601DateFormatter()

    func show(match: Match, nextMatch: Match? = nil, pinnedIsLive: Bool = false) {
        apply(match)
        updateSubtitle(match: match, nextMatch: nextMatch, pinnedIsLive: pinnedIsLive)
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
        Task { await notch?.expand() }
    }

    func update(match: Match, nextMatch: Match? = nil, pinnedIsLive: Bool = false) {
        let oldHome = homeScore
        let oldAway = awayScore
        apply(match)
        updateSubtitle(match: match, nextMatch: nextMatch, pinnedIsLive: pinnedIsLive)
        if isLive, let newH = homeScore, let newA = awayScore,
           newH > (oldHome ?? -1) || newA > (oldAway ?? -1) {
            Task { await goalScored() }
        }
    }

    func hide() {
        Task { await notch?.hide() }
    }

    private func goalScored() async {
        await notch?.hide()
        try? await Task.sleep(for: .seconds(0.3))
        await notch?.expand()
    }

    private func apply(_ match: Match) {
        homeTeam = match.homeTeam.displayName
        awayTeam = match.awayTeam.displayName
        homeCrest = match.homeTeam.crest
        awayCrest = match.awayTeam.crest
        homeScore = match.score.fullTime?.home
        awayScore = match.score.fullTime?.away
        minute = match.minute ?? ""
        isLive = match.isLive
        isFinished = match.isFinished
    }

    private func updateSubtitle(match: Match, nextMatch: Match?, pinnedIsLive: Bool) {
        if pinnedIsLive || match.isLive {
            if let h = match.score.fullTime?.home, let a = match.score.fullTime?.away {
                let m = match.minute ?? ""
                subtitle = "\(h)-\(a) · \(m)'"
            } else {
                subtitle = "Kick off"
            }
        } else {
            let next: Match? = nextMatch ?? match
            if let next, let date = isoFormatter.date(from: next.utcDate) {
                subtitle = "\(next.homeTeam.shortDisplayName) vs \(next.awayTeam.shortDisplayName) · \(dateFormatter.string(from: date))"
            } else {
                subtitle = ""
            }
        }
    }
}

struct CompactScoreLeading: View {
    @ObservedObject var controller: NotchController

    var body: some View {
        HStack(spacing: 6) {
            crestImage(controller.homeCrest)
            Text(controller.homeTeam)
                .font(.system(size: 16, weight: .bold))
            if controller.isLive, let h = controller.homeScore {
                Text("\(h)")
                    .font(.system(size: 15, weight: .bold))
                    .monospacedDigit()
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func crestImage(_ url: String?) -> some View {
        if let url = url.flatMap({ URL(string: $0) }) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit()
                default:
                    Color.clear
                }
            }
            .frame(width: 18, height: 18)
        }
    }
}

struct CompactScoreTrailing: View {
    @ObservedObject var controller: NotchController

    var body: some View {
        HStack(spacing: 6) {
            if controller.isLive, let a = controller.awayScore {
                Text("\(a)")
                    .font(.system(size: 15, weight: .bold))
                    .monospacedDigit()
            }
            Text(controller.awayTeam)
                .font(.system(size: 16, weight: .bold))
            crestImage(controller.awayCrest)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func crestImage(_ url: String?) -> some View {
        if let url = url.flatMap({ URL(string: $0) }) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit()
                default:
                    Color.clear
                }
            }
            .frame(width: 18, height: 18)
        }
    }
}

struct ExpandedScoreView: View {
    @ObservedObject var controller: NotchController

    var body: some View {
        VStack(spacing: 4) {
            if controller.isLive {
                if !controller.minute.isEmpty {
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 5, height: 5)
                        Text("\(controller.minute)'")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
                if let h = controller.homeScore, let a = controller.awayScore {
                    Text("\(h)-\(a)")
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                }
            } else if controller.isFinished {
                Text("Full Time")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                if let h = controller.homeScore, let a = controller.awayScore {
                    Text("\(h)-\(a)")
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                }
            } else {
                Text("Next Game")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
                Text(controller.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
