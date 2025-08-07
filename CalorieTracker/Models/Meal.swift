import Foundation
import FirebaseFirestore

struct Meal: Identifiable, Hashable {
    let id: String
    let userId: String
    let imageUrl: String?
    let calories: Int
    let date: Date
    let notes: String
    
    init(id: String, userId: String, imageUrl: String?, calories: Int, date: Date, notes: String) {
        self.id = id
        self.userId = userId
        self.imageUrl = imageUrl
        self.calories = calories
        self.date = date
        self.notes = notes
    }
}

