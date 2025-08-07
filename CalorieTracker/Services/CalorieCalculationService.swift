class CalorieCalculationService {
    static func calculateDailyCalorieGoal(for profile: UserProfile) -> Int {
        // Harris-Benedict equation for BMR
        let bmr: Double
        if profile.gender.lowercased() == "male" {
            bmr = 88.362 + (13.397 * profile.weight) + (4.799 * profile.height) - (5.677 * Double(profile.age))
        } else {
            bmr = 447.593 + (9.247 * profile.weight) + (3.098 * profile.height) - (4.330 * Double(profile.age))
        }
        
        // Adjust for activity level
        let activityMultiplier: Double
        switch profile.activityLevel {
        case .sedentary: activityMultiplier = 1.2
        case .lightlyActive: activityMultiplier = 1.375
        case .moderatelyActive: activityMultiplier = 1.55
        case .veryActive: activityMultiplier = 1.725
        case .extremelyActive: activityMultiplier = 1.9
        }
        
        let maintenanceCalories = bmr * activityMultiplier
        
        // Adjust for goal
        switch profile.goal {
        case .weightLoss: return Int(maintenanceCalories * 0.85) // 15% deficit
        case .weightMaintenance: return Int(maintenanceCalories)
        case .weightGain: return Int(maintenanceCalories * 1.15) // 15% surplus
        }
    }
}