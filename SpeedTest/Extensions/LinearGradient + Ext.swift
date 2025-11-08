
import SwiftUI

extension LinearGradient {
    static var appBlueGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#4599F5"),
                Color(hex: "#245BEB")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
