import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var mealViewModel: MealViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated() && authViewModel.userProfile != nil {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(mealViewModel)
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(MealViewModel())
}

