import Foundation

enum LessonVideoSuggestionProvider {
    private static let iosStoryboards = "https://www.youtube.com/watch?v=als-345E2E0"
    private static let swiftFullCourse = "https://www.youtube.com/watch?v=8Xg7E9shq0U"
    private static let swiftOptionals = "https://www.youtube.com/watch?v=3M1G1tdbtDo"
    private static let swiftProtocolOriented = "https://www.youtube.com/watch?v=wATufOPMK-A"
    private static let swiftAsyncAwait = "https://www.youtube.com/watch?v=YyZhYCe68fw"
    private static let swiftErrorHandling = "https://www.youtube.com/watch?v=0lftKa16QFc"
    private static let uiuxFullCourse = "https://www.youtube.com/watch?v=2icljqpaddk"
    private static let businessEnglish = "https://www.youtube.com/watch?v=GwQRH-KFlP0"
    private static let workEnglishPhrases = "https://www.youtube.com/watch?v=jJJwUoBVmFY"
    private static let businessWriting = "https://www.youtube.com/watch?v=eIhwHjYKGng"
    private static let digitalMarketing = "https://www.youtube.com/watch?v=5altc8xTzBg"
    private static let reactFullstack = "https://www.youtube.com/watch?v=7CqJlxBYj-M"
    private static let reactAppwrite = "https://www.youtube.com/watch?v=SwviLVyaRKU"
    private static let reactRedux = "https://www.youtube.com/watch?v=NqzdVN2tyvQ"
    private static let studySkills = "https://www.youtube.com/watch?v=h9ven4N67i0"
    private static let highPerformanceStudents = "https://www.youtube.com/watch?v=vO1bpod0vKM"
    private static let learningHowToLearn = "https://www.youtube.com/watch?v=vd2dtkMINIw"
    private static let expressBasics = "https://www.youtube.com/watch?v=qbwDY6mP8WY"
    private static let nodeRestAPI = "https://www.youtube.com/watch?v=l8WPWK9mS5M"
    private static let apiBeginners = "https://www.youtube.com/watch?v=WXsD0ZgxjRw"
    private static let nodeProjectZero = "https://www.youtube.com/watch?v=Lj-QNEo07yg"
    private static let nodeStructureESLint = "https://www.youtube.com/watch?v=8hhXamKIdsY"
    private static let babelExplained = "https://www.youtube.com/watch?v=aVLgL5LJh5Y"
    private static let mongoNoSQLTips = "https://www.youtube.com/watch?v=a1dogHmrm1c"
    private static let mongodbVsMongoose = "https://www.youtube.com/watch?v=KOvjvVn1j-M"
    private static let nodeDeployRender = "https://www.youtube.com/watch?v=-yl003Wbs78"
    private static let promptEngineering = "https://www.youtube.com/watch?v=CxbHw93oWP0"
    private static let aiInEducation = "https://www.youtube.com/watch?v=-28gv8W8B0s"
    private static let aiCourse = "https://www.youtube.com/watch?v=uRQH2CFvedY"
    private static let productManagerDay = "https://www.youtube.com/watch?v=Dnh0jP-GA0o"
    private static let productLifecycle = "https://www.youtube.com/watch?v=bI48pbtMgKE"
    private static let productRoadmap = "https://www.youtube.com/watch?v=o8Zi8yvgD9k"
    private static let sqlFullCourse = "https://www.youtube.com/watch?v=HXV3zeQKqGY"
    private static let sqlQuerying = "https://www.youtube.com/watch?v=AFY3z4FwRg0"
    private static let sqlWhereClause = "https://www.youtube.com/watch?v=zUoZIyy5kRg"
    private static let sqlJoinTutorial = "https://www.youtube.com/watch?v=0Pg2fvSC05A"
    private static let sqlGroupByTutorial = "https://www.youtube.com/watch?v=GWj2R_0wAGk"
    private static let sqlAggregateFunctions = "https://www.youtube.com/watch?v=rzbFQnTWhPM"
    private static let presentationOpening = "https://www.youtube.com/watch?v=LrjlW00kkws"
    private static let storytellingPresentation = "https://www.youtube.com/watch?v=8M83OFKAnFk"
    private static let slideDesignPresentation = "https://www.youtube.com/watch?v=iGjSdWxKfjA"
    private static let presentationBodyLanguage = "https://www.youtube.com/watch?v=ET7qsJv6nLk"
    private static let presentationFrameworks = "https://www.youtube.com/watch?v=pd36Jay0B_8"

