import PhotosUI
import UIKit

final class PhotoLibraryImagePicker: NSObject, PHPickerViewControllerDelegate {
    private weak var presenter: UIViewController?
    private var onPicked: ((String?) -> Void)?
    private var onError: ((String) -> Void)?

    func present(
        from presenter: UIViewController,
        onPicked: @escaping (String?) -> Void,
        onError: @escaping (String) -> Void
    ) {
        self.presenter = presenter
        self.onPicked = onPicked
        self.onError = onError

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presenter.present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else {
            DispatchQueue.main.async { [weak self] in
                self?.onPicked?(nil)
                self?.releaseCallbacks()
            }
            return
        }

        guard provider.canLoadObject(ofClass: UIImage.self) else {
            DispatchQueue.main.async { [weak self] in
                self?.onError?("Ảnh đã chọn không thể đọc được trong app.")
                self?.releaseCallbacks()
            }
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    self.onError?(error.localizedDescription)
                    self.releaseCallbacks()
                    return
                }

                guard let image = object as? UIImage else {
                    self.onError?("App không lấy được ảnh từ bộ sưu tập.")
                    self.releaseCallbacks()
                    return
                }

                do {
                    let storedValue = try LocalMediaStore.saveImage(image)
                    self.onPicked?(storedValue)
                } catch {
                    self.onError?(error.localizedDescription)
                }
                self.releaseCallbacks()
            }
        }
    }

    private func releaseCallbacks() {
        onPicked = nil
        onError = nil
    }
}
