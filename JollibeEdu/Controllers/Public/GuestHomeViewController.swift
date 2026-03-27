import UIKit

final class GuestHomeViewController: BaseStackContainerViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var heroCardView: UIView!
    @IBOutlet private weak var browseButton: UIButton!
    @IBOutlet private weak var secondaryButton: UIButton!
    @IBOutlet private weak var featureContainerView: UIView!
    @IBOutlet private weak var popularStateContainerView: UIView!
    @IBOutlet private weak var popularCollectionContainerView: UIView!

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("books.vertical.fill", "Nhiều khóa học", "Khám phá lộ trình học đa dạng từ lập trình, thiết kế đến ngoại ngữ."),
        ("person.2.fill", "Giảng viên chuyên môn", "Học cùng đội ngũ đã triển khai sản phẩm và chương trình học thực tế."),
        ("rosette", "Chứng chỉ hoàn thành", "Nhận certificate khi hoàn thành khóa học và đủ điều kiện đánh giá."),
        ("chart.line.uptrend.xyaxis", "Theo dõi tiến độ", "Theo sát lesson, completion rate và nhịp học hàng tuần.")
    ]

    private var popularCourses: [Course] = []
    private let popularLoadingView = LoadingStateView()
    private let popularErrorView = EmptyStateView()

    private lazy var featureCollectionView: IntrinsicCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 14
        let view = IntrinsicCollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.dataSource = self
        view.delegate = self
        view.register(FeatureCardCollectionViewCell.self, forCellWithReuseIdentifier: FeatureCardCollectionViewCell.reuseIdentifier)
        return view
    }()

    private lazy var popularCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(CourseCardCollectionViewCell.self, forCellWithReuseIdentifier: CourseCardCollectionViewCell.reuseIdentifier)
        return view
    }()

    override func buildContent() {
        title = "JolibeeEdu"
        navigationItem.largeTitleDisplayMode = .always

        heroCardView.applyCardStyle(backgroundColor: AppTheme.brandOrange)
        featureContainerView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        popularStateContainerView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        popularCollectionContainerView.applyCardStyle(backgroundColor: AppTheme.warmBackground)

        browseButton.applyPrimaryStyle()
        browseButton.configuration?.baseBackgroundColor = .white
        browseButton.configuration?.baseForegroundColor = AppTheme.brandOrangeDark
        browseButton.addAction(UIAction { [weak self] _ in
            self?.openCourseList()
        }, for: .touchUpInside)

        secondaryButton.applySecondaryOutlineStyle()
        secondaryButton.configuration?.baseForegroundColor = .white
        secondaryButton.configuration?.background.strokeColor = UIColor.white.withAlphaComponent(0.7)
        secondaryButton.configuration?.background.backgroundColor = UIColor.clear
        secondaryButton.setTitle(SessionManager.shared.isLoggedIn ? "Mở Dashboard" : "Đăng ký ngay", for: .normal)
        secondaryButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if SessionManager.shared.isLoggedIn, let user = SessionManager.shared.currentUser {
                RootRouter.shared.routeAfterAuthentication(with: user)
            } else {
                self.performSegue(withIdentifier: "GuestHomeShowRegister", sender: self)
            }
        }, for: .touchUpInside)

        embedCollectionView(featureCollectionView, in: featureContainerView)
        embedCollectionView(popularCollectionView, in: popularCollectionContainerView)
        installPopularStateView(popularLoadingView)
        popularCollectionView.isHidden = true

        Task {
            await loadPopularCourses()
        }
    }

    private func embedCollectionView(_ collectionView: UIView, in container: UIView, inset: CGFloat = 12) {
        guard collectionView.superview !== container else { return }
        collectionView.removeFromSuperview()
        container.subviews.forEach { $0.removeFromSuperview() }
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            collectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            collectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            collectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset)
        ])
    }

    private func installPopularStateView(_ stateView: UIView) {
        popularStateContainerView.subviews.forEach { $0.removeFromSuperview() }
        stateView.translatesAutoresizingMaskIntoConstraints = false
        popularStateContainerView.addSubview(stateView)
        NSLayoutConstraint.activate([
            stateView.topAnchor.constraint(equalTo: popularStateContainerView.topAnchor, constant: 12),
            stateView.leadingAnchor.constraint(equalTo: popularStateContainerView.leadingAnchor, constant: 12),
            stateView.trailingAnchor.constraint(equalTo: popularStateContainerView.trailingAnchor, constant: -12),
            stateView.bottomAnchor.constraint(equalTo: popularStateContainerView.bottomAnchor, constant: -12)
        ])
    }

    private func loadPopularCourses() async {
        do {
            popularCourses = try await CourseService.shared.getPopular().filter { ($0.status ?? "published") != "draft" || SessionManager.shared.isAdmin }
            popularStateContainerView.isHidden = true
            popularCollectionView.isHidden = false
            popularCollectionView.reloadData()
        } catch {
            popularCollectionView.isHidden = true
            popularStateContainerView.isHidden = false
            popularErrorView.configure(icon: "wifi.exclamationmark", title: "Chưa tải được khóa học", subtitle: error.localizedDescription, actionTitle: "Thử lại")
            popularErrorView.onActionTapped = { [weak self] in
                guard let self else { return }
                self.installPopularStateView(self.popularLoadingView)
                Task { await self.loadPopularCourses() }
            }
            installPopularStateView(popularErrorView)
        }
    }

    private func openCourseList() {
        performSegue(withIdentifier: "GuestHomeShowCourseList", sender: self)
    }

    private func openCourse(_ course: Course) {
        let controller: CourseDetailViewController = RootRouter.shared.instantiate(identifier: "CourseDetailViewController")
        controller.course = course
        navigationController?.pushViewController(controller, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView === featureCollectionView ? features.count : popularCourses.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === featureCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureCardCollectionViewCell.reuseIdentifier, for: indexPath) as? FeatureCardCollectionViewCell else {
                return UICollectionViewCell()
            }
            let item = features[indexPath.item]
            cell.configure(icon: item.icon, title: item.title, subtitle: item.subtitle)
            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseCardCollectionViewCell.reuseIdentifier, for: indexPath) as? CourseCardCollectionViewCell else {
            return UICollectionViewCell()
        }
        let course = popularCourses[indexPath.item]
        cell.configure(with: course, actionTitle: "View Details")
        cell.onActionTapped = { [weak self] in
            self?.openCourse(course)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === popularCollectionView else { return }
        openCourse(popularCourses[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === featureCollectionView {
            let availableWidth = collectionView.bounds.width - 14
            let width = floor(availableWidth / 2)
            let height = max(220, floor((collectionView.bounds.height - 14) / 2))
            return CGSize(width: width, height: height)
        }
        let width = min(300, collectionView.bounds.width * 0.82)
        let height = max(300, collectionView.bounds.height - 8)
        return CGSize(width: width, height: height)
    }
}
