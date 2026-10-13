// CommentModels.swift
// AnimeVsubIOS
//
// Ported from:
//   git.shin.animevsub.data.model.CommentModels.kt

import Foundation

// MARK: - VoteType

public enum VoteType: String, Codable, Hashable, CaseIterable {
    case up   = "UP"
    case down = "DOWN"
    case none = "NONE"
}

// MARK: - CommentBadge

public struct CommentBadge: Codable, Hashable {
    public let name: String
    public let icon: String
    public let color: String

    public init(name: String, icon: String, color: String) {
        self.name = name
        self.icon = icon
        self.color = color
    }
}

// MARK: - Comment

public struct Comment: Codable, Identifiable, Hashable {
    public let id: String
    public let userId: Int
    public let userName: String
    public let userAvatar: String
    public let content: String
    public let isSpoiler: Bool
    public let isPending: Bool
    public let isPinned: Bool
    public let isGlobalPinned: Bool
    public let createdAt: Int64
    public let editedAt: Int64?
    public let votesUp: Int
    public let votesDown: Int
    public let repliesCount: Int
    public let userVote: VoteType
    public let badges: [CommentBadge]
    public let threadKey: String?
    public let parentId: String?
    public let isHidden: Bool
    public let hideReason: String?

    public init(
        id: String,
        userId: Int,
        userName: String,
        userAvatar: String,
        content: String,
        isSpoiler: Bool = false,
        isPending: Bool = false,
        isPinned: Bool = false,
        isGlobalPinned: Bool = false,
        createdAt: Int64,
        editedAt: Int64? = nil,
        votesUp: Int = 0,
        votesDown: Int = 0,
        repliesCount: Int = 0,
        userVote: VoteType = .none,
        badges: [CommentBadge] = [],
        threadKey: String? = nil,
        parentId: String? = nil,
        isHidden: Bool = false,
        hideReason: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.content = content
        self.isSpoiler = isSpoiler
        self.isPending = isPending
        self.isPinned = isPinned
        self.isGlobalPinned = isGlobalPinned
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.votesUp = votesUp
        self.votesDown = votesDown
        self.repliesCount = repliesCount
        self.userVote = userVote
        self.badges = badges
        self.threadKey = threadKey
        self.parentId = parentId
        self.isHidden = isHidden
        self.hideReason = hideReason
    }

    public var createdAtDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt) / 1000.0)
    }

    public var editedAtDate: Date? {
        guard let ts = editedAt else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts) / 1000.0)
    }
}

// MARK: - CommentResponse

public struct CommentResponse: Codable, Hashable {
    public let status: Int
    public let html: String
    public let page: Int
    public let total: Int

    public init(
        status: Int = 200,
        html: String = "",
        page: Int = 1,
        total: Int = 0
    ) {
        self.status = status
        self.html = html
        self.page = page
        self.total = total
    }
}

// MARK: - ReplyResponse

public struct ReplyResponse: Codable, Hashable {
    public let status: Int
    public let html: String

    public init(status: Int = 200, html: String = "") {
        self.status = status
        self.html = html
    }
}

// MARK: - PostCommentResponse

public struct PostCommentResponse: Codable, Hashable {
    public let status: Int
    public let message: String
    public let item: Comment?

    public init(
        status: Int = 200,
        message: String = "OK",
        item: Comment? = nil
    ) {
        self.status = status
        self.message = message
        self.item = item
    }
}

// MARK: - VoteResponse

public struct VoteResponse: Codable, Hashable {
    public let status: Int
    public let message: String
    public let votesUp: Int
    public let votesDown: Int

    public init(status: Int = 200, message: String = "OK", votesUp: Int = 0, votesDown: Int = 0) {
        self.status = status
        self.message = message
        self.votesUp = votesUp
        self.votesDown = votesDown
    }
}

// MARK: - EditCommentResponse

public struct EditCommentResponse: Codable, Hashable {
    public let status: Int
    public let message: String
    public let content: String

    public init(
        status: Int = 200,
        message: String = "OK",
        content: String = ""
    ) {
        self.status = status
        self.message = message
        self.content = content
    }
}
