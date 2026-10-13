import SwiftUI

struct SettingsScreen: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var domainText: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Nguồn Anime").foregroundColor(.red)) {
                HStack {
                    Text("Tên miền")
                    Spacer()
                    TextField("Domain", text: $domainText)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.gray)
                }
                Button("Lưu tên miền") {
                    viewModel.saveDomain(domainText)
                    showAlert = true
                }
                .foregroundColor(.red)
            }

            Section(header: Text("Trình phát").foregroundColor(.red)) {
                Toggle("Tự động chuyển tập", isOn: $viewModel.autoNext)
                Toggle("Tự động bỏ qua Intro", isOn: $viewModel.autoSkip)
            }

            Section(header: Text("Dữ liệu").foregroundColor(.red)) {
                Button("Xoá toàn bộ lịch sử xem") {
                    viewModel.clearHistory()
                }
                .foregroundColor(.red)
            }

            Section(header: Text("Thông tin ứng dụng").foregroundColor(.gray)) {
                HStack {
                    Text("Phiên bản")
                    Spacer()
                    Text("2.0.0 (SwiftUI Native)")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Tương thích")
                    Spacer()
                    Text("iOS 12+ (iPhone 6 trở lên)")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            domainText = viewModel.currentDomain
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Thành công"), message: Text("Đã lưu tên miền nguồn"), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Cài đặt")
    }
}
