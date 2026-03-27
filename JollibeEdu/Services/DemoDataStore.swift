import Foundation

enum DemoDataStoreError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case usernameAlreadyExists
    case usernameRequired
    case invalidUsername
    case emailNotFound
    case passwordMismatch
    case notLoggedIn
    case notAuthorized
    case notFound
    case lockedLesson
    case courseNeedsLessonsToPublish

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return L10n.tr("demo.error.invalidCredentials")
        case .emailAlreadyExists:
            return L10n.tr("demo.error.emailAlreadyExists")
        case .usernameAlreadyExists:
            return L10n.tr("demo.error.usernameAlreadyExists")
        case .usernameRequired:
            return L10n.tr("demo.error.usernameRequired")
        case .invalidUsername:
            return L10n.tr("demo.error.invalidUsername")
        case .emailNotFound:
            return L10n.tr("demo.error.emailNotFound")
        case .passwordMismatch:
            return L10n.tr("demo.error.passwordMismatch")
        case .notLoggedIn:
            return L10n.tr("demo.error.notLoggedIn")
        case .notAuthorized:
            return L10n.tr("demo.error.notAuthorized")
        case .notFound:
            return L10n.tr("demo.error.notFound")
        case .lockedLesson:
            return L10n.tr("demo.error.lockedLesson")
        case .courseNeedsLessonsToPublish:
            return L10n.tr("demo.error.courseNeedsLessonsToPublish")
        }
    }
}

private struct DemoAccount: Codable {
    var user: User
    var password: String
}

private struct DemoEnrollmentRecord: Codable {
    var userID: String
    var courseID: String
    var status: String
    var progress: Double
}

private struct DemoProgressEntry: Codable {
    var userID: String
    var courseID: String
    var lessonID: String
    var completed: Bool
    var completedAt: String?
}

private struct DemoPaymentRecord: Codable {
    var payment: Payment
    var userID: String
}

private struct DemoStoreState: Codable {
    var accounts: [DemoAccount]
    var categories: [Category]
    var courses: [Course]
    var lessons: [Lesson]
    var enrollments: [DemoEnrollmentRecord]
    var progressEntries: [DemoProgressEntry]
    var payments: [DemoPaymentRecord]
    var paymentSeed: Int
    var catalogVersion: Int? = nil
}

struct CourseStatistic: Codable, Equatable {
    var course: Course
    var enrolledStudents: Int
    var completionRate: Double
}

struct StudentStatistic: Codable, Equatable {
    var user: User
    var progress: Double
}

struct InstructorStatistic: Codable, Equatable {
    var instructorName: String
    var totalCourses: Int
    var totalStudents: Int
}

struct MonthlyReport: Codable, Equatable {
    var labels: [String]
    var values: [Double]
}

final class DemoDataStore {
    static let shared = DemoDataStore()
    private static let currentCatalogVersion = 16

    // Legacy defaults are only kept to migrate older builds.
    // The active source of truth is now the Core Data-backed payload below.
    private let defaults = UserDefaults.standard
    private let coreDataManager = CoreDataManager.shared
    private let legacyStorageKey = "demo.store.state.v3"
    private let isoFormatter = ISO8601DateFormatter()

    private var state: DemoStoreState

