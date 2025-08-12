import Foundation

struct CalorieCalculator {
    /// Mifflin–St Jeor + activity + goal adjustment
    static func targetCalories(for profile: UserProfile) -> Int {
        let weightKg = profile.weight
        let heightCm = profile.height
        let age = profile.age

        // Basal Metabolic Rate (gender string in profile: "Male"/"Female")
        let s: Double = profile.gender.lowercased().hasPrefix("m") ? 5 : -161
        let bmr = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(age) + s

        // Activity factor (enum-based)
        let factor: Double
        switch profile.activityLevel {
        case .sedentary:         factor = 1.2
        case .lightlyActive:     factor = 1.375
        case .moderatelyActive:  factor = 1.55
        case .veryActive:        factor = 1.725
        case .extremelyActive:   factor = 1.9
        }

        var tdee = bmr * factor

        // Goal adjustment (enum-based)
        switch profile.goal {
        case .weightLoss:
            tdee -= 500
        case .weightGain:
            tdee += 300
        case .weightMaintenance:
            break
        }

        return max(Int(round(tdee)), 1200) // floor safeguard
    }
}

