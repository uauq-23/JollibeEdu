import Foundation

final class LessonService {
    static let shared = LessonService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func getByCourse(courseId: String) async throws -> [Lesson] {
        return demoStore.lessons(for: courseId)
    }

    func getById(id: String) async throws -> Lesson {
        return try demoStore.lesson(by: id)
    }

    func getNext(courseId: String, lessonOrder: Int) async throws -> Lesson? {
        return demoStore.nextLesson(courseID: courseId, lessonOrder: lessonOrder)
    }

    func create(data: [String: String]) async throws -> Lesson {
        return try demoStore.createLesson(data: data)
    }

    func update(id: String, data: [String: String]) async throws -> Lesson {
        return try demoStore.updateLesson(id: id, data: data)
    }

    func delete(id: String) async throws {
        try demoStore.deleteLesson(id: id)
    }
}
