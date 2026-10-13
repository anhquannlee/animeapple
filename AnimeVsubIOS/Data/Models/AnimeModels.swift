// AnimeModels.swift
// AnimeVsubIOS
//
// Swift mirror of the Android Kotlin data models.
// All models are Codable for JSON serialisation and Equatable for diffing.

import Foundation

// MARK: - User

public struct User: Codable, Equatable, Identifiable {
    public let id: String
    public let avatar: String?
    public let email: String?
    public let name: String
    public let sex: String?
    public let username: String

    public init(id: String = UUID().uuidString,
                avatar: String? = nil,
                email: String? = nil,
                name: String,
                sex: String? = nil,
                username: String) {
        self.id = id
        self.avatar = avatar
        self.email = email
        self.name = name
        self.sex = sex
        self.username = username
    }
}

// MARK: - Filter

public struct FilterOption: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct FilterGroup: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let options: [FilterOption]
    public let isMultiple: Bool
    public let `default`: String?

    public init(id: String,
                name: String,
                options: [FilterOption],
                isMultiple: Bool = false,
                default defaultValue: String? = nil) {
        self.id = id
        self.name = name
        self.options = options
        self.isMultiple = isMultiple
        self.default = defaultValue
    }
}

public struct SelectedFilter: Codable, Equatable {
    public let groupId: String
    public let id: String
    public let name: String
    public let include: Bool
    public let exclude: Bool

    public init(groupId: String,
                id: String,
                name: String,
                include: Bool = true,
                exclude: Bool = false) {
        self.groupId = groupId
        self.id = id
        self.name = name
        self.include = include
        self.exclude = exclude
    }
}

// MARK: - Category / Links

public struct CategoryLink: Codable, Equatable {
    public let name: String
    public let filters: [SelectedFilter]

    public init(name: String, filters: [SelectedFilter] = []) {
        self.name = name
        self.filters = filters
    }
}

// MARK: - Anime Card

public struct AnimeCard: Codable, Equatable, Identifiable {
    public let id: String          // maps to animeId
    public let animeId: String
    public let image: String
    public let name: String
    public let lastEpisode: ChapterInfo?
    public let rate: Float
    public let views: Int?
    public let quality: String?
    public let process: String?
    public let year: Int?
    public let description: String?
    public let studio: String?
    public let genre: [CategoryLink]
    public let timeRelease: TimeInterval?

    public init(animeId: String,
                image: String,
                name: String,
                lastEpisode: ChapterInfo? = nil,
                rate: Float = 0,
                views: Int? = nil,
                quality: String? = nil,
                process: String? = nil,
                year: Int? = nil,
                description: String? = nil,
                studio: String? = nil,
                genre: [CategoryLink] = [],
                timeRelease: TimeInterval? = nil) {
        self.id = animeId
        self.animeId = animeId
        self.image = image
        self.name = name
        self.lastEpisode = lastEpisode
        self.rate = rate
        self.views = views
        self.quality = quality
        self.process = process
        self.year = year
        self.description = description
        self.studio = studio
        self.genre = genre
        self.timeRelease = timeRelease
    }
}

// MARK: - Season

public struct Season: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// A display-friendly season (may be a virtual split of a very long real season)
public struct DisplaySeason: Equatable, Identifiable {
    public let id: String
    public let realId: String
    public let name: String
    public let range: ClosedRange<Int>?
    public let isVirtual: Bool

    public init(id: String,
                realId: String,
                name: String,
                range: ClosedRange<Int>? = nil,
                isVirtual: Bool = false) {
        self.id = id
        self.realId = realId
        self.name = name
        self.range = range
        self.isVirtual = isVirtual
    }
}

// MARK: - Home Page

public struct HomeData: Equatable {
    public let thisSeason: [AnimeCard]
    public let carousel: [AnimeCard]
    public let lastUpdate: [AnimeCard]
    public let preRelease: [AnimeCard]
    public let nominate: [AnimeCard]
    public let hotUpdate: [AnimeCard]

