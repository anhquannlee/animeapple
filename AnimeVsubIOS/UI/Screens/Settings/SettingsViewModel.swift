import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var autoNext: Bool
    @Published var autoSkip: Bool
    @Published var currentDomain: String

    private let preferences = PreferencesManager.shared

    init() {
        self.autoNext = preferences.autoNext
        self.autoSkip = preferences.autoSkip
        self.currentDomain = preferences.preferredServer.isEmpty ? "https://animevietsub.xyz" : preferences.preferredServer
    }

    func saveDomain(_ domain: String) {
        preferences.preferredServer = domain
        self.currentDomain = domain
        UserDefaults.standard.set(domain, forKey: "AnimeVsub.savedBaseURL")
    }

    func clearHistory() {
        HistoryManager.shared.clearAll()
    }
}
