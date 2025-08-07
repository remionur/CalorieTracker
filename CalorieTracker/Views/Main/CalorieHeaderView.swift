import SwiftUI

struct CalorieHeaderView: View {
    let consumed: Int
    let goal: Int

    var body: some View {
        VStack {
            Text("Calories Consumed: \(consumed)")
            Text("Calorie Goal: \(goal)")
            Text("Remaining: \(goal - consumed)")
                .fontWeight(.bold)
        }
        .padding()
    }
}

