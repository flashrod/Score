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
    @Published var homeWinPercent: Int?
    @Published var drawPercent: Int?
    @Published var awayWinPercent: Int?

    @Published private(set) var animatingEvent: AnimatingEvent?

    enum AnimatingEvent: Equatable {
        case goal(team: MatchEvent.GoalTeam, score: String)
        case statusChange(String)
    }

    private var notch: DynamicNotch<ExpandedScoreView, CompactScoreLeading, CompactScoreTrailing>?
    private let eventQueue: EventQueue

    private var pendingEvents: [MatchEvent] = []
    private var processingTask: Task<Void, Never>?
    private var hoverExitTask: Task<Void, Never>?

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
        Task { @MainActor in await notch?.compact() }
    }

    func update(match: Match, nextMatch: Match?) {
        apply(match)
        updateSubtitle(match: match, nextMatch: nextMatch)
    }

    func toggleNotch() {
        guard let notch else { return }
        Task { @MainActor in
            switch notch.state {
            case .expanded: await notch.compact()
            case .compact, .hidden: await notch.expand()
            }
        }
    }

    func hide() {
        processingTask?.cancel()
        processingTask = nil
        hoverExitTask?.cancel()
        hoverExitTask = nil
        animatingEvent = nil
        pendingEvents.removeAll()
        let currentNotch = notch
        notch = nil
        Task { await currentNotch?.hide() }
    }

    /// DynamicNotchKit's hover configuration only affects appearance; it does not
    /// expand or compact the notch. We manage the pre-match hover interaction here.
    func updatePreMatchHover(_ isHovering: Bool) {
        guard !isLive, !isFinished, animatingEvent == nil else { return }

        hoverExitTask?.cancel()
        if isHovering {
            Task { @MainActor in await notch?.expand() }
        } else {
            // Allow the pointer to travel from the compact teams into the expanded
            // panel without causing a visible close/reopen flicker.
            hoverExitTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                await self?.notch?.compact()
            }
        }
    }

    // MARK: - Event Handling

    private func receive(_ event: MatchEvent) {
        switch event {
        case .matchPinned, .matchUnpinned:
            break
        default:
            pendingEvents.append(event)
            processQueue()
        }
    }

    private func processQueue() {
        guard processingTask == nil else { return }

        processingTask = Task { @MainActor in
            while !pendingEvents.isEmpty, !Task.isCancelled {
                let event = pendingEvents.removeFirst()
                await animate(event)
            }
            processingTask = nil
        }
    }

    private func animate(_ event: MatchEvent) async {
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
            return
        }

        await notch?.expand()

        let duration: UInt64 = event.isGoal ? 3_000_000_000 : 2_000_000_000
        try? await Task.sleep(nanoseconds: duration)

        guard !Task.isCancelled else { return }
        animatingEvent = nil
        await notch?.compact()
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

    private func updateSubtitle(match: Match, nextMatch _: Match?) {
        if match.isLive || match.isFinished {
            if let h = match.score.fullTime?.home, let a = match.score.fullTime?.away {
                let m = match.minute ?? ""
                subtitle = "\(h)-\(a) · \(m)'"
            } else {
                subtitle = "Kick off"
            }
        } else {
            if let date = isoFormatter.date(from: match.utcDate) {
                subtitle = "\(match.homeTeam.shortDisplayName) vs \(match.awayTeam.shortDisplayName) · \(dateFormatter.string(from: date))"
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
            CrestImage(presenter.homeCrest, width: 18, height: 18)
            Text(presenter.homeTeam)
                .font(.system(size: 16, weight: .bold))
            if presenter.isLive, let h = presenter.homeScore {
                Text("\(h)")
                    .font(.system(size: 15, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: h)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .onHover(perform: presenter.updatePreMatchHover)
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
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: a)
            }
            Text(presenter.awayTeam)
                .font(.system(size: 16, weight: .bold))
            CrestImage(presenter.awayCrest, width: 18, height: 18)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .onHover(perform: presenter.updatePreMatchHover)
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
        .onHover(perform: presenter.updatePreMatchHover)
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
                HStack(spacing: 0) {
                    Text("\(h)")
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: h)
                    Text("-")
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                    Text("\(a)")
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: a)
                }
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
        Group {
            if let h = presenter.homeWinPercent,
               let d = presenter.drawPercent,
               let a = presenter.awayWinPercent {
                OddsBreakdownView(
                    homePercent: h,
                    drawPercent: d,
                    awayPercent: a,
                    subtitle: presenter.subtitle
                )
            } else {
                PreMatchOverviewView(
                    homeTeam: presenter.homeTeam,
                    awayTeam: presenter.awayTeam,
                    homeCrest: presenter.homeCrest,
                    awayCrest: presenter.awayCrest,
                    subtitle: presenter.subtitle
                )
            }
        }
        .frame(width: 280)
        .frame(minHeight: 118)
    }
}

// MARK: - Pre-match odds

private struct PreMatchOverviewView: View {
    let homeTeam: String
    let awayTeam: String
    let homeCrest: String?
    let awayCrest: String?
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Text("UP NEXT")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundColor(.white.opacity(0.48))

            HStack(spacing: 12) {
                crestImage(homeCrest)
                Text(homeTeam)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("VS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                Text(awayTeam)
                    .frame(maxWidth: .infinity, alignment: .leading)
                crestImage(awayCrest)
            }
            .font(.system(size: 12, weight: .semibold))
            .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.58))

            Text("Market odds will appear here when available")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.38))
        }
    }

    private func crestImage(_ urlString: String?) -> some View {
        CrestImage(urlString, width: 18, height: 18)
    }
}

private struct OddsBreakdownView: View {
    let homePercent: Int
    let drawPercent: Int
    let awayPercent: Int
    let subtitle: String

    private let homeColor = Color(red: 0.26, green: 0.68, blue: 1.0)
    private let drawColor = Color.white.opacity(0.34)
    private let awayColor = Color(red: 1.0, green: 0.53, blue: 0.25)

    private var probabilities: (home: Int, draw: Int, away: Int) {
        let total = max(homePercent + drawPercent + awayPercent, 1)
        let home = Int((Double(homePercent) / Double(total) * 100).rounded())
        let draw = Int((Double(drawPercent) / Double(total) * 100).rounded())
        return (home, draw, max(0, 100 - home - draw))
    }

    var body: some View {
        VStack(spacing: 9) {
            Text("MATCH ODDS")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundColor(.white.opacity(0.48))

            HStack(spacing: 0) {
                probabilityColumn(label: "HOME WIN", probability: probabilities.home, color: homeColor)
                probabilityColumn(label: "DRAW", probability: probabilities.draw, color: .white)
                probabilityColumn(label: "AWAY WIN", probability: probabilities.away, color: awayColor)
            }

            GeometryReader { geometry in
                HStack(spacing: 2) {
                    barSegment(homeColor, fraction: probabilities.home, in: geometry.size.width)
                    barSegment(drawColor, fraction: probabilities.draw, in: geometry.size.width)
                    barSegment(awayColor, fraction: probabilities.away, in: geometry.size.width)
                }
            }
            .frame(height: 5)
            .clipShape(Capsule())

            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(width: 280)
    }

    private func probabilityColumn(label: String, probability: Int, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.46))
            Text("\(probability)%")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    private func barSegment(_ color: Color, fraction: Int, in availableWidth: CGFloat) -> some View {
        color.frame(width: max(0, availableWidth * CGFloat(fraction) / 100 - 2))
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
