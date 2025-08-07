
import SwiftUI
import Charts

struct WeeklySummaryView: View {
    @ObservedObject var viewModel: SummaryViewModel
    @State private var selectedDay: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                WeeklyHeader()

                WeeklyChartView(viewModel: viewModel)

                WeeklyStats(viewModel: viewModel)

                DailyDetail(viewModel: viewModel, selectedDay: selectedDay)
            }
            .padding()
        }
        .onAppear {
            viewModel.fetchWeeklyData()
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
    @ObservedObject var viewModel: SummaryViewModel

    var body: some View {
        Chart {
            ForEach(viewModel.weeklyData) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Calories", day.calories)
                )
                .foregroundStyle(day.calories > (viewModel.dailyGoal ?? 2000) ? .red : .green)
                .annotation(position: .top) {
                    Text("\(day.calories)")
                        .font(.caption2)
                }
            }

            if let goal = viewModel.dailyGoal {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            }
        }
        .frame(height: 300)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }
}

private struct WeeklyStats: View {
    @ObservedObject var viewModel: SummaryViewModel

    var body: some View {
        HStack {
            StatCard(title: "Total", value: "\(viewModel.weeklyTotal)", unit: "cal")
            StatCard(title: "Avg/Day", value: "\(viewModel.weeklyAverage)", unit: "cal")
            StatCard(title: "Goal Met", value: "\(viewModel.daysMetGoal)", unit: "days")
        }
    }
}

private struct DailyDetail: View {
    @ObservedObject var viewModel: SummaryViewModel
    let selectedDay: Date?

    var body: some View {
        if let selectedDay = selectedDay,
           let dayData = viewModel.weeklyData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }) {
            DayDetailView(dayData: dayData)
        } else {
            Text("Select a day on the chart to see details")
                .foregroundColor(.gray)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.title)
                .bold()
            Text(unit)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

private struct DayDetailView: View {
    let dayData: DailySummary

    var body: some View {
        VStack(alignment: .leading) {
            Text("Details for \(dayData.date.formatted(.dateTime.weekday().month().day()))")
                .font(.headline)
            Text("Calories: \(dayData.calories)")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

