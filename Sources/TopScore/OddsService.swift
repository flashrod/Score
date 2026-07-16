import Foundation

actor OddsService {
    static let shared = OddsService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func fetchOdds() async throws -> [Odds] {
        let apiKey = APIConfiguration.shared.oddsAPIKey
        guard !apiKey.isEmpty else { return [] }

        let base = APIConfiguration.shared.oddsBaseURL
        var components = URLComponents(string: "\(base)/sports/soccer_epl/odds/")!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "regions", value: "uk"),
            URLQueryItem(name: "markets", value: "h2h"),
        ]

        guard let url = components.url else { return [] }

        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode([APIMatch].self, from: data)

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

private struct APIMatch: Decodable {
    let homeTeam: String
    let awayTeam: String
    let bookmakers: [APIMatchBookmaker]
}

private struct APIMatchBookmaker: Decodable {
    let markets: [APIMarket]
}

private struct APIMarket: Decodable {
    let outcomes: [APIOutcome]
}

private struct APIOutcome: Decodable {
    let name: String
    let price: Double
}
