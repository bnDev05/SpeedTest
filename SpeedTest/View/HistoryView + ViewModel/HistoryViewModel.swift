import SwiftUI
import Combine

final class HistoryViewModel: ObservableObject {
    @Published var historyItems: [TestResultEntity] = []
    @Published var isInEdit: Bool = false
    @Published var unitAmount: String = "Mbit/s"
    
    @AppStorage("unit") private var unit: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        historyItems = TestResultEntity.fetchAll()
        updateUnitDisplay()
        observeUnitChanges()
    }
    
    private func observeUnitChanges() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateUnitDisplay()
            }
            .store(in: &cancellables)
    }
    
    private func updateUnitDisplay() {
        let selectedUnit = SpeedUnit(rawValue: unit) ?? .mbitPerSec
        unitAmount = selectedUnit.displayName
    }
    
    // Convert stored speed (in Mbit/s) to current selected unit
    func convertSpeed(_ speedInMbit: Double) -> Double {
        let selectedUnit = SpeedUnit(rawValue: unit) ?? .mbitPerSec
        return SpeedConverter.shared.convertSpeed(speedInMbit, to: selectedUnit)
    }
    
    // Format speed for display
    func formatSpeed(_ speedInMbit: Double) -> String {
        let convertedSpeed = convertSpeed(speedInMbit)
        return String(format: "%.0f", convertedSpeed)
    }
}
