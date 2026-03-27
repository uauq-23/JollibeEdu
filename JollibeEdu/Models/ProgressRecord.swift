import Foundation

struct ProgressRecord: Codable, Equatable {
    var lesson_id: String
    var completed: Bool
    var completed_at: String?
}
