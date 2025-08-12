import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss   // ✅ fixed

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Onboarding").font(.title2).bold()

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(isSaving ? "Saving..." : "Finish") {
                Task { await finishOnboarding() }
            }
            .disabled(isSaving)
        }
        .padding()
    }

    private func finishOnboarding() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            if Auth.auth().currentUser == nil {
                _ = try await Auth.auth().signInAnonymously()
            }
            await MainActor.run {
                // no '$' here — call directly on the environment object
                mealViewModel.startListening()
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

