import Foundation

struct Enrollment: Codable, Equatable {
    var course_id: String
    var status: String
    var progress: Double?
}
