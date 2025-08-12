
import SwiftUI
import Charts

struct DailySummaryView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @ObservedObject var viewModel: SummaryViewModel
    let date: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.title2.bold())

                if let dailyData = viewModel.weeklyData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                    // Daily progress
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily Progress")
                            .font(.headline)

                        let goal = viewModel.dailyGoal ?? 2000
                        ProgressView(value: min(1.0, Double(dailyData.calories) / Double(goal)))
                            .tint(dailyData.calories > goal ? .red : .green)

                        HStack {
                            Text("\(dailyData.calories) cal")
                            Spacer()
                            if let goalValue = viewModel.dailyGoal {
                                Text("(goal: \(goalValue) cal)")
                            }
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                    // Meal list
                    Text("Meals")
                        .font(.headline)

                    if dailyData.meals.isEmpty {
                        Text("No meals recorded for this day")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(dailyData.meals) { meal in
                            MealCard(meal: meal)
                        }
                    }
                } else {
                    Text("No meals recorded for this day")
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .navigationTitle("Daily Summary")
        .onAppear {
            viewModel.rebuild(using: mealViewModel)
        }
    }
}
