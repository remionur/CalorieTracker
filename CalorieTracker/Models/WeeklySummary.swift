import Foundation

struct WeeklySummary {
    let startDate: Date
    let endDate: Date
    let dailySummaries: [DailySummary]
    let totalCalories: Int
    let averageCalories: Int
    let goalMetDays: Int
}