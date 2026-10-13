import Foundation

public final class AnimeVietSubDataSource: AnimeDataSource {
    public static let shared = AnimeVietSubDataSource()

    public var hostCurl: String {
        return (URL(string: baseUrl)?.host) ?? "animevietsub.xyz"
    }

    public var baseUrl: String {
        get {
            return UserDefaults.standard.string(forKey: "AnimeVsub.savedBaseURL") ?? "https://animevietsub.xyz"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "AnimeVsub.savedBaseURL")
        }
    }

    public var loginUrl: String { "\(baseUrl)/dang-nhap.html" }

    public func getUser() async -> User? {
        return nil
    }

    public func refreshUser() async throws -> User {
        throw NetworkError.requestFailed(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chưa đăng nhập"]))
    }

    public func logout() async {
        NetworkManager.shared.clearCookies(for: hostCurl)
    }

    public func getHomePage() async throws -> HomeData {
        let data = try await NetworkManager.shared.get(url: baseUrl)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.noData
        }
        return parseHomePage(html: html)
    }

    public func getSchedule() async throws -> [ScheduleDay] {
        return []
    }

    public func getRankings(type: String) async throws -> [AnimeCard] {
        let home = try await getHomePage()
        return home.hotUpdate
    }

    public func getRankingTypes() async throws -> [FilterOption] {
        return [
            FilterOption(id: "day", name: "Ngày"),
            FilterOption(id: "week", name: "Tuần"),
            FilterOption(id: "month", name: "Tháng"),
            FilterOption(id: "year", name: "Năm")
        ]
    }

    public func preSearch(keyword: String) async throws -> [SearchSuggestion] {
        let url = "\(baseUrl)/ajax/suggest"
        let data = try await NetworkManager.shared.postForm(
            url: url,
            params: ["q": keyword, "limit": "10"],
            headers: ["Referer": baseUrl, "X-Requested-With": "XMLHttpRequest"]
        )
        guard let html = String(data: data, encoding: .utf8) else { return [] }
        return parseSuggestions(html: html)
    }

    public func search(keyword: String, page: Int) async throws -> CategoryPage {
        let slug = slugify(keyword)
        let url = "\(baseUrl)/tim-kiem/\(slug)/trang-\(page).html"
        let data = try await NetworkManager.shared.get(url: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.noData
        }
        let items = parseCards(from: html)
        return CategoryPage(items: items, totalPages: max(page, 1), currentPage: page, name: keyword, title: "Tìm kiếm: \(keyword)")
    }

    public func getCategory(filters: [SelectedFilter], page: Int) async throws -> CategoryPage {
        let url = "\(baseUrl)/danh-sach/trang-\(page).html"
        let data = try await NetworkManager.shared.get(url: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.noData
        }
        let items = parseCards(from: html)
        return CategoryPage(items: items, totalPages: 10, currentPage: page, name: "Danh sách", title: "Tất cả anime")
    }

    public func getFilters(filters: [SelectedFilter]) async throws -> [FilterGroup] {
        return []
    }

    public func getAnimeDetail(animeId: String) async throws -> AnimeDetail {
        let url = "\(baseUrl)/phim/\(animeId).html"
        let data = try await NetworkManager.shared.get(url: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.noData
        }
        return parseDetail(html: html, animeId: animeId)
    }

    public func getChapters(animeId: String) async throws -> ChapterData {
        let url = "\(baseUrl)/phim/\(animeId)/xem-phim.html"
        let data = try await NetworkManager.shared.get(url: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.noData
        }
        let chapters = parseEpisodes(from: html)
        return ChapterData(chaps: chapters, update: nil, image: "", poster: "")
    }

    public func getServers(chapter: ChapterInfo) async throws -> [ServerInfo] {
        return [ServerInfo(name: "Vsub Server", extra: chapter.extra ?? [:])]
    }

    public func getPlayerLink(server: ServerInfo) async throws -> PlayerData {
        let url = "\(baseUrl)/ajax/player"
        var params: [String: String] = [
            "id": server.extra["id"] ?? "",
            "play": server.extra["play"] ?? "",
            "link": server.extra["hash"] ?? "",
            "backuplinks": "1"
        ]
        if params["play"]?.isEmpty == true {
            params["episodeId"] = server.extra["id"] ?? ""
        }

        let data = try await NetworkManager.shared.postForm(
            url: url,
            params: params,
            headers: [
                "Referer": baseUrl,
                "X-Requested-With": "XMLHttpRequest"
            ]
        )
        guard let responseStr = String(data: data, encoding: .utf8) else {
            throw NetworkError.noData
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let link = json["link"] as? String, !link.isEmpty {
            return PlayerData(link: link, type: "hls", headers: ["Referer": baseUrl])
        }

        // Regex m3u8
        let pattern = #"https?://[^"'\\ ]+\.m3u8(?:\?[^"'\\ ]*)?"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: responseStr, range: NSRange(responseStr.startIndex..<responseStr.endIndex, in: responseStr)),
           let range = Range(match.range, in: responseStr) {
            let m3u8 = String(responseStr[range])
            return PlayerData(link: m3u8, type: "hls", headers: ["Referer": baseUrl])
        }

        throw NetworkError.requestFailed(NSError(domain: "Player", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy link m3u8"]))
    }

    public func getFollows(filters: [SelectedFilter], page: Int) async throws -> CategoryPage {
        return CategoryPage(items: [], totalPages: 0, currentPage: 1)
    }

    public func getFollowFilters(filters: [SelectedFilter]) async throws -> [FilterGroup] { return [] }
    public func checkFollow(animeId: String) async throws -> Bool { return false }
    public func toggleFollow(animeId: String, follow: Bool) async throws {}
    public func getNotifications() async throws -> NotificationData { return NotificationData() }
    public func onTrigger(trigger: Trigger) async {}

    public func getComments(filmId: String, anime: AnimeDetail, sort: FilterOption?, offset: Int) async throws -> CommentResponse {
        return CommentResponse(status: 200, html: "", page: 1, total: 0)
    }
    public func getReplies(commentId: String, sort: FilterOption?, offset: Int) async throws -> ReplyResponse {
        return ReplyResponse(status: 200, html: "")
    }
    public func postComment(filmId: String, content: String, isSpoiler: Bool, episodeId: String?, parentId: String, threadKey: String?) async throws -> PostCommentResponse {
        return PostCommentResponse(status: 200, message: "OK", item: nil)
    }
    public func voteComment(commentId: String, voteType: VoteType) async throws -> VoteResponse {
        return VoteResponse(status: 200, message: "OK")
    }
    public func editComment(commentId: String, content: String, isSpoiler: Bool) async throws -> EditCommentResponse {
        return EditCommentResponse(status: 200, message: "OK", content: content)
    }
    public func getCommentSortOptions() async throws -> [FilterOption] { return [] }

    // MARK: - HTML Parsing Helpers

    private func parseHomePage(html: String) -> HomeData {
        let cards = parseCards(from: html)
        let carousel = Array(cards.prefix(5))
        let hot = Array(cards.prefix(12))
        let last = Array(cards.dropFirst(5).prefix(15))
        return HomeData(
            thisSeason: hot,
            carousel: carousel,
            lastUpdate: last,
            preRelease: [],
            nominate: hot,
            hotUpdate: hot
        )
    }

    private func parseCards(from html: String) -> [AnimeCard] {
        var items: [AnimeCard] = []
        let pattern = #"<a[^>]+href=["']/phim/([^"']+)\.html["'][^>]*>[\s\S]*?<img[^>]+(?:src|data-src)=["']([^"']+)["'][^>]*alt=["']([^"']+)["']"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                guard match.numberOfRanges >= 4 else { continue }
                let id = nsString.substring(with: match.range(at: 1))
                let img = nsString.substring(with: match.range(at: 2))
                let name = nsString.substring(with: match.range(at: 3))
                if !items.contains(where: { $0.animeId == id }) {
                    items.append(AnimeCard(
                        animeId: id,
                        image: img,
                        name: name,
                        lastEpisode: ChapterInfo(id: "latest", name: "Mới"),
                        rate: 9.0
                    ))
                }
            }
        }
        return items
    }

    private func parseSuggestions(html: String) -> [SearchSuggestion] {
        return parseCards(from: html).map {
            SearchSuggestion(animeId: $0.animeId, image: $0.image, name: $0.name, status: $0.quality ?? "HD")
        }
    }

    private func parseEpisodes(from html: String) -> [ChapterInfo] {
        var episodes: [ChapterInfo] = []
        let pattern = #"data-id=["']([^"']+)["'][^>]*data-play=["']([^"']*)["'][^>]*data-hash=["']([^"']*)["'][^>]*>([\s\S]*?)<\/a>"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                let id = nsString.substring(with: match.range(at: 1))
                let play = nsString.substring(with: match.range(at: 2))
                let hash = nsString.substring(with: match.range(at: 3))
                let nameRaw = nsString.substring(with: match.range(at: 4))
                let name = nameRaw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                episodes.append(ChapterInfo(
                    id: id,
                    name: name.isEmpty ? "Tập \(episodes.count + 1)" : name,
                    extra: ["id": id, "play": play, "hash": hash]
                ))
            }
        }
        return episodes
    }

    private func parseDetail(html: String, animeId: String) -> AnimeDetail {
        let titlePattern = #"<h1[^>]*>([\s\S]*?)<\/h1>"#
        var title = animeId
        if let regex = try? NSRegularExpression(pattern: titlePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: (html as NSString).length)) {
            title = (html as NSString).substring(with: match.range(at: 1))
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return AnimeDetail(
            name: title,
            othername: nil,
            image: nil,
            poster: nil,
            description: "Xem phim \(title) vietsub chất lượng cao tại AnimeVsub.",
            rate: 9.5,
            countRate: 100,
            duration: "24 phút",
            yearOf: nil,
            views: 12000,
            season: [Season(id: animeId, name: "Phần 1")],
            genre: [CategoryLink(name: "Hành Động")],
            quality: "HD",
            authors: [],
            countries: [],
            follows: 500,
            language: "Vietsub",
            studio: nil,
            seasonOf: nil,
            trailer: nil,
            related: []
        )
    }

    private func slugify(_ text: String) -> String {
        return text.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
