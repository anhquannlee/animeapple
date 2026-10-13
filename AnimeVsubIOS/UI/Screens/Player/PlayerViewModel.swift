import Foundation
import AVFoundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var error: String? = nil
    @Published var servers: [ServerInfo] = []
    @Published var currentServer: ServerInfo? = nil
    @Published var playerLink: String? = nil

    private let animeRepo = AnimeRepository.shared
    private let historyRepo = HistoryRepository.shared

    func load(chapter: ChapterInfo) async {
        isLoading = true
        error = nil
        do {
            let serversList = try await animeRepo.getServers(chapter: chapter)
            self.servers = serversList
            if let first = serversList.first {
                self.currentServer = first
                let playerData = try await animeRepo.getPlayerLink(server: first)
                self.playerLink = playerData.link
            }
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }

    func saveProgress(animeId: String, animeTitle: String, chapter: ChapterInfo, poster: String?, current: Double, total: Double) {
        guard total > 0 else { return }
        Task {
            try? await historyRepo.setSingleProgress(
                name: animeTitle,
                poster: poster ?? "",
                seasonId: animeId,
                seasonName: animeTitle,
                chapId: chapter.id,
                chapName: chapter.name,
                cur: current,
                dur: total
            )
        }
    }
}
