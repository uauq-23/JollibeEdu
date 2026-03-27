import UIKit

final class AdminReportsViewController: AdminProtectedViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource {
    override var clearsInitialStoryboardContent: Bool { false }

    private var summary: ReportSummary?
    private var metrics: [AdminSummaryMetric] = []
    private var topCourses: [Course] = []
    private let mockMonthlyRevenueReport = MonthlyReport(
        labels: ["T10", "T11", "T12", "T1", "T2", "T3"],
        values: [18_500_000, 24_000_000, 27_500_000, 31_000_000, 36_500_000, 42_000_000]
    )
    private let mockUserGrowthValues: [Double] = [22, 29, 34, 41, 47, 52, 58]
    private let mockUserGrowthLabels = ["W1", "W2", "W3", "W4", "W5", "W6", "W7"]

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var summaryCardView: UIView!
    @IBOutlet private weak var summaryContainerView: UIView!
    @IBOutlet private weak var summaryHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var revenueCardView: UIView!
    @IBOutlet private weak var revenueContainerView: UIView!
    @IBOutlet private weak var userGrowthCardView: UIView!
    @IBOutlet private weak var userGrowthContainerView: UIView!
    @IBOutlet private weak var categoryCardView: UIView!
    @IBOutlet private weak var categoryContainerView: UIView!
    @IBOutlet private weak var categoryHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topCoursesCardView: UIView!
    @IBOutlet private weak var topCoursesContainerView: UIView!
    @IBOutlet private weak var topCoursesHeightConstraint: NSLayoutConstraint!

    private let revenueChartView = MonthlyLineChartView()
    private let userGrowthChartView = ProgressChartView()
    private let categoryDistributionStack = UIStackView()

    private lazy var summaryCollectionView: IntrinsicCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 14
        let view = IntrinsicCollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.dataSource = self
        view.delegate = self
        view.register(AdminSummaryCardCollectionViewCell.self, forCellWithReuseIdentifier: AdminSummaryCardCollectionViewCell.reuseIdentifier)
        return view
    }()

    private lazy var topCoursesTableView: IntrinsicTableView = {
        let tableView = IntrinsicTableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.dataSource = self
        tableView.register(AdminListTableViewCell.self, forCellReuseIdentifier: AdminListTableViewCell.reuseIdentifier)
        return tableView
    }()

    override func buildContent() {
        title = L10n.tr("admin.reports.title")
        navigationItem.largeTitleDisplayMode = .never

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        summaryCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        revenueCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        userGrowthCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        categoryCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        topCoursesCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        categoryDistributionStack.translatesAutoresizingMaskIntoConstraints = false
        categoryDistributionStack.axis = .vertical
        categoryDistributionStack.spacing = 12

        embed(summaryCollectionView, in: summaryContainerView)
        embed(revenueChartView, in: revenueContainerView)
        embed(userGrowthChartView, in: userGrowthContainerView)
        embed(categoryDistributionStack, in: categoryContainerView)
        embed(topCoursesTableView, in: topCoursesContainerView)

        Task {
            await loadReports()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateEmbeddedHeights()
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
        summaryCollectionView.layoutIfNeeded()
        topCoursesTableView.layoutIfNeeded()
        categoryDistributionStack.layoutIfNeeded()
        summaryHeightConstraint.constant = max(300, summaryCollectionView.collectionViewLayout.collectionViewContentSize.height)
        categoryHeightConstraint.constant = max(180, categoryDistributionStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
        topCoursesHeightConstraint.constant = max(220, topCoursesTableView.contentSize.height)
    }

    private func loadReports() async {
        do {
            async let systemStatsTask = ReportService.shared.getSystemStatistics()
            async let topCoursesTask = ReportService.shared.getTopCourses(limit: 5)

            summary = try await systemStatsTask
            topCourses = try await topCoursesTask
            let monthlyRevenueValue = mockMonthlyRevenueReport.values.last ?? summary?.monthlyRevenue ?? 0

            metrics = [
                AdminSummaryMetric(symbol: "person.3.fill", title: L10n.tr("admin.reports.metric.totalUsers"), value: "\(summary?.totalUsers ?? 0)"),
                AdminSummaryMetric(symbol: "book.closed.fill", title: L10n.tr("admin.reports.metric.totalCourses"), value: "\(summary?.totalCourses ?? 0)"),
                AdminSummaryMetric(symbol: "rectangle.stack.person.crop.fill", title: L10n.tr("admin.reports.metric.totalEnrollments"), value: "\(summary?.totalEnrollments ?? 0)"),
                AdminSummaryMetric(symbol: "banknote.fill", title: L10n.tr("admin.reports.metric.revenue"), value: AppFormatting.vnd(monthlyRevenueValue))
            ]
            summaryCollectionView.reloadData()
            revenueChartView.setData(labels: mockMonthlyRevenueReport.labels, values: mockMonthlyRevenueReport.values)
            userGrowthChartView.setValues(mockUserGrowthValues, labels: mockUserGrowthLabels)

            categoryDistributionStack.arrangedSubviews.forEach { view in
                categoryDistributionStack.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            let grouped = Dictionary(grouping: topCourses, by: { $0.category_name ?? L10n.tr("admin.courses.fallbackCategory") })
            for (category, courses) in grouped.sorted(by: { $0.key < $1.key }) {
                categoryDistributionStack.addArrangedSubview(makeCategoryRow(name: category, value: courses.count))
            }

            topCoursesTableView.reloadData()
            updateEmbeddedHeights()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func makeCategoryRow(name: String, value: Int) -> UIView {
        let (card, stack) = UIFactory.makeCard(padding: 16, spacing: 8)
        card.backgroundColor = AppTheme.cardBackground
        let title = UIFactory.makeSectionLabel(name)
        title.font = UIFont.boldSystemFont(ofSize: 18)
        let subtitle = UIFactory.makeSubtitleLabel(L10n.tr("admin.reports.category.subtitle", value))
        let bar = UIProgressView(progressViewStyle: .default)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.progressTintColor = AppTheme.brandOrange
        bar.trackTintColor = AppTheme.softBorder
        bar.progress = min(Float(value) / 5, 1)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        stack.addArrangedSubview(bar)
        return card
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
        topCourses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AdminListTableViewCell.reuseIdentifier, for: indexPath) as? AdminListTableViewCell else {
            return UITableViewCell()
        }
        let course = topCourses[indexPath.row]
        let subtitle = L10n.tr(
            "admin.reports.topCourse.subtitle",
            course.category_name ?? L10n.tr("course.detail.fallbackCategory"),
            course.student_count ?? 0,
            course.rating ?? 0
        )
        cell.configure(
            title: course.displayTitle,
            subtitle: subtitle,
            status: course.status ?? "published",
            primaryTitle: L10n.tr("admin.reports.action.open"),
            secondaryTitle: L10n.tr("admin.reports.action.lessons")
        )
        cell.onPrimaryTapped = { [weak self] in
            let controller: CourseDetailViewController = RootRouter.shared.instantiate(identifier: "CourseDetailViewController")
            controller.course = course
            self?.navigationController?.pushViewController(controller, animated: true)
        }
        cell.onSecondaryTapped = { [weak self] in
            let controller: AdminLessonsViewController = RootRouter.shared.instantiate(identifier: "AdminLessonsViewController")
            controller.course = course
            self?.navigationController?.pushViewController(controller, animated: true)
        }
        return cell
    }
}
