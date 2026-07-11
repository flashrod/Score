#!/usr/bin/swift

import Foundation

// --- Config ---
let matchID: String
if CommandLine.arguments.count > 1 {
    matchID = CommandLine.arguments[1]
} else {
    matchID = "537384" // Spain vs Belgium, FINISHED, World Cup
}

let listOutput = "debug_list_v4_matches.json"
let matchOutput = "debug_match_v4_matches_id.json"

guard let apiKey = ProcessInfo.processInfo.environment["FOOTBALL_DATA_API_KEY"], !apiKey.isEmpty else {
    print("FATAL: FOOTBALL_DATA_API_KEY not set")
    exit(1)
}

// ----------------------------------------------------------------
// 1. Fetch individual match endpoint
// ----------------------------------------------------------------
print("=== 1. FETCHING /v4/matches/\(matchID) ===")
var reqMatch = URLRequest(url: URL(string: "https://api.football-data.org/v4/matches/\(matchID)")!)
reqMatch.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
reqMatch.timeoutInterval = 15

guard let (matchData, matchResp) = try? await URLSession.shared.data(for: reqMatch),
      let matchHTTP = matchResp as? HTTPURLResponse else {
    print("FATAL: Network error on individual match endpoint")
    exit(1)
}

print("HTTP \(matchHTTP.statusCode)")

guard matchHTTP.statusCode == 200,
      let matchJson = try? JSONSerialization.jsonObject(with: matchData) as? [String: Any] else {
    // Print the error response and exit
    if let errJson = try? JSONSerialization.jsonObject(with: matchData) as? [String: Any],
       let prettyData = try? JSONSerialization.data(withJSONObject: errJson, options: [.prettyPrinted, .sortedKeys]),
       let prettyStr = String(data: prettyData, encoding: .utf8) {
        print(prettyStr)
    }
    print("\nIndividual match endpoint returned \(matchHTTP.statusCode). Trying list endpoint fallback...\n")
    exit(1)
}

try? matchData.write(to: URL(fileURLWithPath: matchOutput))

if let prettyData = try? JSONSerialization.data(withJSONObject: matchJson, options: [.prettyPrinted, .sortedKeys]),
   let prettyStr = String(data: prettyData, encoding: .utf8) {
    print(prettyStr)
}
print("Saved to: \(matchOutput)")
print("")

// ----------------------------------------------------------------
// 2. Fetch competition list endpoint
// ----------------------------------------------------------------
print("=== 2. FETCHING /v4/competitions/.../matches ===")

// Determine which competition this match belongs to by checking a few
let matchCompetitionID = (matchJson["competition"] as? [String: Any])?["id"] as? Int ?? 2021

let listURL = URL(string: "https://api.football-data.org/v4/competitions/\(matchCompetitionID)/matches")!
var reqList = URLRequest(url: listURL)
reqList.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
reqList.timeoutInterval = 15

guard let (listData, listResp) = try? await URLSession.shared.data(for: reqList),
      let listHTTP = listResp as? HTTPURLResponse,
      listHTTP.statusCode == 200,
      let listJson = try? JSONSerialization.jsonObject(with: listData) as? [String: Any] else {
    print("FATAL: Could not fetch competition list endpoint")
    exit(1)
}

try? listData.write(to: URL(fileURLWithPath: listOutput))

if let prettyData = try? JSONSerialization.data(withJSONObject: listJson, options: [.prettyPrinted, .sortedKeys]),
   let prettyStr = String(data: prettyData, encoding: .utf8) {
    print(prettyStr)
}
print("Saved to: \(listOutput)")
print("")

// ----------------------------------------------------------------
// 3. Find the matching match in the list
// ----------------------------------------------------------------
let listMatch: [String: Any]
if let matches = listJson["matches"] as? [[String: Any]] {
    if let found = matches.first(where: { ($0["id"] as? Int) == Int(matchID) }) {
        listMatch = found
        print("Found match \(matchID) in list endpoint")
    } else {
        print("Match \(matchID) not found in list endpoint — using first match for comparison")
        listMatch = matches.first ?? [:]
    }
} else {
    listMatch = [:]
}
print("")

// ----------------------------------------------------------------
// 4. Compare fields
// ----------------------------------------------------------------
print("======================================================")
print("         FIELD COMPARISON REPORT")
print("======================================================")

func collectKeys(_ dict: [String: Any], prefix: String = "") -> Set<String> {
    var keys = Set<String>()
    for (k, v) in dict {
        let fullKey = prefix.isEmpty ? k : "\(prefix).\(k)"
        if let nested = v as? [String: Any] {
            keys.formUnion(collectKeys(nested, prefix: fullKey))
        } else if let arr = v as? [[String: Any]], let first = arr.first {
            keys.insert(fullKey)
            keys.formUnion(collectKeys(first, prefix: "\(fullKey)[]"))
        } else {
            keys.insert(fullKey)
        }
    }
    return keys
}

