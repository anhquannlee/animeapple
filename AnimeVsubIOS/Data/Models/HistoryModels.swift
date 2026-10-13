// HistoryModels.swift
// AnimeVsubIOS
//
// Ported from:
//   git.shin.animevsub.data.model.HistoryModels.kt
//
// Kotlin @SerialName annotations are mapped to Swift CodingKeys.

import Foundation

// MARK: - HistoryItem

/// A single watch-history entry returned by the `/history` API endpoint.
struct HistoryItem: Codable, Hashable {
    /// Display name of the anime.
    let name: String
    /// URL of the anime's poster image.
    let poster: String
    /// ID of the season (mapped from JSON key `"season"`).
    let seasonId: String
    /// Human-readable season name (mapped from JSON key `"season_name"`).
    let seasonName: String
    /// ISO-8601 timestamp string of when this entry was created (mapped from `"created_at"`).
    let createdAt: String?
    /// ID of the last-watched chapter (mapped from `"watch_id"`).
    let chapId: String?
    /// Name of the last-watched chapter (mapped from `"watch_name"`).
    let chapName: String?
    /// Playback position in seconds (mapped from `"watch_cur"`).
    let cur: Double
    /// Total duration in seconds (mapped from `"watch_dur"`).
    let dur: Double

    enum CodingKeys: String, CodingKey {
        case name
        case poster
        case seasonId    = "season"
        case seasonName  = "season_name"
        case createdAt   = "created_at"
        case chapId      = "watch_id"
        case chapName    = "watch_name"
        case cur         = "watch_cur"
        case dur         = "watch_dur"
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
        self.name = name
        self.poster = poster
        self.seasonId = seasonId
        self.seasonName = seasonName
        self.createdAt = createdAt
        self.chapId = chapId
        self.chapName = chapName
        self.cur = cur
        self.dur = dur
    }

    // MARK: Convenience

    /// Progress fraction in `[0, 1]`. Returns `0` when duration is zero.
    var progressFraction: Double {
        guard dur > 0 else { return 0 }
        return min(cur / dur, 1.0)
    }

    /// Parses `createdAt` as a `Date` using ISO-8601 format.
    var createdAtDate: Date? {
        guard let raw = createdAt else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }
}

// MARK: - WatchProgress

/// Tracks the current playback position for a chapter, POSTed to the server
/// as the user watches.
struct WatchProgress: Codable, Hashable {
    /// Current playback position in seconds.
    let cur: Double
    /// Total video duration in seconds.
    let dur: Double
    /// Optional human-readable chapter name.
    let name: String?
    /// ID of the chapter being watched (mapped from `"chap_id"`).
    let chapId: String?

    enum CodingKeys: String, CodingKey {
        case cur
        case dur
        case name
        case chapId = "chap_id"
    }

    init(cur: Double, dur: Double, name: String? = nil, chapId: String? = nil) {
        self.cur = cur
        self.dur = dur
        self.name = name
        self.chapId = chapId
    }

    /// Progress fraction in `[0, 1]`. Returns `0` when duration is zero.
    var progressFraction: Double {
        guard dur > 0 else { return 0 }
        return min(cur / dur, 1.0)
    }
}

// MARK: - LastChapResponse

/// Response from the endpoint that returns the most-recently-watched chapter ID
/// for a given anime season.
struct LastChapResponse: Codable, Hashable {
    /// ID of the most recently watched chapter (mapped from `"chap_id"`).
    let chapId: String?

    enum CodingKeys: String, CodingKey {
        case chapId = "chap_id"
    }

    init(chapId: String? = nil) {
        self.chapId = chapId
    }
}
