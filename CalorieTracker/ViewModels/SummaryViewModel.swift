
import Foundation

@MainActor
final class SummaryViewModel: ObservableObject {
    /// Per-day summaries for the last 7 days
    @Published var weeklyData: [DailySummary] = []
    /// Optional daily goal (can be set by a parent using profile data)
    @Published var dailyGoal: Int? = nil

    // Derived stats
    var weeklyTotal: Int { weeklyData.reduce(0) { $0 + $1.calories } }
    var weeklyAverage: Int { weeklyData.isEmpty ? 0 : weeklyTotal / weeklyData.count }
    var daysMetGoal: Int {
        let goal = dailyGoal ?? 2000
        return weeklyData.filter { $0.calories >= goal }.count
    }

    /// Convenience initializer so you can construct with or without a MealViewModel.
    /// If provided, we immediately build the last 7 days from it.
    init(mealViewModel: MealViewModel? = nil) {
        if let vm = mealViewModel {
            rebuild(using: vm)
        }
    }

    /// Rebuild summaries from the meal view model
    func rebuild(using mealVM: MealViewModel, endingAt end: Date = .init()) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: end)
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: start) }.reversed()

        self.weeklyData = days.map { day in
            let next = cal.date(byAdding: .day, value: 1, to: day)!
            let dayMeals = mealVM.meals
                .filter { $0.date >= day && $0.date < next }
                .sorted { $0.date > $1.date }
            let total = dayMeals.reduce(0) { $0 + $1.calories }
            return DailySummary(date: day, calories: total, meals: dayMeals)
        }
    }
}
