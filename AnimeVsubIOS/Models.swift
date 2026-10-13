// Models.swift
// AnimeVsubIOS (iOS 12+)
// Ported from Android git.shin.animevsub.data.model.Models.kt

import Foundation

public struct ChapterInfo: Codable, Hashable {
    public let id: String
    public let name: String
    public let extra: [String: String]?

    public init(id: String, name: String, extra: [String: String]? = nil) {
        self.id = id
        self.name = name
        self.extra = extra
    }
}

public struct AnimeCard: Codable, Hashable {
    public let animeId: String
    public let image: String
    public let name: String
    public let lastEpisode: ChapterInfo?
    public let rate: Double
    public let views: Int?
    public let quality: String?
    public let process: String?
    public let year: Int?

    public init(
        animeId: String,
        image: String,
        name: String,
        lastEpisode: ChapterInfo? = nil,
        rate: Double = 0.0,
        views: Int? = nil,
        quality: String? = nil,
        process: String? = nil,
        year: Int? = nil
    ) {
        self.animeId = animeId
        self.image = image
        self.name = name
        self.lastEpisode = lastEpisode
        self.rate = rate
        self.views = views
        self.quality = quality
        self.process = process
        self.year = year
    }
}

public struct HomeData: Codable {
    public let thisSeason: [AnimeCard]
    public let carousel: [AnimeCard]
    public let lastUpdate: [AnimeCard]
    public let preRelease: [AnimeCard]
    public let nominate: [AnimeCard]
    public let hotUpdate: [AnimeCard]

    public init(
        thisSeason: [AnimeCard] = [],
        carousel: [AnimeCard] = [],
        lastUpdate: [AnimeCard] = [],
        preRelease: [AnimeCard] = [],
        nominate: [AnimeCard] = [],
        hotUpdate: [AnimeCard] = []
    ) {
        self.thisSeason = thisSeason
        self.carousel = carousel
        self.lastUpdate = lastUpdate
        self.preRelease = preRelease
        self.nominate = nominate
        self.hotUpdate = hotUpdate
    }
}

public struct CategoryPage: Codable {
    public let items: [AnimeCard]
    public let totalPages: Int
    public let currentPage: Int
    public let name: String?
    public let title: String?

    public init(items: [AnimeCard], totalPages: Int = 1, currentPage: Int = 1, name: String? = nil, title: String? = nil) {
        self.items = items
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.name = name
        self.title = title
    }
}

public struct Season: Codable, Hashable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct CategoryLink: Codable, Hashable {
    public let name: String
    public let filters: [SelectedFilter]?

    public init(name: String, filters: [SelectedFilter]? = nil) {
        self.name = name
        self.filters = filters
    }
}

public struct SelectedFilter: Codable, Hashable {
    public let groupId: String
    public let id: String
    public let name: String
    public let include: Bool?
    public let exclude: Bool?

    public init(groupId: String, id: String, name: String, include: Bool? = nil, exclude: Bool? = nil) {
        self.groupId = groupId
        self.id = id
        self.name = name
        self.include = include
        self.exclude = exclude
    }
}

public struct AnimeDetail: Codable {
    public let name: String
    public let othername: String?
    public let image: String?
    public let poster: String?
    public let description: String
    public let rate: Double
    public let countRate: Int
    public let duration: String?
    public let views: Int
    public let quality: String?
    public let trailer: String?
    public let season: [Season]
    public let genre: [CategoryLink]

    public init(
        name: String,
        othername: String? = nil,
        image: String? = nil,
        poster: String? = nil,
        description: String = "",
        rate: Double = 0.0,
        countRate: Int = 0,
        duration: String? = nil,
        views: Int = 0,
        quality: String? = nil,
        trailer: String? = nil,
        season: [Season] = [],
        genre: [CategoryLink] = []
    ) {
        self.name = name
        self.othername = othername
        self.image = image
        self.poster = poster
        self.description = description
        self.rate = rate
        self.countRate = countRate
        self.duration = duration
        self.views = views
        self.quality = quality
        self.trailer = trailer
        self.season = season
        self.genre = genre
    }
}

public struct PlayerData: Codable, Hashable {
    public let link: String
    public let type: String
    public let headers: [String: String]?
    public let isContent: Bool?

    public init(link: String, type: String = "m3u8", headers: [String: String]? = nil, isContent: Bool? = false) {
        self.link = link
        self.type = type
        self.headers = headers
        self.isContent = isContent
    }
}

public struct SearchSuggestion: Codable, Hashable {
    public let id: String
    public let name: String
    public let image: String?

    public init(id: String, name: String, image: String? = nil) {
        self.id = id
        self.name = name
        self.image = image
    }
}
