import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    // Today’s meals (most recent first)
    private var todayMeals: [Meal] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return mealViewModel.meals
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date > $1.date }
    }

    private var consumed: Int { todayMeals.reduce(0) { $0 + $1.calories } }

    /// Daily goal = manual override if set, otherwise calculated from the profile.
    private var dailyGoal: Int {
        if let manual = authViewModel.userProfile?.dailyCalorieLimit, manual > 0 { return manual }
        if let profile = authViewModel.userProfile { return CalorieCalculator.targetCalories(for: profile) }
        return 0
    }

    private var remaining: Int { max(dailyGoal - consumed, 0) }
    private var progress: Double { dailyGoal > 0 ? min(Double(consumed) / Double(dailyGoal), 1) : 0 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pad  = max(12, min(w, h) * 0.04)
            let gap  = max(12, min(w, h) * 0.03)
            let ring = max(88, min(min(w, h) * 0.26, 180))
            let corner = max(14, min(w, h) * 0.05)

            ScrollView {
                VStack(spacing: gap) {
                    // Header card
                    HStack(spacing: gap) {
                        ProgressRing(progress: progress)
                            .frame(width: ring, height: ring)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Consumed").font(.caption).foregroundStyle(.secondary)
                            (Text(consumed, format: .number.grouping(.automatic)) + Text(" cal"))
                                .font(.system(size: max(20, w * 0.06), weight: .bold))

                            Divider().frame(width: max(100, w * 0.28))

                            Text("Remaining").font(.caption).foregroundStyle(.secondary)
                            (Text(remaining, format: .number.grouping(.automatic)) + Text(" cal"))
                                .font(.system(size: max(18, w * 0.05), weight: .semibold))
                                .foregroundStyle(remaining > 0 ? .green : .red)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(pad)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: corner))

                    // Meals section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today’s Meals").font(.headline)
                        if todayMeals.isEmpty {
                            Text("No meals yet today.").foregroundStyle(.secondary)
                        } else {
                            ForEach(todayMeals) { meal in
                                MealCard(meal: meal)
                            }
                        }
                    }
                }
                .padding(.horizontal, pad)
                 // small bottom breathing room
                .frame(minHeight: h, alignment: .top)  // fill viewport to avoid big voids
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline) // tighter top spacing
    }
}