    public init(thisSeason: [AnimeCard] = [],
                carousel: [AnimeCard] = [],
                lastUpdate: [AnimeCard] = [],
                preRelease: [AnimeCard] = [],
                nominate: [AnimeCard] = [],
                hotUpdate: [AnimeCard] = []) {
        self.thisSeason = thisSeason
        self.carousel = carousel
        self.lastUpdate = lastUpdate
        self.preRelease = preRelease
        self.nominate = nominate
        self.hotUpdate = hotUpdate
    }
}

// MARK: - External Platform

public struct ExternalPlatform: Codable, Equatable {
    public let href: String
    public let name: String
    public let logo: String?

    public init(href: String, name: String, logo: String? = nil) {
        self.href = href
        self.name = name
        self.logo = logo
    }
}

// MARK: - Anime Detail

public struct AnimeDetail: Equatable {
    public let name: String
    public let othername: String?
    public let image: String?
    public let poster: String?
    public let description: String
    public let rate: Double
    public let countRate: Int
    public let duration: String?
    public let yearOf: CategoryLink?
    public let views: Int
    public let season: [Season]
    public let genre: [CategoryLink]
    public let quality: String?
    public let authors: [CategoryLink]
    public let countries: [CategoryLink]
    public let follows: Int
    public let language: String?
    public let studio: CategoryLink?
    public let seasonOf: CategoryLink?
    public let trailer: String?
    public let related: [AnimeCard]
    public let extra: [String: String]
    public let externalPlatforms: [ExternalPlatform]

    public init(name: String,
                othername: String? = nil,
                image: String? = nil,
                poster: String? = nil,
                description: String = "",
                rate: Double = 0,
                countRate: Int = 0,
                duration: String? = nil,
                yearOf: CategoryLink? = nil,
                views: Int = 0,
                season: [Season] = [],
                genre: [CategoryLink] = [],
                quality: String? = nil,
                authors: [CategoryLink] = [],
                countries: [CategoryLink] = [],
                follows: Int = 0,
                language: String? = nil,
                studio: CategoryLink? = nil,
                seasonOf: CategoryLink? = nil,
                trailer: String? = nil,
                related: [AnimeCard] = [],
                extra: [String: String] = [:],
                externalPlatforms: [ExternalPlatform] = []) {
        self.name = name
        self.othername = othername
        self.image = image
        self.poster = poster
        self.description = description
        self.rate = rate
        self.countRate = countRate
        self.duration = duration
        self.yearOf = yearOf
        self.views = views
        self.season = season
        self.genre = genre
        self.quality = quality
        self.authors = authors
        self.countries = countries
        self.follows = follows
        self.language = language
        self.studio = studio
        self.seasonOf = seasonOf
        self.trailer = trailer
        self.related = related
        self.extra = extra
        self.externalPlatforms = externalPlatforms
    }
}

// MARK: - Chapter / Episode

public struct ChapterInfo: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let extra: [String: String]

    public init(id: String, name: String, extra: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.extra = extra
    }
}

public struct ChapterData: Equatable {
    public let chaps: [ChapterInfo]
    /// (current, total, year) tuple equivalent from Android Triple
    public let update: (current: Int, total: Int, year: Int)?
    public let image: String
    public let poster: String

    public init(chaps: [ChapterInfo],
                update: (current: Int, total: Int, year: Int)? = nil,
                image: String = "",
                poster: String = "") {
        self.chaps = chaps
        self.update = update
        self.image = image
        self.poster = poster
    }

    public static func == (lhs: ChapterData, rhs: ChapterData) -> Bool {
        lhs.chaps == rhs.chaps &&
        lhs.image == rhs.image &&
        lhs.poster == rhs.poster
    }
}

// MARK: - Server / Player

public struct ServerInfo: Equatable {
    public let name: String
    public let extra: [String: String]

