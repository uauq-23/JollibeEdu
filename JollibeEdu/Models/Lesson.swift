import Foundation

struct Lesson: Codable, Equatable {
    let id: String
    var course_id: String
    var title: String
    var thumbnail_url: String? = nil
    var video_url: String?
    var lesson_order: Int
    var duration: String?
}
