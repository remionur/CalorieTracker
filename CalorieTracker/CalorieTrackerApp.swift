//  CalorieTrackerApp.swift
import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct CalorieTrackerApp: App {
    @StateObject private var authVM    = AuthViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var mealVM    = MealViewModel()   // keep if you already have this VM

    init() {
        FirebaseApp.configure()

        // Enable offline cache (new API), with safe fallback for older SDKs
        let settings = FirestoreSettings()
        if #available(iOS 14.0, *) {
            settings.cacheSettings = PersistentCacheSettings()
        } else {
            // Deprecated but still works as a fallback on older SDKs
            settings.isPersistenceEnabled = true
        }
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            // Use your actual root view here; ContentView shown for clarity
            ContentView()
                .environmentObject(authVM)
                .environmentObject(profileVM)
                .environmentObject(mealVM)
                // Listen to Auth changes and (un)subscribe to the profile document
                .onReceive(authVM.$user) { user in
                    if let uid = user?.uid {
                        profileVM.startListening(uid: uid)
                    } else {
                        profileVM.stop()
                    }
                }
                .task {
                    // Ensure we’re signed in (anon or your own flow)
                    authVM.bootstrap()
                }
        }
    }
}

