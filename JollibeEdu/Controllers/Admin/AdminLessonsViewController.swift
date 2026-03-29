//
//  AdminLessonsViewController.swift
//  JollibeEdu
//
//  Created by Tạ Minh Thiện on 23/3/26.
//

import UIKit

enum VideoDurationResolverError: LocalizedError {
    case unableToVerifyYouTubeDuration

    var errorDescription: String? {
        switch self {
        case .unableToVerifyYouTubeDuration:
            return L10n.tr("video.duration.error.youtube")
        }
    }
}

enum VideoDurationResolver {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        return URLSession(configuration: configuration)
    }()

    static func syncedDuration(for rawVideoURL: String?, fallbackDuration: String) async throws -> String {
        let trimmedDuration = fallbackDuration.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let rawVideoURL else { return trimmedDuration }
        let trimmedVideoURL = rawVideoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedVideoURL.isEmpty else { return trimmedDuration }

        guard let videoID = MediaURLResolver.extractedYouTubeVideoID(from: trimmedVideoURL) else {
            return trimmedDuration
        }

        return try await fetchYouTubeDuration(videoID: videoID)
    }

    static func fetchYouTubeDuration(videoID: String) async throws -> String {
        guard let url = MediaURLResolver.youtubeWatchURL(for: videoID) else {
            throw VideoDurationResolverError.unableToVerifyYouTubeDuration
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw VideoDurationResolverError.unableToVerifyYouTubeDuration
        }

        let html = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""

        guard let match = html.range(of: #""lengthSeconds":"(\d+)""#, options: .regularExpression) else {
            throw VideoDurationResolverError.unableToVerifyYouTubeDuration
        }

        let fragment = String(html[match])
        guard let seconds = Int(fragment.replacingOccurrences(of: #""lengthSeconds":"([0-9]+)""#, with: "$1", options: .regularExpression)) else {
            throw VideoDurationResolverError.unableToVerifyYouTubeDuration
        }

        return AppFormatting.durationString(from: seconds)
    }
}

final class AdminLessonsViewController: AdminProtectedViewController, UITableViewDataSource, UITableViewDelegate {
    private struct LessonFormDraft {
        var title: String
        var thumbnailURL: String
        var videoURL: String
        var lessonOrder: String
        var duration: String
    }

    var course: Course?
    var courseID: String?

    private var lessons: [Lesson] = []
    private let photoLibraryPicker = PhotoLibraryImagePicker()
    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var listCardView: UIView!
    @IBOutlet private weak var listContainerView: UIView!
    @IBOutlet private weak var listHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableView: IntrinsicTableView!

    override func buildContent() {
        title = L10n.tr("admin.lessons.title")
        navigationItem.largeTitleDisplayMode = .never

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        listCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 0

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AdminListTableViewCell.self, forCellReuseIdentifier: AdminListTableViewCell.reuseIdentifier)

        Task {
            await loadLessons()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }

    private func updateTableHeight() {
        tableView.layoutIfNeeded()
        listHeightConstraint.constant = max(220, tableView.contentSize.height)
    }

    private func loadLessons() async {
        do {
            if course == nil, let courseID {
                course = try await CourseService.shared.getById(id: courseID)
            }
            titleLabel.text = course?.displayTitle ?? L10n.tr("admin.lessons.fallbackTitle")
            guard let course else { return }
            lessons = try await LessonService.shared.getByCourse(courseId: course.id)
            lessons.sort { $0.lesson_order < $1.lesson_order }
            tableView.reloadData()
            updateTableHeight()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    @IBAction private func addLessonTapped(_ sender: Any) {
        presentLessonForm(lesson: nil)
    }

    private func previewLesson(_ lesson: Lesson) {
        guard let course else { return }
        let controller: LessonDetailViewController = RootRouter.shared.instantiate(identifier: "LessonDetailViewController")
        controller.course = course
        controller.lessonID = lesson.id
        controller.allowsAdminPreview = true
        navigationController?.pushViewController(controller, animated: true)
    }

    private func presentLessonForm(lesson: Lesson?, draft: LessonFormDraft? = nil) {
        let currentThumbnailURL = draft?.thumbnailURL ?? lesson?.thumbnail_url ?? ""
        let alert = UIAlertController(
            title: lesson == nil ? L10n.tr("admin.lessons.form.add") : L10n.tr("admin.lessons.form.edit"),
            message: L10n.tr("admin.lessons.form.message"),
            preferredStyle: .alert
        )
        alert.addTextField {
            $0.placeholder = L10n.tr("admin.lessons.form.title")
            $0.text = draft?.title ?? lesson?.title
        }
        alert.addTextField {
            $0.placeholder = L10n.tr("admin.lessons.form.video")
            $0.text = draft?.videoURL ?? lesson?.video_url
        }
        alert.addTextField {
            $0.placeholder = L10n.tr("admin.lessons.form.order")
            $0.keyboardType = .numberPad
            $0.text = draft?.lessonOrder ?? lesson.map { String($0.lesson_order) }
        }
        alert.addTextField {
            $0.placeholder = L10n.tr("admin.lessons.form.duration")
            $0.text = draft?.duration ?? lesson?.duration
        }
        alert.addAction(UIAlertAction(title: L10n.tr("admin.lessons.form.pickImage"), style: .default) { [weak self, weak alert] _ in
            guard let self, let alert else { return }
            let currentDraft = self.makeLessonDraft(from: alert, thumbnailURL: currentThumbnailURL)
            self.pickThumbnailForLesson(lesson: lesson, draft: currentDraft)
        })
        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("common.save"), style: .default) { [weak self] _ in
            guard let self, let course = self.course else { return }
            let formDraft = self.makeLessonDraft(from: alert, thumbnailURL: currentThumbnailURL)

            guard let errorMessage = self.validateLessonForm(formDraft) else {
                Task { @MainActor in
                    do {
                        let syncedDuration = try await VideoDurationResolver.syncedDuration(
                            for: formDraft.videoURL,
                            fallbackDuration: formDraft.duration
                        )
                        let payload = [
                            "course_id": course.id,
                            "title": formDraft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                            "thumbnail_url": formDraft.thumbnailURL.trimmingCharacters(in: .whitespacesAndNewlines),
                            "video_url": formDraft.videoURL.trimmingCharacters(in: .whitespacesAndNewlines),
                            "lesson_order": formDraft.lessonOrder.trimmingCharacters(in: .whitespacesAndNewlines),
                            "duration": syncedDuration
                        ]

                        if let lesson {
                            _ = try await LessonService.shared.update(id: lesson.id, data: payload)
                        } else {
                            let savedLesson = try await LessonService.shared.create(data: payload)
                            if savedLesson.course_id != course.id {
                                self.courseID = savedLesson.course_id
                                self.course = try await CourseService.shared.getById(id: savedLesson.course_id)
                                self.showSuccess(message: L10n.tr("admin.lessons.versioned.success"))
                            }
                        }
                        await self.loadLessons()
                    } catch {
                        self.showError(message: error.localizedDescription) { [weak self] in
                            self?.presentLessonForm(lesson: lesson, draft: formDraft)
                        }
                    }
                }
                return
            }

            self.showError(message: errorMessage) { [weak self] in
                self?.presentLessonForm(lesson: lesson, draft: formDraft)
            }
        })
        present(alert, animated: true)
    }

