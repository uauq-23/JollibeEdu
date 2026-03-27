import UIKit

enum UIFactory {
    static func makeTitleLabel(_ text: String, size: CGFloat = 28) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: size)
        label.textColor = AppTheme.textPrimary
        label.numberOfLines = 0
        return label
    }

    static func makeSubtitleLabel(_ text: String, size: CGFloat = 15) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.systemFont(ofSize: size, weight: .medium)
        label.textColor = AppTheme.textSecondary
        label.numberOfLines = 0
        return label
    }

    static func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = AppTheme.textPrimary
        label.numberOfLines = 0
        return label
    }

    static func makeCard(padding: CGFloat = 18, spacing: CGFloat = 12) -> (UIView, UIStackView) {
        let card = UIView()
        card.applyCardStyle()

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = .fill

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: padding),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: padding),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -padding),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -padding)
        ])

        return (card, stack)
    }

    static func makeHorizontalStack(spacing: CGFloat = 12, alignment: UIStackView.Alignment = .center, distribution: UIStackView.Distribution = .fill) -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.alignment = alignment
        stack.distribution = distribution
        return stack
    }

    static func makeVerticalStack(spacing: CGFloat = 12) -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = .fill
        return stack
    }

    static func makeIconBadge(symbol: String, tint: UIColor = AppTheme.brandOrange) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = tint.withAlphaComponent(0.14)
        container.layer.cornerRadius = 18

        let imageView = UIImageView(image: UIImage(systemName: symbol))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = tint
        imageView.contentMode = .scaleAspectFit
        container.addSubview(imageView)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 36),
            container.widthAnchor.constraint(equalToConstant: 36),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 18),
            imageView.widthAnchor.constraint(equalToConstant: 18)
        ])

        return container
    }

    static func makeSpacer(height: CGFloat) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: height)
        ])
        return view
    }

    static func wrap(_ view: UIView, insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom)
        ])
        return container
    }

    static func makeSeparator() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppTheme.softBorder
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 1)
        ])
        return view
    }
}
