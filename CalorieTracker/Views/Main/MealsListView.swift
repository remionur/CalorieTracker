import SwiftUI

struct MealsListView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel

    // Data only — NO view modifiers here
    private var groupedByDay: [(Date, [Meal])] {
        let byDay = Dictionary(grouping: mealViewModel.meals) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return byDay.keys.sorted(by: >).map { day in
            (day, (byDay[day] ?? []).sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        List {
            if groupedByDay.isEmpty {
                Section {
                    Text("No meals yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedByDay, id: \.0) { day, meals in
                    Section(header: Text(day, style: .date).font(.headline)) {
                        ForEach(meals) { meal in
                            MealCard(meal: meal)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        // Keep the last row above the tab bar without creating a big gap
        .safeAreaPadding(.bottom, 8)
        .navigationTitle("Meals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

