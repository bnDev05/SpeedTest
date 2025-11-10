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
                SpeedometerView(state: $currentState, speed: $speed, onStart: {
                    startTest()
                })
                    .frame(width: 350, height: 350)
                
                Spacer()
                
                // Button below
                if case .connecting = currentState {
                    ConnectingButtonView()
                } else if case .testing = currentState {
                    TestingButtonView()
                } else if case .error(let message) = currentState {
                    VStack(spacing: 16) {
                        ErrorButtonView(action: startTest)
                        
                        Text(message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 0.2, green: 0.15, blue: 0.15))
                            )
                    }
                } else {
                    StartButtonView(action: startTest, isConnected: isConnected, showMessage: .constant(true))
                }
                
                Spacer()
            }
        }
    }
    
    private var isConnected: Bool {
        // Simulating connection check - in real app, check actual connectivity
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
    
    // Track previous speed to determine direction
    @State private var previousSpeed: Double = 0
    @State private var isSpeedIncreasing: Bool = true

    let speedMarks = [
        (value: 0, angle: 150.0),
        (value: 10, angle: 170.0),
        (value: 20, angle: 190.0),
        (value: 50, angle: 220.0),
        (value: 100, angle: 260.0),
        (value: 200, angle: 300.0),
        (value: 300, angle: 330.0),
        (value: 600, angle: 360.0),
        (value: 1000, angle: 390.0)
    ]
    
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
                    StartButtonView(
                        action: {
                            onStart()
                        },
                        isConnected: isConnected,
                        showMessage: $showMessage
                    )
                    .position(
                        x: center.x,
                        y: showMessage ? center.y + geo.size.height * 0.14 : center.y
                    )

                } else if case .connecting = state {
                    ConnectingButtonView()
                        .position(x: center.x, y: center.y)
                    
                } else {
                    Circle()
                        .trim(from: 0, to: min(currentProgress * (240.0 / 360.0), 240.0 / 360.0))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#03A9EB"),
                                    Color(hex: "#71F681"),
                                    Color(red: 0.7, green: 1, blue: 0.3)
                                ]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(240)
                            ),
                            style: StrokeStyle(lineWidth: 28, lineCap: .round)
                        )
                        .frame(width: radius * 2, height: radius * 2)
                        .rotationEffect(.degrees(150))
                        .animation(.easeOut(duration: 0.3), value: currentProgress)
                    
                    // Speed number labels
                    ForEach(speedMarks, id: \.value) { mark in
                        let radian = mark.angle * .pi / 180
                        let labelRadius = radius * 0.78
                        let x = center.x + labelRadius * cos(radian)
                        let y = center.y + labelRadius * sin(radian)
                        
                        Text("\(mark.value)")
                            .font(.poppins(.medium, size: 14))
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
                            Image(isSpeedIncreasing ? .pinkUploadIcon : .speedDownIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28, alignment: .center)
                            
                            Text("Mbit/s")
                                .font(.poppins(.medium, size: 18))
                                .foregroundColor(Color(hex: "#787F88"))
                        }
                    }
                    .position(x: center.x, y: center.y + radius * 0.9)
                }
            }
        }
        .onChange(of: currentSpeed) { newSpeed in
            // Update speed direction
            if newSpeed > previousSpeed {
                isSpeedIncreasing = true
            } else if newSpeed < previousSpeed {
                isSpeedIncreasing = false
            }
            
            previousSpeed = newSpeed
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
        return String(format: "%.2f", currentSpeed)
    }
    
    private var currentProgress: Double {
        let speed = currentSpeed
        if speed <= 0 { return 0 }
        else if speed <= 10 { return speed / 10 * 0.1 }
        else if speed <= 50 { return 0.1 + (speed - 10) / 40 * 0.2 }
        else if speed <= 100 { return 0.3 + (speed - 50) / 50 * 0.2 }
        else if speed <= 300 { return 0.5 + (speed - 100) / 200 * 0.25 }
        else if speed <= 1000 { return 0.75 + (speed - 300) / 700 * 0.25 }
        return 1.0
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
                    
                    Text("Start")
                        .font(.poppins(.bold, size: 25))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
        
            if showMessage {
                if isConnected {
                    Text("You are connected \nto the Internet")
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
                        .padding(.top, -5)
                } else {
                    Text("Check your connection:\nthe speed test may fail")
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
                        .padding(.top, -5)
                }
            }
        }
        .onAppear {
            showMessageWithFade()
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
}

// MARK: - Connecting Button View
struct ConnectingButtonView: View {
    @State private var progress: CGFloat = 0
    @State private var rotationDegrees: Double = 0
    let maxTime: Double = 5.0 // max time in seconds
    
    var body: some View {
        ZStack {
            // Background circle with gradient and shadow
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
            
            // Static background ring
            Circle()
                .stroke(
                    Color(hex: "#292F38"),
                    lineWidth: 10
                )
                .frame(width: 140, height: 140)
            
            // Animated progress ring
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
                .rotationEffect(.degrees(-90)) // Start from bottom (270° = -90°)
                .animation(.linear(duration: maxTime), value: progress)
            
            Text("Connection...")
                .font(.poppins(.bold, size: 16))
                .foregroundColor(.white)
        }
        .onAppear {
            // Animate progress from 0 to 1 over maxTime seconds
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
                    
                    Text("Start")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct SpeedTestView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedTestView(speed: .constant(123.1))
    }
}
