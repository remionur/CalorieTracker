import Foundation
import FirebaseAuth

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var error: Error?
    
    private var handler: AuthStateDidChangeListenerHandle?
    
    init() {
        handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                self?.error = error
                return
            }
            self?.user = result?.user
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.error = error
        }
    }
    
    deinit {
        if let handler = handler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
}