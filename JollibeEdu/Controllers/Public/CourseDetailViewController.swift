import UIKit

final class CourseDetailViewController: BaseStackContainerViewController, UITableViewDataSource, UITableViewDelegate {
    override var clearsInitialStoryboardContent: Bool { false }

    var courseID: String?
    var course: Course?

    private var isEnrolled = false
    @IBOutlet private weak var overviewCardView: UIView!
    @IBOutlet private weak var heroImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var metaLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var learnCardView: UIView!
    @IBOutlet private weak var learningContainerView: UIView!
    @IBOutlet private weak var learningContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var instructorCardView: UIView!
    @IBOutlet private weak var instructorInfoLabel: UILabel!
    @IBOutlet private weak var reviewCardView: UIView!
    @IBOutlet private weak var reviewContainerView: UIView!
    @IBOutlet private weak var reviewContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var ctaCardView: UIView!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var primaryButton: UIButton!
    private let learningStack = UIStackView()
    private let reviewTableView = IntrinsicTableView(frame: .zero, style: .plain)

    private var reviews: [(String, Int, String)] {
        [
            ("Minh Anh", 5, L10n.tr("course.detail.review.1")),
            ("Bao Ngan", 5, L10n.tr("course.detail.review.2")),
            ("Quoc Huy", 4, L10n.tr("course.detail.review.3"))
        ]
    }

    override func buildContent() {
        title = L10n.tr("course.detail.title")
        navigationItem.largeTitleDisplayMode = .never

        overviewCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        learnCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        instructorCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        reviewCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        ctaCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.layer.cornerRadius = 22
        heroImageView.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.25)
        learningContainerView.backgroundColor = .clear
        reviewContainerView.backgroundColor = .clear

        learningStack.translatesAutoresizingMaskIntoConstraints = false
        learningStack.axis = .vertical
        learningStack.spacing = 10
        learningStack.backgroundColor = .clear
        embed(learningStack, in: learningContainerView, inset: 0)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 0

        metaLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        metaLabel.textColor = AppTheme.textSecondary
        metaLabel.numberOfLines = 0

        descriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        descriptionLabel.textColor = AppTheme.textSecondary
        descriptionLabel.numberOfLines = 0

        instructorInfoLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        instructorInfoLabel.textColor = AppTheme.textPrimary
        instructorInfoLabel.numberOfLines = 0

        priceLabel.font = UIFont.boldSystemFont(ofSize: 28)
        priceLabel.textColor = AppTheme.brandOrangeDark
        priceLabel.numberOfLines = 1
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.82
        priceLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        priceLabel.setContentHuggingPriority(.required, for: .vertical)

        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textColor = AppTheme.textSecondary
        statusLabel.numberOfLines = 0

        primaryButton.applyPrimaryStyle()
        primaryButton.setTitle(L10n.tr("course.detail.loading"), for: .normal)
        primaryButton.addAction(UIAction { [weak self] _ in
            self?.handlePrimaryAction()
        }, for: .touchUpInside)

        reviewTableView.translatesAutoresizingMaskIntoConstraints = false
        reviewTableView.backgroundColor = .clear
        reviewTableView.separatorStyle = .none
        reviewTableView.isScrollEnabled = false
        reviewTableView.rowHeight = UITableView.automaticDimension
        reviewTableView.estimatedRowHeight = 120
        reviewTableView.dataSource = self
        reviewTableView.delegate = self
        reviewTableView.register(ReviewTableViewCell.self, forCellReuseIdentifier: ReviewTableViewCell.reuseIdentifier)
        embed(reviewTableView, in: reviewContainerView, inset: 0)

        Task {
            await loadCourseDetail()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateEmbeddedHeights()
    }

