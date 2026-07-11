import Foundation

@MainActor
class MatchViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var standings: [StandingEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshed: Date?

    private let api = APIService.shared
    private var refreshTask: Task<Void, Never>?

    func startPolling() {
        refreshTask?.cancel()
        refreshTask = Task {
            await refresh()
            while !Task.isCancelled {
                let interval: UInt64 = hasLiveMatches ? 15_000_000_000 : 60_000_000_000
                try? await Task.sleep(nanoseconds: interval)
                await refresh()
            }
        }
    }

    func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            async let matchesTask = api.fetchMatches()
            async let standingsTask = api.fetchStandings()
            let (fetchedMatches, fetchedStandings) = await (try matchesTask, try standingsTask)
            matches = fetchedMatches
            standings = fetchedStandings
            lastRefreshed = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var liveMatches: [Match] {
        matches.filter { $0.isLive }.sorted { $0.utcDate < $1.utcDate }
    }

    var upcomingMatches: [Match] {
        matches.filter { !$0.isLive && !$0.isFinished }.sorted { $0.utcDate < $1.utcDate }
    }

    var finishedMatches: [Match] {
        matches.filter { $0.isFinished }.sorted { $0.utcDate > $1.utcDate }
    }

    var hasLiveMatches: Bool {
        !liveMatches.isEmpty
    }

    var liveMatchCount: Int {
        liveMatches.count
    }

    @Published var pinnedMatchId: Int?

    var pinnedMatch: Match? {
        guard let id = pinnedMatchId else { return nil }
        return matches.first { $0.id == id }
    }

    func togglePin(_ matchId: Int) {
        if pinnedMatchId == matchId {
            pinnedMatchId = nil
        } else {
            pinnedMatchId = matchId
        }
    }

    var menuBarLabel: String {
        if let pinned = pinnedMatch {
            let home = pinned.homeTeam.displayName
            let away = pinned.awayTeam.displayName
            if let h = pinned.score.fullTime?.home, let a = pinned.score.fullTime?.away {
                return "\(home) \(h)-\(a) \(away)"
            }
            return "\(home) vs \(away)"
        }
        if hasLiveMatches {
            return "\(liveMatchCount) LIVE"
        }
        return "PL"
    }
}
