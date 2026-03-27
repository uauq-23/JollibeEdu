import UIKit

extension UIView {
    func applyCardStyle(backgroundColor: UIColor = AppTheme.cardBackground) {
        let isCellContentView = next is UITableViewCell || next is UICollectionViewCell
        if !isCellContentView {
            translatesAutoresizingMaskIntoConstraints = false
        }
        layer.cornerRadius = AppTheme.cardCornerRadius
        self.backgroundColor = backgroundColor
        layer.masksToBounds = false
        AppTheme.applyCardShadow(to: self)
    }

    func pinEdges(to otherView: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: otherView.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: otherView.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: otherView.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: otherView.bottomAnchor, constant: -insets.bottom)
        ])
    }
}
