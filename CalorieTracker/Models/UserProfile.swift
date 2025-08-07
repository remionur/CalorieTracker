import Foundation

struct UserProfile: Codable {
    let id: String
    let name: String
    let gender: String
    let age: Int
    let weight: Double // in kg
    let height: Double // in cm
    let goal: GoalType
    let activityLevel: ActivityLevel
    let targetCalories: Int?
    let createdAt: Date
    
    enum GoalType: String, Codable, CaseIterable {
        case weightLoss = "Weight Loss"
        case weightMaintenance = "Weight Maintenance"
        case weightGain = "Weight Gain"
    }
    
    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extremelyActive = "Extremely Active"
    }
}
