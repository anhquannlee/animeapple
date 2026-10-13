import Foundation

public protocol AnimeDataSource {
    var hostCurl: String { get }
    var baseUrl: String { get }
    var loginUrl: String { get }

    func getUser() async -> User?
    func refreshUser() async throws -> User
    func logout() async

    func getHomePage() async throws -> HomeData
    func getSchedule() async throws -> [ScheduleDay]
    func getRankings(type: String) async throws -> [AnimeCard]
    func getRankingTypes() async throws -> [FilterOption]

    func preSearch(keyword: String) async throws -> [SearchSuggestion]
    func search(keyword: String, page: Int) async throws -> CategoryPage
    func getCategory(filters: [SelectedFilter], page: Int) async throws -> CategoryPage
    func getFilters(filters: [SelectedFilter]) async throws -> [FilterGroup]

    func getAnimeDetail(animeId: String) async throws -> AnimeDetail
    func getChapters(animeId: String) async throws -> ChapterData

    func getServers(chapter: ChapterInfo) async throws -> [ServerInfo]
    func getPlayerLink(server: ServerInfo) async throws -> PlayerData

    func getEpisodeSkip(animeId: String, detail: AnimeDetail, chapter: ChapterInfo) async throws -> InOutroEpisode?

    func getFollows(filters: [SelectedFilter], page: Int) async throws -> CategoryPage
    func getFollowFilters(filters: [SelectedFilter]) async throws -> [FilterGroup]
    func checkFollow(animeId: String) async throws -> Bool
    func toggleFollow(animeId: String, follow: Bool) async throws

    func getNotifications() async throws -> NotificationData
    func onTrigger(trigger: Trigger) async

    func getComments(filmId: String, anime: AnimeDetail, sort: FilterOption?, offset: Int) async throws -> CommentResponse
    func getReplies(commentId: String, sort: FilterOption?, offset: Int) async throws -> ReplyResponse
    func postComment(filmId: String, content: String, isSpoiler: Bool, episodeId: String?, parentId: String, threadKey: String?) async throws -> PostCommentResponse
    func voteComment(commentId: String, voteType: VoteType) async throws -> VoteResponse
    func editComment(commentId: String, content: String, isSpoiler: Bool) async throws -> EditCommentResponse

    func getCommentSortOptions() async throws -> [FilterOption]

    func encodeURI(_ url: String) -> String
    func decodeURI(_ url: String) -> String
}

public extension AnimeDataSource {
    func getEpisodeSkip(animeId: String, detail: AnimeDetail, chapter: ChapterInfo) async throws -> InOutroEpisode? {
        return nil
    }

    func encodeURI(_ url: String) -> String {
        return url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
    }

    func decodeURI(_ url: String) -> String {
        return url.removingPercentEncoding ?? url
    }
}