    private func embed(_ view: UIView, in container: UIView, inset: CGFloat) {
        guard view.superview !== container else { return }
        view.removeFromSuperview()
        container.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset)
        ])
    }

    private func updateEmbeddedHeights() {
        learningStack.layoutIfNeeded()
        reviewTableView.layoutIfNeeded()
        learningContainerHeightConstraint.constant = max(160, learningStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
        reviewContainerHeightConstraint.constant = max(330, reviewTableView.contentSize.height)
    }

    private func loadCourseDetail() async {
        do {
            let resolvedCourse: Course
            if let course {
                resolvedCourse = course
            } else if let courseID {
                resolvedCourse = try await CourseService.shared.getById(id: courseID)
            } else {
                throw DemoDataStoreError.notFound
            }

            course = resolvedCourse
            populateContent(with: resolvedCourse)
            if SessionManager.shared.isLoggedIn {
                isEnrolled = (try? await EnrollmentService.shared.checkEnrollment(courseId: resolvedCourse.id)) ?? false
            } else {
                isEnrolled = false
            }
            updateCTA()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func populateContent(with course: Course) {
        ImageLoader.shared.loadImage(from: course.thumbnail, into: heroImageView, placeholder: UIImage(systemName: "play.square.stack.fill"))
        titleLabel.text = course.displayTitle
        metaLabel.text = L10n.tr(
            "course.detail.metaWithPrice",
            course.rating ?? 0,
            course.review_count ?? 0,
            course.student_count ?? 0,
            course.duration ?? "--",
            course.formattedPrice
        )
        descriptionLabel.text = course.description
        instructorInfoLabel.text = L10n.tr(
            "course.detail.instructorInfo",
            course.instructor_name ?? L10n.tr("course.detail.fallbackInstructorName"),
            course.instructor_email ?? L10n.tr("course.detail.fallbackInstructorEmail"),
            course.category_name ?? L10n.tr("course.detail.fallbackCategory")
        )
        priceLabel.text = course.formattedPrice

        learningStack.arrangedSubviews.forEach { view in
            learningStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        suggestedLearningPoints(for: course).forEach { point in
            let row = UIFactory.makeHorizontalStack(spacing: 10)
            let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.tintColor = AppTheme.successGreen
            icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 18).isActive = true
            let label = UIFactory.makeSubtitleLabel(point)
            label.textColor = AppTheme.textPrimary
            row.addArrangedSubview(icon)
            row.addArrangedSubview(label)
            learningStack.addArrangedSubview(row)
        }
        reviewTableView.reloadData()
        updateEmbeddedHeights()
    }

    private func updateCTA() {
        guard let course else { return }
        if SessionManager.shared.isAdmin {
            primaryButton.setTitle(L10n.tr("course.detail.cta.admin"), for: .normal)
            statusLabel.text = L10n.tr("course.detail.cta.admin.status")
        } else if isEnrolled {
            primaryButton.setTitle(L10n.tr("course.detail.cta.enrolled"), for: .normal)
            statusLabel.text = L10n.tr("course.detail.cta.enrolled.status")
        } else if (course.price ?? 0) <= 0 {
            primaryButton.setTitle(L10n.tr("course.detail.cta.free"), for: .normal)
            statusLabel.text = L10n.tr("course.detail.cta.free.status")
        } else {
            primaryButton.setTitle(L10n.tr("course.detail.cta.paid"), for: .normal)
            statusLabel.text = L10n.tr("course.detail.cta.paid.status")
        }
    }

    private func handlePrimaryAction() {
        guard let course else { return }
        if SessionManager.shared.isAdmin {
            openLessonList(for: course, adminPreview: true)
            return
        }

        if !SessionManager.shared.isLoggedIn {
            let controller: LoginViewController = RootRouter.shared.instantiate(identifier: "LoginViewController")
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        if isEnrolled {
            openLessonList(for: course)
            return
        }

        if (course.price ?? 0) <= 0 {
            Task { @MainActor in
                do {
                    _ = try await EnrollmentService.shared.enroll(courseId: course.id)
                    isEnrolled = true
                    updateCTA()
                    openLessonList(for: course)
                } catch {
                    showError(message: error.localizedDescription)
                }
            }
        } else {
            let controller: PaymentViewController = RootRouter.shared.instantiate(identifier: "PaymentViewController")
            controller.course = course
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func openLessonList(for course: Course, adminPreview: Bool = false) {
        let controller: LessonListViewController = RootRouter.shared.instantiate(identifier: "LessonListViewController")
        controller.course = course
        controller.allowsAdminPreview = adminPreview
        navigationController?.pushViewController(controller, animated: true)
    }

    private func suggestedLearningPoints(for _: Course) -> [String] {
        [
            L10n.tr("course.detail.learn.1"),
            L10n.tr("course.detail.learn.2"),
            L10n.tr("course.detail.learn.3"),
            L10n.tr("course.detail.learn.4")
        ]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reviews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReviewTableViewCell.reuseIdentifier, for: indexPath) as? ReviewTableViewCell else {
            return UITableViewCell()
        }
        let review = reviews[indexPath.row]
        cell.configure(name: review.0, rating: review.1, review: review.2)
        return cell
    }
}
