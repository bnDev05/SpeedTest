
import SwiftUI
internal import StoreKit

struct RateAppView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isRateApp: Bool
    var body: some View {
        ZStack(alignment: .bottom) {
            back
            VStack {
                Spacer()
                content
            }
            .ignoresSafeArea()
            .background(.clear)
        }
        .background(.clear)
    }
    
    private var back: some View {
        Color(hex: "#050503").opacity(0.2)
            .background(.ultraThinMaterial)
            .blur(radius: 22.2)
            .ignoresSafeArea()
            .onTapGesture {
                isRateApp = false
            }
            .padding(.horizontal, -35)
    }
    
    private var content: some View {
        VStack(spacing: 10) {
            Image(.rateAppTop)
                .resizable()
                .scaledToFit()
                .padding(.all, -20)
            
            Text("How was your experience?".localized)
                .foregroundStyle(.white)
                .font(.poppins(.bold, size: 22))
            
            Text("We truly value your input—it helps \nus continuously improve".localized)
                .multilineTextAlignment(.center)
                .font(.poppins(.medium, size: 16))
                .foregroundStyle(Color(hex: "#787F88"))
                .padding(.bottom, 40)
            
            Button {
                openAppStoreForRating()
            } label: {
                ZStack {
                    LinearGradient.appBlueGradient
                        .clipShape(Capsule())
                        .frame(height: 70)
                        .shadow(color: Color(hex: "#245BEB78").opacity(0.47), radius: 10, x: 5, y: 10)
                    Text("Write a review".localized)
                        .font(.onest(.semibold, size: 18))
                        .foregroundStyle(.white)
                }
            }

            Button {
                isRateApp = false
            } label: {
                Text("Not now".localized)
                    .font(.onest(.semibold, size: 18))
                    .foregroundStyle(Color(hex: "#919591"))
                    .frame(height: 53)
            }

        }
        .padding(20)
        .padding(.vertical, 10)
        .padding(.bottom, 60)
        .background(
            RoundedRectangle(cornerRadius: 38)
                .foregroundStyle(Color(hex: "#040A15"))
        )
        .padding(.bottom, -60)
    }
    
    private func openAppStoreForRating() {

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        
         if let url = URL(string: "itms-apps:itunes.apple.com/us/app/apple-store/id\(Config.appID)?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    RateAppView(isRateApp: .constant(false))
}
