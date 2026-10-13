import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedAnimeId: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.uiState.isLoading {
                    HomeLoadingView()
                } else if let error = viewModel.uiState.error, viewModel.uiState.data == nil {
                    ErrorView(message: error) {
                        Task { await viewModel.loadHomePage() }
                    }
                } else if let data = viewModel.uiState.data {
                    // Carousel
                    if !data.carousel.isEmpty {
                        CarouselView(items: data.carousel) { anime in
                            selectedAnimeId = anime.animeId
                        }
                    }

                    // Hot Update
                    if !data.hotUpdate.isEmpty {
                        sectionView(title: "🔥 Phim Hot Cập Nhật", items: data.hotUpdate)
                    }

                    // This Season
                    if !data.thisSeason.isEmpty {
                        sectionView(title: "🌸 Anime Mùa Này", items: data.thisSeason)
                    }

                    // Last Update
                    if !data.lastUpdate.isEmpty {
                        sectionView(title: "⏰ Mới Cập Nhật", items: data.lastUpdate)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("AnimeVsub")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let id = selectedAnimeId {
                        DetailScreen(animeId: id)
                    }
                },
                isActive: Binding(
                    get: { selectedAnimeId != nil },
                    set: { if !$0 { selectedAnimeId = nil } }
                )
            ) {
                EmptyView()
            }
        )
    }

    private func sectionView(title: String, items: [AnimeCard]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { anime in
                        AnimeCardView(anime: anime, size: .medium)
                            .onTapGesture {
                                selectedAnimeId = anime.animeId
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
