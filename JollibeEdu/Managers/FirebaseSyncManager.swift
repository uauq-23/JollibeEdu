import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class FirebaseSyncManager {
    static let shared = FirebaseSyncManager()

    private let collectionName = "app_state"
    private let documentID = "demo_state"
    private(set) var isConfigured = false

    private init() {}

    var supportsFirebase: Bool {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        return true
        #else
        return false
        #endif
    }

    var isReady: Bool {
        supportsFirebase && isConfigured
    }

    func configureIfNeeded() {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            isConfigured = false
            return
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        isConfigured = true
        #else
        isConfigured = false
        #endif
    }

    func scheduleUpload(_ payload: Data) {
        guard isReady else { return }
        Task {
            try? await saveState(payload)
        }
    }

    func bootstrapRemoteState(with localFallback: @autoclosure () -> Data?) async {
        guard isReady else { return }
        do {
            if let remotePayload = try await loadState() {
                DemoDataStore.shared.replaceStateFromCloud(remotePayload)
            } else if let localPayload = localFallback() {
                try await saveState(localPayload)
            }
        } catch {
            if let localPayload = localFallback() {
                try? await saveState(localPayload)
            }
        }
    }

    private func saveState(_ payload: Data) async throws {
        #if canImport(FirebaseFirestore)
        let database = Firestore.firestore()
        let data: [String: Any] = [
            "payload": payload.base64EncodedString(),
            "updatedAt": Timestamp(date: Date())
        ]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.collection(collectionName).document(documentID).setData(data, merge: true) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        #else
        throw NSError(domain: "FirebaseSyncManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "FirebaseFirestore is not available"])
        #endif
    }

    private func loadState() async throws -> Data? {
        #if canImport(FirebaseFirestore)
        let database = Firestore.firestore()
        let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            database.collection(collectionName).document(documentID).getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "FirebaseSyncManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing Firestore snapshot"]))
                }
            }
        }

        guard snapshot.exists,
              let rawPayload = snapshot.data()?["payload"] as? String,
              let data = Data(base64Encoded: rawPayload) else {
            return nil
        }
        return data
        #else
        return nil
        #endif
    }
}