    private init() {
        let restoredFromCoreData = coreDataManager.fetchDemoState()

        if let data = restoredFromCoreData,
           let decoded = try? JSONDecoder().decode(DemoStoreState.self, from: data) {
            state = decoded
        } else if let data = defaults.data(forKey: legacyStorageKey),
                  let decoded = try? JSONDecoder().decode(DemoStoreState.self, from: data) {
            state = decoded
        } else {
            state = DemoDataStore.seededState()
        }

        if restoredFromCoreData == nil {
            restoreCoreDataBackedValues()
        }
        applyMigrations()
        persist()
        defaults.removeObject(forKey: legacyStorageKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        coreDataManager.saveDemoState(data)
        syncCoreDataMirror()
        FirebaseSyncManager.shared.scheduleUpload(data)
    }

    func exportStatePayload() -> Data? {
        try? JSONEncoder().encode(state)
    }

    func replaceStateFromCloud(_ payload: Data) {
        guard let decoded = try? JSONDecoder().decode(DemoStoreState.self, from: payload) else { return }
        state = decoded
        applyMigrations()
        persist()
    }

    private func restoreCoreDataBackedValues() {
        let storedAccounts = coreDataManager.fetchAccounts()
        if !storedAccounts.isEmpty {
            state.accounts = storedAccounts.map { snapshot in
                DemoAccount(user: snapshot.user, password: snapshot.password)
            }
        }

        let storedEnrollments = coreDataManager.fetchEnrollments()
        if !storedEnrollments.isEmpty {
            state.enrollments = storedEnrollments.map { snapshot in
                DemoEnrollmentRecord(
                    userID: snapshot.userID,
                    courseID: snapshot.courseID,
                    status: snapshot.status,
                    progress: snapshot.progress
                )
            }
        }

        let storedProgress = coreDataManager.fetchProgressEntries()
        if !storedProgress.isEmpty {
            state.progressEntries = storedProgress.map { snapshot in
                DemoProgressEntry(
                    userID: snapshot.userID,
                    courseID: snapshot.courseID,
                    lessonID: snapshot.lessonID,
                    completed: snapshot.completed,
                    completedAt: snapshot.completedAt
                )
            }
        }
    }

    private func syncCoreDataMirror() {
        coreDataManager.replaceAccounts(
            state.accounts.map { account in
                PersistedAccountSnapshot(user: account.user, password: account.password)
            }
        )
        coreDataManager.replaceEnrollments(
            state.enrollments.map { enrollment in
                PersistedEnrollmentSnapshot(
                    userID: enrollment.userID,
                    courseID: enrollment.courseID,
                    status: enrollment.status,
                    progress: enrollment.progress
                )
            }
        )
        coreDataManager.replaceProgressEntries(
            state.progressEntries.map { entry in
                PersistedProgressSnapshot(
                    userID: entry.userID,
                    courseID: entry.courseID,
                    lessonID: entry.lessonID,
                    completed: entry.completed,
                    completedAt: entry.completedAt
                )
            }
        )
    }

    private func applyMigrations() {
        migrateDefaultAdminCredentials()
        migrateDefaultStudentCredentials()
        migrateUsernames()
        migrateCatalogIfNeeded()
    }

    private func migrateUsernames() {
        for index in state.accounts.indices {
            let existingUsername = normalizeUsername(state.accounts[index].user.username)
            if !existingUsername.isEmpty {
                state.accounts[index].user.username = existingUsername
                continue
            }

            let preferredBase: String
            if state.accounts[index].user.role.lowercased() == "admin" {
                preferredBase = "admin"
            } else {
                preferredBase = baseUsername(
                    preferred: state.accounts[index].user.email.components(separatedBy: "@").first,
                    fallback: state.accounts[index].user.full_name
                )
            }

            state.accounts[index].user.username = availableUsername(base: preferredBase, excludingUserID: state.accounts[index].user.id)

            if SessionManager.shared.currentUser?.id == state.accounts[index].user.id {
                SessionManager.shared.updateCurrentUser(state.accounts[index].user)
            }
        }
    }

    private func migrateCatalogIfNeeded() {
        let currentVersion = state.catalogVersion ?? 1
        guard currentVersion < Self.currentCatalogVersion else { return }

        let seededCatalog = Self.seededCatalog()

        for category in seededCatalog.categories {
            if let index = state.categories.firstIndex(where: { $0.id == category.id }) {
                state.categories[index] = category
            } else {
                state.categories.append(category)
            }
        }

        for course in seededCatalog.courses {
            if let index = state.courses.firstIndex(where: { $0.id == course.id }) {
                var merged = course
                merged.version = state.courses[index].version ?? course.version
                merged.base_course_id = state.courses[index].base_course_id ?? course.base_course_id
                state.courses[index] = merged
            } else {
                state.courses.append(course)
            }
        }

        for lesson in seededCatalog.lessons {
            if let index = state.lessons.firstIndex(where: { $0.id == lesson.id }) {
                state.lessons[index] = lesson
            } else {
                state.lessons.append(lesson)
            }
        }

        state.catalogVersion = Self.currentCatalogVersion
    }

    private func migrateDefaultAdminCredentials() {
        let displayAdminEmail = "Admin@edu.com"
        let newAdminEmail = normalizeEmail(displayAdminEmail)
        let legacyAdminEmail = normalizeEmail("admin@jolibeeedu.vn")

        if let index = state.accounts.firstIndex(where: {
            $0.user.id == "admin-1"
                || normalizeEmail($0.user.email) == legacyAdminEmail
                || (normalizeEmail($0.user.email) == newAdminEmail && $0.user.role.lowercased() == "admin")
        }) {
            state.accounts[index].user.email = displayAdminEmail
            state.accounts[index].user.username = "admin"
            state.accounts[index].password = "123"

            if SessionManager.shared.currentUser?.id == state.accounts[index].user.id {
                SessionManager.shared.updateCurrentUser(state.accounts[index].user)
            }
        } else {
            let adminUser = User(
                id: "admin-1",
                full_name: "Jolibee Admin",
                email: displayAdminEmail,
                role: "admin",
                username: "admin",
                avatar: nil,
                created_at: "2026-01-05"
            )
            state.accounts.insert(DemoAccount(user: adminUser, password: "123"), at: 0)
        }

        let rememberedEmail = SessionManager.shared.rememberedEmail?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if rememberedEmail == legacyAdminEmail {
            SessionManager.shared.storeRememberedEmail(displayAdminEmail)
        }
    }

    private func migrateDefaultStudentCredentials() {
        let displayStudentEmail = "student@gmail.com"
        let newStudentEmail = normalizeEmail(displayStudentEmail)
        let legacyStudentEmail = normalizeEmail("student@jolibeeedu.vn")

        if let index = state.accounts.firstIndex(where: {
            $0.user.id == "student-1"
                || normalizeEmail($0.user.email) == legacyStudentEmail
                || normalizeEmail($0.user.email) == newStudentEmail
        }) {
            state.accounts[index].user.email = displayStudentEmail
            state.accounts[index].user.username = "student"
            state.accounts[index].password = "123"

            if SessionManager.shared.currentUser?.id == state.accounts[index].user.id {
                SessionManager.shared.updateCurrentUser(state.accounts[index].user)
            }
        } else {
            let studentUser = User(
                id: "student-1",
                full_name: "Nguyen Thu Dung",
                email: displayStudentEmail,
                role: "student",
                username: "student",
                avatar: nil,
                created_at: "2026-02-10"
            )
            state.accounts.append(DemoAccount(user: studentUser, password: "123"))
        }

        let rememberedEmail = SessionManager.shared.rememberedEmail?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if rememberedEmail == legacyStudentEmail {
            SessionManager.shared.storeRememberedEmail(displayStudentEmail)
        }
    }

    private static func seededState() -> DemoStoreState {
        let seededCatalog = seededCatalog()

        let users = [
            DemoAccount(user: User(id: "admin-1", full_name: "Jolibee Admin", email: "Admin@edu.com", role: "admin", username: "admin", avatar: nil, created_at: "2026-01-05"), password: "123"),
            DemoAccount(user: User(id: "student-1", full_name: "Nguyen Thu Dung", email: "student@gmail.com", role: "student", username: "student", avatar: nil, created_at: "2026-02-10"), password: "123"),
            DemoAccount(user: User(id: "student-2", full_name: "Tran Minh Anh", email: "minhanh@jolibeeedu.vn", role: "student", username: "tranminhanh", avatar: nil, created_at: "2026-02-12"), password: "Student@123"),
            DemoAccount(user: User(id: "instructor-1", full_name: "Le Hoang Son", email: "son@jolibeeedu.vn", role: "instructor", username: "lehoangson", avatar: nil, created_at: "2026-01-18"), password: "Instructor@123"),
            DemoAccount(user: User(id: "instructor-2", full_name: "Pham Bao Ngan", email: "ngan@jolibeeedu.vn", role: "instructor", username: "phambaongan", avatar: nil, created_at: "2026-01-19"), password: "Instructor@123")
        ]

        let enrollments = [
            DemoEnrollmentRecord(userID: "student-1", courseID: "course-ios", status: "active", progress: 57),
            DemoEnrollmentRecord(userID: "student-1", courseID: "course-english", status: "completed", progress: 100),
            DemoEnrollmentRecord(userID: "student-1", courseID: "course-growth", status: "active", progress: 25),
            DemoEnrollmentRecord(userID: "student-2", courseID: "course-react", status: "active", progress: 50)
        ]

        let progressEntries = [
            DemoProgressEntry(userID: "student-1", courseID: "course-ios", lessonID: "ios-1", completed: true, completedAt: "2026-03-01"),
            DemoProgressEntry(userID: "student-1", courseID: "course-ios", lessonID: "ios-2", completed: true, completedAt: "2026-03-03"),
            DemoProgressEntry(userID: "student-1", courseID: "course-ios", lessonID: "ios-3", completed: true, completedAt: "2026-03-07"),
            DemoProgressEntry(userID: "student-1", courseID: "course-ios", lessonID: "ios-4", completed: true, completedAt: "2026-03-10"),
            DemoProgressEntry(userID: "student-1", courseID: "course-english", lessonID: "eng-1", completed: true, completedAt: "2026-02-12"),
            DemoProgressEntry(userID: "student-1", courseID: "course-english", lessonID: "eng-2", completed: true, completedAt: "2026-02-13"),
            DemoProgressEntry(userID: "student-1", courseID: "course-english", lessonID: "eng-3", completed: true, completedAt: "2026-02-15"),
            DemoProgressEntry(userID: "student-1", courseID: "course-english", lessonID: "eng-4", completed: true, completedAt: "2026-02-17"),
            DemoProgressEntry(userID: "student-1", courseID: "course-english", lessonID: "eng-5", completed: true, completedAt: "2026-02-19"),
            DemoProgressEntry(userID: "student-1", courseID: "course-english", lessonID: "eng-6", completed: true, completedAt: "2026-02-20"),
            DemoProgressEntry(userID: "student-1", courseID: "course-growth", lessonID: "growth-1", completed: true, completedAt: "2026-03-11")
        ]

        let payments = [
            DemoPaymentRecord(payment: Payment(id: 1001, course_id: "course-ios", amount: 1299000, status: "success", payment_method: "bank_card"), userID: "student-1")
        ]

        return DemoStoreState(
            accounts: users,
            categories: seededCatalog.categories,
            courses: seededCatalog.courses,
            lessons: seededCatalog.lessons,
            enrollments: enrollments,
            progressEntries: progressEntries,
            payments: payments,
            paymentSeed: 1002,
            catalogVersion: Self.currentCatalogVersion
        )
    }

    private static func seededCatalog() -> (categories: [Category], courses: [Course], lessons: [Lesson]) {
        func course(
            id: String,
            slug: String,
            title: String,
            description: String,
            thumbnailSeed: String,
            instructorName: String,
            instructorEmail: String,
            categoryID: String,
            categoryName: String,
            studentCount: Int,
            reviewCount: Int,
            rating: Double,
            duration: String,
            price: Double,
            status: String,
            createdAt: String,
            completedLessons: Int,
            totalLessons: Int
        ) -> Course {
            Course(
                id: id,
                slug: slug,
                title: title,
                description: description,
                thumbnail: "bundle://\(thumbnailSeed)",
                instructor_name: instructorName,
                instructor_email: instructorEmail,
                category_id: categoryID,
                category_name: categoryName,
                student_count: studentCount,
                review_count: reviewCount,
                rating: rating,
                duration: duration,
                price: price,
                status: status,
                created_at: createdAt,
                progress: 0,
                completed_lessons: completedLessons,
                total_lessons: totalLessons
            )
        }

        func lesson(
            id: String,
            courseID: String,
            title: String,
            imageSeed: String,
            videoURL: String,
            order: Int,
            duration: String
        ) -> Lesson {
            Lesson(
                id: id,
                course_id: courseID,
                title: title,
                thumbnail_url: "bundle://\(imageSeed)",
                video_url: LessonVideoSuggestionProvider.suggestedURL(for: title, fallback: videoURL),
                lesson_order: order,
                duration: duration
            )
        }

        let iosStoryboards = "https://www.youtube.com/watch?v=als-345E2E0"
        let swiftFullCourse = "https://www.youtube.com/watch?v=8Xg7E9shq0U"
        let uiuxFullCourse = "https://www.youtube.com/watch?v=2icljqpaddk"
        let businessEnglish = "https://www.youtube.com/watch?v=GwQRH-KFlP0"
        let workEnglishPhrases = "https://www.youtube.com/watch?v=jJJwUoBVmFY"
        let businessWriting = "https://www.youtube.com/watch?v=eIhwHjYKGng"
        let digitalMarketing = "https://www.youtube.com/watch?v=5altc8xTzBg"
        let reactFullstack = "https://www.youtube.com/watch?v=7CqJlxBYj-M"
        let reactAppwrite = "https://www.youtube.com/watch?v=SwviLVyaRKU"
        let reactRedux = "https://www.youtube.com/watch?v=NqzdVN2tyvQ"
        let studySkills = "https://www.youtube.com/watch?v=h9ven4N67i0"
        let highPerformanceStudents = "https://www.youtube.com/watch?v=vO1bpod0vKM"
        let learningHowToLearn = "https://www.youtube.com/watch?v=vd2dtkMINIw"
        let nodeProjectZero = "https://www.youtube.com/watch?v=Lj-QNEo07yg"
        let nodeStructureESLint = "https://www.youtube.com/watch?v=8hhXamKIdsY"
        let babelExplained = "https://www.youtube.com/watch?v=aVLgL5LJh5Y"
        let mongoNoSQLTips = "https://www.youtube.com/watch?v=a1dogHmrm1c"
        let mongodbVsMongoose = "https://www.youtube.com/watch?v=KOvjvVn1j-M"
        let nodeDeployRender = "https://www.youtube.com/watch?v=-yl003Wbs78"
        let promptEngineering = "https://www.youtube.com/watch?v=CxbHw93oWP0"
        let aiInEducation = "https://www.youtube.com/watch?v=-28gv8W8B0s"
        let aiCourse = "https://www.youtube.com/watch?v=uRQH2CFvedY"
        let productManagerDay = "https://www.youtube.com/watch?v=Dnh0jP-GA0o"
        let productLifecycle = "https://www.youtube.com/watch?v=bI48pbtMgKE"
        let productRoadmap = "https://www.youtube.com/watch?v=o8Zi8yvgD9k"
        let sqlFullCourse = "https://www.youtube.com/watch?v=HXV3zeQKqGY"
        let sqlWhereClause = "https://www.youtube.com/watch?v=zUoZIyy5kRg"
        let sqlJoinTutorial = "https://www.youtube.com/watch?v=0Pg2fvSC05A"
        let sqlGroupByTutorial = "https://www.youtube.com/watch?v=GWj2R_0wAGk"
        let sqlAggregateFunctions = "https://www.youtube.com/watch?v=rzbFQnTWhPM"
        let swiftOptionals = "https://www.youtube.com/watch?v=3M1G1tdbtDo"
        let swiftProtocolOriented = "https://www.youtube.com/watch?v=wATufOPMK-A"
        let swiftAsyncAwait = "https://www.youtube.com/watch?v=YyZhYCe68fw"
        let swiftErrorHandling = "https://www.youtube.com/watch?v=0lftKa16QFc"
        let publicSpeaking = "https://www.youtube.com/watch?v=LrjlW00kkws"

        let categories = [
            Category(id: "cat-design", name: "Thiết kế", description: "UI/UX, branding, motion design"),
            Category(id: "cat-dev", name: "Lập trình", description: "Web, frontend, architecture"),
            Category(id: "cat-business", name: "Kinh doanh", description: "Growth, analytics, sales"),
            Category(id: "cat-language", name: "Ngoại ngữ", description: "English, communication, IELTS"),
            Category(id: "cat-data", name: "Dữ liệu & AI", description: "SQL, dashboard, AI prompting"),
            Category(id: "cat-mobile", name: "Mobile Development", description: "iOS, UIKit, app architecture"),
            Category(id: "cat-backend", name: "Backend & API", description: "REST API, auth, database"),
            Category(id: "cat-product", name: "Product Management", description: "Discovery, roadmap, prioritization"),
            Category(id: "cat-marketing", name: "Digital Marketing", description: "Lifecycle, funnel, campaign"),
            Category(id: "cat-soft", name: "Kỹ năng mềm", description: "Presentation, teamwork, study habits")
        ]

        let courses = [
            course(id: "course-ios", slug: "xay-dung-ios-uikit", title: "Xây dựng ứng dụng iOS với UIKit", description: "Học cách chuyển một hệ thống web thực tế sang trải nghiệm iPhone chỉn chu bằng UIKit, Storyboard, URLSession và mô hình dữ liệu sạch.", thumbnailSeed: "jbe-course-ios", instructorName: "Le Hoang Son", instructorEmail: "son@jolibeeedu.vn", categoryID: "cat-mobile", categoryName: "Mobile Development", studentCount: 148, reviewCount: 46, rating: 4.9, duration: "08:30:00", price: 1299000, status: "published", createdAt: "2026-01-10", completedLessons: 4, totalLessons: 7),
            course(id: "course-uiux", slug: "ui-ux-thuc-chien", title: "UI/UX Thực chiến cho sản phẩm EdTech", description: "Tối ưu hành trình học tập, thiết kế dashboard, lesson player và payment flow theo tư duy sản phẩm.", thumbnailSeed: "jbe-course-uiux", instructorName: "Pham Bao Ngan", instructorEmail: "ngan@jolibeeedu.vn", categoryID: "cat-design", categoryName: "Thiết kế", studentCount: 93, reviewCount: 21, rating: 4.8, duration: "05:10:00", price: 890000, status: "published", createdAt: "2026-01-12", completedLessons: 0, totalLessons: 5),
            course(id: "course-english", slug: "giao-tiep-tieng-anh-tu-tin", title: "Giao tiếp tiếng Anh tự tin cho người đi làm", description: "Luyện phản xạ tiếng Anh với các tình huống họp nhóm, báo cáo tiến độ, thuyết trình và email.", thumbnailSeed: "jbe-course-english", instructorName: "Pham Bao Ngan", instructorEmail: "ngan@jolibeeedu.vn", categoryID: "cat-language", categoryName: "Ngoại ngữ", studentCount: 212, reviewCount: 85, rating: 4.7, duration: "06:20:00", price: 0, status: "published", createdAt: "2026-02-01", completedLessons: 0, totalLessons: 6),
            course(id: "course-growth", slug: "growth-marketing-foundation", title: "Growth Marketing Foundation", description: "Nắm vững funnel, retention, lifecycle campaigns và cách đọc số liệu để tăng trưởng bền vững cho sản phẩm giáo dục.", thumbnailSeed: "jbe-course-growth", instructorName: "Le Hoang Son", instructorEmail: "son@jolibeeedu.vn", categoryID: "cat-marketing", categoryName: "Digital Marketing", studentCount: 76, reviewCount: 18, rating: 4.6, duration: "04:40:00", price: 990000, status: "published", createdAt: "2026-02-05", completedLessons: 0, totalLessons: 4),
            course(id: "course-react", slug: "react-fullstack-course-platform", title: "Xây dựng Course Platform Fullstack với React", description: "Thiết kế các flow guest, student, admin cho course platform và quản lý API, auth, payment, progress tracking.", thumbnailSeed: "jbe-course-react", instructorName: "Le Hoang Son", instructorEmail: "son@jolibeeedu.vn", categoryID: "cat-dev", categoryName: "Lập trình", studentCount: 184, reviewCount: 67, rating: 4.9, duration: "10:15:00", price: 1499000, status: "published", createdAt: "2026-02-14", completedLessons: 0, totalLessons: 8),
            course(id: "course-cert", slug: "study-roadmap-certificates", title: "Study Roadmap & Completion Certificates", description: "Lập kế hoạch học tập dài hạn, theo dõi tiến độ, xây động lực cá nhân và chuẩn bị chứng chỉ hoàn thành.", thumbnailSeed: "jbe-course-cert", instructorName: "Pham Bao Ngan", instructorEmail: "ngan@jolibeeedu.vn", categoryID: "cat-soft", categoryName: "Kỹ năng mềm", studentCount: 51, reviewCount: 13, rating: 4.5, duration: "03:30:00", price: 450000, status: "draft", createdAt: "2026-02-20", completedLessons: 0, totalLessons: 3),
            course(id: "course-nodeapi", slug: "nodejs-rest-api-course-platform", title: "Node.js REST API cho nền tảng khóa học", description: "Thiết kế backend auth, course, lesson, enrollment, payment và reports cho hệ thống LMS thực tế.", thumbnailSeed: "jbe-course-nodeapi", instructorName: "Le Hoang Son", instructorEmail: "son@jolibeeedu.vn", categoryID: "cat-backend", categoryName: "Backend & API", studentCount: 132, reviewCount: 39, rating: 4.8, duration: "07:20:00", price: 1399000, status: "published", createdAt: "2026-02-24", completedLessons: 0, totalLessons: 6),
            course(id: "course-ai-edu", slug: "ai-prompting-for-education", title: "AI Prompting cho giáo dục và học tập", description: "Ứng dụng AI để tạo lesson outline, learning summary, rubric và dashboard phân tích cho sản phẩm giáo dục.", thumbnailSeed: "jbe-course-ai-edu", instructorName: "Pham Bao Ngan", instructorEmail: "ngan@jolibeeedu.vn", categoryID: "cat-data", categoryName: "Dữ liệu & AI", studentCount: 97, reviewCount: 28, rating: 4.7, duration: "05:45:00", price: 1099000, status: "published", createdAt: "2026-02-26", completedLessons: 0, totalLessons: 5),
            course(id: "course-product", slug: "product-management-edtech", title: "Product Management cho ứng dụng EdTech", description: "Từ problem framing đến roadmap release cho các tính năng guest, payment, learning progress và admin.", thumbnailSeed: "jbe-course-product", instructorName: "Pham Bao Ngan", instructorEmail: "ngan@jolibeeedu.vn", categoryID: "cat-product", categoryName: "Product Management", studentCount: 83, reviewCount: 19, rating: 4.6, duration: "06:05:00", price: 1199000, status: "published", createdAt: "2026-03-01", completedLessons: 0, totalLessons: 5),
            course(id: "course-swift-adv", slug: "swift-nang-cao-cho-uikit", title: "Swift nâng cao cho UIKit Developer", description: "Nắm Optional, protocol, async/await, data flow và cách tổ chức controller sạch cho app UIKit nhiều màn.", thumbnailSeed: "jbe-course-swift-adv", instructorName: "Le Hoang Son", instructorEmail: "son@jolibeeedu.vn", categoryID: "cat-mobile", categoryName: "Mobile Development", studentCount: 115, reviewCount: 31, rating: 4.8, duration: "06:50:00", price: 1290000, status: "published", createdAt: "2026-03-04", completedLessons: 0, totalLessons: 5),
            course(id: "course-sql", slug: "sql-thuc-chien-phan-tich-du-lieu", title: "SQL thực chiến cho phân tích dữ liệu", description: "Làm sạch dữ liệu, viết query, join nhiều bảng và tạo báo cáo cho hệ thống course/enrollment/progress.", thumbnailSeed: "jbe-course-sql", instructorName: "Le Hoang Son", instructorEmail: "son@jolibeeedu.vn", categoryID: "cat-data", categoryName: "Dữ liệu & AI", studentCount: 88, reviewCount: 24, rating: 4.7, duration: "05:30:00", price: 950000, status: "published", createdAt: "2026-03-07", completedLessons: 0, totalLessons: 5),
            course(id: "course-speaking", slug: "ky-nang-thuyet-trinh-bao-cao", title: "Kỹ năng thuyết trình và báo cáo tự tin", description: "Rèn kỹ năng trình bày, kể chuyện, thiết kế nội dung và trả lời câu hỏi trong môi trường học tập và công việc.", thumbnailSeed: "jbe-course-speaking", instructorName: "Pham Bao Ngan", instructorEmail: "ngan@jolibeeedu.vn", categoryID: "cat-soft", categoryName: "Kỹ năng mềm", studentCount: 141, reviewCount: 42, rating: 4.8, duration: "04:55:00", price: 790000, status: "published", createdAt: "2026-03-10", completedLessons: 0, totalLessons: 5)
        ]

        let lessons = [
            lesson(id: "ios-1", courseID: "course-ios", title: "Khởi tạo kiến trúc dự án UIKit", imageSeed: "jbe-ios-1", videoURL: iosStoryboards, order: 1, duration: "12:40"),
            lesson(id: "ios-2", courseID: "course-ios", title: "Thiết kế Theme và reusable views", imageSeed: "jbe-ios-2", videoURL: swiftFullCourse, order: 2, duration: "15:24"),
            lesson(id: "ios-3", courseID: "course-ios", title: "Auth flow, SessionManager, RootRouter", imageSeed: "jbe-ios-3", videoURL: iosStoryboards, order: 3, duration: "18:11"),
            lesson(id: "ios-4", courseID: "course-ios", title: "Dashboard và My Courses", imageSeed: "jbe-ios-4", videoURL: swiftFullCourse, order: 4, duration: "14:55"),
            lesson(id: "ios-5", courseID: "course-ios", title: "Lesson player, progress unlock logic", imageSeed: "jbe-ios-5", videoURL: iosStoryboards, order: 5, duration: "21:07"),
            lesson(id: "ios-6", courseID: "course-ios", title: "Admin CRUD với UIKit", imageSeed: "jbe-ios-6", videoURL: swiftFullCourse, order: 6, duration: "16:32"),
            lesson(id: "ios-7", courseID: "course-ios", title: "Chart báo cáo và polish storyboard", imageSeed: "jbe-ios-7", videoURL: iosStoryboards, order: 7, duration: "17:45"),

            lesson(id: "uiux-1", courseID: "course-uiux", title: "Audit web flow và mobile adaptation", imageSeed: "jbe-uiux-1", videoURL: uiuxFullCourse, order: 1, duration: "10:10"),
            lesson(id: "uiux-2", courseID: "course-uiux", title: "Design card system cho app giáo dục", imageSeed: "jbe-uiux-2", videoURL: uiuxFullCourse, order: 2, duration: "11:50"),
            lesson(id: "uiux-3", courseID: "course-uiux", title: "Tối ưu dashboard và progress UI", imageSeed: "jbe-uiux-3", videoURL: uiuxFullCourse, order: 3, duration: "09:35"),
            lesson(id: "uiux-4", courseID: "course-uiux", title: "Payment UX và empty states", imageSeed: "jbe-uiux-4", videoURL: uiuxFullCourse, order: 4, duration: "10:40"),
            lesson(id: "uiux-5", courseID: "course-uiux", title: "Component review cuối khóa", imageSeed: "jbe-uiux-5", videoURL: uiuxFullCourse, order: 5, duration: "08:25"),

            lesson(id: "eng-1", courseID: "course-english", title: "Small talk tự tin", imageSeed: "jbe-eng-1", videoURL: businessEnglish, order: 1, duration: "07:20"),
            lesson(id: "eng-2", courseID: "course-english", title: "Họp nhóm hiệu quả", imageSeed: "jbe-eng-2", videoURL: workEnglishPhrases, order: 2, duration: "06:45"),
            lesson(id: "eng-3", courseID: "course-english", title: "Báo cáo tiến độ", imageSeed: "jbe-eng-3", videoURL: businessEnglish, order: 3, duration: "08:05"),
            lesson(id: "eng-4", courseID: "course-english", title: "Thuyết trình ngắn", imageSeed: "jbe-eng-4", videoURL: publicSpeaking, order: 4, duration: "07:58"),
            lesson(id: "eng-5", courseID: "course-english", title: "Viết email chuyên nghiệp", imageSeed: "jbe-eng-5", videoURL: businessWriting, order: 5, duration: "09:12"),
            lesson(id: "eng-6", courseID: "course-english", title: "Ôn tập và tự đánh giá", imageSeed: "jbe-eng-6", videoURL: workEnglishPhrases, order: 6, duration: "05:18"),

            lesson(id: "growth-1", courseID: "course-growth", title: "Funnel và North Star", imageSeed: "jbe-growth-1", videoURL: digitalMarketing, order: 1, duration: "11:15"),
            lesson(id: "growth-2", courseID: "course-growth", title: "Retention loops", imageSeed: "jbe-growth-2", videoURL: digitalMarketing, order: 2, duration: "09:32"),
            lesson(id: "growth-3", courseID: "course-growth", title: "Lifecycle campaigns", imageSeed: "jbe-growth-3", videoURL: digitalMarketing, order: 3, duration: "12:03"),
            lesson(id: "growth-4", courseID: "course-growth", title: "Growth dashboard", imageSeed: "jbe-growth-4", videoURL: digitalMarketing, order: 4, duration: "10:01"),

            lesson(id: "react-1", courseID: "course-react", title: "Khởi tạo monorepo và backend", imageSeed: "jbe-react-1", videoURL: reactFullstack, order: 1, duration: "13:21"),
            lesson(id: "react-2", courseID: "course-react", title: "Guest browsing flow", imageSeed: "jbe-react-2", videoURL: reactAppwrite, order: 2, duration: "12:14"),
            lesson(id: "react-3", courseID: "course-react", title: "Student enrollment flow", imageSeed: "jbe-react-3", videoURL: reactFullstack, order: 3, duration: "14:55"),
            lesson(id: "react-4", courseID: "course-react", title: "Payment service integration", imageSeed: "jbe-react-4", videoURL: reactAppwrite, order: 4, duration: "15:40"),
            lesson(id: "react-5", courseID: "course-react", title: "Lesson and progress tracking", imageSeed: "jbe-react-5", videoURL: reactRedux, order: 5, duration: "12:32"),
            lesson(id: "react-6", courseID: "course-react", title: "Admin management screens", imageSeed: "jbe-react-6", videoURL: reactRedux, order: 6, duration: "16:08"),
            lesson(id: "react-7", courseID: "course-react", title: "Reports and analytics", imageSeed: "jbe-react-7", videoURL: reactFullstack, order: 7, duration: "10:56"),
            lesson(id: "react-8", courseID: "course-react", title: "Deployment and polish", imageSeed: "jbe-react-8", videoURL: reactAppwrite, order: 8, duration: "09:42"),

            lesson(id: "cert-1", courseID: "course-cert", title: "Lập kế hoạch học tập", imageSeed: "jbe-cert-1", videoURL: studySkills, order: 1, duration: "08:00"),
            lesson(id: "cert-2", courseID: "course-cert", title: "Tạo thói quen hàng tuần", imageSeed: "jbe-cert-2", videoURL: highPerformanceStudents, order: 2, duration: "07:35"),
            lesson(id: "cert-3", courseID: "course-cert", title: "Mốc hoàn thành và chứng chỉ", imageSeed: "jbe-cert-3", videoURL: learningHowToLearn, order: 3, duration: "06:42"),

            lesson(id: "node-1", courseID: "course-nodeapi", title: "39. Khởi tạo dự án Back-end API từ con số 0", imageSeed: "jbe-node-1", videoURL: nodeProjectZero, order: 1, duration: "29:06"),
            lesson(id: "node-2", courseID: "course-nodeapi", title: "40. Cấu trúc dự án nâng cao, chuẩn thực tế, có ESLint", imageSeed: "jbe-node-2", videoURL: nodeStructureESLint, order: 2, duration: "32:17"),
            lesson(id: "node-3", courseID: "course-nodeapi", title: "Babel Explained in 2 minutes | What is Babel?", imageSeed: "jbe-node-3", videoURL: babelExplained, order: 3, duration: "02:21"),
            lesson(id: "node-4", courseID: "course-nodeapi", title: "42. Tips Thiết kế cơ sở dữ liệu NoSQL | MongoDB Database | NodeJS", imageSeed: "jbe-node-4", videoURL: mongoNoSQLTips, order: 4, duration: "20:45"),
            lesson(id: "node-5", courseID: "course-nodeapi", title: "43. MongoDB vs Mongoose - Đừng nhầm lẫn nữa", imageSeed: "jbe-node-5", videoURL: mongodbVsMongoose, order: 5, duration: "24:08"),
            lesson(id: "node-6", courseID: "course-nodeapi", title: "Deploy Node.js REST API on Render | CRUD | Express | MongoDB Atlas", imageSeed: "jbe-node-6", videoURL: nodeDeployRender, order: 6, duration: "14:21"),

            lesson(id: "ai-1", courseID: "course-ai-edu", title: "Tư duy prompt cho người học", imageSeed: "jbe-ai-1", videoURL: promptEngineering, order: 1, duration: "09:15"),
            lesson(id: "ai-2", courseID: "course-ai-edu", title: "Tạo outline bài học với AI", imageSeed: "jbe-ai-2", videoURL: aiCourse, order: 2, duration: "10:08"),
            lesson(id: "ai-3", courseID: "course-ai-edu", title: "Chấm rubric và phản hồi", imageSeed: "jbe-ai-3", videoURL: aiInEducation, order: 3, duration: "11:26"),
            lesson(id: "ai-4", courseID: "course-ai-edu", title: "Sinh dashboard insight", imageSeed: "jbe-ai-4", videoURL: promptEngineering, order: 4, duration: "09:44"),
            lesson(id: "ai-5", courseID: "course-ai-edu", title: "Ứng dụng vào course platform", imageSeed: "jbe-ai-5", videoURL: aiInEducation, order: 5, duration: "10:31"),

            lesson(id: "product-1", courseID: "course-product", title: "Xác định problem statement", imageSeed: "jbe-product-1", videoURL: productManagerDay, order: 1, duration: "10:20"),
            lesson(id: "product-2", courseID: "course-product", title: "Mapping user flow guest đến admin", imageSeed: "jbe-product-2", videoURL: productLifecycle, order: 2, duration: "11:02"),
            lesson(id: "product-3", courseID: "course-product", title: "Ưu tiên backlog và MVP", imageSeed: "jbe-product-3", videoURL: productManagerDay, order: 3, duration: "09:40"),
            lesson(id: "product-4", courseID: "course-product", title: "Roadmap release cho EdTech", imageSeed: "jbe-product-4", videoURL: productRoadmap, order: 4, duration: "10:50"),
            lesson(id: "product-5", courseID: "course-product", title: "Đo lường outcome sản phẩm", imageSeed: "jbe-product-5", videoURL: productManagerDay, order: 5, duration: "08:42"),

            lesson(id: "swift-1", courseID: "course-swift-adv", title: "Swift optionals và optional binding", imageSeed: "jbe-swift-1", videoURL: swiftOptionals, order: 1, duration: "10:12"),
            lesson(id: "swift-2", courseID: "course-swift-adv", title: "Protocol-oriented programming trong Swift", imageSeed: "jbe-swift-2", videoURL: swiftProtocolOriented, order: 2, duration: "12:30"),
            lesson(id: "swift-3", courseID: "course-swift-adv", title: "Swift async await explained", imageSeed: "jbe-swift-3", videoURL: swiftAsyncAwait, order: 3, duration: "11:44"),
            lesson(id: "swift-4", courseID: "course-swift-adv", title: "Swift error handling với do try catch", imageSeed: "jbe-swift-4", videoURL: swiftErrorHandling, order: 4, duration: "13:10"),
            lesson(id: "swift-5", courseID: "course-swift-adv", title: "UIKit storyboard refresher cho reusable component", imageSeed: "jbe-swift-5", videoURL: iosStoryboards, order: 5, duration: "09:58"),

            lesson(id: "sql-1", courseID: "course-sql", title: "SQL WHERE clause: SELECT và FILTER", imageSeed: "jbe-sql-1", videoURL: sqlWhereClause, order: 1, duration: "08:48"),
            lesson(id: "sql-2", courseID: "course-sql", title: "SQL JOIN tutorial: kết nối nhiều bảng", imageSeed: "jbe-sql-2", videoURL: sqlJoinTutorial, order: 2, duration: "10:22"),
            lesson(id: "sql-3", courseID: "course-sql", title: "SQL GROUP BY tutorial", imageSeed: "jbe-sql-3", videoURL: sqlGroupByTutorial, order: 3, duration: "11:14"),
            lesson(id: "sql-4", courseID: "course-sql", title: "SQL aggregate functions cho báo cáo", imageSeed: "jbe-sql-4", videoURL: sqlAggregateFunctions, order: 4, duration: "10:01"),
            lesson(id: "sql-5", courseID: "course-sql", title: "SQL Full Course recap cho LMS analytics", imageSeed: "jbe-sql-5", videoURL: sqlFullCourse, order: 5, duration: "09:37"),

            lesson(id: "speak-1", courseID: "course-speaking", title: "How to start a presentation", imageSeed: "jbe-speak-1", videoURL: publicSpeaking, order: 1, duration: "08:14"),
            lesson(id: "speak-2", courseID: "course-speaking", title: "5 Storytelling Tips for your Presentation", imageSeed: "jbe-speak-2", videoURL: "https://www.youtube.com/watch?v=8M83OFKAnFk", order: 2, duration: "09:28"),
            lesson(id: "speak-3", courseID: "course-speaking", title: "Slide design for presentations", imageSeed: "jbe-speak-3", videoURL: "https://www.youtube.com/watch?v=iGjSdWxKfjA", order: 3, duration: "10:36"),
            lesson(id: "speak-4", courseID: "course-speaking", title: "Presentation body language", imageSeed: "jbe-speak-4", videoURL: "https://www.youtube.com/watch?v=ET7qsJv6nLk", order: 4, duration: "09:16"),
            lesson(id: "speak-5", courseID: "course-speaking", title: "Presentation frameworks", imageSeed: "jbe-speak-5", videoURL: "https://www.youtube.com/watch?v=pd36Jay0B_8", order: 5, duration: "08:58")
        ]

        return (categories, courses, lessons)
    }

    private func currentUserID() throws -> String {
        guard let userID = SessionManager.shared.currentUser?.id else {
            throw DemoDataStoreError.notLoggedIn
        }
        return userID
    }

    private func requireAdmin() throws {
        guard SessionManager.shared.isAdmin else {
            throw DemoDataStoreError.notAuthorized
        }
    }

    private func saveAccount(_ account: DemoAccount) {
        if let index = state.accounts.firstIndex(where: { $0.user.id == account.user.id }) {
            state.accounts[index] = account
        } else {
            state.accounts.append(account)
        }
        persist()
    }

    private func saveCourse(_ course: Course) {
        if let index = state.courses.firstIndex(where: { $0.id == course.id }) {
            state.courses[index] = course
        } else {
            state.courses.append(course)
        }
        persist()
    }

    private func course(withID id: String) throws -> Course {
        guard let course = state.courses.first(where: { $0.id == id }) else {
            throw DemoDataStoreError.notFound
        }
        return enrich(course: course, for: SessionManager.shared.currentUser?.id)
    }

    func course(by id: String) throws -> Course {
        let course = try course(withID: id)
        if !SessionManager.shared.isAdmin && !isCoursePublic(course) {
            throw DemoDataStoreError.notFound
        }
        return course
    }

    private func nextToken(for user: User) -> String {
        "demo-token-\(user.id)"
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizeUsername(_ username: String?) -> String {
        guard let username else { return "" }
        let folded = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        let cleaned = folded.components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-").inverted).joined()
        return cleaned
    }

    private func baseUsername(preferred: String?, fallback: String) -> String {
        let preferredValue = normalizeUsername(preferred)
        if preferredValue.count >= 3 {
            return preferredValue
        }
        let fallbackValue = normalizeUsername(fallback)
        if fallbackValue.count >= 3 {
            return fallbackValue
        }
        return "student"
    }

    private func availableUsername(base: String, excludingUserID: String?) -> String {
        let normalizedBase = max(base.count, 3) == base.count ? base : "student"
        var candidate = normalizedBase
        var suffix = 2

        while state.accounts.contains(where: {
            $0.user.id != excludingUserID && normalizeUsername($0.user.username) == candidate
        }) {
            candidate = "\(normalizedBase)\(suffix)"
            suffix += 1
        }
        return candidate
    }

    private func lessonProgress(for userID: String, courseID: String) -> [DemoProgressEntry] {
        state.progressEntries.filter { $0.userID == userID && $0.courseID == courseID && $0.completed }
    }

    private func progressPercent(for userID: String, courseID: String) -> Double {
        let total = state.lessons.filter { $0.course_id == courseID }.count
        guard total > 0 else { return 0 }
        let completed = lessonProgress(for: userID, courseID: courseID).count
        return (Double(completed) / Double(total)) * 100
    }

    private func baseCourseID(for course: Course) -> String {
        course.base_course_id ?? course.id
    }

    private func courseVersion(for course: Course) -> Int {
        max(course.version ?? 1, 1)
    }

    private func latestCourseInFamily(for course: Course) -> Course {
        let familyBaseID = baseCourseID(for: course)
        return state.courses
            .filter { baseCourseID(for: $0) == familyBaseID }
            .max { courseVersion(for: $0) < courseVersion(for: $1) } ?? course
    }

    private func courseHasCompletedCertificates(_ courseID: String) -> Bool {
        state.enrollments.contains {
            $0.courseID == courseID && ($0.status == "completed" || $0.progress >= 100)
        }
    }

    private func courseHasLessons(_ courseID: String) -> Bool {
        state.lessons.contains { $0.course_id == courseID }
    }

    private func ensureCourseCanBePublished(courseID: String?, requestedStatus: String?) throws {
        guard requestedStatus?.lowercased() == "published" else { return }
        guard let courseID, courseHasLessons(courseID) else {
            throw DemoDataStoreError.courseNeedsLessonsToPublish
        }
    }

    private func isCoursePublic(_ course: Course) -> Bool {
        (course.status ?? "draft").lowercased() == "published" && courseHasLessons(course.id)
    }

    @discardableResult
    private func createNewCourseVersion(from sourceCourse: Course) -> Course {
        let latestCourse = latestCourseInFamily(for: sourceCourse)
        let nextVersion = courseVersion(for: latestCourse) + 1
        let baseID = baseCourseID(for: latestCourse)

        var duplicatedCourse = latestCourse
        duplicatedCourse.id = "course-\(UUID().uuidString.prefix(8))"
        duplicatedCourse.slug = (latestCourse.slug ?? latestCourse.title.lowercased().replacingOccurrences(of: " ", with: "-")) + "-v\(nextVersion)"
        duplicatedCourse.status = "draft"
        duplicatedCourse.created_at = isoFormatter.string(from: Date())
        duplicatedCourse.student_count = 0
        duplicatedCourse.review_count = 0
        duplicatedCourse.rating = 0
        duplicatedCourse.progress = 0
        duplicatedCourse.completed_lessons = 0
        duplicatedCourse.version = nextVersion
        duplicatedCourse.base_course_id = baseID

        let copiedLessons = lessons(for: latestCourse.id).map { lesson in
            Lesson(
                id: "lesson-\(UUID().uuidString.prefix(8))",
                course_id: duplicatedCourse.id,
                title: lesson.title,
                thumbnail_url: lesson.thumbnail_url,
                video_url: lesson.video_url,
                lesson_order: lesson.lesson_order,
                duration: lesson.duration
            )
        }

        state.courses.append(duplicatedCourse)
        state.lessons.append(contentsOf: copiedLessons)
        persist()
        return duplicatedCourse
    }

    private func enrich(course: Course, for userID: String?) -> Course {
        var updated = course
        if let categoryID = course.category_id {
            updated.category_name = state.categories.first(where: { $0.id == categoryID })?.name
        }
        let studentCount = state.enrollments.filter { $0.courseID == course.id }.count
        updated.student_count = max(studentCount, course.student_count ?? 0)
        updated.total_lessons = state.lessons.filter { $0.course_id == course.id }.count
        if let userID {
            let completed = lessonProgress(for: userID, courseID: course.id).count
            updated.completed_lessons = completed
            updated.progress = progressPercent(for: userID, courseID: course.id)
        }
        return updated
    }

    private func updateEnrollmentProgress(for userID: String, courseID: String) {
        let progress = progressPercent(for: userID, courseID: courseID)
        if let index = state.enrollments.firstIndex(where: { $0.userID == userID && $0.courseID == courseID }) {
            state.enrollments[index].progress = progress
            state.enrollments[index].status = progress >= 100 ? "completed" : "active"
        }
        persist()
    }

    func login(identifier: String, password: String) throws -> (token: String, user: User) {
        let normalizedEmail = normalizeEmail(identifier)
        let normalizedUsername = normalizeUsername(identifier)
        guard let account = state.accounts.first(where: {
            $0.password == password &&
                (normalizeEmail($0.user.email) == normalizedEmail || normalizeUsername($0.user.username) == normalizedUsername)
        }) else {
            throw DemoDataStoreError.invalidCredentials
        }
        return (nextToken(for: account.user), account.user)
    }

    func register(fullName: String, username: String, email: String, password: String) throws -> (token: String, user: User) {
        let normalizedUsername = normalizeUsername(username)
        let normalized = normalizeEmail(email)
        guard !normalizedUsername.isEmpty else {
            throw DemoDataStoreError.usernameRequired
        }
        guard normalizedUsername.count >= 3 else {
            throw DemoDataStoreError.invalidUsername
        }
        guard !state.accounts.contains(where: { normalizeEmail($0.user.email) == normalized }) else {
            throw DemoDataStoreError.emailAlreadyExists
        }
        guard !state.accounts.contains(where: { normalizeUsername($0.user.username) == normalizedUsername }) else {
            throw DemoDataStoreError.usernameAlreadyExists
        }

        let user = User(id: "student-\(UUID().uuidString.prefix(8))", full_name: fullName, email: normalized, role: "student", username: normalizedUsername, avatar: nil, created_at: isoFormatter.string(from: Date()))
        saveAccount(DemoAccount(user: user, password: password))
        return (nextToken(for: user), user)
    }

    func getCurrentUser() throws -> User {
        guard let user = SessionManager.shared.currentUser else {
            throw DemoDataStoreError.notLoggedIn
        }
        return state.accounts.first(where: { $0.user.id == user.id })?.user ?? user
    }

    func checkEmailExists(_ email: String) -> Bool {
        let normalized = normalizeEmail(email)
        return state.accounts.contains(where: { normalizeEmail($0.user.email) == normalized })
    }

    func resetPassword(email: String, newPassword: String) throws {
        let normalized = normalizeEmail(email)
        guard let index = state.accounts.firstIndex(where: { normalizeEmail($0.user.email) == normalized }) else {
            throw DemoDataStoreError.emailNotFound
        }
        state.accounts[index].password = newPassword
        persist()
    }

    func changePassword(currentPassword: String, newPassword: String) throws {
        let userID = try currentUserID()
        guard let index = state.accounts.firstIndex(where: { $0.user.id == userID }) else {
            throw DemoDataStoreError.notFound
        }
        guard state.accounts[index].password == currentPassword else {
            throw DemoDataStoreError.invalidCredentials
        }
        state.accounts[index].password = newPassword
        persist()
    }

    func allUsers(page: Int, limit: Int) throws -> [User] {
        try requireAdmin()
        let users = state.accounts.map(\.user).sorted { $0.full_name < $1.full_name }
        return paginate(items: users, page: page, limit: limit)
    }

    func user(by id: String) throws -> User {
        try requireAdmin()
        guard let user = state.accounts.first(where: { $0.user.id == id })?.user else {
            throw DemoDataStoreError.notFound
        }
        return user
    }

    func updateUser(id: String, fullName: String, username: String, email: String, role: String, password: String?) throws -> User {
        try requireAdmin()
        guard let index = state.accounts.firstIndex(where: { $0.user.id == id }) else {
            throw DemoDataStoreError.notFound
        }
        let normalizedUsername = normalizeUsername(username)
        guard !normalizedUsername.isEmpty else {
            throw DemoDataStoreError.usernameRequired
        }
        guard normalizedUsername.count >= 3 else {
            throw DemoDataStoreError.invalidUsername
        }
        guard !state.accounts.contains(where: {
            $0.user.id != id && normalizeUsername($0.user.username) == normalizedUsername
        }) else {
            throw DemoDataStoreError.usernameAlreadyExists
        }
        state.accounts[index].user.full_name = fullName
        state.accounts[index].user.username = normalizedUsername
        state.accounts[index].user.email = normalizeEmail(email)
        state.accounts[index].user.role = role
        if let password, !password.isEmpty {
            state.accounts[index].password = password
        }
        persist()
        return state.accounts[index].user
    }

    func createUser(fullName: String, username: String, email: String, password: String, role: String) throws -> User {
        try requireAdmin()
        let normalizedUsername = normalizeUsername(username)
        let normalized = normalizeEmail(email)
        guard !normalizedUsername.isEmpty else {
            throw DemoDataStoreError.usernameRequired
        }
        guard normalizedUsername.count >= 3 else {
            throw DemoDataStoreError.invalidUsername
        }
        guard !state.accounts.contains(where: { normalizeEmail($0.user.email) == normalized }) else {
            throw DemoDataStoreError.emailAlreadyExists
        }
        guard !state.accounts.contains(where: { normalizeUsername($0.user.username) == normalizedUsername }) else {
            throw DemoDataStoreError.usernameAlreadyExists
        }
        let user = User(id: "user-\(UUID().uuidString.prefix(8))", full_name: fullName, email: normalized, role: role, username: normalizedUsername, avatar: nil, created_at: isoFormatter.string(from: Date()))
        state.accounts.append(DemoAccount(user: user, password: password))
        persist()
        return user
    }

    func updateProfile(fullName: String, email: String) throws -> User {
        let userID = try currentUserID()
        guard let index = state.accounts.firstIndex(where: { $0.user.id == userID }) else {
            throw DemoDataStoreError.notFound
        }
        state.accounts[index].user.full_name = fullName
        state.accounts[index].user.email = normalizeEmail(email)
        persist()
        return state.accounts[index].user
    }

    func resetPassword(for userID: String, newPassword: String) throws {
        try requireAdmin()
        guard let index = state.accounts.firstIndex(where: { $0.user.id == userID }) else {
            throw DemoDataStoreError.notFound
        }
        state.accounts[index].password = newPassword
        persist()
    }

    func deleteUser(id: String) throws {
        try requireAdmin()
        state.accounts.removeAll(where: { $0.user.id == id })
        state.enrollments.removeAll(where: { $0.userID == id })
        state.progressEntries.removeAll(where: { $0.userID == id })
        persist()
    }

    func allCategories(page: Int, limit: Int) -> [Category] {
        paginate(items: state.categories.sorted { $0.name < $1.name }, page: page, limit: limit)
    }

    func category(by id: String) throws -> Category {
        guard let category = state.categories.first(where: { $0.id == id }) else {
            throw DemoDataStoreError.notFound
        }
        return category
    }

    func createCategory(name: String, description: String) throws -> Category {
        try requireAdmin()
        let category = Category(id: "cat-\(UUID().uuidString.prefix(6))", name: name, description: description)
        state.categories.append(category)
        persist()
        return category
    }

    func updateCategory(id: String, name: String, description: String) throws -> Category {
        try requireAdmin()
        guard let index = state.categories.firstIndex(where: { $0.id == id }) else {
            throw DemoDataStoreError.notFound
        }
        state.categories[index].name = name
        state.categories[index].description = description
        persist()
        syncCategoryNames()
        return state.categories[index]
    }

    func deleteCategory(id: String) throws {
        try requireAdmin()
        state.categories.removeAll(where: { $0.id == id })
        for index in state.courses.indices where state.courses[index].category_id == id {
            state.courses[index].category_id = nil
            state.courses[index].category_name = nil
        }
        persist()
    }

    private func syncCategoryNames() {
        for index in state.courses.indices {
            if let categoryID = state.courses[index].category_id {
                state.courses[index].category_name = state.categories.first(where: { $0.id == categoryID })?.name
            }
        }
        persist()
    }

    func allCourses(page: Int, limit: Int, categoryID: String?) -> [Course] {
        let canSeeDrafts = SessionManager.shared.isAdmin
        let filtered = state.courses
            .filter { canSeeDrafts || isCoursePublic($0) }
            .filter { categoryID == nil || $0.category_id == categoryID }
            .sorted { $0.created_at ?? "" > $1.created_at ?? "" }
            .map { enrich(course: $0, for: SessionManager.shared.currentUser?.id) }
        return paginate(items: filtered, page: page, limit: limit)
    }

    func popularCourses(limit: Int = 5) -> [Course] {
        state.courses
            .filter { SessionManager.shared.isAdmin || isCoursePublic($0) }
            .sorted { ($0.student_count ?? 0) > ($1.student_count ?? 0) }
            .prefix(limit)
            .map { enrich(course: $0, for: SessionManager.shared.currentUser?.id) }
    }

    func course(bySlug slug: String) throws -> Course {
        guard let course = state.courses.first(where: { $0.slug == slug }) else {
            throw DemoDataStoreError.notFound
        }
        if !SessionManager.shared.isAdmin && !isCoursePublic(course) {
            throw DemoDataStoreError.notFound
        }
        return enrich(course: course, for: SessionManager.shared.currentUser?.id)
    }

    func createCourse(data: [String: String]) throws -> Course {
        try requireAdmin()
        try ensureCourseCanBePublished(courseID: nil, requestedStatus: data["status"])
        let course = Course(
            id: "course-\(UUID().uuidString.prefix(8))",
            slug: data["slug"] ?? data["title"]?.lowercased().replacingOccurrences(of: " ", with: "-"),
            title: data["title"] ?? "Khóa học mới",
            description: data["description"] ?? "",
            thumbnail: data["thumbnail"],
            instructor_name: data["instructor_name"] ?? SessionManager.shared.currentUser?.full_name,
            instructor_email: data["instructor_email"] ?? SessionManager.shared.currentUser?.email,
            category_id: data["category_id"],
            category_name: state.categories.first(where: { $0.id == data["category_id"] })?.name,
            student_count: 0,
            review_count: 0,
            rating: 0,
            duration: data["duration"] ?? "00:00:00",
            price: Double(data["price"] ?? "0"),
            status: data["status"] ?? "draft",
            created_at: isoFormatter.string(from: Date()),
            progress: 0,
            completed_lessons: 0,
            total_lessons: 0,
            version: 1,
            base_course_id: nil
        )
        saveCourse(course)
        return enrich(course: course, for: SessionManager.shared.currentUser?.id)
    }

    func updateCourse(id: String, data: [String: String]) throws -> Course {
        try requireAdmin()
        guard let index = state.courses.firstIndex(where: { $0.id == id }) else {
            throw DemoDataStoreError.notFound
        }
        try ensureCourseCanBePublished(courseID: id, requestedStatus: data["status"] ?? state.courses[index].status)
        state.courses[index].title = data["title"] ?? state.courses[index].title
        state.courses[index].description = data["description"] ?? state.courses[index].description
        state.courses[index].thumbnail = data["thumbnail"] ?? state.courses[index].thumbnail
        state.courses[index].price = Double(data["price"] ?? "") ?? state.courses[index].price
        state.courses[index].category_id = data["category_id"] ?? state.courses[index].category_id
        state.courses[index].category_name = state.categories.first(where: { $0.id == state.courses[index].category_id })?.name
        state.courses[index].status = data["status"] ?? state.courses[index].status
        state.courses[index].slug = data["slug"] ?? state.courses[index].slug
        persist()
        return enrich(course: state.courses[index], for: SessionManager.shared.currentUser?.id)
    }

    func updateCourseStatus(id: String, status: String) throws -> Course {
        try requireAdmin()
        guard let index = state.courses.firstIndex(where: { $0.id == id }) else {
            throw DemoDataStoreError.notFound
        }
        try ensureCourseCanBePublished(courseID: id, requestedStatus: status)
        state.courses[index].status = status
        persist()
        return enrich(course: state.courses[index], for: SessionManager.shared.currentUser?.id)
    }

    func deleteCourse(id: String) throws {
        try requireAdmin()
        state.courses.removeAll(where: { $0.id == id })
        state.lessons.removeAll(where: { $0.course_id == id })
        state.enrollments.removeAll(where: { $0.courseID == id })
        state.progressEntries.removeAll(where: { $0.courseID == id })
        persist()
    }

    func lessons(for courseID: String) -> [Lesson] {
        state.lessons.filter { $0.course_id == courseID }.sorted { $0.lesson_order < $1.lesson_order }
    }

    func lesson(by id: String) throws -> Lesson {
        guard let lesson = state.lessons.first(where: { $0.id == id }) else {
            throw DemoDataStoreError.notFound
        }
        return lesson
    }

    func nextLesson(courseID: String, lessonOrder: Int) -> Lesson? {
        lessons(for: courseID).first(where: { $0.lesson_order == lessonOrder + 1 })
    }

    func createLesson(data: [String: String]) throws -> Lesson {
        try requireAdmin()
        guard let courseID = data["course_id"] else {
            throw DemoDataStoreError.notFound
        }
        guard let sourceCourse = state.courses.first(where: { $0.id == courseID }) else {
            throw DemoDataStoreError.notFound
        }
        let editableCourse = latestCourseInFamily(for: sourceCourse)
        let targetCourse = courseHasCompletedCertificates(editableCourse.id)
            ? createNewCourseVersion(from: editableCourse)
            : editableCourse
        let lesson = Lesson(
            id: "lesson-\(UUID().uuidString.prefix(8))",
            course_id: targetCourse.id,
            title: data["title"] ?? "Bài học mới",
            thumbnail_url: data["thumbnail_url"],
            video_url: data["video_url"],
            lesson_order: Int(data["lesson_order"] ?? "1") ?? 1,
            duration: data["duration"] ?? "00:00"
        )
        state.lessons.append(lesson)
        persist()
        return lesson
    }

    func updateLesson(id: String, data: [String: String]) throws -> Lesson {
        try requireAdmin()
        guard let index = state.lessons.firstIndex(where: { $0.id == id }) else {
            throw DemoDataStoreError.notFound
        }
        state.lessons[index].title = data["title"] ?? state.lessons[index].title
        state.lessons[index].thumbnail_url = data["thumbnail_url"] ?? state.lessons[index].thumbnail_url
        state.lessons[index].video_url = data["video_url"] ?? state.lessons[index].video_url
        state.lessons[index].lesson_order = Int(data["lesson_order"] ?? "") ?? state.lessons[index].lesson_order
        state.lessons[index].duration = data["duration"] ?? state.lessons[index].duration
        persist()
        return state.lessons[index]
    }

    func deleteLesson(id: String) throws {
        try requireAdmin()
        let courseID = state.lessons.first(where: { $0.id == id })?.course_id
        state.lessons.removeAll(where: { $0.id == id })
        state.progressEntries.removeAll(where: { $0.lessonID == id })
        if let courseID,
           !courseHasLessons(courseID),
           let courseIndex = state.courses.firstIndex(where: { $0.id == courseID }) {
            state.courses[courseIndex].status = "draft"
        }
        persist()
    }

    func myEnrolledCourses(page: Int, limit: Int) throws -> [Course] {
        let userID = try currentUserID()
        let courses = state.enrollments
            .filter { $0.userID == userID }
            .compactMap { enrollment in state.courses.first(where: { $0.id == enrollment.courseID }) }
            .map { enrich(course: $0, for: userID) }
        return paginate(items: courses, page: page, limit: limit)
    }

    func enrolledStudents(courseID: String, page: Int, limit: Int) throws -> [User] {
        try requireAdmin()
        let studentIDs = state.enrollments.filter { $0.courseID == courseID }.map(\.userID)
        let users = state.accounts.map(\.user).filter { studentIDs.contains($0.id) }
        return paginate(items: users, page: page, limit: limit)
    }

    func isEnrolled(courseID: String) throws -> Bool {
        let userID = try currentUserID()
        return state.enrollments.contains(where: { $0.userID == userID && $0.courseID == courseID })
    }

    func enroll(courseID: String) throws -> Enrollment {
        let userID = try currentUserID()
        if let index = state.enrollments.firstIndex(where: { $0.userID == userID && $0.courseID == courseID }) {
            return Enrollment(course_id: courseID, status: state.enrollments[index].status, progress: state.enrollments[index].progress)
        }
        let record = DemoEnrollmentRecord(userID: userID, courseID: courseID, status: "active", progress: 0)
        state.enrollments.append(record)
        persist()
        return Enrollment(course_id: courseID, status: record.status, progress: record.progress)
    }

    func unenroll(courseID: String) throws {
        let userID = try currentUserID()
        state.enrollments.removeAll(where: { $0.userID == userID && $0.courseID == courseID })
        state.progressEntries.removeAll(where: { $0.userID == userID && $0.courseID == courseID })
        persist()
    }

    func updateEnrollmentStatus(courseID: String, status: String) throws {
        let userID = try currentUserID()
        guard let index = state.enrollments.firstIndex(where: { $0.userID == userID && $0.courseID == courseID }) else {
            throw DemoDataStoreError.notFound
        }
        state.enrollments[index].status = status
        persist()
    }

    func createPayment(courseID: String, paymentMethod: String) throws -> Payment {
        let userID = try currentUserID()
        let course = try course(withID: courseID)
        let payment = Payment(id: state.paymentSeed, course_id: courseID, amount: course.price ?? 0, status: "pending", payment_method: paymentMethod)
        state.paymentSeed += 1
        state.payments.append(DemoPaymentRecord(payment: payment, userID: userID))
        persist()
        return payment
    }

    func confirmPayment(paymentID: Int) throws -> Payment {
        guard let index = state.payments.firstIndex(where: { $0.payment.id == paymentID }) else {
            throw DemoDataStoreError.notFound
        }
        state.payments[index].payment.status = "success"
        persist()
        _ = try enroll(courseID: state.payments[index].payment.course_id)
        return state.payments[index].payment
    }

    func updateProgress(lessonID: String, courseID: String) throws -> ProgressRecord {
        let userID = try currentUserID()
        let orderedLessons = lessons(for: courseID)
        guard let targetLesson = orderedLessons.first(where: { $0.id == lessonID }) else {
            throw DemoDataStoreError.notFound
        }
        let completedIDs = Set(lessonProgress(for: userID, courseID: courseID).map(\.lessonID))
        if targetLesson.lesson_order > 1 {
            let previousLesson = orderedLessons.first(where: { $0.lesson_order == targetLesson.lesson_order - 1 })
            if let previousLesson, !completedIDs.contains(previousLesson.id) {
                throw DemoDataStoreError.lockedLesson
            }
        }
        if let index = state.progressEntries.firstIndex(where: { $0.userID == userID && $0.courseID == courseID && $0.lessonID == lessonID }) {
            state.progressEntries[index].completed = true
            state.progressEntries[index].completedAt = isoFormatter.string(from: Date())
        } else {
            state.progressEntries.append(DemoProgressEntry(userID: userID, courseID: courseID, lessonID: lessonID, completed: true, completedAt: isoFormatter.string(from: Date())))
        }
        updateEnrollmentProgress(for: userID, courseID: courseID)
        let record = ProgressRecord(lesson_id: lessonID, completed: true, completed_at: isoFormatter.string(from: Date()))
        return record
    }

    func studentProgress(courseID: String) throws -> [ProgressRecord] {
        let userID = try currentUserID()
        return lessonProgress(for: userID, courseID: courseID).map {
            ProgressRecord(lesson_id: $0.lessonID, completed: $0.completed, completed_at: $0.completedAt)
        }
    }

    func myProgress() throws -> [Course] {
        try myEnrolledCourses(page: 1, limit: 200)
    }

    func hasCompleted(lessonID: String) throws -> Bool {
        let userID = try currentUserID()
        return state.progressEntries.contains(where: { $0.userID == userID && $0.lessonID == lessonID && $0.completed })
    }

    func courseStats(courseID: String) -> DashboardStats {
        let courseLessons = lessons(for: courseID).count
        let courseEnrollments = state.enrollments.filter { $0.courseID == courseID }
        let completionCount = courseEnrollments.filter { $0.progress >= 100 }.count
        let activeCount = courseEnrollments.filter { $0.progress > 0 && $0.progress < 100 }.count
        let average = courseEnrollments.isEmpty ? 0 : Int(courseEnrollments.reduce(0) { $0 + $1.progress } / Double(courseEnrollments.count))
        return DashboardStats(inProgressCount: activeCount, completedCount: completionCount, totalLessons: courseLessons, averageProgress: average)
    }

    func systemStatistics() -> ReportSummary {
        let monthlyRevenue = state.payments
            .filter { $0.payment.status == "success" }
            .reduce(0) { $0 + $1.payment.amount }

        return ReportSummary(
            totalUsers: state.accounts.count,
            totalCourses: state.courses.count,
            totalEnrollments: state.enrollments.count,
            monthlyRevenue: monthlyRevenue
        )
    }

    func courseStatistics(courseID: String) throws -> CourseStatistic {
        let course = try course(withID: courseID)
        let enrollments = state.enrollments.filter { $0.courseID == courseID }
        let completionRate = enrollments.isEmpty ? 0 : (Double(enrollments.filter { $0.progress >= 100 }.count) / Double(enrollments.count)) * 100
        return CourseStatistic(course: course, enrolledStudents: enrollments.count, completionRate: completionRate)
    }

    func studentStatistics(courseID: String, page: Int, limit: Int) throws -> [StudentStatistic] {
        try requireAdmin()
        let enrollments = state.enrollments.filter { $0.courseID == courseID }
        let stats = enrollments.compactMap { enrollment -> StudentStatistic? in
            guard let user = state.accounts.first(where: { $0.user.id == enrollment.userID })?.user else { return nil }
            return StudentStatistic(user: user, progress: enrollment.progress)
        }
        return paginate(items: stats, page: page, limit: limit)
    }

    func instructorStatistics(instructorID: String) throws -> InstructorStatistic {
        try requireAdmin()
        guard let instructor = state.accounts.first(where: { $0.user.id == instructorID })?.user else {
            throw DemoDataStoreError.notFound
        }
        let courses = state.courses.filter { $0.instructor_email == instructor.email }
        let totalStudents = courses.reduce(into: 0) { result, course in
            result += state.enrollments.filter { $0.courseID == course.id }.count
        }
        return InstructorStatistic(instructorName: instructor.full_name, totalCourses: courses.count, totalStudents: totalStudents)
    }

    func topCourses(limit: Int) -> [Course] {
        popularCourses(limit: limit)
    }

    func monthlyReport(year: Int, month: Int) -> MonthlyReport {
        let labels = ["T1", "T2", "T3", "T4", "T5", "T6"]
        let values = [12.0, 18.0, 23.0, 20.0, 28.0, 31.0].map { $0 * 1_000_000 }
        return MonthlyReport(labels: labels, values: values)
    }

    func dashboardStatsForCurrentUser() throws -> DashboardStats {
        let userID = try currentUserID()
        let enrollments = state.enrollments.filter { $0.userID == userID }
        let inProgress = enrollments.filter { $0.progress > 0 && $0.progress < 100 }.count
        let completed = enrollments.filter { $0.progress >= 100 }.count
        let totalLessons = enrollments.reduce(0) { result, enrollment in
            result + state.lessons.filter { $0.course_id == enrollment.courseID }.count
        }
        let averageProgress = enrollments.isEmpty ? 0 : Int(enrollments.reduce(0) { $0 + $1.progress } / Double(enrollments.count))
        return DashboardStats(inProgressCount: inProgress, completedCount: completed, totalLessons: totalLessons, averageProgress: averageProgress)
    }

    func paginate<T>(items: [T], page: Int, limit: Int) -> [T] {
        guard limit > 0 else { return items }
        let start = max(0, (page - 1) * limit)
        guard start < items.count else { return [] }
        let end = min(items.count, start + limit)
        return Array(items[start ..< end])
    }
}
