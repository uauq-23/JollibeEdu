import Foundation
import AppKit

struct AssetSpec {
    let name: String
    let title: String
    let size: CGSize
}

struct Theme {
    let label: String
    let symbolName: String
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let accent: NSColor
    let chipText: String
}

let sourcePath = "/Users/nguyenthuydung/Desktop/JollibeEdu/JollibeEdu/Services/DemoDataStore.swift"
let assetsPath = "/Users/nguyenthuydung/Desktop/JollibeEdu/JollibeEdu/Assets.xcassets"
let source = try String(contentsOfFile: sourcePath, encoding: .utf8)
let lines = source.components(separatedBy: .newlines)

let titleRegex = try NSRegularExpression(pattern: #"title: \"([^\"]+)\""#)
let courseSeedRegex = try NSRegularExpression(pattern: #"thumbnailSeed: \"([^\"]+)\""#)
let lessonSeedRegex = try NSRegularExpression(pattern: #"imageSeed: \"([^\"]+)\""#)

func firstMatch(_ regex: NSRegularExpression, in line: String) -> String? {
    let range = NSRange(line.startIndex..<line.endIndex, in: line)
    guard let match = regex.firstMatch(in: line, range: range),
          match.numberOfRanges > 1,
          let capture = Range(match.range(at: 1), in: line) else {
        return nil
    }
    return String(line[capture])
}

func ensureDirectory(_ path: String) throws {
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
}

func writeContentsJSON(to path: String, imageName: String) throws {
    let json = """
    {
      "images" : [
        {
          "filename" : "\(imageName)",
          "idiom" : "universal",
          "scale" : "1x"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try json.write(toFile: path, atomically: true, encoding: .utf8)
}

func drawText(_ text: String, in rect: CGRect, font: NSFont, color: NSColor) {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byWordWrapping
    style.alignment = .left
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: style
    ]
    (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs)
}

func theme(for assetName: String, title: String) -> Theme {
    let normalized = "\(assetName) \(title)".lowercased()

    switch normalized {
    case let value where value.contains("jbe-course-ios"):
        return Theme(
            label: "UIKit & Storyboard",
            symbolName: "iphone.gen3",
            backgroundTop: NSColor(calibratedRed: 0.93, green: 0.39, blue: 0.12, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.99, green: 0.72, blue: 0.18, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.93, alpha: 1),
            chipText: "MOBILE"
        )
    case let value where value.contains("jbe-course-uiux"):
        return Theme(
            label: "EdTech Interface Design",
            symbolName: "paintpalette.fill",
            backgroundTop: NSColor(calibratedRed: 0.34, green: 0.18, blue: 0.57, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.79, green: 0.42, blue: 0.86, alpha: 1),
            accent: NSColor(calibratedRed: 0.99, green: 0.96, blue: 1.0, alpha: 1),
            chipText: "UI/UX"
        )
    case let value where value.contains("jbe-course-english"):
        return Theme(
            label: "Business English Practice",
            symbolName: "character.book.closed.fill",
            backgroundTop: NSColor(calibratedRed: 0.16, green: 0.38, blue: 0.68, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.31, green: 0.64, blue: 0.93, alpha: 1),
            accent: NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1),
            chipText: "ENGLISH"
        )
    case let value where value.contains("jbe-course-growth"):
        return Theme(
            label: "Acquisition & Retention",
            symbolName: "chart.line.uptrend.xyaxis",
            backgroundTop: NSColor(calibratedRed: 0.06, green: 0.46, blue: 0.39, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.22, green: 0.78, blue: 0.63, alpha: 1),
            accent: NSColor(calibratedRed: 0.93, green: 0.99, blue: 0.97, alpha: 1),
            chipText: "GROWTH"
        )
    case let value where value.contains("jbe-course-react"):
        return Theme(
            label: "React Course Platform",
            symbolName: "laptopcomputer",
            backgroundTop: NSColor(calibratedRed: 0.07, green: 0.28, blue: 0.46, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.18, green: 0.57, blue: 0.83, alpha: 1),
            accent: NSColor(calibratedRed: 0.95, green: 0.98, blue: 1.0, alpha: 1),
            chipText: "FULLSTACK"
        )
    case let value where value.contains("jbe-course-cert"):
        return Theme(
            label: "Study Plan & Certificate",
            symbolName: "rosette",
            backgroundTop: NSColor(calibratedRed: 0.54, green: 0.33, blue: 0.12, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.94, green: 0.70, blue: 0.24, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.92, alpha: 1),
            chipText: "LEARNING"
        )
    case let value where value.contains("jbe-course-nodeapi"):
        return Theme(
            label: "Node.js & MongoDB API",
            symbolName: "server.rack",
            backgroundTop: NSColor(calibratedRed: 0.10, green: 0.47, blue: 0.27, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.24, green: 0.74, blue: 0.41, alpha: 1),
            accent: NSColor(calibratedRed: 0.95, green: 0.99, blue: 0.96, alpha: 1),
            chipText: "BACKEND"
        )
    case let value where value.contains("jbe-course-ai-edu"):
        return Theme(
            label: "AI for Education",
            symbolName: "brain.head.profile",
            backgroundTop: NSColor(calibratedRed: 0.35, green: 0.22, blue: 0.67, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.67, green: 0.43, blue: 0.89, alpha: 1),
            accent: NSColor(calibratedRed: 0.98, green: 0.95, blue: 1.0, alpha: 1),
            chipText: "AI"
        )
    case let value where value.contains("jbe-course-product"):
        return Theme(
            label: "Roadmap & Product Decisions",
            symbolName: "list.bullet.rectangle.portrait.fill",
            backgroundTop: NSColor(calibratedRed: 0.64, green: 0.16, blue: 0.25, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.90, green: 0.34, blue: 0.43, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.96, alpha: 1),
            chipText: "PRODUCT"
        )
    case let value where value.contains("jbe-course-swift-adv"):
        return Theme(
            label: "Swift Patterns for UIKit",
            symbolName: "curlybraces.square.fill",
            backgroundTop: NSColor(calibratedRed: 0.89, green: 0.29, blue: 0.15, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.99, green: 0.56, blue: 0.22, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.96, blue: 0.93, alpha: 1),
            chipText: "SWIFT"
        )
    case let value where value.contains("jbe-course-sql"):
        return Theme(
            label: "Query & Analytics",
            symbolName: "cylinder.split.1x2.fill",
            backgroundTop: NSColor(calibratedRed: 0.14, green: 0.34, blue: 0.58, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.33, green: 0.63, blue: 0.89, alpha: 1),
            accent: NSColor(calibratedRed: 0.94, green: 0.98, blue: 1.0, alpha: 1),
            chipText: "SQL"
        )
    case let value where value.contains("jbe-course-speaking"):
        return Theme(
            label: "Presentation & Storytelling",
            symbolName: "mic.fill",
            backgroundTop: NSColor(calibratedRed: 0.58, green: 0.26, blue: 0.12, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.97, green: 0.56, blue: 0.23, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.94, alpha: 1),
            chipText: "SPEAKING"
        )
    case let value where value.contains("swift") || value.contains("ios"):
        return Theme(
            label: "iOS UIKit",
            symbolName: "iphone.gen3",
            backgroundTop: NSColor(calibratedRed: 0.95, green: 0.42, blue: 0.15, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.98, green: 0.72, blue: 0.22, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.93, alpha: 1),
            chipText: "MOBILE"
        )
    case let value where value.contains("sql") || value.contains("dashboard") || value.contains("metrics"):
        return Theme(
            label: "SQL Analytics",
            symbolName: "cylinder.split.1x2.fill",
            backgroundTop: NSColor(calibratedRed: 0.14, green: 0.34, blue: 0.58, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.33, green: 0.63, blue: 0.89, alpha: 1),
            accent: NSColor(calibratedRed: 0.94, green: 0.98, blue: 1.0, alpha: 1),
            chipText: "DATA"
        )
    case let value where value.contains("node") || value.contains("mongo") || value.contains("backend") || value.contains("api"):
        return Theme(
            label: "Node.js API",
            symbolName: "server.rack",
            backgroundTop: NSColor(calibratedRed: 0.10, green: 0.47, blue: 0.27, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.22, green: 0.73, blue: 0.43, alpha: 1),
            accent: NSColor(calibratedRed: 0.95, green: 0.99, blue: 0.96, alpha: 1),
            chipText: "BACKEND"
        )
    case let value where value.contains("ai") || value.contains("prompt"):
        return Theme(
            label: "AI Learning",
            symbolName: "brain.head.profile",
            backgroundTop: NSColor(calibratedRed: 0.36, green: 0.22, blue: 0.66, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.66, green: 0.42, blue: 0.88, alpha: 1),
            accent: NSColor(calibratedRed: 0.98, green: 0.95, blue: 1.0, alpha: 1),
            chipText: "AI"
        )
    case let value where value.contains("product") || value.contains("roadmap") || value.contains("backlog"):
        return Theme(
            label: "Product Strategy",
            symbolName: "list.bullet.rectangle.portrait.fill",
            backgroundTop: NSColor(calibratedRed: 0.64, green: 0.16, blue: 0.25, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.90, green: 0.34, blue: 0.43, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.96, alpha: 1),
            chipText: "PRODUCT"
        )
    case let value where value.contains("present") || value.contains("speak") || value.contains("thuyet") || value.contains("bao cao"):
        return Theme(
            label: "Public Speaking",
            symbolName: "mic.fill",
            backgroundTop: NSColor(calibratedRed: 0.58, green: 0.26, blue: 0.12, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.97, green: 0.56, blue: 0.23, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.94, alpha: 1),
            chipText: "SOFT SKILL"
        )
    case let value where value.contains("english") || value.contains("email") || value.contains("small talk") || value.contains("hop nhom"):
        return Theme(
            label: "English",
            symbolName: "character.book.closed.fill",
            backgroundTop: NSColor(calibratedRed: 0.16, green: 0.38, blue: 0.68, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.30, green: 0.63, blue: 0.93, alpha: 1),
            accent: NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1),
            chipText: "LANGUAGE"
        )
    case let value where value.contains("uiux") || value.contains("design"):
        return Theme(
            label: "UI/UX Design",
            symbolName: "paintpalette.fill",
            backgroundTop: NSColor(calibratedRed: 0.30, green: 0.18, blue: 0.57, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.74, green: 0.39, blue: 0.85, alpha: 1),
            accent: NSColor(calibratedRed: 0.99, green: 0.96, blue: 1.0, alpha: 1),
            chipText: "DESIGN"
        )
    case let value where value.contains("growth") || value.contains("marketing"):
        return Theme(
            label: "Growth Marketing",
            symbolName: "megaphone.fill",
            backgroundTop: NSColor(calibratedRed: 0.06, green: 0.47, blue: 0.42, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.18, green: 0.76, blue: 0.67, alpha: 1),
            accent: NSColor(calibratedRed: 0.93, green: 0.99, blue: 0.98, alpha: 1),
            chipText: "MARKETING"
        )
    case let value where value.contains("react") || value.contains("fullstack"):
        return Theme(
            label: "React Platform",
            symbolName: "laptopcomputer",
            backgroundTop: NSColor(calibratedRed: 0.07, green: 0.28, blue: 0.46, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.18, green: 0.57, blue: 0.83, alpha: 1),
            accent: NSColor(calibratedRed: 0.95, green: 0.98, blue: 1.0, alpha: 1),
            chipText: "WEB APP"
        )
    case let value where value.contains("cert") || value.contains("study roadmap"):
        return Theme(
            label: "Study Skills",
            symbolName: "rosette",
            backgroundTop: NSColor(calibratedRed: 0.54, green: 0.33, blue: 0.12, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.93, green: 0.68, blue: 0.24, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.92, alpha: 1),
            chipText: "LEARNING"
        )
    default:
        return Theme(
            label: "Online Course",
            symbolName: "book.closed.fill",
            backgroundTop: NSColor(calibratedRed: 0.95, green: 0.42, blue: 0.15, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.99, green: 0.74, blue: 0.19, alpha: 1),
            accent: NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.96, alpha: 1),
            chipText: "COURSE"
        )
    }
}

func renderSymbol(theme: Theme, canvasSize: CGSize) {
    let config = NSImage.SymbolConfiguration(
        pointSize: canvasSize.width > 1000 ? 176 : 120,
        weight: .regular
    )
    guard let symbolImage = NSImage(systemSymbolName: theme.symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { return }

    let rect = CGRect(
        x: canvasSize.width - (canvasSize.width > 1000 ? 300 : 230),
        y: canvasSize.height * 0.18,
        width: canvasSize.width > 1000 ? 200 : 150,
        height: canvasSize.width > 1000 ? 200 : 150
    )
    symbolImage.draw(in: rect)
}

func renderAsset(_ spec: AssetSpec, to assetDirectory: String) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(spec.size.width),
        pixelsHigh: Int(spec.size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "AssetGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to allocate bitmap"])
    }

    let theme = theme(for: spec.name, title: spec.title)

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "AssetGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context"])
    }
    NSGraphicsContext.current = context

    let bounds = CGRect(origin: .zero, size: spec.size)
    let gradient = NSGradient(starting: theme.backgroundTop, ending: theme.backgroundBottom)
    gradient?.draw(in: bounds, angle: 24)

    let outerCard = NSBezierPath(roundedRect: bounds.insetBy(dx: 28, dy: 28), xRadius: 38, yRadius: 38)
    NSColor.white.withAlphaComponent(0.10).setFill()
    outerCard.fill()

    let labelRect = CGRect(x: 44, y: bounds.height - 100, width: 210, height: 42)
    let labelPath = NSBezierPath(roundedRect: labelRect, xRadius: 21, yRadius: 21)
    NSColor.white.withAlphaComponent(0.20).setFill()
    labelPath.fill()
    drawText(theme.chipText, in: labelRect.insetBy(dx: 18, dy: 8), font: .boldSystemFont(ofSize: spec.size.width > 1000 ? 22 : 16), color: .white)

    let subtitleRect = CGRect(x: 48, y: bounds.height - 160, width: bounds.width - 220, height: 32)
    drawText(theme.label, in: subtitleRect, font: .systemFont(ofSize: spec.size.width > 1000 ? 24 : 18, weight: .semibold), color: NSColor.white.withAlphaComponent(0.95))

    let titleRect = CGRect(x: 48, y: bounds.height * 0.23, width: bounds.width - 180, height: bounds.height * 0.48)
    drawText(spec.title, in: titleRect, font: .boldSystemFont(ofSize: spec.size.width > 1000 ? 62 : 40), color: .white)

    renderSymbol(theme: theme, canvasSize: spec.size)

    let footerRect = CGRect(x: 48, y: 42, width: bounds.width - 120, height: 26)
    drawText("JolibeeEdu • local themed cover", in: footerRect, font: .systemFont(ofSize: spec.size.width > 1000 ? 18 : 13, weight: .medium), color: NSColor.white.withAlphaComponent(0.86))

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AssetGenerator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to render PNG"])
    }

    let imageName = "cover.png"
    try pngData.write(to: URL(fileURLWithPath: assetDirectory).appendingPathComponent(imageName))
    try writeContentsJSON(to: URL(fileURLWithPath: assetDirectory).appendingPathComponent("Contents.json").path, imageName: imageName)
}

var specs: [AssetSpec] = []
for line in lines {
    guard let title = firstMatch(titleRegex, in: line) else { continue }
    if line.contains("course("), let seed = firstMatch(courseSeedRegex, in: line) {
        specs.append(AssetSpec(name: seed, title: title, size: CGSize(width: 1200, height: 700)))
    } else if line.contains("lesson("), let seed = firstMatch(lessonSeedRegex, in: line) {
        specs.append(AssetSpec(name: seed, title: title, size: CGSize(width: 900, height: 506)))
    }
}

for spec in specs {
    let assetDirectory = URL(fileURLWithPath: assetsPath).appendingPathComponent("\(spec.name).imageset").path
    try ensureDirectory(assetDirectory)
    try renderAsset(spec, to: assetDirectory)
}

print("Generated \(specs.count) themed assets")
