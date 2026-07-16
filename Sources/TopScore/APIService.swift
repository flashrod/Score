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

    func fetchOdds() async throws -> [Odds] {
        let url = URL(string: "\(APIConfiguration.shared.backendBaseURL)/odds")!
        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode([OddsAPIMatch].self, from: data)
        return response.compactMap { match -> Odds? in
            guard let market = match.bookmakers.first?.markets.first else { return nil }
            let outcomes = market.outcomes
            guard outcomes.count >= 3 else { return nil }
            let homeOutcome = outcomes.first { $0.name == match.homeTeam }
            let awayOutcome = outcomes.first { $0.name == match.awayTeam }
            let drawOutcome = outcomes.first { $0.name == "Draw" }
            guard let homePrice = homeOutcome?.price,
                  let drawPrice = drawOutcome?.price,
                  let awayPrice = awayOutcome?.price,
                  homePrice > 0, drawPrice > 0, awayPrice > 0
            else { return nil }
            return Odds(
                homeTeam: match.homeTeam,
                awayTeam: match.awayTeam,
                homeWinPercent: Int(round((1.0 / homePrice) * 100.0)),
                drawPercent: Int(round((1.0 / drawPrice) * 100.0)),
                awayWinPercent: Int(round((1.0 / awayPrice) * 100.0))
            )
        }
    }
}

private struct OddsAPIMatch: Decodable {
    let homeTeam: String
    let awayTeam: String
    let bookmakers: [OddsAPIMatchBookmaker]
}

private struct OddsAPIMatchBookmaker: Decodable {
    let markets: [OddsAPIMarket]
}

private struct OddsAPIMarket: Decodable {
    let outcomes: [OddsAPIOutcome]
}

private struct OddsAPIOutcome: Decodable {
    let name: String
    let price: Double
}
