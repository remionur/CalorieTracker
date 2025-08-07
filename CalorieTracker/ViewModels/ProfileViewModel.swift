import Foundation
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
        fetchProfile()
    }
    
    func fetchProfile() {
        isLoading = true
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = error
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    self.userProfile = try snapshot.data(as: UserProfile.self)
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    func saveProfile(_ profile: UserProfile, completion: @escaping (Bool) -> Void) {
        isLoading = true
        do {
            try db.collection("users").document(userId).setData(from: profile) { error in
                self.isLoading = false
                if let error = error {
                    self.error = error
                    completion(false)
                } else {
                    self.userProfile = profile
                    completion(true)
                }
            }
        } catch {
            self.isLoading = false
            self.error = error
            completion(false)
        }
    }
}