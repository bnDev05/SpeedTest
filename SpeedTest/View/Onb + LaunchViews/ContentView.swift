import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var shouldNavigate = false

    var body: some View {
        ZStack {
            Color(hex: "#040A15")
                .ignoresSafeArea()
            
            Image(.appIcon0)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .frame(width: 175, height: 175)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                shouldNavigate = true
            }
        }
        .navigationDestination(isPresented: $shouldNavigate) {
            OnboardingView()
                .environment(\.managedObjectContext, viewContext)
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
