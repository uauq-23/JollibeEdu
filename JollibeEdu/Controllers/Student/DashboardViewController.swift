import UIKit

final class DashboardViewController: AuthenticatedStackViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    override var clearsInitialStoryboardContent: Bool { false }

    private var stats: [DashboardMetric] = []
    private var continueCourses: [Course] = []
    @IBOutlet private weak var greetingCardView: UIView!
    @IBOutlet private weak var greetingLabel: UILabel!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var statsCardView: UIView!
    @IBOutlet private weak var statsContainerView: UIView!
    @IBOutlet private weak var statsContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var continueCardView: UIView!
    @IBOutlet private weak var continueContainerView: UIView!
    @IBOutlet private weak var continueContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var achievementCardView: UIView!
    @IBOutlet private weak var quickActionsCardView: UIView!
    @IBOutlet private weak var browseButton: UIButton!
    @IBOutlet private weak var progressButton: UIButton!
    @IBOutlet private weak var profileButton: UIButton!

    private lazy var statsCollectionView: IntrinsicCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 14
        let view = IntrinsicCollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.dataSource = self
        view.delegate = self
        view.register(StatsCardCollectionViewCell.self, forCellWithReuseIdentifier: StatsCardCollectionViewCell.reuseIdentifier)
        return view
    }()

    private lazy var continueTableView: IntrinsicTableView = {
        let view = IntrinsicTableView(frame: .zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.separatorStyle = .none
        view.isScrollEnabled = false
        view.dataSource = self
        view.delegate = self
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 140
        view.register(ContinueLearningTableViewCell.self, forCellReuseIdentifier: ContinueLearningTableViewCell.reuseIdentifier)
        return view
    }()

    override func buildContent() {
        title = "Dashboard"
        navigationItem.largeTitleDisplayMode = .never

        greetingCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        statsCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        continueCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        achievementCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        quickActionsCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        embed(statsCollectionView, in: statsContainerView)
        embed(continueTableView, in: continueContainerView)

        greetingLabel.font = UIFont.boldSystemFont(ofSize: 30)
        greetingLabel.textColor = AppTheme.textPrimary
        greetingLabel.numberOfLines = 0

        summaryLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        summaryLabel.textColor = AppTheme.textSecondary
        summaryLabel.numberOfLines = 0
        summaryLabel.isHidden = true

        browseButton.applyPrimaryStyle()
        browseButton.setTitle("Khám phá khóa học", for: .normal)
        browseButton.addAction(UIAction { [weak self] _ in
            self?.performSegue(withIdentifier: "DashboardShowCourseList", sender: self)
        }, for: .touchUpInside)

        progressButton.applySecondaryOutlineStyle()
        progressButton.setTitle("Xem tiến độ", for: .normal)
        progressButton.addAction(UIAction { [weak self] _ in
            self?.performSegue(withIdentifier: "DashboardShowProgress", sender: self)
        }, for: .touchUpInside)

        profileButton.applySecondaryOutlineStyle()
        profileButton.setTitle("Hồ sơ", for: .normal)
        profileButton.addAction(UIAction { [weak self] _ in
            self?.performSegue(withIdentifier: "DashboardShowProfile", sender: self)
        }, for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateEmbeddedHeights()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isViewLoaded else { return }
        Task {
            await loadDashboard()
        }
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

    private func updateEmbeddedHeights() {
        statsCollectionView.layoutIfNeeded()
        continueTableView.layoutIfNeeded()
        statsContainerHeightConstraint.constant = max(320, statsCollectionView.collectionViewLayout.collectionViewContentSize.height)
        continueContainerHeightConstraint.constant = max(160, continueTableView.contentSize.height)
    }

    private func loadDashboard() async {
        do {
            let enrolledCourses = try await EnrollmentService.shared.getMyEnrolledCourses(page: 1, limit: 50)
            let user = SessionManager.shared.currentUser
            continueCourses = enrolledCourses
                .filter { !$0.isCompletedCourse }
                .sorted { $0.progressPercentValue > $1.progressPercentValue }
            let completed = enrolledCourses.filter { $0.isCompletedCourse }
            let totalLessons = enrolledCourses.reduce(0) { $0 + ($1.total_lessons ?? 0) }
            let average = enrolledCourses.isEmpty ? 0 : Int(enrolledCourses.reduce(0) { $0 + $1.progressPercentValue } / Double(enrolledCourses.count))
            stats = [
                DashboardMetric(symbol: "play.fill", title: "In Progress", value: "\(continueCourses.count)", subtitle: "Khóa học đang học"),
                DashboardMetric(symbol: "checkmark.seal.fill", title: "Completed", value: "\(completed.count)", subtitle: "Khóa học đã hoàn thành"),
                DashboardMetric(symbol: "list.bullet.rectangle.portrait.fill", title: "Lessons", value: "\(totalLessons)", subtitle: "Tổng lesson khả dụng"),
                DashboardMetric(symbol: "chart.bar.fill", title: "Average", value: "\(average)%", subtitle: "Average progress")
            ]

            greetingLabel.text = "Xin chào, \(user?.full_name ?? "Learner")"
            summaryLabel.text = nil
            summaryLabel.isHidden = true
            statsCollectionView.reloadData()
            continueTableView.reloadData()
            updateEmbeddedHeights()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func openLessonList(for course: Course) {
        let controller: LessonListViewController = RootRouter.shared.instantiate(identifier: "LessonListViewController")
        controller.course = course
        navigationController?.pushViewController(controller, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stats.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatsCardCollectionViewCell.reuseIdentifier, for: indexPath) as? StatsCardCollectionViewCell else {
            return UICollectionViewCell()
        }
        let metric = stats[indexPath.item]
        cell.configure(symbol: metric.symbol, title: metric.title, value: metric.value, subtitle: metric.subtitle)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 14) / 2)
        return CGSize(width: width, height: 152)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(continueCourses.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if continueCourses.isEmpty {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.text = "Bạn chưa có khóa học đang học."
            cell.detailTextLabel?.text = "Hãy khám phá một khóa mới để bắt đầu."
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContinueLearningTableViewCell.reuseIdentifier, for: indexPath) as? ContinueLearningTableViewCell else {
            return UITableViewCell()
        }
        let course = continueCourses[indexPath.row]
        cell.configure(with: course)
        cell.onActionTapped = { [weak self] in
            self?.openLessonList(for: course)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard continueCourses.indices.contains(indexPath.row) else { return }
        openLessonList(for: continueCourses[indexPath.row])
    }
}

struct DashboardMetric {
    let symbol: String
    let title: String
    let value: String
    let subtitle: String
}
