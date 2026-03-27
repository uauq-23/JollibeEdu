import UIKit

final class CourseListViewController: BaseStackContainerViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var searchField: UITextField!
    @IBOutlet private weak var categoryContainerView: UIView!
    @IBOutlet private weak var courseContainerView: UIView!
    @IBOutlet private weak var emptyStateContainerView: UIView!
    @IBOutlet private weak var loadMoreButton: UIButton!
    @IBOutlet private weak var courseContainerHeightConstraint: NSLayoutConstraint!

    private var categories: [Category] = []
    private var loadedCourses: [Course] = []
    private var filteredCourses: [Course] = []
    private var selectedCategoryID: String?
    private var completedCourseIDs = Set<String>()
    private var currentPage = 1
    private let pageLimit = 6
    private var hasMore = true

    private let emptyResultsView = EmptyStateView()

    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(CategoryChipCollectionViewCell.self, forCellWithReuseIdentifier: CategoryChipCollectionViewCell.reuseIdentifier)
        return view
    }()

    private lazy var courseCollectionView: IntrinsicCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 14
        let view = IntrinsicCollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.dataSource = self
        view.delegate = self
        view.register(CourseCardCollectionViewCell.self, forCellWithReuseIdentifier: CourseCardCollectionViewCell.reuseIdentifier)
        return view
    }()

    override func buildContent() {
        title = L10n.tr("course.list.title")
        navigationItem.largeTitleDisplayMode = .never

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        categoryContainerView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        courseContainerView.backgroundColor = .clear
        emptyStateContainerView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        searchField.applyAppStyle(placeholder: L10n.tr("course.list.search.placeholder"))
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)

        loadMoreButton.applySecondaryOutlineStyle()
        loadMoreButton.setTitle(L10n.tr("course.list.loadMore"), for: .normal)
        loadMoreButton.addAction(UIAction { [weak self] _ in
            self?.loadMoreCourses()
        }, for: .touchUpInside)

        emptyResultsView.configure(
            icon: "magnifyingglass",
            title: L10n.tr("course.list.empty.title"),
            subtitle: L10n.tr("course.list.empty.subtitle")
        )
        embed(categoryCollectionView, in: categoryContainerView, inset: 4)
        embed(courseCollectionView, in: courseContainerView, inset: 0)
        embed(emptyResultsView, in: emptyStateContainerView, inset: 12)
        emptyStateContainerView.isHidden = true

        Task {
            await loadInitialData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isViewLoaded else { return }
        Task {
            await refreshCompletedCourseIDs()
            applyFilters()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCourseCollectionHeight()
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

    private func updateCourseCollectionHeight() {
        courseCollectionView.layoutIfNeeded()
        let contentHeight = max(courseCollectionView.collectionViewLayout.collectionViewContentSize.height, 540)
        courseContainerHeightConstraint.constant = contentHeight
    }

    private func loadInitialData() async {
        setLoadingVisible(true)
        do {
            async let categoryTask = CategoryService.shared.getAll(page: 1, limit: 20)
            async let courseTask = CourseService.shared.getAll(page: 1, limit: pageLimit)
            categories = try await categoryTask
            let firstPageCourses = try await courseTask
            await refreshCompletedCourseIDs()
            loadedCourses = visibleCourses(from: firstPageCourses)
            hasMore = firstPageCourses.count == pageLimit
            setLoadingVisible(false)
            applyFilters()
            categoryCollectionView.reloadData()
            updateCourseCollectionHeight()
        } catch {
            setLoadingVisible(false)
            showError(message: error.localizedDescription)
        }
    }

    @objc private func searchChanged() {
        applyFilters()
    }

    private func loadMoreCourses() {
        guard hasMore else { return }
        currentPage += 1
        loadMoreButton.isEnabled = false
        loadMoreButton.setTitle(L10n.tr("course.list.loading"), for: .normal)

        Task { @MainActor in
            defer {
                loadMoreButton.isEnabled = true
                loadMoreButton.setTitle(L10n.tr("course.list.loadMore"), for: .normal)
            }

            do {
                let nextPage = try await CourseService.shared.getAll(page: currentPage, limit: pageLimit, categoryId: selectedCategoryID)
                await refreshCompletedCourseIDs()
                let visiblePage = visibleCourses(from: nextPage)
                loadedCourses.append(contentsOf: visiblePage)
                hasMore = nextPage.count == pageLimit
                applyFilters()
                updateCourseCollectionHeight()
            } catch {
                showError(message: error.localizedDescription)
            }
        }
    }

    private func applyFilters() {
        let searchText = (searchField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        filteredCourses = loadedCourses.filter { course in
            let matchesCategory = selectedCategoryID == nil || course.category_id == selectedCategoryID
            let matchesSearch = searchText.isEmpty
                || course.title.lowercased().contains(searchText)
                || course.description.lowercased().contains(searchText)
                || (course.instructor_name?.lowercased().contains(searchText) ?? false)
            return matchesCategory && matchesSearch
        }
        emptyStateContainerView.isHidden = !filteredCourses.isEmpty
        courseContainerView.isHidden = filteredCourses.isEmpty
        courseCollectionView.reloadData()
        updateCourseCollectionHeight()
    }

    private func openCourse(_ course: Course) {
        let controller: CourseDetailViewController = RootRouter.shared.instantiate(identifier: "CourseDetailViewController")
        controller.course = course
        navigationController?.pushViewController(controller, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === categoryCollectionView {
            return categories.count + 1
        }
        return filteredCourses.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === categoryCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryChipCollectionViewCell.reuseIdentifier, for: indexPath) as? CategoryChipCollectionViewCell else {
                return UICollectionViewCell()
            }
            if indexPath.item == 0 {
                cell.configure(title: L10n.tr("course.list.allCategories"))
                cell.isSelected = selectedCategoryID == nil
            } else {
                let category = categories[indexPath.item - 1]
                cell.configure(title: category.name)
                cell.isSelected = selectedCategoryID == category.id
            }
            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseCardCollectionViewCell.reuseIdentifier, for: indexPath) as? CourseCardCollectionViewCell else {
            return UICollectionViewCell()
        }
        let course = filteredCourses[indexPath.item]
        cell.configure(with: course)
        cell.onActionTapped = { [weak self] in
            self?.openCourse(course)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === categoryCollectionView {
            selectedCategoryID = indexPath.item == 0 ? nil : categories[indexPath.item - 1].id
            currentPage = 1
            Task {
                do {
                    let result = try await CourseService.shared.getAll(page: 1, limit: pageLimit, categoryId: selectedCategoryID)
                    await refreshCompletedCourseIDs()
                    loadedCourses = visibleCourses(from: result)
                    hasMore = result.count == pageLimit
                    applyFilters()
                    categoryCollectionView.reloadData()
                    updateCourseCollectionHeight()
                } catch {
                    showError(message: error.localizedDescription)
                }
            }
        } else {
            openCourse(filteredCourses[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === categoryCollectionView {
            let title = indexPath.item == 0 ? L10n.tr("course.list.allCategories") : categories[indexPath.item - 1].name
            let width = (title as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]).width + 34
            return CGSize(width: width, height: 38)
        }

        let width = floor((collectionView.bounds.width - 14) / 2)
        return CGSize(width: width, height: 428)
    }

    private func refreshCompletedCourseIDs() async {
        guard SessionManager.shared.isLoggedIn, SessionManager.shared.isStudent else {
            completedCourseIDs = []
            return
        }
        let enrolledCourses = (try? await EnrollmentService.shared.getMyEnrolledCourses(page: 1, limit: 100)) ?? []
        completedCourseIDs = Set(enrolledCourses.filter(\.isCompletedCourse).map(\.id))
    }

    private func visibleCourses(from courses: [Course]) -> [Course] {
        courses.filter { course in
            let visibleStatus = (course.status ?? "published") != "draft" || SessionManager.shared.isAdmin
            let hiddenBecauseCompleted = SessionManager.shared.isStudent && completedCourseIDs.contains(course.id)
            return visibleStatus && !hiddenBecauseCompleted
        }
    }
}
