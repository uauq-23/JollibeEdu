//
//  FirebaseSyncManager.swift
//  JollibeEdu
//
//  Created by Tạ Minh Thiện on 23/3/26.
//

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
    private let metadataCollectionName = "seed_meta"
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
        if FirebaseApp.app() == nil {
            guard let options = resolvedFirebaseOptions() else {
                isConfigured = false
                return
            }
            FirebaseApp.configure(options: options)
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

        try await saveReadableCollections(from: payload, database: database)
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

    #if canImport(FirebaseCore)
    private func resolvedFirebaseOptions() -> FirebaseOptions? {
        let sourceFallback = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("GoogleService-Info.plist")
            .path

        let candidatePaths = [
            Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            sourceFallback
        ]

        for path in candidatePaths.compactMap({ $0 }) {
            if let options = FirebaseOptions(contentsOfFile: path) {
                return options
            }
        }

        return nil
    }
    #endif

    #if canImport(FirebaseFirestore)
    private func saveReadableCollections(from payload: Data, database: Firestore) async throws {
        guard let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any] else { return }

        try await saveDocuments(
            in: "categories",
            documents: json["categories"] as? [[String: Any]] ?? [],
            database: database
        ) { document in
            document["id"] as? String
        }

        try await saveDocuments(
            in: "courses",
            documents: json["courses"] as? [[String: Any]] ?? [],
            database: database
        ) { document in
            document["id"] as? String
        }

        try await saveDocuments(
            in: "lessons",
            documents: json["lessons"] as? [[String: Any]] ?? [],
            database: database
        ) { document in
            document["id"] as? String
        }

        let users = (json["accounts"] as? [[String: Any]] ?? []).compactMap { account -> [String: Any]? in
            account["user"] as? [String: Any]
        }
        try await saveDocuments(in: "users", documents: users, database: database) { document in
            document["id"] as? String
        }

        try await saveDocuments(
            in: "enrollments",
            documents: json["enrollments"] as? [[String: Any]] ?? [],
            database: database
        ) { document in
            guard let userID = document["userID"] as? String,
                  let courseID = document["courseID"] as? String else { return nil }
            return "\(userID)_\(courseID)"
        }

        try await saveDocuments(
            in: "progress_entries",
            documents: json["progressEntries"] as? [[String: Any]] ?? [],
            database: database
        ) { document in
            guard let userID = document["userID"] as? String,
                  let courseID = document["courseID"] as? String,
                  let lessonID = document["lessonID"] as? String else { return nil }
            return "\(userID)_\(courseID)_\(lessonID)"
        }

        let payments = (json["payments"] as? [[String: Any]] ?? []).compactMap { entry -> [String: Any]? in
            guard var payment = entry["payment"] as? [String: Any] else { return nil }
            payment["userID"] = entry["userID"]
            return payment
        }
        try await saveDocuments(in: "payments", documents: payments, database: database) { document in
            if let id = document["id"] as? Int {
                return String(id)
            }
            return document["id"] as? String
        }

        let summary: [String: Any] = [
            "categoryCount": (json["categories"] as? [[String: Any]] ?? []).count,
            "courseCount": (json["courses"] as? [[String: Any]] ?? []).count,
            "lessonCount": (json["lessons"] as? [[String: Any]] ?? []).count,
            "userCount": users.count,
            "enrollmentCount": (json["enrollments"] as? [[String: Any]] ?? []).count,
            "progressCount": (json["progressEntries"] as? [[String: Any]] ?? []).count,
            "paymentCount": payments.count,
            "updatedAt": Timestamp(date: Date())
        ]
        try await writeDocument(
            database.collection(metadataCollectionName).document("summary"),
            data: summary
        )
    }

    private func saveDocuments(
        in collection: String,
        documents: [[String: Any]],
        database: Firestore,
        identifier: ([String: Any]) -> String?
    ) async throws {
        for document in documents {
            guard let documentID = identifier(document),
                  let sanitized = sanitize(dictionary: document) else { continue }
            try await writeDocument(
                database.collection(collection).document(documentID),
                data: sanitized
            )
        }
    }

    private func writeDocument(_ reference: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: true) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func sanitize(dictionary: [String: Any]) -> [String: Any]? {
        var result: [String: Any] = [:]

        for (key, value) in dictionary {
            guard let sanitizedValue = sanitize(value: value) else { continue }
            result[key] = sanitizedValue
        }

        return result.isEmpty ? nil : result
    }

    private func sanitize(value: Any) -> Any? {
        switch value {
        case is NSNull:
            return nil
        case let string as String:
            return string
        case let number as NSNumber:
            return number
        case let bool as Bool:
            return bool
        case let int as Int:
            return int
        case let double as Double:
            return double
        case let dictionary as [String: Any]:
            return sanitize(dictionary: dictionary)
        case let array as [Any]:
            let sanitizedArray = array.compactMap { sanitize(value: $0) }
            return sanitizedArray
        default:
            return String(describing: value)
        }
    }
    #endif
}
