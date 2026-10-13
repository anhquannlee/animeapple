// CommentModels.swift
// AnimeVsubIOS
//
// Ported from:
//   git.shin.animevsub.data.model.CommentModels.kt
//
// Kotlin enum class → Swift enum (String raw value for Codable)
// Kotlin data class → Swift struct

import Foundation

// MARK: - VoteType

/// The current vote cast by the authenticated user on a comment.
enum VoteType: String, Codable, Hashable, CaseIterable {
    /// The user up-voted the comment.
    case up   = "UP"
    /// The user down-voted the comment.
    case down = "DOWN"
    /// The user has not voted on this comment.
    case none = "NONE"
}

// MARK: - CommentBadge

/// A decorative badge shown next to a commenter's username (e.g. Moderator, VIP).
struct CommentBadge: Codable, Hashable {
    /// Badge label.
    let name: String
    /// URL or icon identifier for the badge image.
    let icon: String
    /// Hex colour string (e.g. `"#FF5733"`) used to tint the badge.
    let color: String
}

// MARK: - Comment

/// A single comment or reply in a discussion thread.
struct Comment: Codable, Identifiable, Hashable {
    /// Server-assigned unique identifier for the comment.
    let id: String
    /// Numeric ID of the author's account.
    let userId: Int
    /// Display name of the author.
    let userName: String
    /// URL of the author's avatar image.
    let userAvatar: String
    /// Raw text content of the comment.
    let content: String
    /// `true` when the comment is tagged as a spoiler.
    let isSpoiler: Bool
    /// `true` when the comment is awaiting moderation approval.
    let isPending: Bool
    /// `true` when pinned within its thread.
    let isPinned: Bool
    /// `true` when pinned across all threads (globally).
    let isGlobalPinned: Bool
    /// Unix timestamp (milliseconds) of when the comment was posted.
    let createdAt: Int64
    /// Unix timestamp (milliseconds) of the last edit; `nil` if never edited.
    let editedAt: Int64?
    /// Total number of up-votes.
    let votesUp: Int
    /// Total number of down-votes.
    let votesDown: Int
    /// How many direct replies this comment has.
    let repliesCount: Int
    /// The vote cast by the currently authenticated user.
    let userVote: VoteType
    /// Badges awarded to the commenter.
    let badges: [CommentBadge]
    /// Identifier of the discussion thread this comment belongs to.
    let threadKey: String?
    /// ID of the parent comment when this is a reply; `nil` for top-level comments.
    let parentId: String?
    /// `true` when the comment has been hidden by a moderator.
    let isHidden: Bool
    /// Reason supplied by the moderator when hiding the comment.
    let hideReason: String?
    /// Action triggers associated with this comment (e.g. auto-close prompts).
    let triggers: [Trigger]

    init(
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
        hideReason: String? = nil,
        triggers: [Trigger] = []
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
        self.triggers = triggers
    }

    // MARK: Convenience

    /// `createdAt` as a `Date`.
    var createdAtDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt) / 1000.0)
    }

    /// `editedAt` as a `Date`, or `nil` if the comment has never been edited.
    var editedAtDate: Date? {
        guard let ts = editedAt else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts) / 1000.0)
    }
}

// MARK: - CommentResponse

/// Paginated list of top-level comments returned by the comments endpoint.
struct CommentResponse: Codable, Hashable {
    let success: Bool
    let comments: [Comment]
    let total: Int
    let offset: Int
    let hasMore: Bool
    /// Server-side error message, if any.
    let error: String?

    init(
        success: Bool,
        comments: [Comment] = [],
        total: Int = 0,
        offset: Int = 0,
        hasMore: Bool = false,
        error: String? = nil
    ) {
        self.success = success
        self.comments = comments
        self.total = total
        self.offset = offset
        self.hasMore = hasMore
        self.error = error
    }
}

// MARK: - ReplyResponse

/// Paginated list of replies to a specific comment.
struct ReplyResponse: Codable, Hashable {
    let success: Bool
    let replies: [Comment]
    let total: Int
    let offset: Int
    let hasMore: Bool
    /// Server-side error message, if any.
    let error: String?

    init(
        success: Bool,
        replies: [Comment] = [],
        total: Int = 0,
        offset: Int = 0,
        hasMore: Bool = false,
        error: String? = nil
    ) {
        self.success = success
        self.replies = replies
        self.total = total
        self.offset = offset
        self.hasMore = hasMore
        self.error = error
    }
}

// MARK: - PostCommentResponse

/// API response after submitting a new comment or reply.
struct PostCommentResponse: Codable, Hashable {
    let success: Bool
    /// The newly created `Comment` object returned by the server.
    let comment: Comment?
    /// Updated total comment count for the thread.
    let total: Int?
    /// `true` when the submitted comment is held for moderation.
    let pending: Bool
    /// Server-side error message, if any.
    let error: String?

    init(
        success: Bool,
        comment: Comment? = nil,
        total: Int? = nil,
        pending: Bool = false,
        error: String? = nil
    ) {
        self.success = success
        self.comment = comment
        self.total = total
        self.pending = pending
        self.error = error
    }
}

// MARK: - VoteResponse

/// API response after the user casts or removes a vote on a comment.
struct VoteResponse: Codable, Hashable {
    let success: Bool
    /// Updated up-vote count after the vote action.
    let votesUp: Int
    /// Updated down-vote count after the vote action.
    let votesDown: Int
    /// Server-side error message, if any.
    let error: String?

    init(success: Bool, votesUp: Int = 0, votesDown: Int = 0, error: String? = nil) {
        self.success = success
        self.votesUp = votesUp
        self.votesDown = votesDown
        self.error = error
    }
}

// MARK: - EditCommentResponse

/// API response after the user edits one of their own comments.
struct EditCommentResponse: Codable, Hashable {
    let success: Bool
    /// The updated comment text as stored by the server.
    let content: String?
    /// Whether the edited comment was re-tagged as a spoiler.
    let isSpoiler: Bool
    /// Unix timestamp (milliseconds) of the edit; `nil` if not returned.
    let editedAt: Int64?
    /// `true` when the edited comment is held for re-moderation.
    let pending: Bool
    /// Server-side error message, if any.
    let error: String?

    init(
        success: Bool,
        content: String? = nil,
        isSpoiler: Bool = false,
        editedAt: Int64? = nil,
        pending: Bool = false,
        error: String? = nil
    ) {
        self.success = success
        self.content = content
        self.isSpoiler = isSpoiler
        self.editedAt = editedAt
        self.pending = pending
        self.error = error
    }

    /// `editedAt` as a `Date`, or `nil` if not provided.
    var editedAtDate: Date? {
        guard let ts = editedAt else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts) / 1000.0)
    }
}

// MARK: - ActionResponse

/// Generic API response for comment actions (delete, pin, hide, etc.).
struct ActionResponse: Codable, Hashable {
    let success: Bool
    /// Human-readable success or informational message.
    let message: String?
    /// Server-side error message, if any.
    let error: String?
    /// Updated item count, if relevant to the action.
    let total: Int?

    init(success: Bool, message: String? = nil, error: String? = nil, total: Int? = nil) {
        self.success = success
        self.message = message
        self.error = error
        self.total = total
    }
}
