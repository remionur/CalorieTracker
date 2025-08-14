import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class AuthViewModel: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?

    var isAuthenticated: Bool { user != nil }

    init() {
        // Keep user and profile in sync with Firebase Auth
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.user = user
            if let uid = user?.uid {
                self.fetchProfile(uid: uid)
            } else {
                self.userProfile = nil
            }
        }
    }

    deinit {
        if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
    }

    /// Ensure we have an authenticated user (anon sign-in here; swap with your flow if needed)
    func bootstrap() {
        if let u = Auth.auth().currentUser {
            self.user = u
            self.fetchProfile(uid: u.uid)
            return
        }
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error { self?.errorMessage = error.localizedDescription }
            self?.user = result?.user
        }
    }

    private func fetchProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snap, err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription; return }
                if let data = snap?.data(), let p = UserProfile(id: uid, data: data) {
                    self?.userProfile = p
                } else {
                    self?.userProfile = nil
                }
            }
        }
    }
}

