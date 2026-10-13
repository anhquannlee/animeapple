import Foundation

@MainActor
final class CategoryViewModel: ObservableObject {
    @Published var items: [AnimeCard] = []
    @Published var isLoading: Bool = false

    func load() async {
        isLoading = true
        if let page = try? await AnimeRepository.shared.getCategory(filters: [], page: 1) {
            self.items = page.items
        }
        isLoading = false
    }
}
