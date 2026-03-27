import UIKit

extension UIButton {
    func applyPrimaryStyle() {
        AppTheme.stylePrimaryButton(self)
    }

    func applySecondaryOutlineStyle() {
        AppTheme.styleSecondaryButton(self)
    }

    func applyDestructiveOutlineStyle() {
        AppTheme.styleDestructiveButton(self)
    }

    func applyPillStyle(selected: Bool = false) {
        AppTheme.stylePillButton(self, selected: selected)
    }
}
