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
                try? await Task.sleep(nanoseconds: 60_000_000_000)
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
}
