import UIKit

final class LearningProgressViewController: AuthenticatedStackViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    override var clearsInitialStoryboardContent: Bool { false }

    var highlightCourseID: String?

    private var courses: [Course] = []
    private var metrics: [DashboardMetric] = []

    @IBOutlet private weak var introCardView: UIView!
    @IBOutlet private weak var metricsCardView: UIView!
    @IBOutlet private weak var metricsContainerView: UIView!
    @IBOutlet private weak var metricsContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var courseProgressCardView: UIView!
    @IBOutlet private weak var courseProgressContainerView: UIView!
    @IBOutlet private weak var courseProgressHeightConstraint: NSLayoutConstraint!

    private let courseProgressStack = UIStackView()

    private lazy var metricsCollectionView: IntrinsicCollectionView = {
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

    override func buildContent() {
        title = "Tiến độ học tập"
        navigationItem.largeTitleDisplayMode = .never

        introCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        metricsCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        courseProgressCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        courseProgressStack.translatesAutoresizingMaskIntoConstraints = false
        courseProgressStack.axis = .vertical
        courseProgressStack.spacing = 12

        embed(metricsCollectionView, in: metricsContainerView)
        embed(courseProgressStack, in: courseProgressContainerView)

        Task {
            await loadProgress()
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
        metricsCollectionView.layoutIfNeeded()
        courseProgressStack.layoutIfNeeded()
        metricsContainerHeightConstraint.constant = max(320, metricsCollectionView.collectionViewLayout.collectionViewContentSize.height)
        courseProgressHeightConstraint.constant = max(180, courseProgressStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
    }

    private func loadProgress() async {
        do {
            courses = try await ProgressService.shared.getMyProgress()
            if let highlightCourseID, let index = courses.firstIndex(where: { $0.id == highlightCourseID }) {
                let highlighted = courses.remove(at: index)
                courses.insert(highlighted, at: 0)
            }

            let completedCourses = courses.filter { ($0.progress ?? 0) >= 100 }
            let completedLessons = courses.reduce(0) { $0 + ($1.completed_lessons ?? 0) }
            let totalLessons = courses.reduce(0) { $0 + ($1.total_lessons ?? 0) }
            let average = courses.isEmpty ? 0 : Int(courses.reduce(0) { $0 + ($1.progress ?? 0) } / Double(courses.count))
            let totalHours = courses.reduce(0.0) { result, course in
                result + (Double(course.total_lessons ?? 0) * 0.5)
            }

            metrics = [
                DashboardMetric(symbol: "clock.fill", title: "Learning Hours", value: String(format: "%.1f h", totalHours), subtitle: "Ước tính từ lesson"),
                DashboardMetric(symbol: "checkmark.seal.fill", title: "Completed Courses", value: "\(completedCourses.count)", subtitle: "Đã hoàn thành"),
                DashboardMetric(symbol: "chart.bar.fill", title: "Average Progress", value: "\(average)%", subtitle: "Toàn bộ khóa học"),
                DashboardMetric(symbol: "list.bullet.rectangle", title: "Completed Lessons", value: "\(completedLessons)/\(max(totalLessons, 1))", subtitle: "Tiến độ hiện tại")
            ]
            metricsCollectionView.reloadData()

            courseProgressStack.arrangedSubviews.forEach { view in
                courseProgressStack.removeArrangedSubview(view)
                view.removeFromSuperview()
            }

            if courses.isEmpty {
                let empty = EmptyStateView()
                empty.configure(icon: "book.closed", title: "Chưa có progress", subtitle: "Hãy ghi danh một khóa học để bắt đầu theo dõi tiến độ.")
                courseProgressStack.addArrangedSubview(empty)
            } else {
                for course in courses {
                    courseProgressStack.addArrangedSubview(makeProgressRow(for: course))
                }
            }
            updateEmbeddedHeights()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func makeProgressRow(for course: Course) -> UIView {
        let (card, stack) = UIFactory.makeCard(padding: 16, spacing: 8)
        if course.id == highlightCourseID {
            card.layer.borderColor = AppTheme.brandOrange.cgColor
            card.layer.borderWidth = 2
        }
        let title = UIFactory.makeSectionLabel(course.displayTitle)
        title.font = UIFont.boldSystemFont(ofSize: 18)
        let subtitle = UIFactory.makeSubtitleLabel("\(course.completed_lessons ?? 0)/\(course.total_lessons ?? 0) lessons hoàn thành • \(AppFormatting.percent(course.progressPercentValue))")
        let bar = UIProgressView(progressViewStyle: .default)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.progressTintColor = AppTheme.brandOrange
        bar.trackTintColor = AppTheme.softBorder
        bar.progress = Float(course.progressPercentValue / 100)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        stack.addArrangedSubview(bar)
        return card
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        metrics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatsCardCollectionViewCell.reuseIdentifier, for: indexPath) as? StatsCardCollectionViewCell else {
            return UICollectionViewCell()
        }
        let metric = metrics[indexPath.item]
        cell.configure(symbol: metric.symbol, title: metric.title, value: metric.value, subtitle: metric.subtitle)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 14) / 2)
        return CGSize(width: width, height: 152)
    }
}
