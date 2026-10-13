import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .home
    
    enum Tab: Int, CaseIterable {
        case home, search, notification, account
        
        var title: String {
            switch self {
            case .home: return "Trang chủ"
            case .search: return "Tìm kiếm"
            case .notification: return "Thông báo"
            case .account: return "Tài khoản"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .search: return "magnifyingglass"
            case .notification: return "bell"
            case .account: return "person"
            }
        }
        
        var iconFilled: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
            case .notification: return "bell.fill"
            case .account: return "person.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeScreen()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: selectedTab == .home ? Tab.home.iconFilled : Tab.home.icon)
                Text(Tab.home.title)
            }
            .tag(Tab.home)
            
            NavigationView {
                SearchScreen()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: Tab.search.icon)
                Text(Tab.search.title)
            }
            .tag(Tab.search)
            
            NavigationView {
                NotificationScreen()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: selectedTab == .notification ? Tab.notification.iconFilled : Tab.notification.icon)
                Text(Tab.notification.title)
            }
            .tag(Tab.notification)
            
            NavigationView {
                AccountScreen()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: selectedTab == .account ? Tab.account.iconFilled : Tab.account.icon)
                Text(Tab.account.title)
            }
            .tag(Tab.account)
        }
        .accentColor(.red)
        .preferredColorScheme(.dark)
    }
}
