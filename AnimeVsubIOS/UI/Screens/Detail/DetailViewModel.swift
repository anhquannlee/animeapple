// DetailViewModel.swift
// AnimeVsubIOS
//
// Ported from:
//   git.shin.animevsub.ui.screens.detail.DetailViewModel.kt

import Foundation
import Combine

// MARK: - WatchProgress model (lightweight, stored in UserDefaults)

struct WatchProgress: Codable, Hashable {
    var cur: Double        // seconds
    var dur: Double        // seconds
    var chapId: String?
}

// MARK: - Detail UI State

struct DetailUiState {
    var isLoading: Bool = true
    var isRefreshing: Bool = false
    var detail: AnimeDetail? = nil
    var chapterData: ChapterData? = nil
    var isChaptersLoading: Bool = false
    var chaptersError: String? = nil
    var error: String? = nil
    var animeId: String = ""
    var initialChapterId: String? = nil

    // Player
    var isPlayerLoading: Bool = false
    var playerConfig: PlayerConfig? = nil
    var playerError: String? = nil
    var currentChapter: ChapterInfo? = nil
    var servers: [ServerInfo] = []
    var currentServer: ServerInfo? = nil
    var isServersLoading: Bool = false
    var previousHadMultipleServers: Bool = false
    var autoNext: Bool = true
    var introRange: DoubleRange? = nil
    var outroRange: DoubleRange? = nil
    var episodeNameFromApi: String? = nil
    var lastProgress: Double = 0        // seconds
    var chapterProgress: [String: WatchProgress] = [:]

    // Seasons
    var currentSeasonId: String = ""
    var displaySeasons: [DisplaySeason] = []
    var activeDisplaySeasonId: String = ""
    var chapterCounts: [String: Int] = [:]

    // Follow
    var isFollowed: Bool = false

    // Computed
    var currentChapIndex: Int {
        guard let chap = currentChapter, let data = chapterData else { return -1 }
        return data.chaps.firstIndex(where: { $0.id == chap.id }) ?? -1
    }
}

// MARK: - DetailViewModel

@MainActor
final class DetailViewModel: ObservableObject {

    @Published private(set) var uiState = DetailUiState()

    // Side-effect events (snackbar messages etc.)
    enum DetailEffect {
        case showSnackbar(String)
        case requireLogin
    }
    let effectSubject = PassthroughSubject<DetailEffect, Never>()

    // Private
    private let animeRepo = AnimeRepository.shared
    private let historyRepo = HistoryRepository.shared
    private let preferences = PreferencesManager.shared

    private var chapterCache: [String: ChapterData] = [:]
    private var detailCache: [String: AnimeDetail] = [:]

    private var lastUpdateTask: Task<Void, Never>? = nil
    private var isInitialPlayback = true
    private var autoPlaybackRetryKey: String? = nil

    private static let detailTimeoutSec: TimeInterval = 15
    private static let chapterTimeoutSec: TimeInterval = 15
    private static let serverTimeoutSec: TimeInterval = 15
    private static let playerTimeoutSec: TimeInterval = 15
    private static let historyLookupTimeoutSec: TimeInterval = 5

    // MARK: - Init

    init(animeId: String, chapterId: String? = nil) {
        uiState.animeId = animeId
        uiState.initialChapterId = chapterId
        uiState.currentSeasonId = animeId
        uiState.activeDisplaySeasonId = animeId
        uiState.autoNext = preferences.autoNext

        Task { await loadDetail(animeId: animeId, targetChapterId: chapterId) }
    }

    // MARK: - Detail Loading

