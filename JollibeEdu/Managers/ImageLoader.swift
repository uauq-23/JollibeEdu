import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session = URLSession(configuration: .default)

    private init() {}

    func loadImage(from urlString: String?, into imageView: UIImageView, placeholder: UIImage? = UIImage(systemName: "photo")) {
        imageView.image = placeholder
        if let bundledImage = bundledImage(from: urlString) {
            imageView.image = bundledImage
            return
        }

        if let localImage = LocalMediaStore.image(from: urlString) {
            imageView.image = localImage
            return
        }

        guard let url = MediaURLResolver.normalizedImageURL(from: urlString) else { return }
        let cacheKey = url.absoluteString as NSString

        if let cached = cache.object(forKey: cacheKey) {
            imageView.image = cached
            return
        }

        let task = session.dataTask(with: url) { [weak self, weak imageView] data, _, _ in
            guard
                let data,
                let image = UIImage(data: data)
            else { return }

            self?.cache.setObject(image, forKey: cacheKey)
            DispatchQueue.main.async {
                imageView?.image = image
            }
        }
        task.resume()
    }

    private func bundledImage(from rawValue: String?) -> UIImage? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed.replacingOccurrences(of: "bundle://", with: "")
        if let image = UIImage(named: normalized) {
            return image
        }

        let components = normalized.split(separator: ".")
        guard components.count >= 2 else { return nil }
        let fileExtension = String(components.last ?? "")
        let fileName = components.dropLast().joined(separator: ".")
        guard
            !fileName.isEmpty,
            let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return UIImage(data: data)
    }
}
