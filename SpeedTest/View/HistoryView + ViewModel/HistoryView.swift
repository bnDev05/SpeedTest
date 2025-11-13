//
//  HistoryView.swift
//  SpeedTest
//
//  Created by Behruz Norov on 07/11/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Binding var currentTab: Tabs
    var body: some View {
        ZStack {
            BackView()
            VStack {
                topView
                if !viewModel.historyItems.isEmpty {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(viewModel.historyItems, id: \.id) { history in
                                historyCell(item: history)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                } else {
                    Text("History is empty.")
                        .foregroundStyle(.white)
                        .font(.poppins(.semibold, size: 25))
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden()
    }
    
    private var topView: some View {
        HStack {
            Text("History")
                .foregroundStyle(.white)
                .font(.poppins(.semibold, size: 24))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                viewModel.isInEdit.toggle()
            } label: {
                Text("Edit")
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.onest(.semibold, size: 18))
            }
        }
    }
    
    @ViewBuilder
    private func historyCell(item: TestResultEntity) -> some View {
        VStack {
            HStack {
                Text(formattedShort(date: item.testDate ?? Date()))
                    .foregroundStyle(Color(hex: "#787F88"))
                    .font(.onest(.semibold, size: 16))
                Spacer()
                Button {
                    if viewModel.isInEdit {
                        TestResultEntity.delete(item)
                        viewModel.historyItems = TestResultEntity.fetchAll()
                    } else {
                        NavigationManager.shared.push(ResultView(testResults: item.toTestResults(), action: {
                            currentTab = .test
                        }))
                    }
                } label: {
                    Text(viewModel.isInEdit ? "Delete" : "See All")
                        .foregroundStyle(viewModel.isInEdit ? Color(hex: "#FF383C") : Color(hex: "#787F88"))
                        .font(.onest(.semibold, size: 16))
                }
            }
            
            Button {
                NavigationManager.shared.push(ResultView(testResults: item.toTestResults(), action: {
                    currentTab = .test
                }))
            } label: {
                VStack(spacing: 18) {
                    cellInfo(icon: .pingHistory, title: "Ping", amount: Int(item.ping))
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    cellInfo(icon: .greenDownloadIcon, title: "Download", amount: Int(item.downloadSpeed))
                    Divider()
                        .background(.white.opacity(0.25))
                        .padding(.horizontal, -18)
                    cellInfo(icon: .pinkUploadIcon, title: "Upload", amount: Int(item.uploadSpeed))

                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .foregroundStyle(Color(hex: "#292F38"))
                )
            }
        }
    }
    
    @ViewBuilder
    private func cellInfo(icon: ImageResource, title: String, amount: Int) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30, alignment: .center)
            Text(title)
                .font(.onest(.semibold, size: 18))
                .foregroundStyle(.white)
            Spacer()
            Text("\(amount)")
                .font(.poppins(.semibold, size: 18))
                .foregroundStyle(.white)
            Text(viewModel.unitAmount)
                .font(.poppins(.semibold, size: 18))
                .foregroundStyle(Color(hex: "#787F88"))
                .padding(.leading, -6)
            Image(systemName: "chevron.right")
                .resizable()
                .scaledToFit()
                .frame(width: 6, height: 12, alignment: .center)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: "#787F88"))
        }
    }
    
    func formattedShort(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy · HH:mm"
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        HistoryView(currentTab: .constant(.history))
    }
}
