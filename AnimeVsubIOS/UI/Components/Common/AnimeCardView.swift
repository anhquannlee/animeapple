// AnimeCardView.swift
// AnimeVsubIOS
//
// Reusable anime card component.
// Two size variants:
//   • .medium  — used in horizontal scroll lists (100 pt wide)
//   • .small   — used in 3-column grids (fills available width)
//
// Shows poster image, anime name, and an episode/quality badge overlay.

import SwiftUI

// MARK: - CardSize

enum AnimeCardSize {
    case medium   // horizontal scroll: fixed ~100 pt width
    case small    // grid: fills column width
}

// MARK: - AnimeCardView

struct AnimeCardView: View {

    // MARK: Inputs

    let anime: AnimeCard
    var size: AnimeCardSize = .medium
    /// Shows a trending rank badge (1-based) in the top-left corner.
    var rankIndex: Int? = nil
    /// Replaces the episode badge with a date/timeline label.
    var showTimeline: Bool = false
    /// Tapped action — caller is responsible for navigation.
    var onTap: (() -> Void)?

    // MARK: Layout constants

    private var cardWidth: CGFloat {
        switch size {
        case .medium: return 100
        case .small:  return .infinity   // fills column
        }
    }

    private var posterHeight: CGFloat {
        switch size {
        case .medium: return 145
        case .small:  return 155
        }
    }

    // MARK: Body

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 6) {
                posterStack
                titleAndBadge
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: size == .small ? .infinity : cardWidth)
    }

    // MARK: Poster + overlays

    @ViewBuilder
    private var posterStack: some View {
        ZStack(alignment: .bottomLeading) {
            // Poster image
            GeometryReader { geo in
                AsyncImage(url: URL(string: anime.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage
                    default:
                        Color(white: 0.18)
                            .shimmer()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
            .frame(height: posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Episode / quality badge (bottom-left)
            if let badge = badgeText {
                Text(badge)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#E53935"))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(5)
            }

            // Rank badge (top-left)
            if let rank = rankIndex {
                Text("\(rank)")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(rankBadgeColor(rank: rank))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    // MARK: Title & meta

    @ViewBuilder
    private var titleAndBadge: some View {
        Text(anime.name)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Helpers

    /// Text shown in the bottom-left episode badge.
    private var badgeText: String? {
        if showTimeline, let ts = anime.timeRelease {
            let date = Date(timeIntervalSince1970: TimeInterval(ts))
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: date)
        }
        if let ep = anime.lastEpisode {
            let name = ep.name.trimmingCharacters(in: .whitespaces)
            if name.isEmpty { return nil }
            // Trim redundant prefix so "Tập 12" → "T.12", "EP 12" → "EP12"
            if name.lowercased().hasPrefix("ep") {
                return name.replacingOccurrences(of: " ", with: "")
            }
            let digits = name.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if !digits.isEmpty { return "Tập \(digits)" }
            return name
        }
        if let q = anime.quality, !q.isEmpty { return q }
        return nil
    }

    /// Rank badge color: gold → silver → bronze → red accent for rank > 3.
    private func rankBadgeColor(rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.80, blue: 0.0)
        case 2: return Color(white: 0.7)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return Color(hex: "#E53935")
        }
    }

    // MARK: Placeholder image

    private var placeholderImage: some View {
        ZStack {
            Color(white: 0.18)
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 32)
                .foregroundColor(Color(white: 0.4))
        }
    }
}

// MARK: - Color hex convenience (scoped)

extension Color {
    /// Initialise from a CSS hex string like `"#E53935"` or `"E53935"`.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#if DEBUG
struct AnimeCardView_Previews: PreviewProvider {
    static let sample = AnimeCard(
        animeId: "one-piece",
        image: "https://animevietsub.fan/data/poster/2022/08/09/animevsub-TmmkT5G7.jpg",
        name: "One Piece",
        lastEpisode: ChapterInfo(id: "ep-1109", name: "1109"),
        rate: 9.2,
        quality: "FHD"
    )

    static var previews: some View {
        HStack(alignment: .top, spacing: 16) {
            AnimeCardView(anime: sample, size: .medium, rankIndex: 1)
            AnimeCardView(anime: sample, size: .medium, rankIndex: 2)
            AnimeCardView(anime: sample, size: .small)
        }
        .padding()
        .background(Color(hex: "#1a1a1a"))
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
#endif
