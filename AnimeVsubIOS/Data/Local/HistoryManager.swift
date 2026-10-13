// HistoryManager.swift
// AnimeVsubIOS
//
// Local watch history storage using UserDefaults with JSON encoding.
// Simpler than CoreData for this use case; the entire history list is kept
// in-memory as @Published and flushed to UserDefaults on every mutation.

import Foundation
import Combine

// MARK: - Domain models (mirror HistoryModels.kt)

/// Mirrors data class HistoryItem in HistoryModels.kt.
struct HistoryItem: Codable, Identifiable, Equatable {
    /// Synthetic id for SwiftUI lists — uses seasonId as the stable identity.
    var id: String { seasonId }

    let name: String
    let poster: String
    /// @SerialName("season") val seasonId — the anime season/series identifier
    let seasonId: String
    /// @SerialName("season_name") val seasonName
    let seasonName: String
    /// ISO-8601 timestamp string recorded when first watched
    var createdAt: String?
    /// @SerialName("watch_id") — last watched episode id
    var chapId: String?
    /// @SerialName("watch_name") — last watched episode display name
    var chapName: String?
    /// @SerialName("watch_cur") — playback position in seconds
    var cur: Double
    /// @SerialName("watch_dur") — total duration in seconds
    var dur: Double

    /// Fractional watch progress in [0, 1], safe against zero-duration items.
    var progress: Double {
        guard dur > 0 else { return 0 }
        return min(cur / dur, 1.0)
    }

    // MARK: CodingKeys — align with Kotlin @SerialName annotations for cross-platform JSON
    enum CodingKeys: String, CodingKey {
        case name, poster
        case seasonId   = "season"
        case seasonName = "season_name"
        case createdAt  = "created_at"
        case chapId     = "watch_id"
        case chapName   = "watch_name"
        case cur        = "watch_cur"
        case dur        = "watch_dur"
    }

    init(
        name: String,
        poster: String,
        seasonId: String,
        seasonName: String,
        createdAt: String? = nil,
        chapId: String? = nil,
        chapName: String? = nil,
        cur: Double = 0.0,
        dur: Double = 0.0
    ) {
        self.name       = name
        self.poster     = poster
        self.seasonId   = seasonId
        self.seasonName = seasonName
        self.createdAt  = createdAt
        self.chapId     = chapId
        self.chapName   = chapName
        self.cur        = cur
        self.dur        = dur
    }
}

/// Mirrors data class WatchProgress in HistoryModels.kt.
struct WatchProgress: Codable, Equatable {
    let cur: Double
    let dur: Double
    let name: String?
    let chapId: String?

    enum CodingKeys: String, CodingKey {
        case cur, dur, name
        case chapId = "chap_id"
    }

    init(cur: Double, dur: Double, name: String? = nil, chapId: String? = nil) {
        self.cur    = cur
        self.dur    = dur
        self.name   = name
        self.chapId = chapId
    }

    /// Fractional progress in [0, 1].
    var progress: Double {
        guard dur > 0 else { return 0 }
        return min(cur / dur, 1.0)
    }
}

// MARK: - HistoryManager

/// Manages local watch history using UserDefaults.
/// All mutation methods update the in-memory @Published list and then
/// flush the serialised JSON back to UserDefaults.
final class HistoryManager: ObservableObject {

    // MARK: Singleton
    static let shared = HistoryManager()

    // MARK: - Published state
    @Published private(set) var historyItems: [HistoryItem] = []

    // MARK: - Private
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let historyList = "watch_history_list"
    }

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.historyItems = Self.load(from: defaults, decoder: JSONDecoder())
    }

    // MARK: - Public API

    /// Saves or updates a history entry. If an entry with the same `seasonId` already
    /// exists it is replaced; otherwise the item is appended.
    func saveHistory(_ item: HistoryItem) {
        var items = historyItems
        if let idx = items.firstIndex(where: { $0.seasonId == item.seasonId }) {
            items[idx] = item
        } else {
            var newItem = item
            if newItem.createdAt == nil {
                newItem.createdAt = ISO8601DateFormatter().string(from: Date())
            }
            items.append(newItem)
        }
        commit(items)
    }

    /// Returns all stored history items, most-recently-watched first.
    func getAllHistory() -> [HistoryItem] {
        return historyItems.reversed()
    }

    /// Returns the history entry for the given anime season id, or nil if not found.
    func getHistory(animeId: String) -> HistoryItem? {
        return historyItems.first { $0.seasonId == animeId }
    }

    /// Removes the history entry for the given anime season id.
    func deleteHistory(animeId: String) {
        let items = historyItems.filter { $0.seasonId != animeId }
        commit(items)
    }

    /// Removes all history entries.
    func clearAll() {
        commit([])
        defaults.removeObject(forKey: Key.historyList)
    }

    /// Updates (or creates) a history entry's playback position.
    /// - Parameters:
    ///   - animeId:  The season identifier.
    ///   - chapId:   The episode/chapter identifier.
    ///   - chapName: The episode display name.
    ///   - cur:      Current playback position in seconds.
    ///   - dur:      Total episode duration in seconds.
    func updateWatchProgress(
        animeId: String,
        chapId: String,
        chapName: String,
        cur: Double,
        dur: Double
    ) {
        var items = historyItems
        if let idx = items.firstIndex(where: { $0.seasonId == animeId }) {
            var item = items[idx]
            item.chapId   = chapId
            item.chapName = chapName
            item.cur      = cur
            item.dur      = dur
            items[idx] = item
        }
        // If the anime hasn't been saved yet we don't auto-create a skeleton entry;
        // callers should call saveHistory(_:) first with full metadata.
        commit(items)
    }

    /// Returns the watch progress for a specific episode, or nil if no record exists.
    func getWatchProgress(animeId: String, chapId: String) -> WatchProgress? {
        guard let item = historyItems.first(where: { $0.seasonId == animeId }),
              item.chapId == chapId else { return nil }
        return WatchProgress(cur: item.cur, dur: item.dur, name: item.chapName, chapId: item.chapId)
    }

    // MARK: - Private helpers

    /// Updates in-memory state and persists to UserDefaults.
    private func commit(_ items: [HistoryItem]) {
        DispatchQueue.main.async { [weak self] in
            self?.historyItems = items
        }
        persist(items)
    }

    private func persist(_ items: [HistoryItem]) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: Key.historyList)
    }

    private static func load(from defaults: UserDefaults, decoder: JSONDecoder) -> [HistoryItem] {
        guard let data = defaults.data(forKey: Key.historyList),
              let items = try? decoder.decode([HistoryItem].self, from: data) else {
            return []
        }
        return items
    }
}
