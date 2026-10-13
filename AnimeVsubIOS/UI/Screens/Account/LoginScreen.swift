import SwiftUI
import WebKit

struct LoginScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            Text("Đăng nhập")
                .font(.headline)
                .padding()
            Spacer()
            Text("Tính năng đăng nhập qua tài khoản đang hoàn thiện.")
                .foregroundColor(.gray)
            Spacer()
            Button("Đóng") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
    }
}
