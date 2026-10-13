import SwiftUI

struct AccountScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 55, height: 55)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.currentUser?.name ?? "Khách")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(appState.currentUser?.email ?? "Chưa đăng nhập")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color(hex: "#1a1a1a"))

            Section(header: Text("Chức năng").foregroundColor(.gray)) {
                NavigationLink(destination: HistoryScreen()) {
                    Label("Lịch sử xem", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink(destination: FollowScreen()) {
                    Label("Đang theo dõi", systemImage: "heart")
                }
                NavigationLink(destination: SettingsScreen()) {
                    Label("Cài đặt", systemImage: "gearshape")
                }
                NavigationLink(destination: AboutScreen()) {
                    Label("Giới thiệu", systemImage: "info.circle")
                }
            }
            .listRowBackground(Color(hex: "#1a1a1a"))
        }
        .listStyle(GroupedListStyle())
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Tài khoản")
    }
}
