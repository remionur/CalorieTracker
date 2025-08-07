import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: MealViewModel
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    let userProfile: UserProfile
    
    init(userId: String, userProfile: UserProfile) {  // Fix 1: Proper initializer
        _viewModel = StateObject(wrappedValue: MealViewModel(userId: userId))
        self.userProfile = userProfile
    }
    
    var body: some View {
        VStack {
            // Header with remaining calories
            CalorieHeaderView(
                consumed: viewModel.meals.reduce(0) { $0 + $1.calories },
                goal: userProfile.targetCalories ?? 2000
            )
            
            // Recent meals - Fix 2: Ensure Meal conforms to Identifiable
            List(viewModel.meals) { meal in
                MealCard(meal: meal)
            }
            
            // Add meal button
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: processImage) {
            ImagePicker(image: $inputImage)
        }
        .navigationTitle("Today's Meals")
    }
    
    private func processImage() {
        guard let image = inputImage else { return }
        Task {
            do {
                try await viewModel.addMeal(image: image)
                inputImage = nil
            } catch {
                print("Error adding meal: \(error)")
            }
        }
    }
}
