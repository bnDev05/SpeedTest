import SwiftUI
import Charts

struct SpeedDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let speed: Double
}

struct UploadDownloadView: View {
    let isDownload: Bool
    var isGreen: Bool = true
    @State private var selectedUnit: String = "Mbit"
    @Binding var speed: Double
    
    // Store historical speed data for the chart
    @State private var speedHistory: [SpeedDataPoint] = []
    @State private var maxDataPoints = 30
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(isDownload ? .greenDownloadIcon : (isGreen ? .greenUploadIcon : .pinkUploadIcon))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24, alignment: .center)
                
                Text(isDownload ? "Download".localized : "Upload".localized)
                    .font(.poppins(.semibold, size: 16))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            HStack(alignment: .bottom) {
                Text(String(format: "%.0f", speed))
                    .foregroundStyle(.white)
                    .font(.poppins(.semibold, size: 24))
                
                Text("\(selectedUnit)/s")
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.poppins(.semibold, size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            // Chart
            if !speedHistory.isEmpty {
                Chart(speedHistory) { dataPoint in
                    AreaMark(
                        x: .value("Time", dataPoint.index),
                        y: .value("Speed", dataPoint.speed)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#3ACFB6").opacity(0.45),
                                Color(hex: "#3ACFB6").opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Time", dataPoint.index),
                        y: .value("Speed", dataPoint.speed)
                    )
                    .foregroundStyle(Color(hex: "#3ACFB6"))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartXScale(domain: 0...maxDataPoints)
                .chartYScale(domain: 0...(speedHistory.map { $0.speed }.max() ?? 100) * 1.1)
                .frame(height: 41)
                .padding(.bottom, 8)
            } else {
                // Placeholder when no data
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 41)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .frame(height: 116)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .foregroundStyle(Color(hex: "#292F38"))
        )
        .onChange(of: speed) { newSpeed in
            updateSpeedHistory(newSpeed)
        }
    }
    
    private func updateSpeedHistory(_ newSpeed: Double) {
        // Add new data point
        let newIndex = speedHistory.isEmpty ? 0 : (speedHistory.last?.index ?? 0) + 1
        speedHistory.append(SpeedDataPoint(index: newIndex, speed: newSpeed))
        
        // Keep only the last N data points
        if speedHistory.count > maxDataPoints {
            speedHistory.removeFirst()
            
            // Reindex to keep the chart flowing smoothly
            speedHistory = speedHistory.enumerated().map { index, point in
                SpeedDataPoint(index: index, speed: point.speed)
            }
        }
    }
}

#Preview {
    @Previewable @State var speed: Double = 52.0
    
    VStack(spacing: 20) {
        UploadDownloadView(isDownload: true, speed: $speed)
            .padding()
        
        // Simulate fluctuating speed
        Button("Simulate Speed Change") {
            speed = Double.random(in: 20...80)
        }
        .padding()
    }
    .background(Color(hex: "#040A15"))
    .onAppear {
        // Auto-simulate speed changes for preview
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            speed = Double.random(in: 20...80)
        }
    }
}
