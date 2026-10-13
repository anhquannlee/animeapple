// HistoryModels.swift
// AnimeVsubIOS
//
// Ported from:
//   git.shin.animevsub.data.model.HistoryModels.kt

import Foundation

// MARK: - HistoryItem

public struct HistoryItem: Codable, Hashable, Identifiable {
    public var id: String { seasonId }

    public let name: String
    public let poster: String
    public let seasonId: String
    public let seasonName: String
    public var createdAt: String?
    public var chapId: String?
    public var chapName: String?
    public var cur: Double
    public var dur: Double

    public var progress: Double {
        guard dur > 0 else { return 0 }
        return min(cur / dur, 1.0)
    }

    public var progressFraction: Double { progress }

    public var createdAtDate: Date? {
        guard let raw = createdAt else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }

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

    public init(
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

// MARK: - WatchProgress

public struct WatchProgress: Codable, Hashable {
    public var cur: Double
    public var dur: Double
    public var name: String?
    public var chapId: String?

    public var progress: Double {
        guard dur > 0 else { return 0 }
        return min(cur / dur, 1.0)
    }

    enum CodingKeys: String, CodingKey {
        case cur, dur, name
        case chapId = "chap_id"
    }

    public init(cur: Double, dur: Double, name: String? = nil, chapId: String? = nil) {
        self.cur    = cur
        self.dur    = dur
        self.name   = name
        self.chapId = chapId
    }
}

// MARK: - LastChapResponse

public struct LastChapResponse: Codable, Hashable {
    public let chapId: String?
    public let chapName: String?
    public let cur: Double
    public let dur: Double

    enum CodingKeys: String, CodingKey {
        case chapId   = "watch_id"
        case chapName = "watch_name"
        case cur      = "watch_cur"
        case dur      = "watch_dur"
    }

    public init(chapId: String? = nil, chapName: String? = nil, cur: Double = 0.0, dur: Double = 0.0) {
        self.chapId   = chapId
        self.chapName = chapName
        self.cur      = cur
        self.dur      = dur
    }
}