func flattenDict(_ dict: [String: Any], prefix: String = "") -> [String: String] {
    var result = [String: String]()
    for (k, v) in dict {
        let fullKey = prefix.isEmpty ? k : "\(prefix).\(k)"
        if let nested = v as? [String: Any] {
            result.merge(flattenDict(nested, prefix: fullKey)) { $1 }
        } else if let arr = v as? [Any] {
            if let firstDict = arr.first as? [String: Any] {
                result[fullKey] = "Array<Dictionary>"
                result.merge(flattenDict(firstDict, prefix: "\(fullKey)[0]")) { $1 }
            } else {
                result[fullKey] = "Array (\(arr.count) items)"
            }
        } else if v is NSNull {
            result[fullKey] = "null"
        } else {
            result[fullKey] = "\(type(of: v))"
        }
    }
    return result
}

let individualFlat = flattenDict(matchJson)
let listMatchFlat = flattenDict(listMatch)

let individualKeys = Set(individualFlat.keys)
let listKeys = Set(listMatchFlat.keys)

let onlyInIndividual = individualKeys.subtracting(listKeys).sorted()
let onlyInList = listKeys.subtracting(individualKeys).sorted()
let shared = individualKeys.intersection(listKeys).sorted()

print("\n--- Fields only in /v4/matches/\(matchID) (individual endpoint) ---")
if onlyInIndividual.isEmpty {
    print("  (none — individual endpoint has no unique fields)")
} else {
    for key in onlyInIndividual {
        print("  \(key): \(individualFlat[key] ?? "?")")
    }
}

print("\n--- Fields only in /v4/competitions/.../matches (list endpoint) ---")
if onlyInList.isEmpty {
    print("  (none — list endpoint has no unique fields)")
} else {
    for key in onlyInList {
        print("  \(key): \(listMatchFlat[key] ?? "?")")
    }
}

print("\n--- Shared fields (\(shared.count)) ---")
let individualOnlyCount = onlyInIndividual.count
let listOnlyCount = onlyInList.count

print("  Individual unique:  \(individualOnlyCount)")
print("  List unique:        \(listOnlyCount)")
print("  Shared:             \(shared.count)")

// Print value differences for shared fields
print("\n--- Value differences for shared fields ---")
var differences = 0
for key in shared {
    let iv = individualFlat[key] ?? ""
    let lv = listMatchFlat[key] ?? ""
    if iv != lv {
        differences += 1
        if differences <= 20 {
            print("  \(key)")
            print("    individual: \(iv)")
            print("    list:       \(lv)")
        }
    }
}
if differences == 0 {
    print("  (identical values for all shared fields)")
} else {
    print("  ... \(differences) total differences")
}

// ----------------------------------------------------------------
// 5. Dump specific match-level event/player fields
// ----------------------------------------------------------------
print("\n--- Special match-level event/player fields ---")
let eventFields = ["goalscorers", "bookings", "cards", "substitutions", "events",
                   "lineups", "incidents", "penalties", "shootout"]

print("  From individual endpoint:")
for field in eventFields {
    if let val = matchJson[field] {
        print("    \(field): PRESENT — \(typeDesc(val))")
    } else {
        print("    \(field): NOT PRESENT")
    }
}

print("  From list endpoint (match object):")
for field in eventFields {
    if let val = listMatch[field] {
        print("    \(field): PRESENT — \(typeDesc(val))")
    } else {
        print("    \(field): NOT PRESENT")
    }
}

// Also check for minute, attendance, venue, referees
print("\n  Additional fields:")
for field in ["minute", "attendance", "venue"] {
    let iv = matchJson[field] ?? "(not present)"
    let lv = listMatch[field] ?? "(not present)"
    print("    \(field): individual=\(typeDesc(iv as Any)), list=\(typeDesc(lv as Any))")
}

// Referees special: might be array
let refsI = matchJson["referees"] as? [Any] ?? []
let refsL = listMatch["referees"] as? [Any] ?? []
print("    referees: individual=Array (\(refsI.count) items), list=Array (\(refsL.count) items)")

print("\n======================================================")
print("                    END REPORT")
print("======================================================")

// MARK: - Helpers
func typeDesc(_ value: Any?) -> String {
    guard let value else { return "null" }
    switch value {
    case is String: return "String"
    case is Int: return "Int"
    case is Double: return "Double"
    case is Bool: return "Bool"
    case let arr as [Any]:
        if arr.isEmpty { return "Array (empty)" }
        if let first = arr.first as? [String: Any] {
            return "Array<Dictionary> (\(arr.count) items)"
        }
        return "Array (\(arr.count) items)"
    case let dict as [String: Any]:
        if dict.isEmpty { return "Dictionary (empty)" }
        return "Dictionary (\(dict.keys.count) keys)"
    default:
        return "\(type(of: value))"
    }
}
