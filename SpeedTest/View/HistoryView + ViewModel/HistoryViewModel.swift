import SwiftUI
import Combine

final class HistoryViewModel: ObservableObject {
    @Published var historyItems: [TestResultEntity] = []
    @Published var isInEdit: Bool = false
    @Published var unitAmount: String = "Mbit/s"
    init() {
        historyItems = TestResultEntity.fetchAll()
    }
}
