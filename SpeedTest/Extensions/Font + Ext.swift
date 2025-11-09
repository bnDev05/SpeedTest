
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

enum OnestWeight: String {
    case regular  = "Onest-Regular"
    case medium   = "Onest-Medium"
    case semibold = "Onest-SemiBold"
    case bold     = "Onest-Bold"
    case light    = "Onest-Light"
    case extrabold = "Onest-ExtraBold"
    case thin     = "Onest-Thin"
    case black    = "Onest-Black"
}


extension Font {
    static func onest(_ weight: OnestWeight, size: CGFloat) -> Font {
        return Font.custom(weight.rawValue, size: size)
    }
}
