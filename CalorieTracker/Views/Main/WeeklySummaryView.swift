import SwiftUI
import Charts

struct WeeklySummaryView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @StateObject private var viewModel = SummaryViewModel()
    @State private var selectedDay: Date? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                WeeklyHeader()
                    .padding(.top, 8)

                WeeklyChartView(
                    weeklyData: viewModel.weeklyData,
                    dailyGoal: viewModel.dailyGoal
                )
                .frame(height: 200)

                WeeklyStats(
                    total: viewModel.weeklyTotal,
                    average: viewModel.weeklyAverage,
                    daysMetGoal: viewModel.daysMetGoal
                )
                .padding(.horizontal, 16)

                DailyDetail(
                    weeklyData: viewModel.weeklyData,
                    selectedDay: selectedDay
                )
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Weekly Summary")
        .onAppear {
            if !mealViewModel.isListening { mealViewModel.startListening() }
            viewModel.rebuild(using: mealViewModel)
        }
    }
}

// MARK: - Subviews used by WeeklySummaryView

private struct WeeklyHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weekly")
                .font(.title2.weight(.semibold))
            Text("Last 7 Days")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }
}

private struct WeeklyChartView: View {
    let weeklyData: [DailySummary]
    let dailyGoal: Int?

    var body: some View {
        Chart(weeklyData, id: \.id) { day in
            BarMark(
                x: .value("Calories", day.calories),
                y: .value("Day", dayLabel(day.date))
            )
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 7))
        }
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .padding(.horizontal, 16)
    }

    private func dayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }
}

private struct WeeklyStats: View {
    let total: Int
    let average: Int
    let daysMetGoal: Int

    var body: some View {
        HStack(spacing: 16) {
            StatCard(title: "Total", value: total)
            StatCard(title: "Avg", value: average)
            StatCard(title: "Met Goal", value: daysMetGoal)
        }
    }

    private struct StatCard: View {
        let title: String
        let value: Int
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.headline.monospacedDigit())
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.12))
            )
        }
    }
}

private struct DailyDetail: View {
    let weeklyData: [DailySummary]
    let selectedDay: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)

            if let selectedDay,
               let day = weeklyData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }) {

                if day.meals.isEmpty {
                    Text("No meals for this day.")
                        .foregroundStyle(.secondary)
                } else {
                    // ✅ Use the Identifiable overload to avoid Binding-related init
                    ForEach(day.meals) { meal in
                        HStack {
                            Text(meal.notes.isEmpty ? "Meal" : meal.notes)
                            Spacer()
                            Text("\(meal.calories) cal")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text("Tap a day to see meals.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

