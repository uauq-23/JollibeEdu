import UIKit

final class AdminCategoriesViewController: AdminProtectedViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    private var categories: [Category] = []
    private var metrics: [AdminSummaryMetric] = []

    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var summaryCardView: UIView!
    @IBOutlet private weak var summaryContainerView: UIView!
    @IBOutlet private weak var summaryHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var listCardView: UIView!
    @IBOutlet private weak var listContainerView: UIView!
    @IBOutlet private weak var listHeightConstraint: NSLayoutConstraint!

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

    private lazy var tableView: IntrinsicTableView = {
        let tableView = IntrinsicTableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 130
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AdminListTableViewCell.self, forCellReuseIdentifier: AdminListTableViewCell.reuseIdentifier)
        return tableView
    }()

    override func buildContent() {
        title = L10n.tr("admin.categories.title")
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCategoryTapped))

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        summaryCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        listCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        embed(summaryCollectionView, in: summaryContainerView)
        embed(tableView, in: listContainerView)

        Task {
            await loadCategories()
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
        tableView.layoutIfNeeded()
        summaryHeightConstraint.constant = max(300, summaryCollectionView.collectionViewLayout.collectionViewContentSize.height)
        listHeightConstraint.constant = max(220, tableView.contentSize.height)
    }

    private func loadCategories() async {
        do {
            categories = try await CategoryService.shared.getAll(page: 1, limit: 100)
            metrics = [
                AdminSummaryMetric(symbol: "square.grid.2x2.fill", title: L10n.tr("admin.categories.metric.total"), value: "\(categories.count)"),
                AdminSummaryMetric(symbol: "paintpalette.fill", title: L10n.tr("admin.categories.metric.design"), value: "\(categories.filter { $0.name.lowercased().contains("thiết") }.count)"),
                AdminSummaryMetric(symbol: "terminal.fill", title: L10n.tr("admin.categories.metric.tech"), value: "\(categories.filter { $0.name.lowercased().contains("lập") }.count)"),
                AdminSummaryMetric(symbol: "checkmark.seal.fill", title: L10n.tr("admin.categories.metric.ready"), value: "\(categories.count)")
            ]
            summaryCollectionView.reloadData()
            tableView.reloadData()
            updateEmbeddedHeights()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    @objc private func addCategoryTapped() {
        presentCategoryForm(category: nil)
    }

    private func presentCategoryForm(category: Category?) {
        let alert = UIAlertController(
            title: category == nil ? L10n.tr("admin.categories.form.add") : L10n.tr("admin.categories.form.edit"),
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { $0.placeholder = L10n.tr("admin.categories.form.name"); $0.text = category?.name }
        alert.addTextField { $0.placeholder = L10n.tr("admin.categories.form.description"); $0.text = category?.description }
        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("common.save"), style: .default) { [weak self] _ in
            let name = alert.textFields?[0].text ?? ""
            let description = alert.textFields?[1].text ?? ""
            Task { @MainActor in
                do {
                    if let category {
                        _ = try await CategoryService.shared.update(id: category.id, data: ["name": name, "description": description])
                    } else {
                        _ = try await CategoryService.shared.create(name: name, description: description)
                    }
                    if let self {
                        await self.loadCategories()
                    }
                } catch {
                    self?.showError(message: error.localizedDescription)
                }
            }
        })
        present(alert, animated: true)
    }

    private func deleteCategory(_ category: Category) {
        showConfirm(
            title: L10n.tr("admin.categories.delete.title"),
            message: L10n.tr("admin.categories.delete.message", category.name),
            confirmTitle: L10n.tr("admin.categories.delete.confirm")
        ) { [weak self] in
            Task { @MainActor in
                do {
                    try await CategoryService.shared.delete(id: category.id)
                    if let self {
                        await self.loadCategories()
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
        categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AdminListTableViewCell.reuseIdentifier, for: indexPath) as? AdminListTableViewCell else {
            return UITableViewCell()
        }
        let category = categories[indexPath.row]
        cell.configure(
            title: category.name,
            subtitle: category.description ?? L10n.tr("common.noDescription"),
            status: "active",
            primaryTitle: L10n.tr("admin.categories.action.edit"),
            secondaryTitle: L10n.tr("admin.categories.action.delete")
        )
        cell.onPrimaryTapped = { [weak self] in self?.presentCategoryForm(category: category) }
        cell.onSecondaryTapped = { [weak self] in self?.deleteCategory(category) }
        return cell
    }
}
