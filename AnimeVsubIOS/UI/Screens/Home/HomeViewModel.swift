// HomeViewModel.swift
// AnimeVsubIOS
//
// Ported from:
//   git.shin.animevsub.ui.screens.home.HomeViewModel.kt
//
// Uses Swift async/await + @MainActor instead of Kotlin coroutines.
// AnimeRepository.shared replaces Hilt-injected repository.

import Foundation
import Combine

// MARK: - HomeUiState

struct HomeUiState {
    var isLoading: Bool = true
    var data: HomeData? = nil
    var error: String? = nil
    var isRefreshing: Bool = false
}

// MARK: - HomeViewModel

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: Published State

    @Published private(set) var uiState = HomeUiState()

    // MARK: Dependencies

    private let repository: AnimeRepository

    // MARK: Init

    init(repository: AnimeRepository = .shared) {
        self.repository = repository
        Task { await loadHomePage() }
    }

    // MARK: Public API

    /// Loads the home page data. Sets `isLoading = true` while fetching.
    func loadHomePage() async {
        uiState = HomeUiState(isLoading: true, error: nil)
        await fetchHome(isRefresh: false)
    }

    /// Pull-to-refresh: keeps existing data visible, sets `isRefreshing = true`.
    func refresh() async {
        uiState.isRefreshing = true
        await fetchHome(isRefresh: true)
    }

    // MARK: Private Helpers

    private func fetchHome(isRefresh: Bool) async {
        do {
            let data = try await repository.getHomePage()
            uiState = HomeUiState(
                isLoading: false,
                data: data,
                error: nil,
                isRefreshing: false
            )
        } catch {
            if isRefresh {
                // Keep existing data on refresh failure; surface error only
                uiState.isRefreshing = false
                uiState.error = error.localizedDescription
            } else {
                uiState = HomeUiState(
                    isLoading: false,
                    data: nil,
                    error: error.localizedDescription,
                    isRefreshing: false
                )
            }
        }
    }
}
