import UIKit

final class BootstrapLoadingViewController: UIViewController {
    private let spinner = UIActivityIndicatorView(style: .large)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.warmBackground
        setupViews()
    }

    private func setupViews() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = AppTheme.brandOrange
        spinner.startAnimating()

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "JolibeeEdu"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        titleLabel.textColor = AppTheme.textPrimary

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = L10n.tr("loading.title")
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [spinner, titleLabel, subtitleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 260)
        ])
    }
}
