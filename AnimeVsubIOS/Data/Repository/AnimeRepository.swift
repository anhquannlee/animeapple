import Foundation

public final class AnimeRepository {
    public static let shared = AnimeRepository()

    private let dataSource: AnimeDataSource
    private var homeCache: (data: HomeData, timestamp: Date)?

    public init(dataSource: AnimeDataSource = AnimeVietSubDataSource.shared) {
        self.dataSource = dataSource
    }

    public func getHomePage(forceRefresh: Bool = false) async throws -> HomeData {
        if !forceRefresh, let cache = homeCache, Date().timeIntervalSince(cache.timestamp) < 300 {
            return cache.data
        }
        let data = try await dataSource.getHomePage()
        homeCache = (data, Date())
        return data
    }

    public func fetchSuggestions(query: String) async throws -> [SearchSuggestion] {
        return try await dataSource.preSearch(keyword: query)
    }

    public func searchAnime(query: String, page: Int, filter: SearchFilter) async throws -> ([AnimeSearchResult], Bool) {
        let catPage = try await dataSource.search(keyword: query, page: page)
        let results = catPage.items.map {
            AnimeSearchResult(
                id: $0.animeId,
                name: $0.name,
                posterURL: $0.image,
                subCount: $0.lastEpisode?.name ?? "HD",
                year: $0.year != nil ? "\($0.year!)" : "2024",
                rating: String(format: "%.1f", $0.rate)
            )
        }
        let hasMore = catPage.currentPage < catPage.totalPages
        return (results, hasMore)
    }

    public func getAnimeDetail(animeId: String) async throws -> AnimeDetail {
        return try await dataSource.getAnimeDetail(animeId: animeId)
    }

    public func getChapters(animeId: String) async throws -> ChapterData {
        return try await dataSource.getChapters(animeId: animeId)
    }

    public func getServers(chapter: ChapterInfo) async throws -> [ServerInfo] {
        return try await dataSource.getServers(chapter: chapter)
    }

    public func getPlayerLink(server: ServerInfo) async throws -> PlayerData {
        return try await dataSource.getPlayerLink(server: server)
    }

    public func checkFollow(animeId: String) async throws -> Bool {
        return try await dataSource.checkFollow(animeId: animeId)
    }

    public func toggleFollow(animeId: String, follow: Bool) async throws {
        try await dataSource.toggleFollow(animeId: animeId, follow: follow)
    }

    public func getSchedule() async throws -> [ScheduleDay] {
        return try await dataSource.getSchedule()
    }

    public func getRankings(type: String) async throws -> [AnimeCard] {
        return try await dataSource.getRankings(type: type)
    }

    public func getRankingTypes() async throws -> [FilterOption] {
        return try await dataSource.getRankingTypes()
    }

    public func getCategory(filters: [SelectedFilter], page: Int) async throws -> CategoryPage {
        return try await dataSource.getCategory(filters: filters, page: page)
    }
}
