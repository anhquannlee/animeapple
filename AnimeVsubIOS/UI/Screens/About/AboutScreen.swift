import SwiftUI

struct AboutScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)

            Text("AnimeVsub iOS")
                .font(.title)
                .bold()

            Text("Phiên bản 2.0.0")
                .foregroundColor(.gray)

            Text("Ứng dụng xem Anime Vietsub native được xây dựng bằng Swift & SwiftUI, hỗ trợ iPhone 6 (iOS 12+) trở lên.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
        .padding(.top, 40)
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Giới thiệu")
    }
}
