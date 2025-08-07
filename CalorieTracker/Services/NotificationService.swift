import UserNotifications
import Combine

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    
    @Published var permissionGranted: Bool = false
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func scheduleDailyReminders() {
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Calorie Tracker Reminder"
        content.body = "Don't forget to log your meals today!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 19 // 7 PM
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func sendImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                         content: content,
                                         trigger: nil)
        center.add(request)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
