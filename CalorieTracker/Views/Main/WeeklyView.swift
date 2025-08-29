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
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return mealViewModel.meals
            .filter { $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 7 Days")
                    .font(.headline)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    ForEach(last7, id: \.self) { day in
                        let cals = total(on: day)
                        HStack {
                            Text(day, format: .dateTime.month(.abbreviated).day())
                                .font(.subheadline)
                                .frame(width: 76, alignment: .leading)

                            Rectangle()
                                .frame(width: CGFloat(max(cals, 0)) / 20.0, height: 14)
                                .cornerRadius(8)
                                .foregroundStyle(.blue.opacity(0.7))

                            Spacer()

                            Text("\(cals)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .navigationTitle("Weekly")
        .navigationBarTitleDisplayMode(.inline)
        // Keep content clear of the tab bar without weird spacing
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 60) }
    }
}

