import SwiftUI

struct ScheduleScreen: View {
    @StateObject private var viewModel = ScheduleViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text("Lịch phát sóng đang được cập nhật.")
                    .foregroundColor(.gray)
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Lịch chiếu")
        .task {
            await viewModel.load()
        }
    }
}
