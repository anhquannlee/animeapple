import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var historyItems: [HistoryItem] = []

    private let historyManager = HistoryManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        historyManager.$historyItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.historyItems = items.reversed()
            }
            .store(in: &cancellables)

        self.historyItems = historyManager.getAllHistory()
    }

    func delete(item: HistoryItem) {
        historyManager.deleteHistory(animeId: item.seasonId)
    }

    func clearAll() {
        historyManager.clearAll()
    }
}
