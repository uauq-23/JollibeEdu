import UIKit

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
    private lazy var addBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addLessonTapped))
    }()

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var listCardView: UIView!
    @IBOutlet private weak var listContainerView: UIView!
    @IBOutlet private weak var listHeightConstraint: NSLayoutConstraint!

    private lazy var tableView: IntrinsicTableView = {
        let tableView = IntrinsicTableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AdminListTableViewCell.self, forCellReuseIdentifier: AdminListTableViewCell.reuseIdentifier)
        return tableView
    }()

    override func buildContent() {
        title = L10n.tr("admin.lessons.title")
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = addBarButtonItem

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        listCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 0

        embed(tableView, in: listContainerView)

        Task {
            await loadLessons()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }

    private func embed(_ view: UIView, in container: UIView) {
        guard view.superview !== container else { return }
        view.removeFromSuperview()
        container.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
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

    @objc private func addLessonTapped() {
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
            $0.placeholder = L10n.tr("admin.lessons.form.thumbnail")
            $0.text = draft?.thumbnailURL ?? lesson?.thumbnail_url
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
            let currentDraft = self.makeLessonDraft(from: alert)
            self.pickThumbnailForLesson(lesson: lesson, draft: currentDraft)
        })
        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("common.save"), style: .default) { [weak self] _ in
            guard let self, let course = self.course else { return }
            let formDraft = self.makeLessonDraft(from: alert)

            guard let errorMessage = self.validateLessonForm(formDraft) else {
                let payload = [
                    "course_id": course.id,
                    "title": formDraft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    "thumbnail_url": formDraft.thumbnailURL.trimmingCharacters(in: .whitespacesAndNewlines),
                    "video_url": formDraft.videoURL.trimmingCharacters(in: .whitespacesAndNewlines),
                    "lesson_order": formDraft.lessonOrder.trimmingCharacters(in: .whitespacesAndNewlines),
                    "duration": formDraft.duration.trimmingCharacters(in: .whitespacesAndNewlines)
                ]

                Task { @MainActor in
                    do {
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

    private func makeLessonDraft(from alert: UIAlertController) -> LessonFormDraft {
        LessonFormDraft(
            title: alert.textFields?[0].text ?? "",
            thumbnailURL: alert.textFields?[1].text ?? "",
            videoURL: alert.textFields?[2].text ?? "",
            lessonOrder: alert.textFields?[3].text ?? "1",
            duration: alert.textFields?[4].text ?? "00:00"
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
