import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @State private var isBootstrapping = true
    @State private var bootError: String?

    var body: some View {
        Group {
            if isBootstrapping {
                VStack(spacing: 12) {
                    ProgressView("Loading...")
                    if let bootError {
                        Text(bootError).font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            } else {
                // Replace with your real root view (e.g., MainTabView())
                MainTabView()
            }
        }
        .task {
            await bootstrap()
        }
    }

    private func bootstrap() async {
        do {
            if Auth.auth().currentUser == nil {
                _ = try await Auth.auth().signInAnonymously()
            }
            await MainActor.run {
                mealViewModel.startListening()
                isBootstrapping = false
            }
        } catch {
            await MainActor.run {
                self.bootError = error.localizedDescription
                self.isBootstrapping = false
            }
        }
    }
}
