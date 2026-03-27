import Foundation

final class CategoryService {
    static let shared = CategoryService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func getAll(page: Int, limit: Int) async throws -> [Category] {
        return demoStore.allCategories(page: page, limit: limit)
    }

    func getById(id: String) async throws -> Category {
        return try demoStore.category(by: id)
    }

    func create(name: String, description: String) async throws -> Category {
        return try demoStore.createCategory(name: name, description: description)
    }

    func update(id: String, data: [String: String]) async throws -> Category {
        return try demoStore.updateCategory(id: id, name: data["name"] ?? "", description: data["description"] ?? "")
    }

    func delete(id: String) async throws {
        try demoStore.deleteCategory(id: id)
    }
}
