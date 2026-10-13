import SwiftUI

struct FollowScreen: View {
    @StateObject private var viewModel = FollowViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.followedAnime.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Chưa theo dõi anime nào.")
                        .foregroundColor(.gray)
                }
            } else {
                List(viewModel.followedAnime) { anime in
                    NavigationLink(destination: DetailScreen(animeId: anime.animeId)) {
                        Text(anime.name)
                    }
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Đang theo dõi")
        .task {
            await viewModel.load()
        }
    }
}
