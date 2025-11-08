import SwiftUI
import Combine

final class TestViewModel: ObservableObject {
    @Published var pingAmount: Int = 0 // in ms
    @Published var jitterAmount: Int = 0 // in ms
    @Published var lossAmount: Int = 0 // in percentage
    @Published var selectedUnit: String = "ms" // user selected unit

}
