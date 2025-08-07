import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

class MealViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var isLoading = false
    @Published var error: Error?

    var userId: String = "" {
        didSet {
            if !userId.isEmpty {
                fetchMeals()
            }
        }
    }

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var mealsListener: ListenerRegistration?

    // ✅ Default init for StateObject
    init() {}

    // ✅ Keeps HomeView's custom usage working
    init(userId: String) {
        self.userId = userId
        fetchMeals()
    }

    // MARK: - Meal Management

    func addMeal(image: UIImage, notes: String = "") async throws {
        guard !userId.isEmpty else {
            throw NSError(domain: "MealError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User ID is required"
            ])
        }

        await MainActor.run { isLoading = true }

        do {
            let imageUrl = try await uploadImage(image)
            let newMeal = Meal(
                id: UUID().uuidString,
                userId: userId,
                imageUrl: imageUrl,
                calories: estimateCalories(from: image),
                date: Date(),
                notes: notes
            )

            try await saveMeal(meal: newMeal)
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            throw error
        }

        await MainActor.run { isLoading = false }
    }

    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "MealError", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Could not convert image to JPEG"
            ])
        }

        let storageRef = storage.reference()
        let imagePath = "meal_images/\(userId)/\(UUID().uuidString).jpg"
        let imageRef = storageRef.child(imagePath)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        return try await imageRef.downloadURL().absoluteString
    }

    private func saveMeal(meal: Meal) async throws {
        let documentRef = db.collection("meals").document(meal.id)
        try await documentRef.setData([
            "userId": meal.userId,
            "imageUrl": meal.imageUrl,
            "calories": meal.calories,
            "date": Timestamp(date: meal.date),
            "notes": meal.notes
        ])

        await MainActor.run {
            meals.append(meal)
            meals.sort { $0.date > $1.date }
        }
    }

    private func estimateCalories(from image: UIImage) -> Int {
        return Int.random(in: 300...800)
    }

    func fetchMeals() {
        guard !userId.isEmpty else { return }

        isLoading = true
        mealsListener?.remove()

        mealsListener = db.collection("meals")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                Task {
                    await self.handleMealsSnapshot(snapshot: snapshot, error: error)
                }
            }
    }

    @MainActor
    private func handleMealsSnapshot(snapshot: QuerySnapshot?, error: Error?) {
        isLoading = false
        if let error = error {
            self.error = error
            return
        }

        guard let documents = snapshot?.documents else {
            meals = []
            return
        }

        meals = documents.compactMap { doc -> Meal? in
            let data = doc.data()
            guard
                let userId = data["userId"] as? String,
                let imageUrl = data["imageUrl"] as? String,
                let calories = data["calories"] as? Int,
                let timestamp = data["date"] as? Timestamp
            else {
                return nil
            }

            return Meal(
                id: doc.documentID,
                userId: userId,
                imageUrl: imageUrl,
                calories: calories,
                date: timestamp.dateValue(),
                notes: data["notes"] as? String ?? ""
            )
        }
    }

    func getWeeklyMeals() async throws -> [DailySummary] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        let snapshot = try await db.collection("meals")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: startOfWeek)
            .order(by: "date")
            .getDocuments()

        let meals = snapshot.documents.compactMap { doc -> Meal? in
            let data = doc.data()
            guard
                let userId = data["userId"] as? String,
                let imageUrl = data["imageUrl"] as? String,
                let calories = data["calories"] as? Int,
                let timestamp = data["date"] as? Timestamp
            else {
                return nil
            }

            return Meal(
                id: doc.documentID,
                userId: userId,
                imageUrl: imageUrl,
                calories: calories,
                date: timestamp.dateValue(),
                notes: data["notes"] as? String ?? ""
            )
        }

        let grouped = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.date)
        }

        var summaries: [DailySummary] = []

        for (date, dayMeals) in grouped {
            let totalCalories = dayMeals.reduce(0) { $0 + $1.calories }
            summaries.append(DailySummary(
                date: date,
                calories: totalCalories,
                meals: dayMeals
            ))
        }

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            if !summaries.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                summaries.append(DailySummary(
                    date: date,
                    calories: 0,
                    meals: []
                ))
            }
        }

        return summaries.sorted { $0.date < $1.date }
    }

    func deleteMeal(_ meal: Meal) async throws {
        guard !userId.isEmpty else { return }

        let mealId = meal.id

        try await db.collection("meals").document(mealId).delete()

        if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
            let storageRef = storage.reference(forURL: url.absoluteString)
            try await storageRef.delete()
        }

        await MainActor.run {
            meals.removeAll { $0.id == meal.id }
        }
    }
}



