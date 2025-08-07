import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @State private var name = ""
    @State private var age = ""
    @State private var gender = "Male"
    @State private var weight = ""
    @State private var height = ""
    @State private var goal = UserProfile.GoalType.weightMaintenance
    @State private var activityLevel = UserProfile.ActivityLevel.moderatelyActive
    @State private var isLoading = false
    @State private var error: String?
    
    let genders = ["Male", "Female", "Other"]
    let goals = UserProfile.GoalType.allCases
    let activityLevels = UserProfile.ActivityLevel.allCases
    
    var onCompletion: (UserProfile) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $name)
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender)
                    }
                }
                
                HStack {
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                    Text("kg")
                }
                
                HStack {
                    TextField("Height", text: $height)
                        .keyboardType(.decimalPad)
                    Text("cm")
                }
            }
            
            Section(header: Text("Goals")) {
                Picker("Goal", selection: $goal) {
                    ForEach(goals, id: \.self) { goal in
                        Text(goal.rawValue)
                    }
                }
                
                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(activityLevels, id: \.self) { level in
                        Text(level.rawValue)
                    }
                }
            }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button(action: saveProfile) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Complete Setup")
                }
            }
            .disabled(!formIsValid)
        }
        .navigationTitle("Profile Setup")
    }
    
    private var formIsValid: Bool {
        !name.isEmpty &&
        Int(age) != nil &&
        Double(weight) != nil &&
        Double(height) != nil
    }
    
    private func saveProfile() {
        guard let age = Int(age),
              let weight = Double(weight),
              let height = Double(height) else {
            error = "Please enter valid values"
            return
        }
        
        isLoading = true
        
        let profile = UserProfile(
            id: Auth.auth().currentUser?.uid ?? "unknown",
            name: name,
            gender: gender,
            age: age,
            weight: weight,
            height: height,
            goal: goal,
            activityLevel: activityLevel,
            targetCalories: nil,
            createdAt: Date()
        )
        
        onCompletion(profile)
    }
}
