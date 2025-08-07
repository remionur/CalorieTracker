import SwiftUI
import Firebase

class SummaryViewModel: ObservableObject {
    @Published var weeklyData: [DailySummary] = []
    @Published var dailyGoal: Int?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private let userId: String
    private let mealViewModel: MealViewModel
    
    var weeklyTotal: Int {
        weeklyData.reduce(0) { $0 + $1.calories }
    }
    
    var weeklyAverage: Int {
        let daysWithData = weeklyData.filter { $0.calories > 0 }.count
        return daysWithData > 0 ? weeklyTotal / daysWithData : 0
    }
    
    var daysMetGoal: Int {
        guard let goal = dailyGoal else { return 0 }
        return weeklyData.filter { $0.calories <= goal && $0.calories > 0 }.count
    }
    
    init(userId: String, mealViewModel: MealViewModel) {
        self.userId = userId
        self.mealViewModel = mealViewModel
        fetchUserGoal()
    }
    
    func fetchWeeklyData() {
        isLoading = true
        Task {
            do {
                let dailySummaries = try await mealViewModel.getWeeklyMeals()
                await MainActor.run {
                    self.isLoading = false
                    self.weeklyData = dailySummaries.map {
                        var modified = $0
                        modified.goal = self.dailyGoal
                        return modified
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error = error
                }
            }
        }
    }
    
    private func fetchUserGoal() {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error
                return
            }
            
            if let profile = try? document?.data(as: UserProfile.self) {
                self.dailyGoal = profile.targetCalories
            }
        }
    }
}
