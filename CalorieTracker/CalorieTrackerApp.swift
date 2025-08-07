import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import UserNotifications

@main
struct CalorieTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var mealViewModel = MealViewModel()

    init() {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.debug)

        let settings = Firestore.firestore().settings
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(notificationService)
                .environmentObject(mealViewModel)
                .onReceive(authViewModel.$user.compactMap { $0?.uid }) { uid in
                    mealViewModel.userId = uid
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        backgroundTaskID = application.beginBackgroundTask {
            application.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
            if self.backgroundTaskID != .invalid {
                application.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = .invalid
            }
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}


