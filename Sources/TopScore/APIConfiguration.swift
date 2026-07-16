import Foundation

final class APIConfiguration: @unchecked Sendable {
    static let shared = APIConfiguration()

    let backendBaseURL: String
    let oddsAPIKey: String
    let oddsBaseURL: String

    private init() {
        backendBaseURL = "https://score.flashrod.deno.net"
        if let url = Bundle.module.url(forResource: "APIKeys", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
           let dict = plist as? [String: Any] {
            oddsAPIKey = (dict["OddsAPIKey"] as? String) ?? ""
            oddsBaseURL = (dict["OddsBaseURL"] as? String) ?? "https://api.the-odds-api.com/v4"
        } else {
            oddsAPIKey = ""
            oddsBaseURL = "https://api.the-odds-api.com/v4"
        }
    }
}
