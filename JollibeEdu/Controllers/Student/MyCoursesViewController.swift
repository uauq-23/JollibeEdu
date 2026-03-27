import UIKit

final class MyCoursesViewController: AuthenticatedStackViewController, UITableViewDataSource, UITableViewDelegate {
    override var clearsInitialStoryboardContent: Bool { false }

    private var allCourses: [Course] = []
    private var inProgressCourses: [Course] = []
    private var completedCourses: [Course] = []

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var searchField: UITextField!
    @IBOutlet private weak var inProgressCardView: UIView!
    @IBOutlet private weak var inProgressContainerView: UIView!
    @IBOutlet private weak var inProgressHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var completedCardView: UIView!
    @IBOutlet private weak var completedContainerView: UIView!
    @IBOutlet private weak var completedHeightConstraint: NSLayoutConstraint!

    private lazy var inProgressTableView = makeTableView()
    private lazy var completedTableView = makeTableView()

    override func buildContent() {
        title = "Khóa học của tôi"
        navigationItem.largeTitleDisplayMode = .never

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        inProgressCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        completedCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        searchField.applyAppStyle(placeholder: "Tìm khóa học đã ghi danh...")
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        embed(inProgressTableView, in: inProgressContainerView)
        embed(completedTableView, in: completedContainerView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isViewLoaded else { return }
        Task {
            await loadCourses()
        }
    }

    private func makeTableView() -> IntrinsicTableView {
        let tableView = IntrinsicTableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.register(MyCourseTableViewCell.self, forCellReuseIdentifier: MyCourseTableViewCell.reuseIdentifier)
        return tableView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeights()
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

    private func updateTableHeights() {
        inProgressTableView.layoutIfNeeded()
        completedTableView.layoutIfNeeded()
        inProgressHeightConstraint.constant = max(160, inProgressTableView.contentSize.height)
        completedHeightConstraint.constant = max(160, completedTableView.contentSize.height)
    }

    private func loadCourses() async {
        do {
            allCourses = try await EnrollmentService.shared.getMyEnrolledCourses(page: 1, limit: 100)
            applyFilters()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    @objc private func searchChanged() {
        applyFilters()
    }

    private func applyFilters() {
        let query = (searchField.text ?? "").lowercased()
        let filtered = allCourses.filter { query.isEmpty || $0.title.lowercased().contains(query) }
        inProgressCourses = filtered.filter { !$0.isCompletedCourse }
        completedCourses = filtered.filter { $0.isCompletedCourse }
        inProgressTableView.reloadData()
        completedTableView.reloadData()
        updateTableHeights()
    }

    private func courseFor(indexPath: IndexPath, in tableView: UITableView) -> Course? {
        if tableView === inProgressTableView {
            return inProgressCourses.indices.contains(indexPath.row) ? inProgressCourses[indexPath.row] : nil
        }
        return completedCourses.indices.contains(indexPath.row) ? completedCourses[indexPath.row] : nil
    }

    private func openCourse(_ course: Course, completed: Bool) {
        if completed {
            let controller: LearningProgressViewController = RootRouter.shared.instantiate(identifier: "LearningProgressViewController")
            controller.highlightCourseID = course.id
            navigationController?.pushViewController(controller, animated: true)
        } else {
            let controller: LessonListViewController = RootRouter.shared.instantiate(identifier: "LessonListViewController")
            controller.course = course
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = tableView === inProgressTableView ? inProgressCourses.count : completedCourses.count
        return max(count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let course = courseFor(indexPath: indexPath, in: tableView) else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.text = tableView === inProgressTableView ? "Chưa có khóa đang học." : "Chưa có khóa hoàn thành."
            cell.detailTextLabel?.text = "Các khóa phù hợp sẽ xuất hiện tại đây."
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: MyCourseTableViewCell.reuseIdentifier, for: indexPath) as? MyCourseTableViewCell else {
            return UITableViewCell()
        }
        let isCompleted = tableView === completedTableView
        cell.configure(with: course, actionTitle: isCompleted ? "View Progress" : "Resume")
        cell.onActionTapped = { [weak self] in
            self?.openCourse(course, completed: isCompleted)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let course = courseFor(indexPath: indexPath, in: tableView) else { return }
        openCourse(course, completed: tableView === completedTableView)
    }
}
