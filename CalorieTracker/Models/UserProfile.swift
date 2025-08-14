import Foundation

// MARK: - Enums

public enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case extremelyActive
    public var id: String { rawValue }
}

public enum Goal: String, Codable, CaseIterable, Identifiable {
    case weightLoss
    case weightMaintenance
    case weightGain
    public var id: String { rawValue }
}

// MARK: - Model

public struct UserProfile: Codable, Identifiable, Equatable {
    public var id: String               // Firebase Auth UID
    public var gender: String           // "male" / "female" (case-insensitive)
    public var age: Int                 // years
    public var height: Double           // centimeters
    public var weight: Double           // kilograms
    public var activityLevel: ActivityLevel
    public var goal: Goal
    public var dailyCalorieLimit: Int?  // optional manual override

    public init(
        id: String,
        gender: String,
        age: Int,
        height: Double,
        weight: Double,
        activityLevel: ActivityLevel,
        goal: Goal,
        dailyCalorieLimit: Int? = nil
    ) {
        self.id = id
        self.gender = gender
        self.age = age
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
        self.goal = goal
        self.dailyCalorieLimit = dailyCalorieLimit
    }
}

// MARK: - Firestore mapping (no FirebaseFirestoreSwift)

public extension UserProfile {
    /// Initialize from Firestore document data.
    init?(id: String, data: [String: Any]) {
        // Support a few key variations so older docs still decode.
        let gender = (data["gender"] as? String) ?? ""
        guard
            let age = data["age"] as? Int,
            let activityRaw = data["activityLevel"] as? String,
            let goalRaw = data["goal"] as? String
        else { return nil }

        // height / weight may exist as "height", "heightCm", "weight", or "weightKg"
        guard
            let height = (data["height"] as? Double) ?? (data["heightCm"] as? Double),
            let weight = (data["weight"] as? Double) ?? (data["weightKg"] as? Double)
        else { return nil }

        self.id = id
        self.gender = gender
        self.age = age
        self.height = height
        self.weight = weight
        self.activityLevel = ActivityLevel(rawValue: activityRaw) ?? .sedentary
        self.goal = Goal(rawValue: goalRaw) ?? .weightMaintenance
        self.dailyCalorieLimit = data["dailyCalorieLimit"] as? Int
    }

    /// Convert to a Firestore dictionary.
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "gender": gender.lowercased(),
            "age": age,
            "height": height,     // store canonical keys
            "weight": weight,
            "activityLevel": activityLevel.rawValue,
            "goal": goal.rawValue
        ]
        if let daily = dailyCalorieLimit { dict["dailyCalorieLimit"] = daily }
        return dict
    }
}

