// HistoryManager.swift
// AnimeVsubIOS
//
// Local watch history storage using UserDefaults with JSON encoding.

import Foundation
import Combine

// MARK: - HistoryManager

public final class HistoryManager: ObservableObject {

    // MARK: Singleton
    public static let shared = HistoryManager()

    // MARK: - Published state
    @Published public private(set) var historyItems: [HistoryItem] = []

    // MARK: - Private
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let historyList = "watch_history_list"
    }

    // MARK: - Init

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.historyItems = Self.load(from: defaults, decoder: JSONDecoder())
    }

    // MARK: - Public API

    public func saveHistory(_ item: HistoryItem) {
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

    public func getAllHistory() -> [HistoryItem] {
        return historyItems.reversed()
    }

    public func getHistory(animeId: String) -> HistoryItem? {
        return historyItems.first { $0.seasonId == animeId }
    }

    public func deleteHistory(animeId: String) {
        let items = historyItems.filter { $0.seasonId != animeId }
        commit(items)
    }

    public func clearAll() {
        commit([])
        defaults.removeObject(forKey: Key.historyList)
    }

    public func updateWatchProgress(
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
        commit(items)
    }

    public func getWatchProgress(animeId: String, chapId: String) -> WatchProgress? {
        guard let item = historyItems.first(where: { $0.seasonId == animeId }),
              item.chapId == chapId else { return nil }
        return WatchProgress(cur: item.cur, dur: item.dur, name: item.chapName, chapId: item.chapId)
    }

    // MARK: - Private helpers

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