    private func makeLessonDraft(from alert: UIAlertController, thumbnailURL: String) -> LessonFormDraft {
        LessonFormDraft(
            title: alert.textFields?[0].text ?? "",
            thumbnailURL: thumbnailURL,
            videoURL: alert.textFields?[1].text ?? "",
            lessonOrder: alert.textFields?[2].text ?? "1",
            duration: alert.textFields?[3].text ?? "00:00"
        )
    }

    private func pickThumbnailForLesson(lesson: Lesson?, draft: LessonFormDraft) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.photoLibraryPicker.present(
                from: self,
                onPicked: { [weak self] storedValue in
                    guard let self else { return }
                    var nextDraft = draft
                    if let storedValue {
                        nextDraft.thumbnailURL = storedValue
                    }
                    self.presentLessonForm(lesson: lesson, draft: nextDraft)
                },
                onError: { [weak self] message in
                    self?.showError(message: message) { [weak self] in
                        self?.presentLessonForm(lesson: lesson, draft: draft)
                    }
                }
            )
        }
    }

    private func validateLessonForm(_ draft: LessonFormDraft) -> String? {
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return L10n.tr("admin.lessons.validation.title")
        }
        guard let order = Int(draft.lessonOrder.trimmingCharacters(in: .whitespacesAndNewlines)), order > 0 else {
            return L10n.tr("admin.lessons.validation.order")
        }
        guard AppFormatting.seconds(fromDurationString: draft.duration) != nil else {
            return L10n.tr("admin.lessons.validation.duration")
        }
        return nil
    }

    private func deleteLesson(_ lesson: Lesson) {
        showConfirm(
            title: L10n.tr("admin.lessons.delete.title"),
            message: L10n.tr("admin.lessons.delete.message", lesson.title),
            confirmTitle: L10n.tr("admin.lessons.delete.confirm")
        ) { [weak self] in
            Task { @MainActor in
                do {
                    try await LessonService.shared.delete(id: lesson.id)
                    if let self {
                        await self.loadLessons()
                    }
                } catch {
                    self?.showError(message: error.localizedDescription)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(lessons.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard lessons.indices.contains(indexPath.row) else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.text = L10n.tr("admin.lessons.empty.title")
            cell.detailTextLabel?.text = L10n.tr("admin.lessons.empty.subtitle")
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AdminListTableViewCell.reuseIdentifier, for: indexPath) as? AdminListTableViewCell else {
            return UITableViewCell()
        }
        let lesson = lessons[indexPath.row]
        let imageStatus = (lesson.thumbnail_url?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? L10n.tr("admin.lessons.image.available")
            : L10n.tr("admin.lessons.image.missing")
        cell.configure(
            title: L10n.tr("admin.lessons.row.title", lesson.lesson_order, lesson.title),
            subtitle: L10n.tr("admin.lessons.row.subtitle", lesson.duration ?? "--:--", imageStatus, lesson.video_url ?? "N/A"),
            status: "active",
            primaryTitle: L10n.tr("admin.lessons.action.preview"),
            secondaryTitle: L10n.tr("admin.lessons.action.edit"),
            tertiaryTitle: L10n.tr("admin.lessons.action.delete")
        )
        cell.onPrimaryTapped = { [weak self] in self?.previewLesson(lesson) }
        cell.onSecondaryTapped = { [weak self] in self?.presentLessonForm(lesson: lesson) }
        cell.onTertiaryTapped = { [weak self] in self?.deleteLesson(lesson) }
        return cell
    }
}
