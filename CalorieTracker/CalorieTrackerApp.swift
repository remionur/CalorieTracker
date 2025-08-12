import SwiftUI
import FirebaseCore

@main
struct CalorieTrackerApp: App {
    @StateObject private var mealViewModel = MealViewModel()
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        // Ensure Firebase is configured exactly once.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            // If your real root is different (e.g., MainTabView or RootView), keep it here.
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(mealViewModel)
        }
    }
}
