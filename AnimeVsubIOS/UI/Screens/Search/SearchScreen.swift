import SwiftUI

// MARK: - SearchScreen

struct SearchScreen: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var searchFocused: Bool

    /// Navigation closure – caller (ContentView / NavigationLink) supplies this
    var onNavigateToDetail: ((_ animeId: String, _ episodeId: String?) -> Void)?

    // 2-column grid
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            Color("DarkBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                Divider().background(Color.white.opacity(0.08))
                content
            }
        }
        .navigationBarHidden(true)
        .onAppear { searchFocused = true }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("TextGrey"))
                .padding(.leading, 12)

            TextField("", text: $viewModel.state.query)
                .placeholder(when: viewModel.state.query.isEmpty) {
                    Text("Tìm kiếm anime…")
                        .foregroundColor(Color("TextGrey"))
                }
                .foregroundColor(Color("TextPrimary"))
                .submitLabel(.search)
                .focused($searchFocused)
                .onSubmit {
                    viewModel.onSearch(viewModel.state.query)
                    searchFocused = false
                }
                .onChange(of: viewModel.state.query) { newValue in
                    viewModel.onQueryChange(newValue)
                }

            if !viewModel.state.query.isEmpty {
                Button {
                    viewModel.onQueryChange("")
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("TextGrey"))
                }
                .padding(.trailing, 8)
            }
        }
        .frame(height: 44)
        .background(Color("DarkCard"))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Content switch

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isSearching {
            searchResultsView
        } else if viewModel.state.query.isEmpty {
            historyView
        } else if viewModel.state.isLoadingSuggestions {
            suggestionSkeletonView
        } else {
            suggestionsView
        }
    }

    // MARK: - History

    private var historyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.state.searchHistory.isEmpty {
                    emptyState(message: "Chưa có lịch sử tìm kiếm")
                } else {
                    HStack {
                        Text("Lịch sử tìm kiếm")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("TextPrimary"))
                        Spacer()
                        Button("Xóa tất cả") {
                            viewModel.clearHistory()
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Color("AccentMain"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // Chip row (wrapping)
                    SearchHistoryChips(
                        history: viewModel.state.searchHistory,
                        onTap: { term in
                            viewModel.onQueryChange(term)
                            viewModel.onSearch(term)
                            searchFocused = false
                        },
                        onDelete: { term in
                            viewModel.removeHistoryItem(term)
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.state.suggestions) { suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        onNavigateToDetail?(suggestion.id, nil)
                    }
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.leading, 78)
                }

                if !viewModel.state.suggestions.isEmpty {
                    Button {
                        viewModel.onSearch(viewModel.state.query)
                        searchFocused = false
                    } label: {
                        Text("Xem tất cả kết quả cho \"\(viewModel.state.query)\"")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("AccentMain"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                } else if !viewModel.state.isLoadingSuggestions {
                    emptyState(message: "Không tìm thấy gợi ý")
                }
            }
        }
    }

    // MARK: - Suggestion skeleton

    private var suggestionSkeletonView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { _ in
                    SuggestionSkeletonRow()
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.leading, 78)
                }
            }
        }
    }

    // MARK: - Search Results (grid)

    private var searchResultsView: some View {
        ZStack {
            if viewModel.state.isLoadingResults && viewModel.state.searchResults.isEmpty {
                searchResultsSkeleton
            } else if viewModel.state.searchResults.isEmpty && !viewModel.state.isLoadingResults {
                emptyState(message: viewModel.state.error ?? "Không có kết quả nào")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(viewModel.state.searchResults) { item in
                            AnimeGridCard(
                                id: item.id,
                                name: item.name,
                                posterURL: item.posterURL,
                                subLabel: item.subCount
                            ) {
                                onNavigateToDetail?(item.id, nil)
                            }
                            .onAppear {
                                // Trigger load more when nearing end
                                if item.id == viewModel.state.searchResults.last?.id {
                                    viewModel.loadMore()
                                }
                            }
                        }

                        if viewModel.state.isLoadingMore {
                            ForEach(0..<2, id: \.self) { _ in
                                AnimeGridCardSkeleton()
                            }
                        }
                    }
                    .padding(12)
                }
                .refreshable { viewModel.refresh() }
            }
        }
    }

    private var searchResultsSkeleton: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<10, id: \.self) { _ in AnimeGridCardSkeleton() }
            }
            .padding(12)
        }
    }

    // MARK: - Empty state

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(Color("TextGrey"))
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Color("TextGrey"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - SearchHistoryChips

/// Wrapping chip layout for recent search terms
private struct SearchHistoryChips: View {
    let history: [String]
    let onTap: (String) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(history, id: \.self) { term in
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(Color("TextGrey"))
                        Text(term)
                            .font(.system(size: 13))
                            .foregroundColor(Color("TextPrimary"))
                        Button {
                            onDelete(term)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color("TextGrey"))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color("DarkCard"))
                    .cornerRadius(20)
                    .onTapGesture { onTap(term) }
                }
            }
        }
    }
}

// MARK: - SuggestionRow

private struct SuggestionRow: View {
    let suggestion: SearchSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncPosterImage(url: suggestion.image)
                    .frame(width: 50, height: 70)
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("TextPrimary"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(suggestion.status)
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextGrey"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextGrey"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - SuggestionSkeletonRow

private struct SuggestionSkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
                .frame(width: 50, height: 70)
                .shimmer()

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(maxWidth: .infinity)
                    .frame(height: 14)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 11)
                    .shimmer()
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - AnimeGridCard

struct AnimeGridCard: View {
    let id: String
    let name: String
    let posterURL: String
    let subLabel: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                AsyncPosterImage(url: posterURL)
                    .aspectRatio(2/3, contentMode: .fill)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        VStack {
                            Spacer()
                            Text(subLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color("AccentMain"))
                                .cornerRadius(4)
                                .padding(6)
                        }, alignment: .bottomLeading
                    )

                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - AnimeGridCardSkeleton

struct AnimeGridCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .aspectRatio(2/3, contentMode: .fill)
                .shimmer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(height: 12)
                .shimmer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(width: 60, height: 12)
                .shimmer()
        }
    }
}

// MARK: - AsyncPosterImage

/// A simple async image view with a grey placeholder.
struct AsyncPosterImage: View {
    let url: String

    var body: some View {
        if let imageURL = URL(string: url) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    Color.white.opacity(0.08).shimmer()
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.white.opacity(0.08)
                        .overlay(Image(systemName: "photo").foregroundColor(Color("TextGrey")))
                @unknown default:
                    Color.white.opacity(0.08)
                }
            }
        } else {
            Color.white.opacity(0.08)
                .overlay(Image(systemName: "photo").foregroundColor(Color("TextGrey")))
        }
    }
}

// MARK: - TextField placeholder helper

extension View {
    func placeholder<Content: View>(
        when condition: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            if condition { placeholder() }
            self
        }
    }
}
