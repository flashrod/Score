import SwiftUI

struct StandingsView: View {
    let standings: [StandingEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("STANDINGS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 6)

            HStack(spacing: 0) {
                Text("#").frame(width: 24, alignment: .leading)
                Text("Club").frame(maxWidth: .infinity, alignment: .leading)
                Text("P").frame(width: 24)
                Text("W").frame(width: 24)
                Text("D").frame(width: 24)
                Text("L").frame(width: 24)
                Text("GD").frame(width: 30)
                Text("Pts").frame(width: 30)
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.bottom, 4)

            ForEach(Array(standings.enumerated()), id: \.offset) { idx, entry in
                HStack(spacing: 0) {
                    Text("\(idx + 1)")
                        .frame(width: 24, alignment: .leading)
                        .foregroundColor(positionColor(idx + 1))
                    HStack(spacing: 6) {
                        if let crest = entry.team.crest, URL(string: crest) != nil {
                            CrestImage(entry.team.crest, width: 20, height: 20)
                                .padding(2)
                                .background(Color(.windowBackgroundColor).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        Text(entry.team.name)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(entry.playedGames)").frame(width: 24)
                    Text("\(entry.won)").frame(width: 24)
                    Text("\(entry.draw)").frame(width: 24)
                    Text("\(entry.lost)").frame(width: 24)
                    Text("\(entry.goalDifference)").frame(width: 30)
                    Text("\(entry.points)")
                        .frame(width: 30)
                        .fontWeight(.bold)
                }
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal)
                .padding(.vertical, 3)
                Divider().opacity(0.3)
            }

        }
    }

    private func positionColor(_ pos: Int) -> Color {
        switch pos {
        case 1...4: return .green
        case 5: return .orange
        case 18...20: return .red
        default: return .primary
        }
    }
}
