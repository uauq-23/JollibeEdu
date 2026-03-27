import UIKit

final class TextFieldPickerAdapter: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    private weak var textField: UITextField?
    private let options: [String]
    private let displayText: (String) -> String
    private let onSelection: (String) -> Void
    private let pickerView = UIPickerView()

    init(
        textField: UITextField,
        options: [String],
        selectedValue: String?,
        displayText: @escaping (String) -> String = { $0 },
        onSelection: @escaping (String) -> Void = { _ in }
    ) {
        self.textField = textField
        self.options = options
        self.displayText = displayText
        self.onSelection = onSelection
        super.init()

        pickerView.dataSource = self
        pickerView.delegate = self
        textField.inputView = pickerView
        textField.tintColor = .clear

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Chọn", style: .done, target: self, action: #selector(doneTapped))
        ]
        textField.inputAccessoryView = toolbar

        let initialValue = selectedValue.flatMap { value in
            options.contains(value) ? value : nil
        } ?? options.first

        if let initialValue, let selectedIndex = options.firstIndex(of: initialValue) {
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
            applySelection(at: selectedIndex)
        }
    }

    @objc private func doneTapped() {
        textField?.resignFirstResponder()
    }

    private func applySelection(at index: Int) {
        guard options.indices.contains(index) else { return }
        let value = options[index]
        textField?.text = displayText(value)
        onSelection(value)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        options.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard options.indices.contains(row) else { return nil }
        return displayText(options[row])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        applySelection(at: row)
    }
}
