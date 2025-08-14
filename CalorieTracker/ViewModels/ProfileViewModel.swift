import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var targetCalories: Int {
        guard let p = profile else { return 2000 }
        return CalorieCalculator.targetCalories(for: p)
    }

    // One-shot load (still useful in some flows)
    func loadProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user."
            return
        }
        isLoading = true
        db.collection("users").document(uid).getDocument { [weak self] snap, err in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let err = err {
                    self?.errorMessage = err.localizedDescription
                    return
                }
                guard let data = snap?.data(), let user = UserProfile(id: uid, data: data) else {
                    self?.errorMessage = "Profile not found."
                    self?.profile = nil
                    return
                }
                self?.profile = user
            }
        }
    }

    // Realtime listener — call from App on auth changes
    func startListening(uid: String) {
        stop()
        listener = db.collection("users").document(uid).addSnapshotListener { [weak self] snap, err in
            DispatchQueue.main.async {
                if let err = err {
                    self?.errorMessage = err.localizedDescription
                    return
                }
                guard let data = snap?.data(), let user = UserProfile(id: uid, data: data) else {
                    self?.profile = nil
                    return
                }
                self?.profile = user
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
        profile = nil
    }

    // Save/merge profile (no FirebaseFirestoreSwift)
    func saveProfile(_ profile: UserProfile, merge: Bool = true, completion: ((Error?) -> Void)? = nil) {
        db.collection("users").document(profile.id).setData(profile.toDict(), merge: merge) { [weak self] err in
            DispatchQueue.main.async {
                if err == nil { self?.profile = profile }
                completion?(err)
            }
        }
    }

    // Convenience upsert used by onboarding
    func upsertProfile(
        gender: String,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        activityLevel: ActivityLevel,
        goal: Goal,
        dailyCalorieLimit: Int? = nil
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user."
            return
        }
        let p = UserProfile(
            id: uid,
            gender: gender,
            age: age,
            height: heightCm,
            weight: weightKg,
            activityLevel: activityLevel,
            goal: goal,
            dailyCalorieLimit: dailyCalorieLimit
        )
        saveProfile(p)
    }
}

