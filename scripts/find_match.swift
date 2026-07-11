#!/usr/bin/swift

import Foundation

guard let apiKey = ProcessInfo.processInfo.environment["FOOTBALL_DATA_API_KEY"], !apiKey.isEmpty else {
    print("FATAL: FOOTBALL_DATA_API_KEY not set")
    exit(1)
}

// Search across relevant competitions for Spain vs Belgium
let competitionIDs = [2000, 2001, 2006, 2018, 2019, 2021, 2015, 2002, 2003, 2007, 2008, 2009, 2013, 2014, 2016, 2017]
let searchTeams = ["Spain", "Belgium", "spain", "belgium", "ESP", "BEL", "España", "België"]

var request = URLRequest(url: URL(string: "https://api.football-data.org/v4/competitions")!)
request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")

guard let (data, _) = try? await URLSession.shared.data(for: request) else {
    print("Failed to fetch competitions")
    exit(1)
}

guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let comps = json["competitions"] as? [[String: Any]] else {
    print("Failed to parse competitions")
    exit(1)
}

print("Available competitions (\(comps.count)):")
for comp in comps {
    let id = comp["id"] as? Int ?? 0
    let name = comp["name"] as? String ?? ""
    let code = comp["code"] as? String ?? ""
    let plan = comp["plan"] as? String ?? ""
    print("  \(id): \(name) (\(code)) [\(plan)]")
}

// Search their matches
print("\nSearching for Spain vs Belgium...")
for compID in competitionIDs {
    let url = URL(string: "https://api.football-data.org/v4/competitions/\(compID)/matches?status=FINISHED,SCHEDULED,IN_PLAY,PAUSED")!
    var req = URLRequest(url: url)
    req.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
    req.timeoutInterval = 10
    
    guard let (data, _) = try? await URLSession.shared.data(for: req),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let matches = json["matches"] as? [[String: Any]] else {
        continue
    }
    
    for match in matches {
        let home = (match["homeTeam"] as? [String: Any])?["name"] as? String ?? ""
        let away = (match["awayTeam"] as? [String: Any])?["name"] as? String ?? ""
        let mid = match["id"] as? Int ?? 0
        let status = match["status"] as? String ?? ""
        let date = match["utcDate"] as? String ?? ""
        
        let homeLower = home.lowercased()
        let awayLower = away.lowercased()
        
        let isSpain = homeLower.contains("spain") || homeLower.contains("esp") || homeLower.contains("españa")
        let isBelgium = awayLower.contains("belgium") || awayLower.contains("bel") || awayLower.contains("belgië")
        let isSpainAway = awayLower.contains("spain") || awayLower.contains("esp") || awayLower.contains("españa")
        let isBelgiumHome = homeLower.contains("belgium") || homeLower.contains("bel") || homeLower.contains("belgië")
        
        if (isSpain && isBelgium) || (isSpainAway && isBelgiumHome) {
            print("  Match \(mid): \(home) vs \(away) — \(status) — \(date)")
        }
    }
}

print("\nDone.")
