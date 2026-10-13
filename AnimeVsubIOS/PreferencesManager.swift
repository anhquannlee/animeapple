// PreferencesManager.swift
// AnimeVsubIOS (iOS 12+)

import Foundation

public final class PreferencesManager {
    public static let shared = PreferencesManager()
    private let defaults = UserDefaults.standard

    private enum Key {
        static let autoNext = "pref_auto_next"
        static let doubleTapSkip = "pref_double_tap_skip"
        static let playbackSpeed = "pref_playback_speed"
        static let searchHistory = "pref_search_history"
    }

    public var autoNext: Bool {
        get { defaults.object(forKey: Key.autoNext) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.autoNext) }
    }

    public var doubleTapSkip: Int {
        get { defaults.object(forKey: Key.doubleTapSkip) as? Int ?? 10 }
        set { defaults.set(newValue, forKey: Key.doubleTapSkip) }
    }

    public var playbackSpeed: Float {
        get { defaults.object(forKey: Key.playbackSpeed) as? Float ?? 1.0 }
        set { defaults.set(newValue, forKey: Key.playbackSpeed) }
    }

    public var searchHistory: [String] {
        get { defaults.stringArray(forKey: Key.searchHistory) ?? [] }
        set { defaults.set(newValue, forKey: Key.searchHistory) }
    }

    public func addSearchHistory(_ query: String) {
        var current = searchHistory
        current.removeAll { $0 == query }
        current.insert(query, at: 0)
        if current.count > 15 { current = Array(current.prefix(15)) }
        searchHistory = current
    }

    public func clearSearchHistory() {
        searchHistory = []
    }
}
