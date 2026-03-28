//
//  LessonListViewController.swift
//  JollibeEdu
//
//  Created by Nguyễn Hoàng Quân on 22/3/26.
//

import UIKit

final class LessonListViewController: AuthenticatedStackViewController, UITableViewDataSource, UITableViewDelegate {
    override var clearsInitialStoryboardContent: Bool { false }

    var course: Course?
    var courseID: String?
    var allowsAdminPreview = false

    private var lessons: [Lesson] = []
    private var completedLessonIDs = Set<String>()

    @IBOutlet private weak var summaryCardView: UIView!
    @IBOutlet private weak var courseImageView: UIImageView!
    @IBOutlet private weak var courseTitleLabel: UILabel!
    @IBOutlet private weak var progressLabel: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var lessonCardView: UIView!
    @IBOutlet private weak var lessonContainerView: UIView!
    @IBOutlet private weak var lessonContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var lessonTableView: IntrinsicTableView!

    override func buildContent() {
        title = L10n.tr("lesson.list.title")
        navigationItem.largeTitleDisplayMode = .never

        summaryCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        lessonCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        courseImageView.layer.cornerRadius = 18
        courseImageView.clipsToBounds = true
        courseImageView.contentMode = .scaleAspectFill
        courseImageView.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.2)
        courseImageView.tintColor = AppTheme.brandOrange

        courseTitleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        courseTitleLabel.textColor = AppTheme.textPrimary
        courseTitleLabel.numberOfLines = 0

        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        progressLabel.textColor = AppTheme.textSecondary

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = AppTheme.brandOrange
        progressView.trackTintColor = AppTheme.softBorder
        lessonTableView.backgroundColor = .clear
        lessonTableView.separatorStyle = .none
        lessonTableView.isScrollEnabled = false
        lessonTableView.dataSource = self
        lessonTableView.delegate = self
        lessonTableView.rowHeight = UITableView.automaticDimension
        lessonTableView.estimatedRowHeight = 96
        lessonTableView.register(LessonRowTableViewCell.self, forCellReuseIdentifier: LessonRowTableViewCell.reuseIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isViewLoaded else { return }
        Task {
            await loadData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }

    private func updateTableHeight() {
        lessonTableView.layoutIfNeeded()
        lessonContainerHeightConstraint.constant = max(220, lessonTableView.contentSize.height)
    }

    private func loadData() async {
        do {
            let resolvedCourseID = course?.id ?? courseID
            if let resolvedCourseID {
                course = try await CourseService.shared.getById(id: resolvedCourseID)
            }
            guard let course else { return }
            lessons = try await LessonService.shared.getByCourse(courseId: course.id)
            if isAdminPreviewMode {
                completedLessonIDs = []
            } else {
                let progress = try await ProgressService.shared.getStudentProgress(courseId: course.id)
                completedLessonIDs = Set(progress.filter(\.completed).map(\.lesson_id))
            }
            courseTitleLabel.text = course.displayTitle
            ImageLoader.shared.loadImage(from: course.thumbnail, into: courseImageView, placeholder: UIImage(systemName: "photo.on.rectangle.angled"))
            if isAdminPreviewMode {
                progressLabel.text = L10n.tr("lesson.list.adminPreview.progress", lessons.count)
                progressView.progress = lessons.isEmpty ? 0 : Float(1.0 / Double(lessons.count))
            } else {
                let percent = AppFormatting.percent(max(course.progressPercentValue, calculateProgress()))
                progressLabel.text = L10n.tr("lesson.list.progress", completedLessonIDs.count, lessons.count, percent)
                progressView.progress = Float(max(course.progressPercentValue, calculateProgress()) / 100)
            }
            lessonTableView.reloadData()
            updateTableHeight()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private var isAdminPreviewMode: Bool {
        allowsAdminPreview && SessionManager.shared.isAdmin
    }

    private func calculateProgress() -> Double {
        guard !lessons.isEmpty else { return 0 }
        return (Double(completedLessonIDs.count) / Double(lessons.count)) * 100
    }

    private func isUnlocked(_ lesson: Lesson) -> Bool {
        if isAdminPreviewMode { return true }
        if lesson.lesson_order == 1 { return true }
        if completedLessonIDs.contains(lesson.id) { return true }
        guard let previous = lessons.first(where: { $0.lesson_order == lesson.lesson_order - 1 }) else { return false }
        return completedLessonIDs.contains(previous.id)
    }

    private func openLesson(_ lesson: Lesson) {
        let controller: LessonDetailViewController = RootRouter.shared.instantiate(identifier: "LessonDetailViewController")
        controller.course = course
        controller.lessonID = lesson.id
        controller.allowsAdminPreview = isAdminPreviewMode
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lessons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LessonRowTableViewCell.reuseIdentifier, for: indexPath) as? LessonRowTableViewCell else {
            return UITableViewCell()
        }
        let lesson = lessons[indexPath.row]
        let completed = completedLessonIDs.contains(lesson.id)
        let locked = !isUnlocked(lesson)
        let current = !completed && isUnlocked(lesson)
        cell.configure(lesson: lesson, completed: completed, locked: locked, current: current)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let lesson = lessons[indexPath.row]
        if isAdminPreviewMode {
            openLesson(lesson)
            return
        }
        guard isUnlocked(lesson) else {
            showError(message: L10n.tr("lesson.list.lockedError"))
            return
        }
        openLesson(lesson)
    }
}
