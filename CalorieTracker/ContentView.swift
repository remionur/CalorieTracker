import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var mealViewModel: MealViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Your main UI when signed in and profile exists
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(mealViewModel)
            } else {
                // Onboarding / create profile flow
                OnboardingView()
                    .environmentObject(authViewModel)
                    .environmentObject(mealViewModel)
            }
        }
        .onAppear { authViewModel.bootstrap() }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(MealViewModel())
}

