import Foundation

@MainActor
final class FollowViewModel: ObservableObject {
    @Published var followedAnime: [AnimeCard] = []
    @Published var isLoading: Bool = false

    func load() async {
        isLoading = true
        self.followedAnime = []
        isLoading = false
    }
}
