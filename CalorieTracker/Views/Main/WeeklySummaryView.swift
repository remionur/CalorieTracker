
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
                WeeklyChartView(weeklyData: viewModel.weeklyData, dailyGoal: viewModel.dailyGoal)
                WeeklyStats(total: viewModel.weeklyTotal, average: viewModel.weeklyAverage, daysMetGoal: viewModel.daysMetGoal)
                DailyDetail(weeklyData: viewModel.weeklyData, selectedDay: selectedDay)
            }
            .padding()
        }
        .navigationTitle("Weekly Summary")
        .onAppear {
            if !mealViewModel.isListening { mealViewModel.startListening() }
            viewModel.rebuild(using: mealViewModel)
        }
    }
}

private struct WeeklyHeader: View {
    var body: some View {
        Text("Weekly Calorie Intake")
            .font(.title2.bold())
    }
}

private struct WeeklyChartView: View {
    let weeklyData: [DailySummary]
    let dailyGoal: Int?

    var body: some View {
        Chart {
            ForEach(weeklyData) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Calories", day.calories)
                )
                .foregroundStyle(day.calories > (dailyGoal ?? 2000) ? .red : .green)
                .annotation(position: .top) {
                    Text("\(day.calories)")
                        .font(.caption2)
                }
            }
        }
        .frame(height: 220)
    }
}

private struct WeeklyStats: View {
    let total: Int
    let average: Int
    let daysMetGoal: Int

    var body: some View {
        HStack(spacing: 12) {
            StatCard(title: "Total", value: "\(total)", unit: "cal")
            StatCard(title: "Average", value: "\(average)", unit: "cal/day")
            StatCard(title: "Days Met Goal", value: "\(daysMetGoal)", unit: "days")
        }
    }
}

private struct DailyDetail: View {
    let weeklyData: [DailySummary]
    let selectedDay: Date?

    var body: some View {
        let dateToShow = selectedDay ?? weeklyData.last?.date
        if let date = dateToShow,
           let day = weeklyData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                if day.meals.isEmpty {
                    Text("No meals recorded for this day")
                        .foregroundColor(.gray)
                } else {
                    ForEach(day.meals) { meal in
                        MealCard(meal: meal)
                    }
                }
            }
        }
    }
}

/*private struct StatCard: View {
    let title: String; let value: String; let unit: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3).bold()
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
*/
