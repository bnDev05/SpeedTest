import SwiftUI

struct TestView: View {
    @StateObject private var viewModel = TestViewModel()
    
    var body: some View {
        ZStack {
            BackView()
            content
        }
        .navigationBarBackButtonHidden()
    }
    
    private var content: some View {
        VStack {
            title
            topInfoView
            Spacer()
            SpeedometerView(state: $viewModel.speedState, speed: $viewModel.speed, isConnected: viewModel.isConnected) {
                viewModel.startTest()
            }
            .frame(width: UIScreen.main.bounds.width - 80, height: UIScreen.main.bounds.width - 80, alignment: .center)
            Spacer()
            sourceAndProvidersView
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
    
    private var sourceAndProvidersView: some View {
        VStack(spacing: 14) {
            sourceProviderCell(image: viewModel.isWifiSource ? .wifiProvider : .internetProviderIcon, name: viewModel.sourceName, subtitle: viewModel.phoneName)
            sourceProviderCell(image: .internetProviderIcon, name: viewModel.serverName, subtitle: viewModel.serverLocationName, isProvider: true)
        }
    }
    
    @ViewBuilder
    private func sourceProviderCell(image: ImageResource, name: String, subtitle: String, isProvider: Bool = false) -> some View {
        HStack(alignment: .top) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40, alignment: .center)
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.poppins(.semibold, size: 16))
                    .foregroundStyle(.white)
                
                HStack {
                    Text(subtitle)
                        .font(.poppins(.medium, size: 16))
                        .foregroundStyle(Color(hex: "#787F88"))
                    
                    if isProvider {
                        Button {
                            
                        } label: {
                            Text("Change testing server".localized)
                                .font(.poppins(.medium, size: 16))
                                .foregroundStyle(Color(hex: "#4599F5"))
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(height: 52)
    }
}

#Preview {
    TestView()
}
