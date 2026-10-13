// WatchHistoryManager.swift
// AnimeVsubIOS (iOS 12+)

import Foundation

public struct HistoryRecord: Codable, Hashable {
    public let animeId: String
    public let title: String
    public let poster: String?
    public var chapterId: String
    public var chapterName: String
    public var currentSeconds: Double
    public var totalSeconds: Double
    public var updatedAt: Date

    public var progressPercent: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(currentSeconds / totalSeconds, 1.0)
    }

    public init(
        animeId: String,
        title: String,
        poster: String?,
        chapterId: String,
        chapterName: String,
        currentSeconds: Double,
        totalSeconds: Double,
        updatedAt: Date = Date()
    ) {
        self.animeId = animeId
        self.title = title
        self.poster = poster
        self.chapterId = chapterId
        self.chapterName = chapterName
        self.currentSeconds = currentSeconds
        self.totalSeconds = totalSeconds
        self.updatedAt = updatedAt
    }
}

public final class WatchHistoryManager {
    public static let shared = WatchHistoryManager()
    public static let didChangeNotification = Notification.Name("AnimeVsubHistoryDidChange")

    private let key = "AnimeVsub_WatchHistory_v1"
    private var records: [HistoryRecord] = []

    private init() {
        load()
    }

    public func getAll() -> [HistoryRecord] {
        return records
    }

    public func get(animeId: String) -> HistoryRecord? {
        return records.first { $0.animeId == animeId }
    }

    public func save(
        animeId: String,
        title: String,
        poster: String?,
        chapterId: String,
        chapterName: String,
        current: Double,
        total: Double
    ) {
        records.removeAll { $0.animeId == animeId }
        let record = HistoryRecord(
            animeId: animeId,
            title: title,
            poster: poster,
            chapterId: chapterId,
            chapterName: chapterName,
            currentSeconds: current,
            totalSeconds: total,
            updatedAt: Date()
        )
        records.insert(record, at: 0)
        persist()
    }

    public func delete(animeId: String) {
        records.removeAll { $0.animeId == animeId }
        persist()
    }

    public func clearAll() {
        records.removeAll()
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
        NotificationCenter.default.post(name: WatchHistoryManager.didChangeNotification, object: nil)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([HistoryRecord].self, from: data) {
            records = saved
        }
    }
}
