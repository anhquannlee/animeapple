// PlaylistModels.swift
// AnimeVsubIOS
//
// Ported from:
//   git.shin.animevsub.data.model.PlaylistModels.kt
//
// Kotlin @SerialName annotations are mapped to Swift CodingKeys.
// Kotlin `public` keyword conflict is avoided — Swift `isPublic` is used directly.

import Foundation

// MARK: - Playlist

/// A user-created playlist that groups anime together.
struct Playlist: Codable, Identifiable, Hashable {
    /// Server-assigned playlist identifier.
    let id: Int
    /// User-facing playlist name.
    let name: String
    /// Optional description entered by the user.
    let description: String?
    /// Whether the playlist is publicly visible (mapped from JSON key `"public"`).
    let isPublic: Bool
    /// ISO-8601 timestamp string of when the playlist was created (mapped from `"created_at"`).
    let createdAt: String?
    /// Number of anime added to this playlist (mapped from `"movies_count"`).
    let movieCount: Int
    /// URL of the playlist's auto-generated poster image (mapped from `"poster_url"`).
    let poster: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case isPublic   = "public"
        case createdAt  = "created_at"
        case movieCount = "movies_count"
        case poster     = "poster_url"
    }

    init(
        id: Int,
        name: String,
        description: String? = nil,
        isPublic: Bool = false,
        createdAt: String? = nil,
        movieCount: Int = 0,
        poster: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.movieCount = movieCount
        self.poster = poster
    }

    /// Parses `createdAt` as a `Date` using ISO-8601 format.
    var createdAtDate: Date? {
        guard let raw = createdAt else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }
}

// MARK: - PlaylistItem

/// A single anime entry within a playlist.
struct PlaylistItem: Codable, Hashable {
    /// Server-assigned row ID (may be nil for locally-constructed objects).
    let id: Int?
    /// Display name of the anime.
    let name: String
    /// URL of the anime's poster image.
    let poster: String
    /// Season ID the item belongs to (mapped from `"season"`).
    let seasonId: String
    /// Human-readable season name (mapped from `"name_season"`).
    let seasonName: String
    /// ID of the bookmarked chapter, if any (mapped from `"chap"`).
    let chapId: String?
    /// Human-readable name of the bookmarked chapter, if any (mapped from `"name_chap"`).
    let chapName: String?
    /// ISO-8601 timestamp string of when the item was added to the playlist (mapped from `"add_at"`).
    let addAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case poster
        case seasonId   = "season"
        case seasonName = "name_season"
        case chapId     = "chap"
        case chapName   = "name_chap"
        case addAt      = "add_at"
    }

    init(
        id: Int? = nil,
        name: String,
        poster: String,
        seasonId: String,
        seasonName: String,
        chapId: String? = nil,
        chapName: String? = nil,
        addAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.poster = poster
        self.seasonId = seasonId
        self.seasonName = seasonName
        self.chapId = chapId
        self.chapName = chapName
        self.addAt = addAt
    }

    /// Parses `addAt` as a `Date` using ISO-8601 format.
    var addAtDate: Date? {
        guard let raw = addAt else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }
}

// MARK: - PlaylistHasMovieResponse

/// API response indicating whether a specific anime season is already in a playlist.
struct PlaylistHasMovieResponse: Codable, Hashable {
    /// The playlist that was queried (mapped from `"playlist_id"`).
    let playlistId: Int
    /// `true` when the anime is already a member of this playlist (mapped from `"has_movie"`).
    let hasMovie: Bool

    enum CodingKeys: String, CodingKey {
        case playlistId = "playlist_id"
        case hasMovie   = "has_movie"
    }

    init(playlistId: Int, hasMovie: Bool) {
        self.playlistId = playlistId
        self.hasMovie = hasMovie
    }
}

// MARK: - PlaylistPosterResponse

/// API response returned after a playlist's cover image is updated.
struct PlaylistPosterResponse: Codable, Hashable {
    /// New poster URL; `nil` if the server removed the image.
    let poster: String?

    init(poster: String? = nil) {
        self.poster = poster
    }
}