    public init(name: String, extra: [String: String] = [:]) {
        self.name = name
        self.extra = extra
    }
}

public struct PlayerData: Equatable {
    public let link: String
    public let type: String           // "m3u8", "mp4", "embed", etc.
    public let headers: [String: String]?
    public let isContent: Bool        // true when link IS the content (not a redirect)

    public init(link: String,
                type: String,
                headers: [String: String]? = nil,
                isContent: Bool = false) {
        self.link = link
        self.type = type
        self.headers = headers
        self.isContent = isContent
    }
}

// MARK: - Schedule

public struct ScheduleDay: Equatable, Identifiable {
    public var id: TimeInterval { date }
    public let date: TimeInterval   // Unix timestamp (seconds)
    public let items: [AnimeCard]

    public init(date: TimeInterval, items: [AnimeCard]) {
        self.date = date
        self.items = items
    }
}

// MARK: - Search

public struct SearchSuggestion: Equatable, Identifiable {
    public let animeId: String
    public let image: String
    public let name: String
    public let status: String
    public var id: String { animeId }

    public init(animeId: String, image: String, name: String, status: String) {
        self.animeId = animeId
        self.image = image
        self.name = name
        self.status = status
    }
}

public struct CategoryPage: Equatable {
    public let items: [AnimeCard]
    public let totalPages: Int
    public let currentPage: Int
    public let name: String
    public let title: String

    public init(items: [AnimeCard],
                totalPages: Int,
                currentPage: Int,
                name: String = "",
                title: String = "") {
        self.items = items
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.name = name
        self.title = title
    }
}

// MARK: - Trigger

public struct Trigger: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String?
    public let extra: [String: String]

    public init(id: String, name: String? = nil, extra: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.extra = extra
    }
}

// MARK: - Notifications

public struct NotificationItem: Codable, Equatable, Identifiable {
    public let id: String
    public let image: String?
    public let avatar: String?
    public let title: String
    public let content: String
    public let description: String
    public let link: String
    public let animeId: String?
    public let chapId: String?
    public let createdAt: Date?
    public let closeTrigger: Trigger?

    public init(id: String,
                image: String? = nil,
                avatar: String? = nil,
                title: String = "",
                content: String = "",
                description: String = "",
                link: String = "",
                animeId: String? = nil,
                chapId: String? = nil,
                createdAt: Date? = nil,
                closeTrigger: Trigger? = nil) {
        self.id = id
        self.image = image
        self.avatar = avatar
        self.title = title
        self.content = content
        self.description = description
        self.link = link
        self.animeId = animeId
        self.chapId = chapId
        self.createdAt = createdAt
        self.closeTrigger = closeTrigger
    }
}
// MARK: - Double Range (for intro/outro skip)

public struct DoubleRange: Codable, Equatable {
    public let start: Double
    public let end: Double

    public init(start: Double, end: Double) {
        self.start = start
        self.end = end
    }

    public func contains(_ value: Double) -> Bool {
        return value >= start && value <= end
    }
}

public struct InOutroEpisode: Codable, Equatable {
    public let intro: DoubleRange
    public let outro: DoubleRange
    public let episodeName: String?

    public init(intro: DoubleRange, outro: DoubleRange, episodeName: String? = nil) {
        self.intro = intro
        self.outro = outro
        self.episodeName = episodeName
    }
}

// MARK: - Network Error

public enum AnimeDataSourceError: LocalizedError {
    case notImplemented(String)
    case networkError(Error)
    case parseError(String)
    case unauthorized
    case notFound(String)
    case serverError(Int, String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let msg): return "Not implemented: \(msg)"
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .parseError(let msg): return "Parse error: \(msg)"
        case .unauthorized: return "Authentication required"
        case .notFound(let msg): return "Not found: \(msg)"
        case .serverError(let code, let msg): return "Server error \(code): \(msg)"
        }
    }
}
