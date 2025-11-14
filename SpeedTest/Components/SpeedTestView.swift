import SwiftUI
import CoreGraphics

// MARK: - Speed Test State
enum SpeedTestState: Equatable {
    case idle
    case connecting
    case testing(speed: Double)
    case complete(speed: Double)
    case error(message: String)
}

// MARK: - Main Speed Test View
struct SpeedTestView: View {
    @State private var currentState: SpeedTestState = .idle
    @Binding var speed: Double

    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main speedometer
                SpeedometerView(
                    state: $currentState,
                    speed: $speed,
                    onStart: {
                        startTest()
                    },
                    isDownloadSpeed: .constant(true)
                )
                .frame(width: 350, height: 350)
                
                Spacer()
                
                NetworkDiagnosticsView(
                    action: {},
                    progressPercentage: .constant(70),
                    diagnosticStatus: .constant(1)
                )
                
                Spacer()
            }
        }
    }
    
    private var isConnected: Bool {
        return Bool.random()
    }
    
    private func startTest() {
        currentState = .connecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            simulateSpeedTest()
        }
    }
    
    private func simulateSpeedTest() {
        var speed = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            speed += Double.random(in: 5...15)
            
            if speed >= 300 {
                timer.invalidate()
                currentState = .complete(speed: speed)
            } else {
                currentState = .testing(speed: speed)
            }
        }
    }
}

// MARK: - Speedometer View
struct SpeedometerView: View {
    @Binding var state: SpeedTestState
    @Binding var speed: Double
    var isConnected: Bool = true
    var onStart: (() -> Void)
    @State private var showMessage = false
    @Binding var isDownloadSpeed: Bool
    @State private var messageOpacity: Double = 0
    @AppStorage("unit") private var unit: Int = 0
    @AppStorage("dialScale") private var dialScale: Int = 0
    
    @State private var selectedUnit: SpeedUnit = .mbitPerSec
    @State private var selectedDialScale: DialScale = .scale1000

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius: CGFloat = size * 0.42

            ZStack {
                Circle()
                    .trim(from: 0.0, to: 240.0 / 360.0)
                    .stroke(
                        Color(hex: "#292F38"),
                        style: StrokeStyle(lineWidth: 28, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(150))

                if state == .idle || state == .complete(speed: speed) {
                    VStack(spacing: 0) {
                        StartButtonView(
                            action: {
                                onStart()
                            },
                            isConnected: isConnected,
                            showMessage: $showMessage
                        )
                        .onAppear {
                            showMessageWithFade()
                        }
                        .position(
                            x: center.x,
                            y: showMessage ? center.y : center.y
                        )
                        
                        if showMessage {
                            if isConnected {
                                Text("You are connected \nto the Internet".localized)
                                    .font(.poppins(.medium, size: 16))
                                    .foregroundColor(Color(hex: "#4599F5"))
                                    .multilineTextAlignment(.center)
                                    .frame(height: 45)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 22)
                                            .fill(Color(hex: "#4599F5").opacity(0.15))
                                    )
                                    .opacity(messageOpacity)
                                    .padding(.top, -10)
                            } else {
                                Text("Check your connection:\nthe speed test may fail".localized)
                                    .font(.poppins(.medium, size: 16))
                                    .foregroundColor(Color(hex: "#FF4D6D"))
                                    .frame(height: 45)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 22)
                                            .fill(Color(red: 0.3, green: 0.1, blue: 0.15))
                                    )
                                    .opacity(messageOpacity)
                                    .padding(.top, -10)
                            }
                        }
                    }

                } else if case .connecting = state {
                    ConnectingButtonView()
                        .position(x: center.x, y: center.y)
                    
                } else {
                    Circle()
                        .trim(from: 0, to: min(currentProgress * (240.0 / 360.0), 240.0 / 360.0))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors:
                                    isDownloadSpeed ?
                                    [
                                        Color(hex: "#71F681"),
                                        Color(hex: "#03A9EB")
                                    ] :
                                    [
                                        Color(hex: "#F472AE"),
                                        Color(hex: "#7652D0")
                                    ]
                                ),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(240)
                            ),
                            style: StrokeStyle(lineWidth: 28, lineCap: .round)
                        )
                        .frame(width: radius * 2, height: radius * 2)
                        .rotationEffect(.degrees(150))
                        .animation(.easeOut(duration: 0.3), value: currentProgress)
                    
                    // Speed number labels based on dial scale
                    ForEach(selectedDialScale.getSpeedMarks(), id: \.value) { mark in
                        let radian = mark.angle * .pi / 180
                        let labelRadius = radius * 0.78
                        let x = center.x + labelRadius * cos(radian)
                        let y = center.y + labelRadius * sin(radian)
                        
                        Text("\(mark.value)")
                            .font(.poppins(.medium, size: mark.value >= 1000 ? 12 : 14))
                            .foregroundColor(.white)
                            .position(x: x, y: y)
                    }
                    
                    // Needle stick
                    ZStack {
                        Image(.stick)
                            .resizable()
                            .scaledToFill()
                            .frame(width: radius * 0.6, height: 12)
                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                            .offset(x: radius * 0.35)
                            .rotationEffect(.degrees(needleAngle))
                    }
                    .position(center)
                    
                    VStack(spacing: 8) {
                        Text(speedText)
                            .font(.poppins(.semibold, size: 48))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        HStack(spacing: 6) {
                            Image(!isDownloadSpeed ? .pinkUploadIcon : .speedDownIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28, alignment: .center)
                            
                            Text(selectedUnit.displayName)
                                .font(.poppins(.medium, size: 18))
                                .foregroundColor(Color(hex: "#787F88"))
                        }
                    }
                    .position(x: center.x, y: center.y + radius * 0.9)
                }
            }
        }
        .onAppear {
            selectedUnit = SpeedUnit(rawValue: unit) ?? .mbitPerSec
            selectedDialScale = DialScale(rawValue: dialScale) ?? .scale1000
        }
    }
    
    private func showMessageWithFade() {
        showMessage = true
        
        withAnimation(.easeIn(duration: 0.3)) {
            messageOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeOut(duration: 0.5)) {
                messageOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showMessage = false
            }
        }
    }
    
    // MARK: - Computed properties
    private var currentSpeed: Double {
        switch state {
        case .testing(let speed): return speed
        case .complete(let speed): return speed
        default: return 0
        }
    }
    
    private var speedText: String {
        if case .idle = state { return "0.00" }
        // Always show actual converted value, even if it exceeds dial scale
        let convertedSpeed = SpeedConverter.shared.convertSpeed(currentSpeed, to: selectedUnit)
        return String(format: "%.2f", convertedSpeed)
    }
    
    private var currentProgress: Double {
        // Use converted speed for dial position, but clamp it to dial scale max
        let convertedSpeed = SpeedConverter.shared.convertSpeed(currentSpeed, to: selectedUnit)
        return selectedDialScale.calculateProgress(for: convertedSpeed)
    }
    
    private var needleAngle: Double {
        return 150 + (currentProgress * 240)
    }
}

