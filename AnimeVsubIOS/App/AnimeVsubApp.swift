import SwiftUI

@main
struct AnimeVsubApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

/// Global app state shared across the app
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    
    let preferences = PreferencesManager.shared
    let historyRepo = HistoryRepository.shared
    let animeRepo = AnimeRepository.shared
    
    init() {
        // Load persisted user if any
        if let userData = UserDefaults.standard.data(forKey: "current_user"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    func login(user: User) {
        self.currentUser = user
        self.isLoggedIn = true
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "current_user")
        }
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "current_user")
    }
}
