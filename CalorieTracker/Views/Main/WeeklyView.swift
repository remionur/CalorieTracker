import SwiftUI

struct WeeklyView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    private var last7: [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return (0..<7).map { cal.date(byAdding: .day, value: -$0, to: start)! }.reversed()
    }
    private func total(on day: Date) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return mealViewModel.meals.filter { $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.calories }
    }

    private var dailyGoal: Int {
        if let goal = authViewModel.userProfile?.targetCalories, goal > 0 { return goal }
        if let profile = authViewModel.userProfile { return CalorieCalculator.targetCalories(for: profile) }
        return 0
    }
    private var totals: [Int] { last7.map(total(on:)) }
    private var sum: Int { totals.reduce(0, +) }
    private var avg: Int { totals.isEmpty ? 0 : sum / totals.count }
    private var met: Int { dailyGoal > 0 ? totals.filter { $0 <= dailyGoal }.count : 0 }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        StatCard(title: "Total", value: "\(sum)", unit: "cal")
                        StatCard(title: "Avg/Day", value: "\(avg)", unit: "cal")
                        StatCard(title: "Goal Met", value: "\(met)", unit: "days")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last 7 Days").font(.headline)
                        ForEach(Array(zip(last7.indices, last7)), id: \.0) { _, day in
                            let t = total(on: day)
                            HStack {
                                Text(day, format: .dateTime.weekday().month().day())
                                Spacer()
                                Text("\(t) cal")
                                    .foregroundStyle((dailyGoal > 0 && t > dailyGoal) ? .red : .primary)
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Weekly")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if !mealViewModel.isListening { mealViewModel.startListening() }
        }
    }
}

private struct StatCard: View {
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
