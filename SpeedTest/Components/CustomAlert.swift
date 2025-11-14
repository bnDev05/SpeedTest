import SwiftUI

struct CustomAlertView: View {
    let title: String
    let options: [String]
    let onSelect: (Int) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            if #available(iOS 26.0, *) {
                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            Button {
                                onSelect(index)
                                onDismiss()
                            } label: {
                                Text(option)
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(HapticButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .frame(width: 320)
//                .background(Color(uiColor: .systemGray5))
                .cornerRadius(40)
                .glassEffect(in: RoundedRectangle(cornerRadius: 40))
            } else {
                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            Button {
                                onSelect(index)
                                onDismiss()
                            } label: {
                                Text(option)
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(HapticButtonStyle())

                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .frame(width: 320)
                .background(Color(uiColor: .systemGray5))
                .cornerRadius(20)
            }
        }
    }
}
