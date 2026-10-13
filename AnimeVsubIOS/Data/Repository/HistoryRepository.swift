import Foundation

public final class HistoryRepository {
    public static let shared = HistoryRepository()
    private let manager = HistoryManager.shared

    public init() {}

    public func getAllHistory() -> [HistoryItem] {
        return manager.getAllHistory()
    }

    public func getSingleProgress(seasonId: String, chapId: String) async throws -> WatchProgress? {
        return manager.getWatchProgress(animeId: seasonId, chapId: chapId)
    }

    public func getWatchProgress(seasonId: String) async throws -> [WatchProgress] {
        if let item = manager.getHistory(animeId: seasonId), let chapId = item.chapId {
            return [WatchProgress(cur: item.cur, dur: item.dur, name: item.chapName, chapId: chapId)]
        }
        return []
    }

    public func setSingleProgress(
        name: String,
        poster: String,
        seasonId: String,
        seasonName: String,
        chapId: String,
        chapName: String,
        cur: Double,
        dur: Double
    ) async throws {
        var item = manager.getHistory(animeId: seasonId) ?? HistoryItem(
            name: name,
            poster: poster,
            seasonId: seasonId,
            seasonName: seasonName,
            createdAt: nil,
            chapId: chapId,
            chapName: chapName,
            cur: cur,
            dur: dur
        )
        item.chapId = chapId
        item.chapName = chapName
        item.cur = cur
        item.dur = dur
        manager.saveHistory(item)
    }

    public func remove(seasonId: String) {
        manager.deleteHistory(animeId: seasonId)
    }

    public func clearAll() {
        manager.clearAll()
    }
}
