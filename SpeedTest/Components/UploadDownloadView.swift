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
    @Binding var speed: Double
    var isHistoryGiven: Bool = false

    /// Static history passed from outside (Core Data)
    var initialHistory: [SpeedDataPoint] = []

    /// Dynamic live history for real-time updates
    @State private var liveHistory: [SpeedDataPoint] = []

    @State private var maxDataPoints = 20

    // Unit settings
    @AppStorage("unit") private var unit: Int = 0
    @State private var selectedUnit: SpeedUnit = .mbitPerSec
    @State private var displayedSpeed: String = "0.0"
    @State private var displayedUnit: String = "Mbit"

    init(
        isDownload: Bool,
        isGreen: Bool = true,
        speed: Binding<Double>,
        isHistoryGiven: Bool = false,
        speedHistory: [SpeedDataPoint] = []
    ) {
        self.isDownload = isDownload
        self.isGreen = isGreen
        self._speed = speed
        self.isHistoryGiven = isHistoryGiven
        self.initialHistory = speedHistory
    }

    /// Computed source of truth for chart
    private var historyForChart: [SpeedDataPoint] {
        isHistoryGiven ? initialHistory : liveHistory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // TITLE
            HStack {
                Image(isDownload ? .greenDownloadIcon : (isGreen ? .greenUploadIcon : .pinkUploadIcon))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text(isDownload ? "Download".localized : "Upload".localized)
                    .font(.poppins(.semibold, size: 16))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            // SPEED TEXT
            HStack(alignment: .bottom) {
                Text(displayedSpeed)
                    .foregroundStyle(.white)
                    .font(.poppins(.semibold, size: 24))

                Text(displayedUnit)
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.poppins(.semibold, size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            // CHART
            if !historyForChart.isEmpty {
                Chart(historyForChart) { dataPoint in
                    AreaMark(
                        x: .value("Index", dataPoint.index),
                        y: .value("Speed", dataPoint.speed)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: isGreen ? [
                                Color(hex: "#3ACFB6").opacity(0.45),
                                Color(hex: "#3ACFB6").opacity(0)
                            ] : [
                                Color(hex: "#9359C7").opacity(0.45),
                                Color(hex: "#9359C7").opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Index", dataPoint.index),
                        y: .value("Speed", dataPoint.speed)
                    )
                    .foregroundStyle(isGreen ? Color(hex: "#3ACFB6") : Color(hex: "#9359C7"))
                    .lineStyle(.init(lineWidth: 2, lineCap: .round))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartXScale(domain: 0 ... max(maxDataPoints, historyForChart.count))
                .chartYScale(domain: 0 ... (historyForChart.map { $0.speed }.max() ?? 100) * 1.1)
                .frame(height: 41)
                .padding(.bottom, 8)

            } else {
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
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .onChange(of: speed) { newSpeed in
            updateDisplayedSpeed(newSpeed)
            if !isHistoryGiven { updateSpeedHistory(newSpeed) }
        }
        .onChange(of: unit) { _ in
            updateUnit()
            updateDisplayedSpeed(speed)
        }
        .onAppear {
            updateUnit()
            updateDisplayedSpeed(speed)
        }
    }

    // MARK: - UPDATE LOGIC

    private func updateSpeedHistory(_ newSpeed: Double) {
        let newIndex = liveHistory.isEmpty ? 0 : (liveHistory.last?.index ?? 0) + 1

        liveHistory.append(.init(index: newIndex, speed: newSpeed))

        if liveHistory.count > maxDataPoints {
            liveHistory.removeFirst()
            liveHistory = liveHistory.enumerated().map { i, p in
                SpeedDataPoint(index: i, speed: p.speed)
            }
        }
    }

    private func updateUnit() {
        selectedUnit = SpeedUnit(rawValue: unit) ?? .mbitPerSec
        displayedUnit = selectedUnit.displayName
    }

    private func updateDisplayedSpeed(_ newSpeed: Double) {
        let converted = SpeedConverter.shared.convertSpeed(newSpeed, to: selectedUnit)
        displayedSpeed = String(format: "%.1f", converted)
    }
}
