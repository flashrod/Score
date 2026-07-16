import Foundation

actor APIService {
    static let shared = APIService()

    private let base = "https://api.football-data.org/v4"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["X-Auth-Token": APIConfiguration.shared.footballDataAPIKey]
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
    }

    func fetchMatches() async throws -> [Match] {
        let url = URL(string: "\(base)/competitions/PL/matches?status=SCHEDULED,TIMED,IN_PLAY,PAUSED,FINISHED")!
        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(MatchResponse.self, from: data)
        return response.matches
    }

    func fetchStandings() async throws -> [StandingEntry] {
        let url = URL(string: "\(base)/competitions/PL/standings")!
        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(StandingsResponse.self, from: data)
        return response.standings.first?.table ?? []
    }
}
