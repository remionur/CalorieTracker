//  CalorieTrackerApp.swift
import SwiftUI
import FirebaseCore
import FirebaseFirestore
// import Combine  // ← not needed with .onChange, so you can omit

@main
struct CalorieTrackerApp: App {
    @StateObject private var authVM    = AuthViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var mealVM    = MealViewModel()

    init() {
        FirebaseApp.configure()

        // Enable offline cache (new API), with safe fallback for older SDKs
        let settings = FirestoreSettings()
        #if swift(>=5.8)
        if #available(iOS 14.0, *) {
            settings.cacheSettings = PersistentCacheSettings()
        } else {
            settings.isPersistenceEnabled = true
        }
        #else
        settings.isPersistenceEnabled = true
        #endif
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(profileVM)
                .environmentObject(mealVM)

                // ✅ Use onChange instead of onReceive — avoids Binding/NSObject issues
                .onChange(of: authVM.user) { user in
                    if let uid = user?.uid {
                        // Start listeners when signed in
                        mealVM.startListening()
                        profileVM.startListening(uid: uid)
                    } else {
                        // Stop listeners when signed out
                        mealVM.stopListening()
                        profileVM.stop()
                    }
                }

                .task {
                    // Ensure we’re signed in (anon or your flow)
                    authVM.bootstrap()
                }
        }
    }
}

