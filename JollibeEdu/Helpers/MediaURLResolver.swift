import Foundation

enum MediaSource {
    case bundled(URL)
    case player(URL)
    case web(URL)
    case youtube(String)
}

enum MediaURLResolver {
    private static let directPlayableExtensions: Set<String> = [
        "aac", "m3u8", "m4a", "m4v", "mov", "mp3", "mp4", "wav", "webm"
    ]

    static func normalizedImageURL(from rawValue: String?) -> URL? {
        if let localFileURL = LocalMediaStore.fileURL(from: rawValue) {
            return localFileURL
        }

        guard let trimmed = normalizedValue(from: rawValue),
              let url = URL(string: trimmed) else {
            return nil
        }

        if let driveFileID = googleDriveFileID(from: url) {
            return URL(string: "https://drive.google.com/uc?export=view&id=\(driveFileID)")
        }

        if isDropboxURL(url) {
            return normalizedDropboxURL(from: url)
        }

        return url
    }

    static func mediaSource(from rawValue: String?) -> MediaSource? {
        guard let trimmed = normalizedValue(from: rawValue) else {
            return nil
        }

        if let bundledURL = bundledResourceURL(from: trimmed) {
            return .bundled(bundledURL)
        }

        if let youtubeID = extractedYouTubeVideoID(from: trimmed) {
            return .youtube(youtubeID)
        }

        guard let url = URL(string: trimmed) else {
            return nil
        }

        if let driveFileID = googleDriveFileID(from: url),
           let previewURL = URL(string: "https://drive.google.com/file/d/\(driveFileID)/preview") {
            return .web(previewURL)
        }

        let normalizedURL = isDropboxURL(url) ? normalizedDropboxURL(from: url) : url
        if directPlayableExtensions.contains(normalizedURL.pathExtension.lowercased()) {
            return .player(normalizedURL)
        }

        return .web(normalizedURL)
    }

    static func bundledResourceURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.replacingOccurrences(of: "bundle://", with: "")
        let components = normalized.split(separator: ".")
        guard components.count >= 2 else { return nil }
        let fileExtension = String(components.last ?? "")
        let fileName = components.dropLast().joined(separator: ".")
        guard !fileName.isEmpty else { return nil }
        return Bundle.main.url(forResource: fileName, withExtension: fileExtension)
    }

    static func extractedYouTubeVideoID(from rawValue: String) -> String? {
        guard let url = URL(string: rawValue) else { return nil }
        let host = (url.host ?? "").lowercased()

        if host.contains("youtu.be") {
            return url.pathComponents.dropFirst().first
        }

        if host.contains("youtube.com") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let value = components.queryItems?.first(where: { $0.name == "v" })?.value,
               !value.isEmpty {
                return value
            }

            let pathComponents = url.pathComponents
            if let embedIndex = pathComponents.firstIndex(of: "embed"),
               pathComponents.indices.contains(embedIndex + 1) {
                return pathComponents[embedIndex + 1]
            }

            if let shortsIndex = pathComponents.firstIndex(of: "shorts"),
               pathComponents.indices.contains(shortsIndex + 1) {
                return pathComponents[shortsIndex + 1]
            }
        }

        return nil
    }

    static func youtubeWatchURL(for videoID: String) -> URL? {
        URL(string: "https://www.youtube.com/watch?v=\(videoID)")
    }

    static func youtubeThumbnailURL(for videoID: String) -> URL? {
        URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
    }

    private static func normalizedValue(from rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func googleDriveFileID(from url: URL) -> String? {
        let host = (url.host ?? "").lowercased()
        guard host.contains("drive.google.com") else { return nil }

        let pathComponents = url.pathComponents
        if let fileIndex = pathComponents.firstIndex(of: "d"),
           pathComponents.indices.contains(fileIndex + 1) {
            return pathComponents[fileIndex + 1]
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let id = components.queryItems?.first(where: { $0.name == "id" })?.value,
           !id.isEmpty {
            return id
        }

        return nil
    }

    private static func isDropboxURL(_ url: URL) -> Bool {
        (url.host ?? "").lowercased().contains("dropbox.com")
    }

    private static func normalizedDropboxURL(from url: URL) -> URL {
        let updatedString = url.absoluteString
            .replacingOccurrences(of: "www.dropbox.com", with: "dl.dropboxusercontent.com")
            .replacingOccurrences(of: "?dl=0", with: "")
            .replacingOccurrences(of: "&dl=0", with: "")
            .replacingOccurrences(of: "?raw=1", with: "")
            .replacingOccurrences(of: "&raw=1", with: "")

        return URL(string: updatedString) ?? url
    }
}
