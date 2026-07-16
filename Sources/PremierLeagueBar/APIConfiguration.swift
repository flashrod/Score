import Foundation

final class APIConfiguration: @unchecked Sendable {
    static let shared = APIConfiguration()

    let footballDataAPIKey: String
    let oddsAPIKey: String
    let oddsBaseURL: String

    private init() {
        guard let url = Bundle.module.url(forResource: "APIKeys", withExtension: "plist") else {
            fatalError("""
                APIKeys.plist not found. Create Sources/PremierLeagueBar/Resources/APIKeys.plist with:
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>FootballDataAPIKey</key>
                    <string>YOUR_API_KEY</string>
                </dict>
                </plist>
                """)
        }

        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
            guard let dict = plist as? [String: Any] else {
                fatalError("APIKeys.plist is not a valid dictionary.")
            }

            guard let key = dict["FootballDataAPIKey"] as? String, !key.isEmpty else {
                fatalError("""
                    FootballDataAPIKey in APIKeys.plist is empty or missing.
                    Get a free key at https://www.football-data.org/ and add it to Resources/APIKeys.plist.
                    """)
            }

            footballDataAPIKey = key
            oddsAPIKey = (dict["OddsAPIKey"] as? String) ?? ""
            oddsBaseURL = (dict["OddsBaseURL"] as? String) ?? "https://api.the-odds-api.com/v4"
        } catch {
            fatalError("Failed to read APIKeys.plist: \(error.localizedDescription)")
        }
    }
}
