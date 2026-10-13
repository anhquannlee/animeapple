import SwiftUI

struct RankingsScreen: View {
    @StateObject private var viewModel = RankingsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.rankings) { anime in
                    NavigationLink(destination: DetailScreen(animeId: anime.animeId)) {
                        Text(anime.name)
                    }
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Bảng xếp hạng")
        .task {
            await viewModel.load()
        }
    }
}
