import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class MealViewModel: ObservableObject {
    @Published var meals: [Meal] = []

    private var listener: ListenerRegistration?
    /// Whether a snapshot listener is currently attached
    var isListening: Bool { listener != nil }
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private var uid: String? { Auth.auth().currentUser?.uid }

    deinit { listener?.remove() }

    // MARK: - Live updates
    func startListening() {
        listener?.remove()
        guard let uid else {
            meals = []
            return
        }

        let q = db.collection("meals")
            .whereField("userId", isEqualTo: uid)
            .order(by: "date", descending: true)

        listener = q.addSnapshotListener { [weak self] snap, error in
            guard let self else { return }
            if let error { print("Meal listener error:", error.localizedDescription); return }

            let documents = snap?.documents ?? []
            let mapped: [Meal] = documents.compactMap { doc in
                let data = doc.data()

                guard
                    let userId = data["userId"] as? String,
                    let ts = data["date"] as? Timestamp
                else { return nil }

                let imageUrl = data["imageUrl"] as? String
                let notes = data["notes"] as? String ?? ""

                let calories: Int = {
                    if let i = data["calories"] as? Int { return i }
                    if let d = data["calories"] as? Double { return Int(d) }
                    return 0
                }()

                return Meal(
                    id: doc.documentID,
                    userId: userId,
                    imageUrl: imageUrl,
                    calories: calories,
                    date: ts.dateValue(),
                    notes: notes
                )
            }

            Task { @MainActor in
                self.meals = mapped
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    enum MealError: LocalizedError {
        case missingUser
        var errorDescription: String? { "User ID required. Please sign in again." }
    }

    // MARK: - Create
    
// MARK: - Create
func addMeal(image: UIImage, notes: String = "", calories: Int = 0, date: Date = .init()) async throws {
    guard let uid else { throw MealError.missingUser }

    var finalCalories = calories
    if finalCalories == 0 {
        // Try OpenAI estimate if API key exists; ignore failures
        let estimator = OpenAINutritionService()
        if let estimate = try? await estimator.estimateCalories(from: image) {
            finalCalories = max(estimate.totalCalories, 0)
        }
    }

    // 1) Upload image
    let imageId = UUID().uuidString + ".jpg"
    let path = "meal_images/\(uid)/\(imageId)"
    let ref = storage.reference(withPath: path)
    let data = image.jpegData(compressionQuality: 0.8) ?? Data()
    _ = try await ref.putDataAsync(data, metadata: nil)
    let url = try await ref.downloadURL()

    // 2) Firestore doc
    let payload: [String: Any] = [
        "userId": uid,
        "date": Timestamp(date: date),
        "calories": finalCalories,
        "notes": notes,
        "imageUrl": url.absoluteString
    ]
    _ = try await db.collection("meals").addDocument(data: payload)

    // 3) Refresh handled by snapshot listener; no local insert to avoid duplicates.
}

    // MARK: - Delete
    func deleteMeal(_ meal: Meal) async throws {
        try await db.collection("meals").document(meal.id).delete()
    }

    // MARK: - Weekly summaries (for SummaryViewModel)
    func weeklySummaries(endingAt endDate: Date = .init()) -> [DailySummary] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: endDate)
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: start) }.reversed()

        return days.map { day in
            let next = cal.date(byAdding: .day, value: 1, to: day)!
            let total = meals
                .filter { $0.date >= day && $0.date < next }
                .reduce(0) { $0 + $1.calories }
            let dayMeals = meals.filter { $0.date >= day && $0.date < next }
            let dayTotal = dayMeals.reduce(0) { $0 + $1.calories }
            return DailySummary(date: day, calories: dayTotal, meals: dayMeals)
        }
    }
}