// MARK: - Start Button View
struct StartButtonView: View {
    let action: () -> Void
    let isConnected: Bool
    @Binding var showMessage: Bool
    @State private var messageOpacity: Double = 0

    var body: some View {
        VStack(spacing: 30) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#171F2C"), Color(hex: "#0F1826")],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .shadow(
                            color: isConnected ? Color(hex: "#245BEB").opacity(0.4) : Color(hex: "#F71C4C").opacity(0.4),
                            radius: 54,
                            x: 0,
                            y: 0
                        )
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: isConnected
                                ? [Color(hex: "#03A9EB"), Color(hex: "#03A9EB").opacity(0.7)]
                                : [Color(hex: "#FF4D6D"), Color(hex: "#FF4D6D").opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 9.49
                        )
                        .frame(width: 140, height: 140)
                    
                    Text("Start".localized)
                        .font(.poppins(.bold, size: 25))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(HapticButtonStyle())
        }
    }
}

struct NetworkDiagnosticsView: View {
    let action: () -> Void
    @Binding var progressPercentage: Int
    @Binding var diagnosticStatus: Int
    
    var body: some View {
        Button {
            if diagnosticStatus == 0 {
                action()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "#171F2C"), Color(hex: "#0F1826")],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .shadow(
                        color: Color(hex: "#00D37F").opacity(0.4),
                        radius: 76,
                        x: 0,
                        y: 0
                    )
                    .frame(width: 180, height: 180)
                
                Circle()
                    .stroke(
                        Color(hex: "#292F38"),
                        lineWidth: 13
                    )
                    .frame(width: 167, height: 167)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progressPercentage) / 100.0)
                    .stroke(
                        Color(hex: "#00D37F"),
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .frame(width: 167, height: 167)
                    .rotationEffect(.degrees(90))
                    .animation(.linear, value: CGFloat(progressPercentage) / 100.0)
                
                Text((diagnosticStatus == 0) ? "Start" : ((diagnosticStatus == 1) ? "\(progressPercentage)%" : "Ready".localized))
                    .font(.poppins(.bold, size: (diagnosticStatus == 1) ? 50 : 34))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(HapticButtonStyle())
        .disabled(diagnosticStatus != 0)
    }
}

// MARK: - Connecting Button View
struct ConnectingButtonView: View {
    @State private var progress: CGFloat = 0
    @State private var rotationDegrees: Double = 0
    let maxTime: Double = 5.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hex: "#171F2C"), Color(hex: "#0F1826")],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .shadow(
                    color: Color(hex: "#245BEB").opacity(0.4),
                    radius: 54,
                    x: 0,
                    y: 0
                )
                .frame(width: 140, height: 140)
            
            Circle()
                .stroke(
                    Color(hex: "#292F38"),
                    lineWidth: 10
                )
                .frame(width: 140, height: 140)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#4599F5"), Color(hex: "#245BEB").opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(90))
                .animation(.linear(duration: maxTime), value: progress)
            
            Text("Connection...".localized)
                .font(.poppins(.bold, size: 16))
                .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(.linear(duration: maxTime)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Needle Shape
struct NeedleShape: Shape {
    let angle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let length = rect.width
        let radian = angle * .pi / 180
        
        let endPoint = CGPoint(
            x: center.x + length * cos(radian),
            y: center.y + length * sin(radian)
        )
        
        path.move(to: center)
        path.addLine(to: endPoint)
        
        return path
    }
}

// MARK: - Testing Button View
struct TestingButtonView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.18, green: 0.2, blue: 0.24), lineWidth: 18)
                .frame(width: 180, height: 180)
        }
    }
}

// MARK: - Error Button View
struct ErrorButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#FF4D6D"), Color(hex: "#FF4D6D").opacity(0.7)],
                            center: .center,
                            startRadius: 61,
                            endRadius: 70
                        )
                    )
                    .frame(width: 180, height: 180)
                
                ZStack {
                    Circle()
                        .fill(Color(red: 0.13, green: 0.15, blue: 0.18))
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.red, Color.red.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 110, height: 110)
                    
                    Text("Start".localized)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(HapticButtonStyle())
    }
}

// MARK: - Preview
struct SpeedTestView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedTestView(speed: .constant(123.1))
    }
}
