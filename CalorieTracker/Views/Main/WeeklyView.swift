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
        return mealViewModel.meals
            .filter { $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pad  = max(12, min(w, h) * 0.04)
            let barH = max(14, min(w, h) * 0.022)

            ScrollView {
                VStack(alignment: .leading, spacing: pad) {
                    Text("Last 7 Days").font(.headline)

                    VStack(spacing: 10) {
                        ForEach(last7, id: \.self) { day in
                            let cals = total(on: day)
                            HStack {
                                Text(day, format: .dateTime.month(.abbreviated).day())
                                    .font(.subheadline).frame(width: 76, alignment: .leading)
                                Rectangle()
                                    .frame(width: max(6, min(CGFloat(cals) / 20.0, w * 0.55)), height: barH)
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
                .padding(.horizontal, pad)
                
                .frame(minHeight: h, alignment: .top)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .navigationTitle("Weekly")
        .navigationBarTitleDisplayMode(.inline)
    }
}
