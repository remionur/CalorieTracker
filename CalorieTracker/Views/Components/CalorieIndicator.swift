import SwiftUI

struct CalorieIndicator: View {
    let current: Int
    let goal: Int
    
    var body: some View {
        VStack {
            Text("\(current)/\(goal)")
                .font(.title2.bold())
            Text("CALORIES")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}