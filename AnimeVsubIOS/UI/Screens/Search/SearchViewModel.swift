import Foundation
import Combine

// MARK: - Models

/// A full search result item (same shape as an AnimeItem used on Home)
public struct AnimeSearchResult: Identifiable, Equatable {
    public let id: String       // animeId
    public let name: String
    public let posterURL: String
    public let subCount: String  // e.g. "Vietsub – 24/24"
    public let year: String
    public let rating: String

    public init(id: String, name: String, posterURL: String, subCount: String, year: String, rating: String) {
        self.id = id
        self.name = name
        self.posterURL = posterURL
        self.subCount = subCount
        self.year = year
        self.rating = rating
    }
}

/// Active search filters
public struct SearchFilter: Equatable {
    public var genre: String?     // nil = all genres
    public var year: String?      // nil = all years
    public var status: String?    // "ongoing" | "completed" | nil
    public var sortBy: String     // "newest" | "name" | "views"

    public static let `default` = SearchFilter(genre: nil, year: nil, status: nil, sortBy: "newest")

    public init(genre: String? = nil, year: String? = nil, status: String? = nil, sortBy: String = "newest") {
        self.genre = genre
        self.year = year
        self.status = status
        self.sortBy = sortBy
    }
}

// MARK: - UI State

struct SearchUiState {
    var query: String = ""
    var suggestions: [SearchSuggestion] = []
    var searchResults: [AnimeSearchResult] = []
    var searchHistory: [String] = []
    var filter: SearchFilter = .default

    /// True when a full search is active (user pressed Search / tapped "Xem tất cả")
    var isSearching: Bool = false
    var isLoadingSuggestions: Bool = false
    var isLoadingResults: Bool = false
    var isLoadingMore: Bool = false
    var hasMore: Bool = true
    var currentPage: Int = 1
    var error: String? = nil
}

// MARK: - ViewModel

@MainActor
final class SearchViewModel: ObservableObject {

    @Published var state = SearchUiState()

    // Debounce pipeline
    private var queryCancellable: AnyCancellable?
    private let querySubject = PassthroughSubject<String, Never>()

    private let preferences = PreferencesManager.shared
    private let animeRepo   = AnimeRepository.shared

    init() {
        loadHistory()
        setupDebouncedSuggestions()
    }

    // MARK: - Public actions

    /// Called on every keystroke in the search bar
    func onQueryChange(_ newQuery: String) {
        state.query = newQuery
        state.isSearching = false
        state.searchResults = []
        state.error = nil

        if newQuery.isEmpty {
            state.suggestions = []
            state.isLoadingSuggestions = false
        } else {
            querySubject.send(newQuery)
        }
    }

    /// Called when user presses the Search key or taps "Xem tất cả"
    func onSearch(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        state.query = query
        state.isSearching = true
        state.searchResults = []
        state.currentPage = 1
        state.hasMore = true
        state.error = nil

        saveHistory(query)
        Task { await fetchResults(page: 1, reset: true) }
    }

    /// Infinite-scroll trigger
    func loadMore() {
        guard state.hasMore,
              !state.isLoadingMore,
              !state.isLoadingResults else { return }
        Task { await fetchResults(page: state.currentPage + 1, reset: false) }
    }

    /// Pull-to-refresh
    func refresh() {
        guard state.isSearching else { return }
        Task { await fetchResults(page: 1, reset: true) }
    }

    func setFilter(_ filter: SearchFilter) {
        state.filter = filter
        if state.isSearching {
            state.searchResults = []
            state.currentPage = 1
            state.hasMore = true
            Task { await fetchResults(page: 1, reset: true) }
        }
    }

    func clearHistory() {
        state.searchHistory = []
        preferences.clearSearchHistory()
    }

    func removeHistoryItem(_ item: String) {
        state.searchHistory.removeAll { $0 == item }
        preferences.saveSearchHistory(state.searchHistory)
    }

    // MARK: - Private helpers

    private func setupDebouncedSuggestions() {
        queryCancellable = querySubject
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self, !query.isEmpty else { return }
                Task { await self.fetchSuggestions(query: query) }
            }
    }

    private func fetchSuggestions(query: String) async {
        state.isLoadingSuggestions = true
        defer { state.isLoadingSuggestions = false }

        do {
            let results = try await animeRepo.fetchSuggestions(query: query)
            // Only apply if the query hasn't changed since the request started
            guard state.query == query, !state.isSearching else { return }
            state.suggestions = results
        } catch {
            // Suggestions are best-effort – silently ignore errors
            state.suggestions = []
        }
    }

    private func fetchResults(page: Int, reset: Bool) async {
        if reset {
            state.isLoadingResults = true
        } else {
            state.isLoadingMore = true
        }
        defer {
            state.isLoadingResults = false
            state.isLoadingMore   = false
        }

        do {
            let (items, hasMore) = try await animeRepo.searchAnime(
                query: state.query,
                page: page,
                filter: state.filter
            )
            if reset {
                state.searchResults = items
            } else {
                state.searchResults.append(contentsOf: items)
            }
            state.hasMore    = hasMore
            state.currentPage = page
            state.error       = nil
        } catch {
            state.error = error.localizedDescription
        }
    }

    private func loadHistory() {
        state.searchHistory = preferences.loadSearchHistory()
    }

    private func saveHistory(_ query: String) {
        var history = state.searchHistory
        history.removeAll { $0 == query }
        history.insert(query, at: 0)
        if history.count > 20 { history = Array(history.prefix(20)) }
        state.searchHistory = history
        preferences.saveSearchHistory(history)
    }
}
