//
//  AdminCoursesViewController.swift
//  JollibeEdu
//
//  Created by Trương Công Hoan on 21/3/26.
//

import UIKit

final class AdminCoursesViewController: AdminProtectedViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    private struct CourseFormDraft {
        var thumbnail: String
        var title: String
        var description: String
        var price: String
        var categoryID: String
        var status: String
    }

    private var allCourses: [Course] = []
    private var filteredCourses: [Course] = []
    private var metrics: [AdminSummaryMetric] = []
    private var categories: [Category] = []
    private var activePickerAdapters: [TextFieldPickerAdapter] = []
    private let photoLibraryPicker = PhotoLibraryImagePicker()

    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var summaryCardView: UIView!
    @IBOutlet private weak var summaryContainerView: UIView!
    @IBOutlet private weak var summaryHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var searchField: UITextField!
    @IBOutlet private weak var listCardView: UIView!
    @IBOutlet private weak var listContainerView: UIView!
    @IBOutlet private weak var listHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var summaryCollectionView: IntrinsicCollectionView!
    @IBOutlet private weak var tableView: IntrinsicTableView!

    override func buildContent() {
        title = L10n.tr("admin.courses.title")
        navigationItem.largeTitleDisplayMode = .never

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        summaryCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        listCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        searchField.applyAppStyle(placeholder: L10n.tr("admin.courses.search.placeholder"))
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        if let layout = summaryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 14
            layout.minimumInteritemSpacing = 14
        }
        summaryCollectionView.backgroundColor = .clear
        summaryCollectionView.isScrollEnabled = false
        summaryCollectionView.dataSource = self
        summaryCollectionView.delegate = self
        summaryCollectionView.register(AdminSummaryCardCollectionViewCell.self, forCellWithReuseIdentifier: AdminSummaryCardCollectionViewCell.reuseIdentifier)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AdminListTableViewCell.self, forCellReuseIdentifier: AdminListTableViewCell.reuseIdentifier)

        Task {
            await loadCourses()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateEmbeddedHeights()
    }

    private func updateEmbeddedHeights() {
        summaryCollectionView.layoutIfNeeded()
        tableView.layoutIfNeeded()
        summaryHeightConstraint.constant = max(300, summaryCollectionView.collectionViewLayout.collectionViewContentSize.height)
        listHeightConstraint.constant = max(220, tableView.contentSize.height)
    }

    private func loadCourses() async {
        do {
            async let coursesTask = CourseService.shared.getAll(page: 1, limit: 200)
            async let categoriesTask = CategoryService.shared.getAll(page: 1, limit: 50)
            allCourses = try await coursesTask
            categories = try await categoriesTask
            metrics = [
                AdminSummaryMetric(symbol: "book.closed.fill", title: L10n.tr("admin.courses.metric.total"), value: "\(allCourses.count)"),
                AdminSummaryMetric(symbol: "checkmark.circle.fill", title: L10n.tr("admin.courses.metric.published"), value: "\(allCourses.filter { ($0.status ?? "draft") == "published" && ($0.total_lessons ?? 0) > 0 }.count)"),
                AdminSummaryMetric(symbol: "clock.arrow.circlepath", title: L10n.tr("admin.courses.metric.draft"), value: "\(allCourses.filter { $0.status == "draft" }.count)"),
                AdminSummaryMetric(symbol: "person.2.fill", title: L10n.tr("admin.courses.metric.enrollments"), value: "\(allCourses.reduce(0) { $0 + ($1.student_count ?? 0) })")
            ]
            summaryCollectionView.reloadData()
            applyFilters()
            updateEmbeddedHeights()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    @objc private func searchChanged() {
        applyFilters()
    }

    private func applyFilters() {
        let query = (searchField.text ?? "").lowercased()
        filteredCourses = allCourses.filter { course in
            query.isEmpty
                || course.title.lowercased().contains(query)
                || (course.instructor_name?.lowercased().contains(query) ?? false)
                || (course.category_name?.lowercased().contains(query) ?? false)
        }
        tableView.reloadData()
        updateEmbeddedHeights()
    }

    @IBAction private func addCourseTapped(_ sender: Any) {
        presentCourseForm(course: nil)
    }

    private func presentCourseForm(course: Course?, draft: CourseFormDraft? = nil) {
        activePickerAdapters.removeAll()
        var selectedCategoryID = draft?.categoryID ?? course?.category_id ?? categories.first?.id ?? ""
        var selectedStatus = draft?.status ?? course?.status ?? "draft"

        let alert = UIAlertController(
            title: course == nil ? L10n.tr("admin.courses.form.add") : L10n.tr("admin.courses.form.edit"),
            message: L10n.tr("admin.courses.form.message"),
            preferredStyle: .alert
        )
        alert.addTextField {
            $0.placeholder = L10n.tr("admin.courses.form.thumbnail")
            $0.text = draft?.thumbnail ?? course?.thumbnail
        }
        alert.addTextField {
            $0.placeholder = L10n.tr("admin.courses.form.title")
            $0.text = draft?.title ?? course?.title
        }
        alert.addTextField {
            $0.placeholder = L10n.tr("admin.courses.form.description")
            $0.text = draft?.description ?? course?.description
        }
        alert.addTextField {
            $0.placeholder = L10n.tr("admin.courses.form.price")
            $0.keyboardType = .decimalPad
            $0.text = draft?.price ?? course?.price.map { String(Int($0)) }
        }
        alert.addTextField { textField in
            textField.placeholder = L10n.tr("admin.courses.form.category")
            let categoryIDs = self.categories.map(\.id)
            let adapter = TextFieldPickerAdapter(
                textField: textField,
                options: categoryIDs,
                selectedValue: selectedCategoryID,
                displayText: { [weak self] categoryID in
                    self?.categories.first(where: { $0.id == categoryID })?.name ?? categoryID
                },
                onSelection: { value in
                    selectedCategoryID = value
                }
            )
            self.activePickerAdapters.append(adapter)
            textField.isEnabled = !categoryIDs.isEmpty
            if categoryIDs.isEmpty {
                textField.text = L10n.tr("admin.courses.form.noCategories")
            }
        }
        alert.addTextField { textField in
            textField.placeholder = L10n.tr("admin.courses.form.status")
            let adapter = TextFieldPickerAdapter(
                textField: textField,
                options: ["published", "draft"],
                selectedValue: selectedStatus,
                displayText: { [weak self] in self?.courseStatusDisplayName(for: $0) ?? $0.capitalized },
                onSelection: { value in
                    selectedStatus = value
                }
            )
            self.activePickerAdapters.append(adapter)
        }
        alert.addAction(UIAlertAction(title: L10n.tr("admin.courses.form.pickImage"), style: .default) { [weak self, weak alert] _ in
            guard let self, let alert else { return }
            self.activePickerAdapters.removeAll()
            let currentDraft = self.makeCourseDraft(
                from: alert,
                selectedCategoryID: selectedCategoryID,
                selectedStatus: selectedStatus
            )
            self.pickThumbnailForCourse(course: course, draft: currentDraft)
        })
        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel) { [weak self] _ in
            self?.activePickerAdapters.removeAll()
        })
        alert.addAction(UIAlertAction(title: L10n.tr("common.save"), style: .default) { [weak self] _ in
            guard let self else { return }
            self.activePickerAdapters.removeAll()
            let formDraft = CourseFormDraft(
                thumbnail: alert.textFields?[0].text ?? "",
                title: alert.textFields?[1].text ?? "",
                description: alert.textFields?[2].text ?? "",
                price: alert.textFields?[3].text ?? "0",
                categoryID: selectedCategoryID,
                status: selectedStatus
            )

            guard let errorMessage = self.validateCourseForm(formDraft, editingCourse: course) else {
                let payload: [String: String] = [
                    "thumbnail": formDraft.thumbnail,
                    "title": formDraft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    "description": formDraft.description.trimmingCharacters(in: .whitespacesAndNewlines),
                    "price": formDraft.price.trimmingCharacters(in: .whitespacesAndNewlines),
                    "category_id": formDraft.categoryID,
                    "status": formDraft.status
                ]

                Task { @MainActor in
                    do {
                        if let course {
                            _ = try await CourseService.shared.update(id: course.id, data: payload)
                        } else {
                            _ = try await CourseService.shared.create(data: payload)
                        }
                        await self.loadCourses()
                    } catch {
                        self.showError(message: error.localizedDescription) { [weak self] in
                            self?.presentCourseForm(course: course, draft: formDraft)
                        }
                    }
                }
                return
            }

            self.showError(message: errorMessage) { [weak self] in
                self?.presentCourseForm(course: course, draft: formDraft)
            }
        })
        present(alert, animated: true)
    }

    private func makeCourseDraft(
        from alert: UIAlertController,
        selectedCategoryID: String,
        selectedStatus: String
    ) -> CourseFormDraft {
        CourseFormDraft(
            thumbnail: alert.textFields?[0].text ?? "",
            title: alert.textFields?[1].text ?? "",
            description: alert.textFields?[2].text ?? "",
            price: alert.textFields?[3].text ?? "0",
            categoryID: selectedCategoryID,
            status: selectedStatus
        )
    }

    private func pickThumbnailForCourse(course: Course?, draft: CourseFormDraft) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.photoLibraryPicker.present(
                from: self,
                onPicked: { [weak self] storedValue in
                    guard let self else { return }
                    var nextDraft = draft
                    if let storedValue {
                        nextDraft.thumbnail = storedValue
                    }
                    self.presentCourseForm(course: course, draft: nextDraft)
                },
                onError: { [weak self] message in
                    self?.showError(message: message) { [weak self] in
                        self?.presentCourseForm(course: course, draft: draft)
                    }
                }
            )
        }
    }

    private func validateCourseForm(_ draft: CourseFormDraft, editingCourse: Course?) -> String? {
        guard !categories.isEmpty else {
            return L10n.tr("admin.courses.validation.noCategories")
        }
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return L10n.tr("admin.courses.validation.title")
        }
        guard !draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return L10n.tr("admin.courses.validation.description")
        }
        guard categories.contains(where: { $0.id == draft.categoryID }) else {
            return L10n.tr("admin.courses.validation.category")
        }
        let trimmedPrice = draft.price.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Double(trimmedPrice) != nil else {
            return L10n.tr("admin.courses.validation.price")
        }
        if draft.status == "published" && (editingCourse?.total_lessons ?? 0) == 0 {
            return L10n.tr("admin.courses.validation.publishNeedsLessons")
        }
        return nil
    }

    private func courseStatusDisplayName(for status: String) -> String {
        L10n.statusName(for: status)
    }

    private func openLessons(for course: Course) {
        let controller: AdminLessonsViewController = RootRouter.shared.instantiate(identifier: "AdminLessonsViewController")
        controller.course = course
        navigationController?.pushViewController(controller, animated: true)
    }

    private func previewCourse(_ course: Course) {
        let controller: LessonListViewController = RootRouter.shared.instantiate(identifier: "LessonListViewController")
        controller.course = course
        controller.allowsAdminPreview = true
        navigationController?.pushViewController(controller, animated: true)
    }

    private func deleteCourse(_ course: Course) {
        showConfirm(
            title: L10n.tr("admin.courses.delete.title"),
            message: L10n.tr("admin.courses.delete.message", course.title),
            confirmTitle: L10n.tr("admin.courses.delete.confirm")
        ) { [weak self] in
            Task { @MainActor in
                do {
                    try await CourseService.shared.delete(id: course.id)
                    if let self {
                        await self.loadCourses()
                    }
                } catch {
                    self?.showError(message: error.localizedDescription)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        metrics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AdminSummaryCardCollectionViewCell.reuseIdentifier, for: indexPath) as? AdminSummaryCardCollectionViewCell else {
            return UICollectionViewCell()
        }
        let metric = metrics[indexPath.item]
        cell.configure(symbol: metric.symbol, title: metric.title, value: metric.value)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 14) / 2)
        return CGSize(width: width, height: 132)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(filteredCourses.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard filteredCourses.indices.contains(indexPath.row) else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.text = L10n.tr("admin.courses.empty.title")
            cell.detailTextLabel?.text = L10n.tr("admin.courses.empty.subtitle")
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AdminListTableViewCell.reuseIdentifier, for: indexPath) as? AdminListTableViewCell else {
            return UITableViewCell()
        }
        let course = filteredCourses[indexPath.row]
        let subtitle = L10n.tr(
            "admin.courses.subtitle",
            course.category_name ?? L10n.tr("admin.courses.fallbackCategory"),
            course.instructor_name ?? L10n.tr("admin.courses.fallbackInstructor"),
            course.formattedPrice
        )
        cell.configure(
            title: course.displayTitle,
            subtitle: subtitle,
            status: course.status ?? "draft",
            primaryTitle: L10n.tr("admin.courses.action.lessons"),
            secondaryTitle: L10n.tr("admin.courses.action.edit"),
            tertiaryTitle: L10n.tr("admin.courses.action.preview"),
            statusStyleKey: course.status ?? "draft",
            tertiaryStyleKey: "preview"
        )
        cell.onPrimaryTapped = { [weak self] in self?.openLessons(for: course) }
        cell.onSecondaryTapped = { [weak self] in self?.presentCourseForm(course: course) }
        cell.onTertiaryTapped = { [weak self] in self?.previewCourse(course) }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard filteredCourses.indices.contains(indexPath.row) else { return nil }
        let course = filteredCourses[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: L10n.tr("admin.courses.action.delete")) { [weak self] _, _, completion in
            self?.deleteCourse(course)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
