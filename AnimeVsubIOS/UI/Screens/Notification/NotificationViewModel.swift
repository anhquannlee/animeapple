import Foundation

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading: Bool = false

    func load() async {
        isLoading = true
        // Best-effort load
        self.notifications = []
        isLoading = false
    }
}
