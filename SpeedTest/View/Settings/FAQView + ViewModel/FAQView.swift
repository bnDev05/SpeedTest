import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss
    let questions: [FAQQuestionsModel] = FAQQuestionsModel.fetchQuestions()
    var body: some View {
        ZStack {
            BackView()
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(questions, id: \.id) { question in
                            FAQQuestionCell(question: question)
                                .padding(.horizontal, 18)
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("FAQ".localized)
                    .foregroundStyle(.white)
                    .font(.poppins(.bold, size: 24))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
struct FAQQuestionCell: View {
    @State private var isExtended: Bool = false
    let question: FAQQuestionsModel
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Text(question.question.localized)
                    .font(.onest(.semibold, size: 18))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button {
                    isExtended.toggle()
                } label: {
                    Image(systemName: isExtended ? "chevron.up" : "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 7, alignment: .center)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "#787F88"))
                }
                .buttonStyle(HapticButtonStyle())
            }
            
            if isExtended {
                Divider()
                    .background(Color.white.opacity(0.25))
                    .padding(.bottom, 5)
                ForEach(0..<question.answerStrings.count) { text in
                    HStack(alignment: .top) {
                        if question.isDotted {
                            Circle()
                                .foregroundStyle(.white)
                                .frame(width: 6, height: 6, alignment: .center)
                                .padding(.vertical)
                                .padding(.trailing)
                        }
                        Text(question.answerStrings[text].localized)
                            .font(.onest(.medium, size: 16))
                            .foregroundStyle(.white)
                            .lineLimit(100)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .foregroundStyle(Color(hex: "#292F38"))
        )
    }
}


#Preview {
    NavigationView {
        FAQView()
    }
}
