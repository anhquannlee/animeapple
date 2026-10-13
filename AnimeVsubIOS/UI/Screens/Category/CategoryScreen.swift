import SwiftUI

struct CategoryScreen: View {
    @StateObject private var viewModel = CategoryViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.items) { anime in
                    NavigationLink(destination: DetailScreen(animeId: anime.animeId)) {
                        Text(anime.name)
                    }
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Thể loại")
        .task {
            await viewModel.load()
        }
    }
}
