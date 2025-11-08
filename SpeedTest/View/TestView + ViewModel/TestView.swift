import SwiftUI

struct TestView: View {
    @StateObject private var viewModel = TestViewModel()
    
    var body: some View {
        ZStack {
            BackView()
            content
        }
    }
    
    private var content: some View {
        VStack {
            title
            topInfoView
        }
        .padding(.horizontal)
    }
    
    private var title: some View {
        Text("Speed Test".localized)
            .font(.poppins(.semibold, size: 24))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)

    }
    
    private var topInfoView: some View {
        HStack(spacing: 40) {
            topInfoCell(icon: .pingSpeedIcon, title: "Ping:".localized, amount: viewModel.pingAmount)
            topInfoCell(icon: .jitterSpeedIcon, title: "Jitter:".localized, amount: viewModel.jitterAmount)
            topInfoCell(icon: .lossSpeedIcon, title: "Loss:".localized, amount: viewModel.lossAmount, isPercentage: true)
        }
    }
    
    @ViewBuilder private func topInfoCell(icon: ImageResource, title: String, amount: Int, isPercentage: Bool = false) -> some View {
        VStack(alignment: .trailing) {
            HStack {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20, alignment: .center)
                Text(title.localized)
                    .font(.poppins(.medium, size: 16))
                    .foregroundStyle(Color(hex: "#787F88"))
            }
            
            HStack(spacing: 3) {
                Text("\(amount)")
                    .font(.poppins(.semibold, size: 16))
                    .foregroundColor(.white)
                Text(isPercentage ? "%" : viewModel.selectedUnit)
                    .font(.poppins(.medium, size: 16))
                    .foregroundStyle(Color(hex: "#787F88"))
            }
        }
    }
}

#Preview {
    TestView()
}
