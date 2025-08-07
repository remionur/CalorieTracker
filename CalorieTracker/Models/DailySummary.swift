import Foundation

struct DailySummary: Identifiable {
    var id: Date { date }  // Use date as a unique ID
    let date: Date
    let calories: Int
    var goal: Int?
    let meals: [Meal]
}

