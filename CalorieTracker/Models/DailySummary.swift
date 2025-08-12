import Foundation

struct DailySummary: Identifiable {
    let id: String
    let date: Date
    /// Total calories for the day
    let calories: Int
    /// Meals that belong to this day (optional consumer)
    let meals: [Meal]

    // Backwards-compat alias if any view still refers to `totalCalories`
    var totalCalories: Int { calories }

    init(date: Date, calories: Int, meals: [Meal]) {
        self.date = date
        self.calories = calories
        self.meals = meals
        // Stable id: start-of-day ISO string
        let start = Calendar.current.startOfDay(for: date)
        let fmt = ISO8601DateFormatter()
        self.id = fmt.string(from: start)
    }
}
