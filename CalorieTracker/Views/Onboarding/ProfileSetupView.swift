import SwiftUI
import FirebaseAuth

// Readable labels for pickers
private extension Goal {
    var label: String {
        switch self {
        case .weightLoss:         return "Weight Loss"
        case .weightMaintenance:  return "Weight Maintenance"
        case .weightGain:         return "Weight Gain"
        }
    }
}
private extension ActivityLevel {
    var label: String {
        switch self {
        case .sedentary:        return "Sedentary"
        case .lightlyActive:    return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive:       return "Very Active"
        case .extremelyActive:  return "Extremely Active"
        }
    }
}

struct ProfileSetupView: View {
    // Text fields as strings; we’ll validate/convert on Save
    @State private var ageText: String = ""
    @State private var heightText: String = ""   // cm
    @State private var weightText: String = ""   // kg
    @State private var gender: String = "Male"

    @State private var goal: Goal = .weightMaintenance
    @State private var activityLevel: ActivityLevel = .moderatelyActive

    @State private var isLoading = false
    @State private var error: String?

    let genders = ["Male", "Female", "Other"]

    /// Caller provides what to do with the completed profile
    var onCompletion: (UserProfile) -> Void

    var body: some View {
        Form {
            Section("Personal Information") {
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { Text($0) }
                }
                TextField("Age (years)", text: $ageText)
                    .keyboardType(.numberPad)
                TextField("Height (cm)", text: $heightText)
                    .keyboardType(.decimalPad)
                TextField("Weight (kg)", text: $weightText)
                    .keyboardType(.decimalPad)
            }

            Section("Lifestyle & Goal") {
                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.label).tag(level)
                    }
                }
                Picker("Goal", selection: $goal) {
                    ForEach(Goal.allCases) { g in
                        Text(g.label).tag(g)
                    }
                }
            }

            if let error {
                Text(error)
                    .foregroundColor(.red)
            }

            Section {
                Button {
                    save()
                } label: {
                    if isLoading { ProgressView() } else { Text("Save Profile") }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Set Up Profile")
    }

    private func save() {
        error = nil

        guard let uid = Auth.auth().currentUser?.uid else {
            error = "You must be signed in."
            return
        }
        guard let age = Int(ageText), age > 0 else {
            error = "Please enter a valid age."
            return
        }
        guard let height = Double(heightText), height > 0 else {
            error = "Please enter height in centimeters."
            return
        }
        guard let weight = Double(weightText), weight > 0 else {
            error = "Please enter weight in kilograms."
            return
        }

        isLoading = true
        let profile = UserProfile(
            id: uid,
            gender: gender,              // stored lowercased by toDict()
            age: age,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            goal: goal,
            dailyCalorieLimit: nil       // no manual override initially
        )

        // hand back to caller (e.g., call ProfileViewModel.saveProfile in the parent)
        onCompletion(profile)
        isLoading = false
    }
}