    func loadDetail(animeId: String, targetChapterId: String? = nil, isSwitchingSeason: Bool = false) async {
        uiState.animeId = animeId
        uiState.currentSeasonId = animeId
        uiState.error = nil
        uiState.chaptersError = nil
        uiState.isLoading = detailCache[animeId] == nil
        uiState.isChaptersLoading = chapterCache[animeId] == nil

        // Load detail
        if let cached = detailCache[animeId] {
            uiState.detail = cached
            uiState.isLoading = false
            updateDisplaySeasons()
            await checkFollow()
        } else {
            do {
                let detail = try await withTimeout(seconds: Self.detailTimeoutSec) {
                    try await self.animeRepo.getAnimeDetail(animeId: animeId)
                }
                detailCache[animeId] = detail
                uiState.detail = detail
                uiState.isLoading = false
                updateDisplaySeasons()
                await checkFollow()
            } catch {
                uiState.isLoading = false
                uiState.error = error.localizedDescription
            }
        }

        // Load chapters
        if let cached = chapterCache[animeId] {
            uiState.chapterData = cached
            uiState.isChaptersLoading = false
            updateChapterCount(seasonId: animeId, count: cached.chaps.count)
            await loadAllChapterProgress(seasonId: animeId)
            if !isSwitchingSeason {
                await handleInitialChapter(chapterData: cached, targetChapterId: targetChapterId)
            } else if !cached.chaps.isEmpty {
                let chap = cached.chaps.first(where: { $0.id == targetChapterId }) ?? cached.chaps[0]
                await playChapter(chapter: chap, seasonId: animeId)
            }
        } else {
            do {
                let chapterData = try await withTimeout(seconds: Self.chapterTimeoutSec) {
                    try await self.animeRepo.getChapters(animeId: animeId)
                }
                chapterCache[animeId] = chapterData
                uiState.chapterData = chapterData
                uiState.isChaptersLoading = false
                updateChapterCount(seasonId: animeId, count: chapterData.chaps.count)
                await loadAllChapterProgress(seasonId: animeId)
                if !isSwitchingSeason {
                    await handleInitialChapter(chapterData: chapterData, targetChapterId: targetChapterId)
                } else if !chapterData.chaps.isEmpty {
                    let chap = chapterData.chaps.first(where: { $0.id == targetChapterId }) ?? chapterData.chaps[0]
                    await playChapter(chapter: chap, seasonId: animeId)
                }
            } catch {
                uiState.isChaptersLoading = false
                uiState.chaptersError = error.localizedDescription
            }
        }
    }

    private func handleInitialChapter(chapterData: ChapterData, targetChapterId: String?) async {
        guard !chapterData.chaps.isEmpty else { return }

        var chapterToPlay: ChapterInfo
        if let tid = targetChapterId, let found = chapterData.chaps.first(where: { $0.id == tid }) {
            chapterToPlay = found
        } else {
            // Check watch history for continue-watching
            let lastChapId = try? await withTimeout(seconds: Self.historyLookupTimeoutSec) {
                try await self.historyRepo.getLastChapterId(seasonId: self.uiState.animeId)
            }
            if let lid = lastChapId, let found = chapterData.chaps.first(where: { $0.id == lid }) {
                chapterToPlay = found
            } else {
                chapterToPlay = chapterData.chaps[0]
            }
        }
        await playChapter(chapter: chapterToPlay, seasonId: uiState.animeId)
    }

    // MARK: - Chapter/Season

    func setActiveDisplaySeason(id: String) {
        guard let ds = uiState.displaySeasons.first(where: { $0.id == id }) else { return }
        uiState.activeDisplaySeasonId = id
        uiState.currentSeasonId = ds.realId
        Task { await loadChaptersOnly(seasonId: ds.realId) }
    }

    func loadChaptersOnly(seasonId: String) async {
        uiState.currentSeasonId = seasonId
        uiState.chaptersError = nil

        if let cached = chapterCache[seasonId] {
            uiState.chapterData = cached
            uiState.isChaptersLoading = false
            updateChapterCount(seasonId: seasonId, count: cached.chaps.count)
            await loadAllChapterProgress(seasonId: seasonId)
            return
        }

        uiState.isChaptersLoading = true
        do {
            let data = try await withTimeout(seconds: Self.chapterTimeoutSec) {
                try await self.animeRepo.getChapters(animeId: seasonId)
            }
            chapterCache[seasonId] = data
            uiState.chapterData = data
            uiState.isChaptersLoading = false
            updateChapterCount(seasonId: seasonId, count: data.chaps.count)
            await loadAllChapterProgress(seasonId: seasonId)
        } catch {
            uiState.isChaptersLoading = false
            uiState.chaptersError = error.localizedDescription
        }
    }

    // MARK: - Play Chapter

    func playChapter(chapter: ChapterInfo, seasonId: String) async {
        let data = chapterCache[seasonId] ?? uiState.chapterData
        let index = data?.chaps.firstIndex(where: { $0.id == chapter.id }) ?? -1

        let displayId: String
        if let count = data?.chaps.count, count > 30, index >= 0 {
            displayId = "\(seasonId)_\((index / 30) * 30)"
        } else {
            displayId = seasonId
        }

        let prevMultiple = uiState.servers.count >= 2

        let isNewSeason = seasonId != uiState.animeId
        uiState.currentChapter = chapter
        uiState.animeId = seasonId
        uiState.isPlayerLoading = true
        uiState.playerError = nil
        uiState.activeDisplaySeasonId = displayId
        uiState.currentSeasonId = seasonId
        uiState.introRange = nil
        uiState.outroRange = nil
        uiState.episodeNameFromApi = nil
        uiState.servers = []
        uiState.currentServer = nil
        uiState.previousHadMultipleServers = prevMultiple
        uiState.isServersLoading = true
        uiState.playerConfig = nil
        uiState.lastProgress = 0
        isInitialPlayback = true
        autoPlaybackRetryKey = nil

        if isNewSeason {
            Task { await loadDetail(animeId: seasonId, targetChapterId: chapter.id, isSwitchingSeason: true) }
        }

        await loadServers(chapter: chapter)
        await loadHistory(chapter: chapter, seasonId: seasonId)
        await loadAllChapterProgress(seasonId: seasonId)
    }

