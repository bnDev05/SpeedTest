
import SwiftUI

struct ChangeServerView: View {
    @StateObject private var viewModel = ChangeServerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BackView()
            content
        }
    }
    
    private var content: some View {
        VStack(spacing: 15) {
            topView
            searchView
            selectAutomaticallyButton
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Loading servers...")
                            .foregroundColor(.white)
                            .padding()
                    } else if viewModel.filteredServers.isEmpty && !viewModel.servers.isEmpty {
                        Text("No servers found")
                            .font(.poppins(.medium, size: 16))
                            .foregroundColor(Color(hex: "#787F88"))
                            .padding()
                    } else if viewModel.servers.isEmpty {
                        Text("No servers available. Check your connection.")
                            .font(.poppins(.medium, size: 16))
                            .foregroundColor(Color(hex: "#787F88"))
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        ForEach(viewModel.filteredServers, id: \.id) { server in
                            serverCell(server: server)
                                .onTapGesture {
                                    viewModel.selectServer(server)
                                }
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal)
    }
    
    private var topView: some View {
        VStack(spacing: 30) {
            Capsule()
                .frame(width: 50, height: 6, alignment: .center)
                .padding(.top, 5)
                .foregroundStyle(.gray)
            HStack {
                Text("Change server".localized)
                    .font(.poppins(.bold, size: 28))
                    .foregroundStyle(Color.white)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(.glassLiquidXButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36, alignment: .center)
                }
                
            }
        }
    }
    
    private var searchView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30, alignment: .center)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: "#787F88"))
            TextField(text: $viewModel.searchText, prompt: Text("Server search".localized).foregroundColor(Color(hex: "#787F88")), label: {})
                .foregroundStyle(.white)
                .font(.poppins(.medium, size: 18))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .foregroundStyle(Color(hex: "#292F38"))
        )
    }
    
    private var selectAutomaticallyButton: some View {
        Button {
            viewModel.selectAutomatically()
            dismiss()
        } label: {
            HStack {
                Image(.selectAutomaticallyIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28, alignment: .center)
                
                Text("Select automatically".localized)
                    .foregroundStyle(Color(hex: "#4599F5"))
                    .font(.poppins(.medium, size: 18))
            }
        }
    }
    
    @ViewBuilder func serverCell(server: ServerModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(server.name)
                    .font(.onest(.semibold, size: 18))
                    .foregroundStyle(.white)
                Text(server.city)
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.onest(.medium, size: 14))
            }
            .lineLimit(1)
            Spacer()
            
            Text("\(Int(server.distanceKm)) km")
                .foregroundStyle(Color(hex: "#787F88"))
                .font(.poppins(.medium, size: 18))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .foregroundStyle(Color(hex: "#292F38"))
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke((server.host == viewModel.selectedServer.host) ? Color(hex: "#4599F5") : .clear, lineWidth: 2)
                })
        )
    }
}

#Preview {
    ChangeServerView()
}
