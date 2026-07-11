import SwiftUI
import DynamicNotchKit

@MainActor
final class DynamicNotchPresenter: ObservableObject {
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

    @Published private(set) var animatingEvent: AnimatingEvent?

    enum AnimatingEvent: Equatable {
        case goal(team: MatchEvent.GoalTeam, score: String)
        case statusChange(String)
    }

    private var notch: DynamicNotch<ExpandedScoreView, CompactScoreLeading, CompactScoreTrailing>?
    private let eventQueue: EventQueue
    private var animationTask: Task<Void, Never>?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM · HH:mm"
        return f
    }()

    private let isoFormatter = ISO8601DateFormatter()

    init(eventQueue: EventQueue) {
        self.eventQueue = eventQueue
        eventQueue.setHandler { [weak self] event in
            self?.receive(event)
        }
    }

    func show(match: Match, nextMatch: Match?) {
        apply(match)
        updateSubtitle(match: match, nextMatch: nextMatch)
        if notch == nil {
            notch = DynamicNotch(hoverBehavior: .all, style: .notch) {
                ExpandedScoreView(presenter: self)
            } compactLeading: {
                CompactScoreLeading(presenter: self)
            } compactTrailing: {
                CompactScoreTrailing(presenter: self)
            }
            notch?.transitionConfiguration.skipIntermediateHides = true
        }
        animatingEvent = nil
        Task { await notch?.compact() }
    }

    func update(match: Match, nextMatch: Match?) {
        apply(match)
        updateSubtitle(match: match, nextMatch: nextMatch)
    }

    func hide() {
        animationTask?.cancel()
        animationTask = nil
        animatingEvent = nil
        Task { await notch?.hide() }
    }

    // MARK: - Event Handling

    private func receive(_ event: MatchEvent) {
        switch event {
        case .matchPinned, .matchUnpinned:
            animatingEvent = nil
        default:
            runAnimation(for: event)
        }
    }

    private func runAnimation(for event: MatchEvent) {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            guard notch != nil else { return }

            switch event {
            case .goal:
                animatingEvent = .goal(
                    team: event.goalTeam,
                    score: "\(homeScore ?? 0)-\(awayScore ?? 0)"
                )
            case .kickoff:
                animatingEvent = .statusChange("Kick Off")
            case .halftime:
                animatingEvent = .statusChange("Half Time")
            case .secondHalfStarted:
                animatingEvent = .statusChange("Second Half")
            case .fulltime:
                animatingEvent = .statusChange("Full Time")
            case .matchPinned, .matchUnpinned:
                break
            }

            await notch?.expand()

            let duration: UInt64 = event.isGoal ? 3_000_000_000 : 2_000_000_000
            try? await Task.sleep(nanoseconds: duration)

            guard !Task.isCancelled else { return }
            animatingEvent = nil
            await notch?.compact()
        }
    }

    // MARK: - State

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

    private func updateSubtitle(match: Match, nextMatch: Match?) {
        if match.isLive || match.isFinished {
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

// MARK: - Compact Leading (left side of notch)

struct CompactScoreLeading: View {
    @ObservedObject var presenter: DynamicNotchPresenter

    var body: some View {
        HStack(spacing: 6) {
            crestImage(presenter.homeCrest)
            Text(presenter.homeTeam)
                .font(.system(size: 16, weight: .bold))
            if presenter.isLive, let h = presenter.homeScore {
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

// MARK: - Compact Trailing (right side of notch)

struct CompactScoreTrailing: View {
    @ObservedObject var presenter: DynamicNotchPresenter

    var body: some View {
        HStack(spacing: 6) {
            if presenter.isLive, let a = presenter.awayScore {
                Text("\(a)")
                    .font(.system(size: 15, weight: .bold))
                    .monospacedDigit()
            }
            Text(presenter.awayTeam)
                .font(.system(size: 16, weight: .bold))
            crestImage(presenter.awayCrest)
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

// MARK: - Expanded View (below notch)

struct ExpandedScoreView: View {
    @ObservedObject var presenter: DynamicNotchPresenter

    var body: some View {
        Group {
            if let animation = presenter.animatingEvent {
                AnimationContentView(animation: animation)
            } else if presenter.isLive {
                liveContent
            } else if presenter.isFinished {
                finishedContent
            } else {
                upcomingContent
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var liveContent: some View {
        VStack(spacing: 4) {
            if !presenter.minute.isEmpty {
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 5, height: 5)
                    Text("\(presenter.minute)'")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            if let h = presenter.homeScore, let a = presenter.awayScore {
                Text("\(h)-\(a)")
                    .font(.system(size: 20, weight: .bold))
                    .monospacedDigit()
            }
        }
    }

    private var finishedContent: some View {
        VStack(spacing: 4) {
            Text("Full Time")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            if let h = presenter.homeScore, let a = presenter.awayScore {
                Text("\(h)-\(a)")
                    .font(.system(size: 20, weight: .bold))
                    .monospacedDigit()
            }
        }
    }

    private var upcomingContent: some View {
        VStack(spacing: 4) {
            Text("Next Game")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
            Text(presenter.subtitle)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Animation Content

private struct AnimationContentView: View {
    let animation: DynamicNotchPresenter.AnimatingEvent

    var body: some View {
        VStack(spacing: 6) {
            switch animation {
            case .goal(_, let score):
                Text("\u{26BD} GOAL")
                    .font(.system(size: 20, weight: .bold))
                Text(score)
                    .font(.system(size: 16, weight: .medium))
                    .monospacedDigit()
            case .statusChange(let text):
                Text(text)
                    .font(.system(size: 20, weight: .bold))
            }
        }
    }
}
