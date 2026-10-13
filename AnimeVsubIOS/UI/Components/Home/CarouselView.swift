import SwiftUI

struct CarouselView: View {
    let items: [AnimeCard]
    let onItemClick: (AnimeCard) -> Void

    @State private var currentIndex: Int = 0
    private let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            TabView(selection: $currentIndex) {
                ForEach(0..<items.count, id: \.self) { index in
                    let anime = items[index]
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: anime.image)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(anime.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            if let ep = anime.lastEpisode?.name {
                                Text("Tập mới: \(ep)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(12)
                    }
                    .tag(index)
                    .onTapGesture {
                        onItemClick(anime)
                    }
                }
            }
            .frame(height: 220)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .onReceive(timer) { _ in
                guard !items.isEmpty else { return }
                withAnimation {
                    currentIndex = (currentIndex + 1) % items.count
                }
            }
        }
    }
}
