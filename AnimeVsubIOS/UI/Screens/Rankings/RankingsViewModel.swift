import Foundation

@MainActor
final class RankingsViewModel: ObservableObject {
    @Published var rankings: [AnimeCard] = []
    @Published var isLoading: Bool = false

    func load() async {
        isLoading = true
        if let items = try? await AnimeRepository.shared.getRankings(type: "day") {
            self.rankings = items
        }
        isLoading = false
    }
}
