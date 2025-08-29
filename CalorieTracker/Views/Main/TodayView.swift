import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    // Data only — NO view modifiers here
    private var todayMeals: [Meal] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return mealViewModel.meals
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date > $1.date }
    }

    private var consumed: Int { todayMeals.reduce(0) { $0 + $1.calories } }

    private var goal: Int {
        guard let profile = authViewModel.userProfile else { return 0 }
        return CalorieCalculator.targetCalories(for: profile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CalorieHeaderView(consumed: consumed, goal: goal)

                Text("Today’s Meals")
                    .font(.title2.bold())

                if todayMeals.isEmpty {
                    Text("No meals yet. Add one from the Add tab.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(todayMeals) { meal in
                            MealCard(meal: meal)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        // ← This belongs on the VIEW, not the computed property
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 60) }
    }
}

