import SwiftUI

struct MatchRowView: View {
    let match: Match

    var body: some View {
        HStack(spacing: 12) {
            if match.isLive {
                LiveIndicator()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TeamLabel(team: match.homeTeam, alignment: .leading)
                    Spacer()
                    ScoreBadge(match: match)
                    Spacer()
                    TeamLabel(team: match.awayTeam, alignment: .trailing)
                }

                HStack {
                    if match.isLive {
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    Text(match.dateFormatted)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(match.statusDisplay)
                        .font(.caption2)
                        .fontWeight(match.isLive ? .bold : .regular)
                        .foregroundColor(match.isLive ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct LiveIndicator: View {
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(.red)
            .frame(width: 8, height: 8)
            .opacity(animate ? 1 : 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
    }
}

struct TeamLabel: View {
    let team: Match.Team
    let alignment: HorizontalAlignment

    var body: some View {
        HStack(spacing: 6) {
            if alignment == .trailing {
                Text(team.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                crestView
            } else {
                crestView
                Text(team.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: 120, alignment: alignment == .leading ? .leading : .trailing)
    }

    @ViewBuilder
    private var crestView: some View {
        if let url = team.crest.flatMap({ URL(string: $0) }) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit().frame(width: 18, height: 18)
                default:
                    Rectangle().fill(.clear).frame(width: 18, height: 18)
                }
            }
        }
    }
}

struct ScoreBadge: View {
    let match: Match

    var body: some View {
        HStack(spacing: 4) {
            if let home = match.score.fullTime?.home, let away = match.score.fullTime?.away {
                Text("\(home)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(match.isLive ? .primary : .primary)
                Text(":")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                Text("\(away)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(match.isLive ? .primary : .primary)
            } else {
                Text("vs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(match.isLive ? Color.red.opacity(0.12) : Color.gray.opacity(0.08))
        .cornerRadius(6)
    }
}
