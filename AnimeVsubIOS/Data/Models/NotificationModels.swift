import Foundation

public struct NotificationData: Codable, Equatable {
    public let items: [NotificationItem]
    public let max: Int

    public init(items: [NotificationItem] = [], max: Int = 0) {
        self.items = items
        self.max = max
    }
}

public struct DbNotificationEpisode: Codable, Equatable, Identifiable {
    public let id: Int?
    public let name: String
    public let time: String?
    public let chapId: String
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, time
        case chapId = "chap_id"
        case createdAt = "created_at"
    }
}

public struct DbNotificationItem: Codable, Equatable, Identifiable {
    public var id: String { season }
    public let season: String
    public let name: String
    public let image: String?
    public let episodes: [DbNotificationEpisode]
    public let latestChapTime: String?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case season, name, image, episodes
        case latestChapTime = "latest_chap_time"
        case createdAt = "created_at"
    }
}
