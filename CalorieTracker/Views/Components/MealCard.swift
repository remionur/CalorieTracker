import SwiftUI

struct MealCard: View {
    let meal: Meal
    
    var body: some View {
        HStack {
            if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text("\(meal.calories) calories")
                    .font(.headline)
                
                if !meal.notes.isEmpty {
                    Text(meal.notes)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(meal.date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}