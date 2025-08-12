import SwiftUI

/// Standalone meals list with per-day grouping.
struct MealsListView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @State private var isRefreshing = false

    private var groupedByDay: [(Date, [Meal])] {
        let byDay = Dictionary(grouping: mealViewModel.meals) { meal in
            Calendar.current.startOfDay(for: meal.date)
        }
        return byDay.keys.sorted(by: >).map { day in
            let meals = (byDay[day] ?? []).sorted { $0.date > $1.date }
            return (day, meals)
        }
    }

    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            List {
                ForEach(groupedByDay, id: \.0) { (day, meals) in
                    DaySection(day: day, meals: meals)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Meals")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(for: Meal.self) { meal in
            MealDetailScreen(meal: meal)
        }
        .refreshable {
            isRefreshing = true
            if !mealViewModel.isListening { mealViewModel.startListening() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { isRefreshing = false }
        }
        .onAppear {
            if mealViewModel.meals.isEmpty { if !mealViewModel.isListening { mealViewModel.startListening() } }
        }
    }
}

private struct DaySection: View {
    let day: Date
    let meals: [Meal]

    var body: some View {
        let dailyTotal = meals.reduce(0) { $0 + $1.calories }
        Section {
            ForEach(meals) { meal in
                NavigationLink(value: meal) {
                    MealCard(meal: meal)
                }
            }
        } header: {
            HStack {
                Text(day.formatted(date: .abbreviated, time: .omitted))
                Spacer()
                Text("\(dailyTotal) cal").foregroundStyle(.secondary)
            }
        }
    }
}

private struct MealDetailScreen: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isDeleting = false
    @State private var deleteError: String?
    let meal: Meal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Rectangle().opacity(0.08).aspectRatio(1, contentMode: .fit)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text("\(meal.calories) cal").font(.title2.bold())
                Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
                if !meal.notes.isEmpty { Text(meal.notes) }
                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { Task { await deleteMeal() } } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(isDeleting)
            }
        }
        .alert("Couldn't delete", isPresented: .constant(deleteError != nil)) {
            Button("OK") { deleteError = nil }
        } message: { Text(deleteError ?? "") }
    }

    private func deleteMeal() async {
        isDeleting = true
        do { try await mealViewModel.deleteMeal(meal); await MainActor.run { dismiss() } }
        catch { await MainActor.run { deleteError = error.localizedDescription } }
        isDeleting = false
    }
}
