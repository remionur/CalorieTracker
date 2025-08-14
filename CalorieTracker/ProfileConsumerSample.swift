import SwiftUI

struct ProfileConsumerSample: View {
    @EnvironmentObject var profileVM: ProfileViewModel

    var body: some View {
        VStack(spacing: 8) {
            if let p = profileVM.profile {
                Text("Daily goal: \(CalorieCalculator.targetCalories(for: p)) kcal")
            } else {
                Text("No profile loaded")
            }
        }
        .padding()
    }
}

