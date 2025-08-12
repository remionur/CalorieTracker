import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var mealViewModel: MealViewModel

    private var todayMeals: [Meal] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return mealViewModel.meals
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date > $1.date }
    }

    private var consumed: Int { todayMeals.reduce(0) { $0 + $1.calories } }

    private var dailyGoal: Int {
        if let goal = authViewModel.userProfile?.targetCalories, goal > 0 { return goal }
        if let profile = authViewModel.userProfile { return CalorieCalculator.targetCalories(for: profile) }
        return 0
    }

    private var remaining: Int { max(dailyGoal - consumed, 0) }
    private var progress: Double { dailyGoal > 0 ? min(Double(consumed)/Double(dailyGoal), 1) : 0 }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ProgressRing(progress: progress)
                            .frame(width: 96, height: 96)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Consumed").font(.caption).foregroundStyle(.secondary)
                            Text(consumed, format: .number.grouping(.automatic)) + Text(" cal")
                                .font(.title2.bold())
                            Divider().frame(width: 120)
                            Text("Remaining").font(.caption).foregroundStyle(.secondary)
                            (Text(remaining, format: .number.grouping(.automatic)) + Text(" cal"))
                                .font(.title3.bold())
                                .foregroundStyle(remaining > 0 ? .green : .red)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Meals").font(.headline)
                        if todayMeals.isEmpty {
                            Text("No meals yet today.").foregroundStyle(.secondary)
                        } else {
                            ForEach(todayMeals) { meal in MealCard(meal: meal) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if !mealViewModel.isListening { mealViewModel.startListening() }
        }
    }
}