    // MARK: - Servers & Player

    private func loadServers(chapter: ChapterInfo) async {
        do {
            let servers = try await withTimeout(seconds: Self.serverTimeoutSec) {
                try await self.animeRepo.getServers(chapter: chapter)
            }
            uiState.servers = servers
            uiState.isServersLoading = false
            if !servers.isEmpty {
                let preferred = preferences.preferredServer
                let server = servers.first(where: { $0.name == preferred }) ?? servers[0]
                uiState.currentServer = server
                await loadPlayer(chapter: chapter, server: server)
            } else {
                uiState.isPlayerLoading = false
                uiState.playerError = "Không tìm thấy server"
            }
        } catch {
            uiState.isServersLoading = false
            uiState.isPlayerLoading = false
            uiState.playerError = error.localizedDescription
        }
    }

    func selectServer(server: ServerInfo) {
        guard let chapter = uiState.currentChapter else { return }
        autoPlaybackRetryKey = nil
        uiState.currentServer = server
        uiState.isPlayerLoading = true
        uiState.playerError = nil
        uiState.playerConfig = nil
        preferences.preferredServer = server.name
        Task { await loadPlayer(chapter: chapter, server: server) }
    }

    private func loadPlayer(chapter: ChapterInfo, server: ServerInfo) async {
        do {
            let config = try await withTimeout(seconds: Self.playerTimeoutSec) {
                try await self.animeRepo.getPlayerLink(chapter: chapter, server: server)
            }
            uiState.playerConfig = config
            uiState.isPlayerLoading = false
            uiState.playerError = nil
        } catch {
            handlePlaybackFailure(message: error.localizedDescription)
        }
    }

    func handlePlaybackFailure(message: String) {
        guard let chapter = uiState.currentChapter,
              let server = uiState.currentServer else {
            uiState.isPlayerLoading = false
            uiState.playerError = message
            return
        }
        let retryKey = "\(chapter.id):\(server.name)"
        if autoPlaybackRetryKey != retryKey {
            autoPlaybackRetryKey = retryKey
            uiState.playerConfig = nil
            uiState.playerError = nil
            uiState.isPlayerLoading = true
            Task { await loadPlayer(chapter: chapter, server: server) }
        } else {
            uiState.isPlayerLoading = false
            uiState.playerError = message
        }
    }

    func retryPlayer() {
        guard let chapter = uiState.currentChapter else { return }
        autoPlaybackRetryKey = nil
        uiState.playerConfig = nil
        uiState.playerError = nil
        uiState.isPlayerLoading = true
        Task {
            if let server = uiState.currentServer {
                await loadPlayer(chapter: chapter, server: server)
            } else {
                await loadServers(chapter: chapter)
            }
        }
    }

    // MARK: - Play Next

    @discardableResult
    func playNext() -> Bool {
        let currentAnimeId = uiState.animeId
        guard let data = chapterCache[currentAnimeId],
              let chapId = uiState.currentChapter?.id else { return false }
        guard let idx = data.chaps.firstIndex(where: { $0.id == chapId }) else { return false }
        let next = idx + 1
        if next < data.chaps.count {
            Task { await playChapter(chapter: data.chaps[next], seasonId: currentAnimeId) }
            return true
        }
        // Try next season
        if let detail = uiState.detail {
            let seasons = detail.season
            if let si = seasons.firstIndex(where: { $0.id == currentAnimeId }), si + 1 < seasons.count {
                let nextSeason = seasons[si + 1]
                Task { await loadDetail(animeId: nextSeason.id, isSwitchingSeason: true) }
                return true
            }
        }
        return false
    }

    func onEpisodeEnded() {
        if uiState.autoNext {
            let _ = playNext()
        }
    }

    // MARK: - History

    private func loadHistory(chapter: ChapterInfo, seasonId: String) async {
        if let progress = try? await historyRepo.getSingleProgress(seasonId: seasonId, chapId: chapter.id) {
            uiState.lastProgress = progress.cur
        }
    }

    private func loadAllChapterProgress(seasonId: String) async {
        if let progressList = try? await historyRepo.getWatchProgress(seasonId: seasonId) {
            var map = uiState.chapterProgress
            for p in progressList {
                if let cid = p.chapId { map[cid] = p }
            }
            uiState.chapterProgress = map
        }
    }

