import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var mealViewModel: MealViewModel
    @State private var showingAddMeal = false
    @State private var selectedMeal: Meal?
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated() && authViewModel.userProfile != nil {
                mainContentView
            } else {
                OnboardingView()
            }
        }
    }
    
    private var mainContentView: some View {
        NavigationSplitView {
            List(mealViewModel.meals, selection: $selectedMeal) { meal in
                NavigationLink {
                    MealDetailView(meal: meal)
                } label: {
                    MealRowView(meal: meal)
                }
            }
            .navigationTitle("My Meals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMeal = true }) {
                        Label("Add Meal", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
            .refreshable {
                mealViewModel.fetchMeals()
            }
        } detail: {
            Text("Select a meal")
                .foregroundColor(.secondary)
        }
    }
}

struct MealRowView: View {
    let meal: Meal
    
    var body: some View {
        HStack {
            if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text("\(meal.calories) calories")
                    .font(.headline)
                Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MealDetailView: View {
    @EnvironmentObject private var mealViewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss

    let meal: Meal
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                }

                Text("\(meal.calories) calories")
                    .font(.title)

                Text(meal.date.formatted(date: .complete, time: .complete))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !meal.notes.isEmpty {
                    Text(meal.notes)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Visible Delete button (also in toolbar below)
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        } else {
                            Label("Delete Meal", systemImage: "trash")
                        }
                        Spacer()
                    }
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(isDeleting)
            }
        }
        .alert("Delete this meal?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteMeal()
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Couldn’t delete", isPresented: .constant(deleteError != nil)) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    private func deleteMeal() async {
        isDeleting = true
        do {
            try await mealViewModel.deleteMeal(meal)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { deleteError = error.localizedDescription }
        }
        isDeleting = false
    }
}


#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(MealViewModel(userId: "test-user"))
}



