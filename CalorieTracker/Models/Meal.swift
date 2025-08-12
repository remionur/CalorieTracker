import Foundation

struct Meal: Identifiable, Hashable {
    let id: String
    let userId: String
    let imageUrl: String?
    let calories: Int
    let date: Date
    let notes: String
}
