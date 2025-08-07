import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var error: Error?
    @Published private(set) var isLoading = false
    @Published private(set) var authState: AuthState = .initial

    enum AuthState {
        case initial
        case authenticated
        case unauthenticated
        case error(Error)
    }

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var profileListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAuthListener()
    }

    deinit {
        removeListeners()
    }

    private func setupAuthListener() {
        removeListeners()
        authStateHandler = auth.addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            Task {
                await self.updateAuthState(user: user)
            }
        }
    }

    @MainActor
    private func updateAuthState(user: User?) {
        self.user = user
        if let userId = user?.uid {
            self.authState = .authenticated
            self.fetchUserProfile(userId: userId)
        } else {
            self.authState = .unauthenticated
            self.userProfile = nil
        }
    }

    private func removeListeners() {
        authStateHandler.map(auth.removeStateDidChangeListener)
        profileListener?.remove()
    }

    func signInAnonymously() async throws {
        guard !isLoading else { throw AuthError.operationInProgress }

        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let result = try await auth.signInAnonymously()
            await MainActor.run {
                self.user = result.user
                self.authState = .authenticated
                self.isLoading = false
            }
        } catch {
            await handleAuthError(error)
            throw error
        }
    }

    func signOut() async {
        do {
            try auth.signOut()
            await MainActor.run {
                self.userProfile = nil
            }
        } catch {
            await handleAuthError(error)
        }
    }

    @MainActor
    private func handleAuthError(_ error: Error) {
        self.error = error
        self.authState = .error(error)
        self.isLoading = false
    }

    private func fetchUserProfile(userId: String) {
        profileListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task {
                    await self?.handleProfileSnapshot(snapshot: snapshot, error: error)
                }
            }
    }

    @MainActor
    private func handleProfileSnapshot(snapshot: DocumentSnapshot?, error: Error?) {
        if let error = error {
            self.error = error
            return
        }

        do {
            if let snapshot = snapshot, snapshot.exists {
                self.userProfile = try snapshot.data(as: UserProfile.self)
            } else {
                self.userProfile = nil
            }
        } catch {
            self.error = error
        }
    }

    func saveProfile(_ profile: UserProfile) async throws {
        guard let userId = user?.uid else {
            throw AuthError.noAuthenticatedUser
        }

        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            var profileToSave = profile
            profileToSave = UserProfile(
                id: userId,
                name: profile.name,
                gender: profile.gender,
                age: profile.age,
                weight: profile.weight,
                height: profile.height,
                goal: profile.goal,
                activityLevel: profile.activityLevel,
                targetCalories: profile.targetCalories,
                createdAt: profile.createdAt
            )

            print("📤 Trying to save profile for user \(userId): \(profileToSave)")

            try await db.collection("users").document(userId).setData(from: profileToSave)

            await MainActor.run {
                self.userProfile = profileToSave
                self.isLoading = false
            }
        } catch {
            print("❌ Failed to save profile: \(error.localizedDescription)")
            await handleAuthError(error)
            throw error
        }
    }


    func resetError() {
        Task {
            await MainActor.run {
                self.error = nil
                if case .error = authState {
                    authState = user == nil ? .unauthenticated : .authenticated
                }
            }
        }
    }

    func isAuthenticated() -> Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }

    enum AuthError: Error {
        case noAuthenticatedUser
        case operationInProgress
    }
}

