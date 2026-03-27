import UIKit

enum LocalMediaStore {
    private static let directoryName = "LocalMedia"
    private static let imagePrefix = "local-image://"

    static func saveImage(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.88) else {
            throw LocalMediaStoreError.cannotEncodeImage
        }

        let directoryURL = try makeDirectoryURL()
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return imagePrefix + fileName
    }

    static func image(from rawValue: String?) -> UIImage? {
        guard let fileURL = fileURL(from: rawValue) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    static func fileURL(from rawValue: String?) -> URL? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix(imagePrefix) {
            let fileName = String(trimmed.dropFirst(imagePrefix.count))
            guard !fileName.isEmpty else { return nil }
            guard let directoryURL = try? makeDirectoryURL() else { return nil }
            return directoryURL.appendingPathComponent(fileName)
        }

        if trimmed.hasPrefix("file://") {
            return URL(string: trimmed)
        }

        return nil
    }

    private static func makeDirectoryURL() throws -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directoryURL = baseURL.appendingPathComponent(directoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL
    }
}

enum LocalMediaStoreError: LocalizedError {
    case cannotEncodeImage

    var errorDescription: String? {
        switch self {
        case .cannotEncodeImage:
            return "App không thể lưu ảnh này vào bộ nhớ cục bộ."
        }
    }
}