    static func suggestedURL(for lessonTitle: String, courseTitle: String? = nil, fallback: String? = nil) -> String {
        let title = normalized(lessonTitle)
        if let exact = exactTitleMap[title] {
            return exact
        }
        if let fallback, !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fallback
        }
        return searchURL(for: lessonTitle, courseTitle: courseTitle)
    }

    static func autofillURL(for lessonTitle: String, courseTitle: String? = nil) -> String {
        let title = normalized(lessonTitle)
        if let exact = exactTitleMap[title] {
            return exact
        }
        return searchURL(for: lessonTitle, courseTitle: courseTitle)
    }

    static func searchURL(for lessonTitle: String, courseTitle: String? = nil) -> String {
        let combinedQuery = [courseTitle, lessonTitle, "youtube"]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let encoded = combinedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? combinedQuery
        return "https://www.youtube.com/results?search_query=\(encoded)"
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static let exactTitleMap: [String: String] = [
        normalized("Khởi tạo kiến trúc dự án UIKit"): iosStoryboards,
        normalized("Thiết kế Theme và reusable views"): swiftFullCourse,
        normalized("Auth flow, SessionManager, RootRouter"): iosStoryboards,
        normalized("Dashboard và My Courses"): iosStoryboards,
        normalized("Lesson player, progress unlock logic"): swiftFullCourse,
        normalized("Admin CRUD với UIKit"): swiftFullCourse,
        normalized("Chart báo cáo và polish storyboard"): iosStoryboards,

        normalized("Audit web flow và mobile adaptation"): uiuxFullCourse,
        normalized("Design card system cho app giáo dục"): uiuxFullCourse,
        normalized("Tối ưu dashboard và progress UI"): uiuxFullCourse,
        normalized("Payment UX và empty states"): uiuxFullCourse,
        normalized("Component review cuối khóa"): uiuxFullCourse,

        normalized("Small talk tự tin"): businessEnglish,
        normalized("Họp nhóm hiệu quả"): workEnglishPhrases,
        normalized("Báo cáo tiến độ"): businessEnglish,
        normalized("Thuyết trình ngắn"): presentationOpening,
        normalized("Viết email chuyên nghiệp"): businessWriting,
        normalized("Ôn tập và tự đánh giá"): workEnglishPhrases,

        normalized("Funnel và North Star"): digitalMarketing,
        normalized("Retention loops"): digitalMarketing,
        normalized("Lifecycle campaigns"): digitalMarketing,
        normalized("Growth dashboard"): digitalMarketing,

        normalized("Khởi tạo monorepo và backend"): reactFullstack,
        normalized("Guest browsing flow"): reactAppwrite,
        normalized("Student enrollment flow"): reactFullstack,
        normalized("Payment service integration"): reactAppwrite,
        normalized("Lesson and progress tracking"): reactRedux,
        normalized("Admin management screens"): reactRedux,
        normalized("Reports and analytics"): reactFullstack,
        normalized("Deployment and polish"): reactAppwrite,

        normalized("Lập kế hoạch học tập"): studySkills,
        normalized("Tạo thói quen hàng tuần"): highPerformanceStudents,
        normalized("Mốc hoàn thành và chứng chỉ"): learningHowToLearn,

        normalized("39. Khởi tạo dự án Back-end API từ con số 0"): nodeProjectZero,
        normalized("40. Cấu trúc dự án nâng cao, chuẩn thực tế, có ESLint"): nodeStructureESLint,
        normalized("Babel Explained in 2 minutes | What is Babel?"): babelExplained,
        normalized("42. Tips Thiết kế cơ sở dữ liệu NoSQL | MongoDB Database | NodeJS"): mongoNoSQLTips,
        normalized("43. MongoDB vs Mongoose - Đừng nhầm lẫn nữa"): mongodbVsMongoose,
        normalized("Deploy Node.js REST API on Render | CRUD | Express | MongoDB Atlas"): nodeDeployRender,
        normalized("Thiết kế cấu trúc REST API"): nodeProjectZero,
        normalized("Auth và phân quyền người dùng"): nodeStructureESLint,
        normalized("CRUD course và category"): babelExplained,
        normalized("Lesson, enrollment và progress"): mongoNoSQLTips,
        normalized("Payment flow và báo cáo"): mongodbVsMongoose,
        normalized("Deploy và kiểm thử API"): nodeDeployRender,

        normalized("Tư duy prompt cho người học"): promptEngineering,
        normalized("Tạo outline bài học với AI"): aiCourse,
        normalized("Chấm rubric và phản hồi"): aiInEducation,
        normalized("Sinh dashboard insight"): promptEngineering,
        normalized("Ứng dụng vào course platform"): aiInEducation,

        normalized("Xác định problem statement"): productManagerDay,
        normalized("Mapping user flow guest đến admin"): productLifecycle,
        normalized("Ưu tiên backlog và MVP"): productLifecycle,
        normalized("Roadmap release cho EdTech"): productRoadmap,
        normalized("Đo lường outcome sản phẩm"): productManagerDay,

        normalized("Optional, guard và error handling"): swiftOptionals,
        normalized("Swift optionals và optional binding"): swiftOptionals,
        normalized("Protocol-oriented design"): swiftProtocolOriented,
        normalized("Protocol-oriented programming trong Swift"): swiftProtocolOriented,
        normalized("Async await với service layer"): swiftAsyncAwait,
        normalized("Swift async await explained"): swiftAsyncAwait,
        normalized("State management trong UIKit"): swiftErrorHandling,
        normalized("Swift error handling với do try catch"): swiftErrorHandling,
        normalized("Tổ chức file và reusable component"): iosStoryboards,
        normalized("UIKit storyboard refresher cho reusable component"): iosStoryboards,

        normalized("SELECT và FILTER căn bản"): sqlWhereClause,
        normalized("SQL WHERE clause: SELECT và FILTER"): sqlWhereClause,
        normalized("JOIN dữ liệu user-course-progress"): sqlJoinTutorial,
        normalized("SQL JOIN tutorial: kết nối nhiều bảng"): sqlJoinTutorial,
        normalized("GROUP BY và metrics dashboard"): sqlGroupByTutorial,
        normalized("SQL GROUP BY tutorial"): sqlGroupByTutorial,
        normalized("Tối ưu truy vấn báo cáo"): sqlAggregateFunctions,
        normalized("SQL aggregate functions cho báo cáo"): sqlAggregateFunctions,
        normalized("Case study LMS analytics"): sqlFullCourse,
        normalized("SQL Full Course recap cho LMS analytics"): sqlFullCourse,

        normalized("Chuẩn bị mở đầu bài thuyết trình"): presentationOpening,
        normalized("How to start a presentation"): presentationOpening,
        normalized("Storytelling cho bài thuyết trình"): storytellingPresentation,
        normalized("5 Storytelling Tips for your Presentation"): storytellingPresentation,
        normalized("Thiết kế slide presentation dễ nhìn"): slideDesignPresentation,
        normalized("Slide design for presentations"): slideDesignPresentation,
        normalized("Body language khi thuyết trình"): presentationBodyLanguage,
        normalized("Presentation body language"): presentationBodyLanguage,
        normalized("Presentation frameworks để giữ người nghe"): presentationFrameworks,
        normalized("Presentation frameworks"): presentationFrameworks
    ]
}
