import SwiftUI

struct MealCard: View {
    let meal: Meal

    var body: some View {
        GeometryReader { geo in
            // Image side dynamically scales with width but stays within sensible bounds.
            let side = max(56, min(geo.size.width * 0.18, 90))

            HStack(spacing: 12) {
                if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    // Fallback placeholder
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: side * 0.6, height: side * 0.6)
                        .frame(width: side, height: side)
                        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(meal.calories) cal").font(.headline)
                    if !meal.notes.isEmpty {
                        Text(meal.notes)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 96) // Container height lets the GeometryReader resolve a width
    }
}
