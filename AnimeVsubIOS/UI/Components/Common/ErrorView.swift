// ErrorView.swift
// AnimeVsubIOS
//
// Generic error screen shown when a network or parsing failure occurs.
// Provides a retry button whose action is supplied by the caller.

import SwiftUI

// MARK: - ErrorView

struct ErrorView: View {

    // MARK: Inputs

    /// The error message to display.  Falls back to a generic Vietnamese message.
    var message: String?
    /// Called when the user taps the retry button.
    var onRetry: (() -> Void)?

    // MARK: Body

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Error icon
            Image(systemName: "wifi.exclamationmark")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(Color(hex: "#E53935").opacity(0.85))

            // Title
            Text("Đã xảy ra lỗi")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Error detail
            Text(message ?? "Không thể tải dữ liệu. Vui lòng kiểm tra kết nối và thử lại.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Retry button
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Thử lại")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#E53935"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#1a1a1a"))
    }
}

// MARK: - Preview

#if DEBUG
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(
            message: "Lỗi mạng: The Internet connection appears to be offline.",
            onRetry: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif
