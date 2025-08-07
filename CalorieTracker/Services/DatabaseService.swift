import Foundation
import FirebaseFirestore
//import FirebaseFirestoreSwift

class DatabaseService {
    private let db = Firestore.firestore()
    
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void) {
        do {
            try db.collection("users").document(profile.id).setData(from: profile, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func fetchUserProfile(userId: String, completion: @escaping (UserProfile?, Error?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil, nil)
                return
            }
            
            do {
                let profile = try snapshot.data(as: UserProfile.self)
                completion(profile, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}
