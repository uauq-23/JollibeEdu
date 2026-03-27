import CoreData
import Foundation

// Snapshot structs are plain Swift values used to move data
// between app models and Core Data entities in a simple way.
struct PersistedAccountSnapshot {
    let user: User
    let password: String
}

struct PersistedEnrollmentSnapshot {
    let userID: String
    let courseID: String
    let status: String
    let progress: Double
}

struct PersistedProgressSnapshot {
    let userID: String
    let courseID: String
    let lessonID: String
    let completed: Bool
    let completedAt: String?
}

struct PersistedSessionSnapshot {
    let token: String
    let user: User
}

final class CoreDataManager {
    static let shared = CoreDataManager()
    private static let storeName = "JollibeEduPersistence"

    private enum EntityName {
        static let demoState = "StoredDemoState"
        static let account = "StoredAccount"
        static let session = "StoredSession"
        static let preference = "StoredPreference"
        static let enrollment = "StoredEnrollment"
        static let progress = "StoredProgress"
    }

    private let persistentContainer: NSPersistentContainer

    private var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Init

    private init() {
        persistentContainer = Self.makePersistentContainer()
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Session

    func saveSession(token: String, user: User) {
        viewContext.performAndWait {
            clearRecords(entityName: EntityName.session)
            let object = StoredSession(context: viewContext)
            object.token = token
            write(user: user, to: object)
            saveContext()
        }
    }

    // MARK: - Demo State

    func saveDemoState(_ payload: Data) {
        viewContext.performAndWait {
            clearRecords(entityName: EntityName.demoState)
            let object = StoredDemoState(context: viewContext)
            object.storeID = "primary"
            object.payload = payload
            object.updatedAt = Date()
            saveContext()
        }
    }

    func fetchDemoState() -> Data? {
        var payload: Data?
        viewContext.performAndWait {
            let request = StoredDemoState.fetchRequest()
            request.fetchLimit = 1
            let objects = (try? viewContext.fetch(request)) ?? []
            payload = objects.first?.payload
        }
        return payload
    }

    func currentSession() -> PersistedSessionSnapshot? {
        var snapshot: PersistedSessionSnapshot?
        viewContext.performAndWait {
            let request = StoredSession.fetchRequest()
            request.fetchLimit = 1
            let objects = (try? viewContext.fetch(request)) ?? []
            guard let object = objects.first,
                  let user = user(from: object) else {
                return
            }
            snapshot = PersistedSessionSnapshot(token: object.token, user: user)
        }
        return snapshot
    }

    func updateCurrentSessionUser(_ user: User, token: String?) {
        guard let token else { return }
        saveSession(token: token, user: user)
    }

    func clearCurrentSession() {
        viewContext.performAndWait {
            clearRecords(entityName: EntityName.session)
            saveContext()
        }
    }

    // MARK: - Preferences

    func saveRememberedEmail(_ email: String?) {
        viewContext.performAndWait {
            let request = StoredPreference.fetchRequest()
            request.fetchLimit = 1

            let object = ((try? viewContext.fetch(request)) ?? []).first ?? StoredPreference(context: viewContext)
            object.storeID = "primary"
            object.rememberedEmail = email
            saveContext()
        }
    }

    func fetchRememberedEmail() -> String? {
        var email: String?
        viewContext.performAndWait {
            let request = StoredPreference.fetchRequest()
            request.fetchLimit = 1
            let objects = (try? viewContext.fetch(request)) ?? []
            email = objects.first?.rememberedEmail
        }
        return email
    }

    // MARK: - Accounts

    func replaceAccounts(_ accounts: [PersistedAccountSnapshot]) {
        viewContext.performAndWait {
            clearRecords(entityName: EntityName.account)
            accounts.forEach { account in
                let object = StoredAccount(context: viewContext)
                object.password = account.password
                write(user: account.user, to: object)
            }
            saveContext()
        }
    }

    func fetchAccounts() -> [PersistedAccountSnapshot] {
        var snapshots: [PersistedAccountSnapshot] = []
        viewContext.performAndWait {
            let request = StoredAccount.fetchRequest()
            let objects = (try? viewContext.fetch(request)) ?? []
            snapshots = objects.compactMap { object in
                guard let user = user(from: object) else {
                    return nil
                }
                return PersistedAccountSnapshot(user: user, password: object.password)
            }
        }
        return snapshots
    }

    // MARK: - Enrollments

    func replaceEnrollments(_ enrollments: [PersistedEnrollmentSnapshot]) {
        viewContext.performAndWait {
            clearRecords(entityName: EntityName.enrollment)
            enrollments.forEach { enrollment in
                let object = StoredEnrollment(context: viewContext)
                object.userID = enrollment.userID
                object.courseID = enrollment.courseID
                object.status = enrollment.status
                object.progress = enrollment.progress
            }
            saveContext()
        }
    }

    func fetchEnrollments() -> [PersistedEnrollmentSnapshot] {
        var snapshots: [PersistedEnrollmentSnapshot] = []
        viewContext.performAndWait {
            let request = StoredEnrollment.fetchRequest()
            let objects = (try? viewContext.fetch(request)) ?? []
            snapshots = objects.compactMap { object in
                PersistedEnrollmentSnapshot(
                    userID: object.userID,
                    courseID: object.courseID,
                    status: object.status,
                    progress: object.progress
                )
            }
        }
        return snapshots
    }

    // MARK: - Progress

    func replaceProgressEntries(_ entries: [PersistedProgressSnapshot]) {
        viewContext.performAndWait {
            clearRecords(entityName: EntityName.progress)
            entries.forEach { entry in
                let object = StoredProgress(context: viewContext)
                object.userID = entry.userID
                object.courseID = entry.courseID
                object.lessonID = entry.lessonID
                object.completed = entry.completed
                object.completedAt = entry.completedAt
            }
            saveContext()
        }
    }

    func fetchProgressEntries() -> [PersistedProgressSnapshot] {
        var snapshots: [PersistedProgressSnapshot] = []
        viewContext.performAndWait {
            let request = StoredProgress.fetchRequest()
            let objects = (try? viewContext.fetch(request)) ?? []
            snapshots = objects.compactMap { object in
                PersistedProgressSnapshot(
                    userID: object.userID,
                    courseID: object.courseID,
                    lessonID: object.lessonID,
                    completed: object.completed,
                    completedAt: object.completedAt
                )
            }
        }
        return snapshots
    }

    // MARK: - Mapping

    private func write(user: User, to object: StoredAccount) {
        object.userID = user.id
        object.fullName = user.full_name
        object.email = user.email
        object.role = user.role
        object.username = user.username
        object.avatar = user.avatar
        object.createdAt = user.created_at
    }

    private func write(user: User, to object: StoredSession) {
        object.userID = user.id
        object.fullName = user.full_name
        object.email = user.email
        object.role = user.role
        object.username = user.username
        object.avatar = user.avatar
        object.createdAt = user.created_at
    }

    private func user(from object: StoredAccount) -> User? {
        return User(
            id: object.userID,
            full_name: object.fullName,
            email: object.email,
            role: object.role,
            username: object.username,
            avatar: object.avatar,
            created_at: object.createdAt
        )
    }

    private func user(from object: StoredSession) -> User? {
        return User(
            id: object.userID,
            full_name: object.fullName,
            email: object.email,
            role: object.role,
            username: object.username,
            avatar: object.avatar,
            created_at: object.createdAt
        )
    }

    // MARK: - Low Level Helpers

    private func clearRecords(entityName: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let objects = (try? viewContext.fetch(request)) ?? []
        objects.forEach(viewContext.delete)
    }

    private func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Failed to save Core Data context: \(error.localizedDescription)")
        }
    }

    // MARK: - Model Loading

    // We keep a programmatic model here because it is stable in this
    // shared environment, while the app still uses typed Core Data entities
    // like StoredAccount / StoredSession / StoredEnrollment / StoredProgress.
    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            makeDemoStateEntity(),
            makeAccountEntity(),
            makeSessionEntity(),
            makePreferenceEntity(),
            makeEnrollmentEntity(),
            makeProgressEntity()
        ]
        return model
    }

    private static func makePersistentContainer() -> NSPersistentContainer {
        let model = makeManagedObjectModel()
        let container = NSPersistentContainer(name: storeName, managedObjectModel: model)

        let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("\(storeName).sqlite")
        let description = configuredStoreDescription(url: storeURL, type: NSSQLiteStoreType)
        container.persistentStoreDescriptions = [description]

        if loadPersistentStores(for: container) == nil {
            return container
        }

        resetStoreFiles(at: storeURL)

        let retryContainer = NSPersistentContainer(name: storeName, managedObjectModel: model)
        retryContainer.persistentStoreDescriptions = [configuredStoreDescription(url: storeURL, type: NSSQLiteStoreType)]
        if loadPersistentStores(for: retryContainer) == nil {
            return retryContainer
        }

        let memoryContainer = NSPersistentContainer(name: storeName, managedObjectModel: model)
        let memoryDescription = configuredStoreDescription(url: nil, type: NSInMemoryStoreType)
        memoryContainer.persistentStoreDescriptions = [memoryDescription]
        let memoryError = loadPersistentStores(for: memoryContainer)
        if let memoryError {
            print("Failed to load in-memory Core Data store: \(memoryError.localizedDescription)")
        }
        return memoryContainer
    }

    private static func configuredStoreDescription(url: URL?, type: String) -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription()
        description.type = type
        description.url = url
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        return description
    }

    private static func loadPersistentStores(for container: NSPersistentContainer) -> Error? {
        var loadError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }

        semaphore.wait()
        return loadError
    }

    private static func resetStoreFiles(at url: URL) {
        let fileManager = FileManager.default
        let sidecarURLs = [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal")
        ]

        sidecarURLs.forEach { fileURL in
            guard fileManager.fileExists(atPath: fileURL.path) else { return }
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Failed to remove Core Data store file at \(fileURL.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    private static func makeDemoStateEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = EntityName.demoState
        entity.managedObjectClassName = NSStringFromClass(StoredDemoState.self)
        entity.properties = [
            attribute(name: "storeID", type: .stringAttributeType),
            attribute(name: "payload", type: .binaryDataAttributeType),
            attribute(name: "updatedAt", type: .dateAttributeType, optional: true)
        ]
        return entity
    }

    private static func makeAccountEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = EntityName.account
        entity.managedObjectClassName = NSStringFromClass(StoredAccount.self)
        entity.properties = [
            attribute(name: "userID", type: .stringAttributeType),
            attribute(name: "fullName", type: .stringAttributeType),
            attribute(name: "email", type: .stringAttributeType),
            attribute(name: "role", type: .stringAttributeType),
            attribute(name: "username", type: .stringAttributeType, optional: true),
            attribute(name: "avatar", type: .stringAttributeType, optional: true),
            attribute(name: "createdAt", type: .stringAttributeType, optional: true),
            attribute(name: "password", type: .stringAttributeType)
        ]
        return entity
    }

    private static func makeSessionEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = EntityName.session
        entity.managedObjectClassName = NSStringFromClass(StoredSession.self)
        entity.properties = [
            attribute(name: "token", type: .stringAttributeType),
            attribute(name: "userID", type: .stringAttributeType),
            attribute(name: "fullName", type: .stringAttributeType),
            attribute(name: "email", type: .stringAttributeType),
            attribute(name: "role", type: .stringAttributeType),
            attribute(name: "username", type: .stringAttributeType, optional: true),
            attribute(name: "avatar", type: .stringAttributeType, optional: true),
            attribute(name: "createdAt", type: .stringAttributeType, optional: true)
        ]
        return entity
    }

    private static func makePreferenceEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = EntityName.preference
        entity.managedObjectClassName = NSStringFromClass(StoredPreference.self)
        entity.properties = [
            attribute(name: "storeID", type: .stringAttributeType),
            attribute(name: "rememberedEmail", type: .stringAttributeType, optional: true)
        ]
        return entity
    }

    private static func makeEnrollmentEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = EntityName.enrollment
        entity.managedObjectClassName = NSStringFromClass(StoredEnrollment.self)
        entity.properties = [
            attribute(name: "userID", type: .stringAttributeType),
            attribute(name: "courseID", type: .stringAttributeType),
            attribute(name: "status", type: .stringAttributeType),
            attribute(name: "progress", type: .doubleAttributeType)
        ]
        return entity
    }

    private static func makeProgressEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = EntityName.progress
        entity.managedObjectClassName = NSStringFromClass(StoredProgress.self)
        entity.properties = [
            attribute(name: "userID", type: .stringAttributeType),
            attribute(name: "courseID", type: .stringAttributeType),
            attribute(name: "lessonID", type: .stringAttributeType),
            attribute(name: "completed", type: .booleanAttributeType),
            attribute(name: "completedAt", type: .stringAttributeType, optional: true)
        ]
        return entity
    }

    private static func attribute(name: String, type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}
