
import SwiftUI

struct TabView: View {
    @State private var selection: Tabs = .test
    @State private var tabAppears: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            TabContent(selection)
            
            if tabAppears {
                if #available(iOS 26.0, *) {
                    HStack(spacing: 0) {
                        ForEach(Tabs.allCases) { tab in
                            TabButton(
                                tab: tab,
                                isSelected: selection == tab
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selection = tab
                                }
                            }
                        }
                    }
                    .buttonStyle(HapticButtonStyle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(hex: "040A15").overlay(content: {
                        Color.white.opacity(0.12)
                    }))
                    .glassEffect()
                    .clipShape(Capsule())
                    .padding(.horizontal, 15)
                } else {
                    HStack(spacing: 0) {
                        ForEach(Tabs.allCases) { tab in
                            TabButton(
                                tab: tab,
                                isSelected: selection == tab
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selection = tab
                                }
                            }
                        }
                    }
                    .buttonStyle(HapticButtonStyle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(hex: "040A15").overlay(content: {
                        Color.white.opacity(0.12)
                    }))
                    .clipShape(Capsule())
                    .padding(.horizontal, 15)
                }
            }
        }
        .background(Color(hex: "#040A15"))
    }
    
    @ViewBuilder
    func TabContent(_ tab: Tabs) -> some View {
        switch tab {
        case .test: TestView()
        case .signal: SignalView()
        case .history: HistoryView(currentTab: $selection)
        case .settings: SettingsView(tabAppears: $tabAppears)
        }
    }
}

struct TabButton: View {
    let tab: Tabs
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                tab.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(isSelected ? .white : Color(hex: "#787F88"))
                
                Text(tab.title.localized)
                    .font(.poppins(.medium, size: 12))
            }
            .foregroundStyle(isSelected ? .white : Color(hex: "#787F88"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .background(
                Group {
                    if isSelected {
                        LinearGradient.appBlueGradient
                            .clipShape(Capsule())
                    } else {
                        Color.clear
                            .clipShape(Rectangle())
                    }
                }
            )
//            .clipShape(isSelected ? Capsule() : Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
    }
}

enum Tabs: String, CaseIterable, Identifiable {
    case test, signal, history, settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .test: "Test"
        case .signal: "Signal"
        case .history: "History"
        case .settings: "Settings"
        }
    }
    
    var image: Image {
        switch self {
        case .test: Image(.tab0)
        case .signal: Image(.tab1)
        case .history: Image(.tab2)
        case .settings: Image(.tab3)
        }
    }
}

#Preview {
    TabView()
}
