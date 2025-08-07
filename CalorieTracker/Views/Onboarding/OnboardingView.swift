import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var mealViewModel: MealViewModel

    @State private var isShowingProfileSetup = false
    @State private var authError: Error?
    @State private var isLoading = false
    @State private var showErrorAlert = false

    var body: some View {
        VStack {
            Spacer()

            Text("Calorie Tracker")
                .font(.largeTitle.bold())
                .padding()

            Text("Track your meals and calories with AI-powered photo analysis")
                .multilineTextAlignment(.center)
                .padding()

            Spacer()

            Button(action: start) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
            .padding()
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                authError = nil
            }
        } message: {
            Text(authError?.localizedDescription ?? "An unknown error occurred")
        }
        .fullScreenCover(isPresented: $isShowingProfileSetup) {
            if let userId = authViewModel.user?.uid {
                ProfileSetupView { profile in
                    Task {
                        await handleProfileSetup(profile: profile, userId: userId)
                    }
                }
            }
        }
        .onAppear {
            authError = nil
        }
    }

    private func start() {
        guard !isLoading else { return }

        Task {
            await MainActor.run {
                isLoading = true
                authError = nil
            }

            do {
                try await authViewModel.signInAnonymously()

                await MainActor.run {
                    isShowingProfileSetup = true
                }
            } catch {
                await MainActor.run {
                    authError = error
                    showErrorAlert = true
                }
                print("Authentication error: \(error.localizedDescription)")
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func handleProfileSetup(profile: UserProfile, userId: String) async {
        do {
            // Request notification permissions
            let granted = await notificationService.requestPermission()
            if granted {
                notificationService.scheduleDailyReminders()
            }

            // Save user profile to Firestore
            try await authViewModel.saveProfile(profile)

            await MainActor.run {
                mealViewModel.userId = userId  // ✅ Set userId only AFTER profile is saved
                isShowingProfileSetup = false
            }

        } catch {
            await MainActor.run {
                authError = error
                showErrorAlert = true
            }
        }
    }
}

