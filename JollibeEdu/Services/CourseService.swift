import Foundation

final class CourseService {
    static let shared = CourseService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func getAll(page: Int, limit: Int, categoryId: String? = nil) async throws -> [Course] {
        return demoStore.allCourses(page: page, limit: limit, categoryID: categoryId)
    }

    func getPopular() async throws -> [Course] {
        return demoStore.popularCourses()
    }

    func getById(id: String) async throws -> Course {
        return try demoStore.course(by: id)
    }

    func getBySlug(slug: String) async throws -> Course {
        return try demoStore.course(bySlug: slug)
    }

    func getByCategory(categoryId: String, page: Int, limit: Int) async throws -> [Course] {
        try await getAll(page: page, limit: limit, categoryId: categoryId)
    }

    func create(data: [String: String]) async throws -> Course {
        return try demoStore.createCourse(data: data)
    }

    func update(id: String, data: [String: String]) async throws -> Course {
        return try demoStore.updateCourse(id: id, data: data)
    }

    func updateStatus(id: String, status: String) async throws -> Course {
        return try demoStore.updateCourseStatus(id: id, status: status)
    }

    func delete(id: String) async throws {
        try demoStore.deleteCourse(id: id)
    }
}