    func updateHistory(currentPosSec: Double, durationSec: Double) {
        guard let chapter = uiState.currentChapter else { return }

        // Update local map immediately
        var map = uiState.chapterProgress
        map[chapter.id] = WatchProgress(cur: currentPosSec, dur: durationSec, chapId: chapter.id)
        uiState.chapterProgress = map
        uiState.lastProgress = currentPosSec

        // Throttle saves
        if lastUpdateTask?.isCancelled == false { return }
        lastUpdateTask = Task {
            if isInitialPlayback {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                isInitialPlayback = false
            }
            guard let detail = uiState.detail,
                  let currentChap = uiState.currentChapter,
                  let latest = uiState.chapterProgress[currentChap.id] else { return }

            let seasonName = detail.season.first(where: { $0.id == uiState.currentSeasonId })?.name ?? ""
            try? await historyRepo.setSingleProgress(
                name: detail.name,
                poster: detail.poster ?? detail.image ?? "",
                seasonId: uiState.currentSeasonId,
                seasonName: seasonName,
                chapId: currentChap.id,
                chapName: currentChap.name,
                cur: latest.cur,
                dur: latest.dur
            )
            let interval = preferences.historySyncInterval
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }

    // MARK: - Follow

    func checkFollow() async {
        let animeId = uiState.animeId
        if let followed = try? await animeRepo.checkFollow(animeId: animeId) {
            uiState.isFollowed = followed
        }
    }

    func toggleFollow() {
        let animeId = uiState.animeId
        let current = uiState.isFollowed
        Task {
            do {
                try await animeRepo.toggleFollow(animeId: animeId, follow: !current)
                uiState.isFollowed = !current
                effectSubject.send(.showSnackbar(current ? "Đã bỏ theo dõi" : "Đã theo dõi"))
            } catch {
                effectSubject.send(.showSnackbar("Có lỗi xảy ra"))
            }
        }
    }

    // MARK: - Auto-next toggle

    func setAutoNext(_ value: Bool) {
        uiState.autoNext = value
        preferences.autoNext = value
    }

    // MARK: - Refresh & Retry

    func refresh() {
        Task {
            uiState.isRefreshing = true
            let animeId = uiState.animeId
            let seasonId = uiState.currentSeasonId
            detailCache.removeValue(forKey: animeId)
            chapterCache.removeValue(forKey: seasonId)
            if let detail = try? await animeRepo.getAnimeDetail(animeId: animeId) {
                detailCache[animeId] = detail
                uiState.detail = detail
                updateDisplaySeasons()
                await checkFollow()
            }
            if let data = try? await animeRepo.getChapters(animeId: seasonId) {
                chapterCache[seasonId] = data
                uiState.chapterData = data
                updateChapterCount(seasonId: seasonId, count: data.chaps.count)
                await loadAllChapterProgress(seasonId: seasonId)
            }
            uiState.isRefreshing = false
        }
    }

    func retry() {
        Task { await loadDetail(animeId: uiState.animeId, targetChapterId: uiState.initialChapterId) }
    }

    // MARK: - Display Seasons

    private func updateChapterCount(seasonId: String, count: Int) {
        uiState.chapterCounts[seasonId] = count
        updateDisplaySeasons()
    }

    private func updateDisplaySeasons() {
        guard let detail = uiState.detail else { return }
        var newList: [DisplaySeason] = []
        for realSeason in detail.season {
            if let count = uiState.chapterCounts[realSeason.id], count > 30 {
                var i = 0
                while i < count {
                    let end = min(i + 30, count)
                    let virtId = "\(realSeason.id)_\(i)"
                    newList.append(DisplaySeason(
                        id: virtId,
                        realId: realSeason.id,
                        name: "\(realSeason.name) (\(i + 1)-\(end))",
                        range: i...(end - 1),
                        isVirtual: true
                    ))
                    i += 30
                }
            } else {
                newList.append(DisplaySeason(
                    id: realSeason.id,
                    realId: realSeason.id,
                    name: realSeason.name,
                    range: nil,
                    isVirtual: false
                ))
            }
        }

        var activeId = uiState.activeDisplaySeasonId
        if activeId.isEmpty || !newList.contains(where: { $0.id == activeId }) {
            activeId = newList.first(where: { $0.realId == uiState.currentSeasonId })?.id
                ?? newList.first?.id ?? ""
        }
        uiState.displaySeasons = newList
        uiState.activeDisplaySeasonId = activeId
    }

    // MARK: - Helpers

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            guard let result = try await group.next() else { throw URLError(.timedOut) }
            group.cancelAll()
            return result
        }
    }
}
