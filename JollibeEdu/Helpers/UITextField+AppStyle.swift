import UIKit

extension UITextField {
    func applyAppStyle(placeholder: String, secure: Bool = false, keyboard: UIKeyboardType = .default) {
        self.placeholder = placeholder
        keyboardType = keyboard
        isSecureTextEntry = secure
        autocapitalizationType = .none
        autocorrectionType = .no
        clearButtonMode = .whileEditing
        AppTheme.styleTextField(self)
    }
}
