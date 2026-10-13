import SwiftUI

struct NotificationScreen: View {
    @StateObject private var viewModel = NotificationViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Không có thông báo mới.")
                        .foregroundColor(.gray)
                }
            } else {
                List(viewModel.notifications, id: \.id) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(item.content)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(hex: "#1a1a1a"))
                }
                .listStyle(PlainListStyle())
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Thông báo")
        .task {
            await viewModel.load()
        }
    }
}
