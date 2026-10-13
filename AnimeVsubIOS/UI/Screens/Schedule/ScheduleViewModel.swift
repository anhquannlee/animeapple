import Foundation

@MainActor
final class ScheduleViewModel: ObservableObject {
    @Published var scheduleDays: [ScheduleDay] = []
    @Published var isLoading: Bool = false

    func load() async {
        isLoading = true
        self.scheduleDays = []
        isLoading = false
    }
}
