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
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pad = max(12, min(w, h) * 0.04)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedByDay, id: \.0) { (day, meals) in
                        HStack {
                            Text(day, format: .dateTime.month(.abbreviated).day(.twoDigits).year())
                                .foregroundStyle(.secondary)
                            Spacer()
                            let total = meals.reduce(0) { $0 + $1.calories }
                            Text("\(total) cal").foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            ForEach(meals) { meal in
                                NavigationLink {
                                    MealDetailView(meal: meal)
                                } label: {
                                    HStack(spacing: 12) {
                                        if let urlStr = meal.imageUrl, let url = URL(string: urlStr) {
                                            AsyncImage(url: url) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Color.gray.opacity(0.2)
                                            }
                                            .frame(width: 90, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(width: 90, height: 90)
                                                .overlay(Image(systemName: "photo"))
                                        }

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("\(meal.calories) cal").font(.headline)
                                            if !meal.notes.isEmpty {
                                                Text(meal.notes).font(.subheadline).foregroundStyle(.secondary)
                                            }
                                            Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, pad)
                
                .frame(minHeight: h, alignment: .top)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .navigationTitle("Meals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Minimal detail view (kept for navigation continuity)
struct MealDetailView: View {
    let meal: Meal
    @EnvironmentObject private var mealViewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        List {
            Section {
                if let urlStr = meal.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: { ProgressView() }
                        .frame(maxWidth: .infinity)
                }
                Text("\(meal.calories) cal").font(.title2.bold())
                if !meal.notes.isEmpty { Text(meal.notes) }
                Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    Task { await deleteMeal() }
                } label: {
                    if isDeleting { ProgressView() } else { Text("Delete") }
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
