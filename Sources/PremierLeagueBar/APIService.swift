import Foundation

actor APIService {
    static let shared = APIService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
    }

    func fetchMatches() async throws -> [Match] {
        let url = URL(string: "\(APIConfiguration.shared.backendBaseURL)/matches")!
        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(MatchResponse.self, from: data)
        return response.matches
    }

    func fetchStandings() async throws -> [StandingEntry] {
        let url = URL(string: "\(APIConfiguration.shared.backendBaseURL)/standings")!
        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(StandingsResponse.self, from: data)
        return response.standings.first?.table ?? []
    }
}
