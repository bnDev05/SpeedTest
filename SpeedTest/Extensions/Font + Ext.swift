
import UIKit
import SwiftUI


enum PoppinsWeight: String {
    case regular  = "Poppins-Regular"
    case medium   = "Poppins-Medium"
    case semibold = "Poppins-SemiBold"
    case bold     = "Poppins-Bold"
    case light    = "Poppins-Light"
    case extrabold = "Poppins-ExtraBold"
    case thin     = "Poppins-Thin"
    case black    = "Poppins-Black"
}


extension Font {
    static func poppins(_ weight: PoppinsWeight, size: CGFloat) -> Font {
        return Font.custom(weight.rawValue, size: size)
    }
}
