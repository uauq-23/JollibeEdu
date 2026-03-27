import AVKit
import UIKit
import WebKit

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

final class LessonDetailViewController: AuthenticatedStackViewController, UITableViewDataSource, UITableViewDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    override var clearsInitialStoryboardContent: Bool { false }

    var course: Course?
    var courseID: String?
    var lessonID: String?
    var allowsAdminPreview = false

    private var lessons: [Lesson] = []
    private var completedLessonIDs = Set<String>()
    private var currentLesson: Lesson?
    private var playerController: AVPlayerViewController?
    private var webView: WKWebView?
    private var didAutoTrackCurrentLesson = false
    private let youtubeMessageName = "youtubePlayerState"
    private let youtubeErrorMessageName = "youtubePlayerError"

    @IBOutlet private weak var lessonCardView: UIView!
    @IBOutlet private weak var mediaContainerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var controlsCardView: UIView!
    @IBOutlet private weak var progressLabel: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var completeButton: UIButton!
    @IBOutlet private weak var contentCardView: UIView!
    @IBOutlet private weak var lessonContainerView: UIView!
    @IBOutlet private weak var lessonContainerHeightConstraint: NSLayoutConstraint!

    private lazy var lessonTableView: IntrinsicTableView = {
        let tableView = IntrinsicTableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96
        tableView.register(LessonRowTableViewCell.self, forCellReuseIdentifier: LessonRowTableViewCell.reuseIdentifier)
        return tableView
    }()

    override func buildContent() {
        title = L10n.tr("lesson.detail.title")
        navigationItem.largeTitleDisplayMode = .never

        lessonCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        controlsCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        contentCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        mediaContainerView.backgroundColor = .black
        mediaContainerView.layer.cornerRadius = 22
        mediaContainerView.clipsToBounds = true

        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 0

        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textColor = AppTheme.textSecondary
        statusLabel.numberOfLines = 0

        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        progressLabel.textColor = AppTheme.textSecondary

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = AppTheme.brandOrange
        progressView.trackTintColor = AppTheme.softBorder

        previousButton.applySecondaryOutlineStyle()
        previousButton.setTitle(L10n.tr("lesson.detail.previous"), for: .normal)
        previousButton.addAction(UIAction { [weak self] _ in self?.navigateToPrevious() }, for: .touchUpInside)

        nextButton.applyPrimaryStyle()
        nextButton.setTitle(L10n.tr("lesson.detail.next"), for: .normal)
        nextButton.addAction(UIAction { [weak self] _ in self?.navigateToNext() }, for: .touchUpInside)

        completeButton.applyPrimaryStyle()
        completeButton.setTitle(L10n.tr("lesson.detail.complete"), for: .normal)
        completeButton.addAction(UIAction { [weak self] _ in self?.handleCompleteButtonTapped() }, for: .touchUpInside)

        embed(lessonTableView, in: lessonContainerView)

        Task {
            await loadLessonData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }

    private func loadLessonData() async {
        do {
            if course == nil, let courseID {
                course = try await CourseService.shared.getById(id: courseID)
            }
            guard let course else { return }

            lessons = try await LessonService.shared.getByCourse(courseId: course.id)
            if isAdminPreviewMode {
                completedLessonIDs = []
            } else {
                let progress = try await ProgressService.shared.getStudentProgress(courseId: course.id)
                completedLessonIDs = Set(progress.filter(\.completed).map(\.lesson_id))
            }

            if let lessonID {
                currentLesson = try await LessonService.shared.getById(id: lessonID)
            } else {
                currentLesson = resolveInitialLesson()
            }

            updateUI()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func embed(_ view: UIView, in container: UIView) {
        guard view.superview !== container else { return }
        view.removeFromSuperview()
        container.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func updateTableHeight() {
        lessonTableView.layoutIfNeeded()
        lessonContainerHeightConstraint.constant = max(240, lessonTableView.contentSize.height)
    }

    private func resolveInitialLesson() -> Lesson? {
        if let firstUnlocked = lessons.first(where: { isUnlocked($0) && !completedLessonIDs.contains($0.id) }) {
            return firstUnlocked
        }
        return lessons.first
    }

    private func updateUI() {
        guard let currentLesson else { return }
        didAutoTrackCurrentLesson = completedLessonIDs.contains(currentLesson.id)
        titleLabel.text = currentLesson.title
        if isAdminPreviewMode {
            statusLabel.text = L10n.tr("lesson.detail.adminPreview.status")
            progressLabel.text = L10n.tr("lesson.detail.adminPreview.progress", currentLesson.lesson_order, max(lessons.count, 1))
            progressView.progress = lessons.isEmpty ? 0 : Float(Double(currentLesson.lesson_order) / Double(max(lessons.count, 1)))
            completeButton.isHidden = true
        } else {
            if isCourseFullyCompleted {
                statusLabel.text = L10n.tr("course.completion.status")
            } else {
                statusLabel.text = completedLessonIDs.contains(currentLesson.id)
                    ? L10n.tr("lesson.detail.completed.status")
                    : L10n.tr("lesson.detail.locked.status")
            }
            progressLabel.text = L10n.tr(
                "lesson.detail.progress",
                completedLessonIDs.count,
                lessons.count,
                AppFormatting.percent(Double(progressValue()) * 100)
            )
            progressView.progress = progressValue()
            let hasNextLesson = nextLesson(for: currentLesson) != nil
            let currentLessonCompleted = completedLessonIDs.contains(currentLesson.id)
            if isCourseFullyCompleted {
                completeButton.setTitle(L10n.tr("course.completion.button"), for: .normal)
                completeButton.isHidden = false
                completeButton.isEnabled = true
                completeButton.alpha = 1
            } else {
                if currentLessonCompleted {
                    completeButton.setTitle(L10n.tr("lesson.detail.continue"), for: .normal)
                } else if hasNextLesson {
                    completeButton.setTitle(L10n.tr("lesson.detail.completeAndContinue"), for: .normal)
                } else {
                    completeButton.setTitle(L10n.tr("lesson.detail.complete"), for: .normal)
                }
                completeButton.isHidden = false
                completeButton.isEnabled = true
                completeButton.alpha = 1
            }
        }

        if previousLesson(for: currentLesson) != nil {
            previousButton.isEnabled = true
            previousButton.alpha = 1
            previousButton.setTitle(L10n.tr("lesson.detail.previous"), for: .normal)
        } else {
            previousButton.isEnabled = false
            previousButton.alpha = 0.5
        }

        if let upcomingLesson = nextLesson(for: currentLesson), isUnlocked(upcomingLesson) {
            nextButton.isEnabled = true
            nextButton.alpha = 1
        } else {
            nextButton.isEnabled = false
            nextButton.alpha = 0.5
        }

        lessonTableView.reloadData()
        updateTableHeight()
        loadMedia(for: currentLesson)
    }

    private func progressValue() -> Float {
        guard !lessons.isEmpty else { return 0 }
        return Float(Double(completedLessonIDs.count) / Double(lessons.count))
    }

    private var isCourseFullyCompleted: Bool {
        !lessons.isEmpty && completedLessonIDs.count >= lessons.count
    }

    private func isUnlocked(_ lesson: Lesson) -> Bool {
        if isAdminPreviewMode { return true }
        if lesson.lesson_order == 1 { return true }
        if completedLessonIDs.contains(lesson.id) { return true }
        guard let previous = previousLesson(for: lesson) else { return false }
        return completedLessonIDs.contains(previous.id)
    }

    private var isAdminPreviewMode: Bool {
        allowsAdminPreview && SessionManager.shared.isAdmin
    }

    private func previousLesson(for lesson: Lesson) -> Lesson? {
        lessons.first(where: { $0.lesson_order == lesson.lesson_order - 1 })
    }

    private func nextLesson(for lesson: Lesson) -> Lesson? {
        lessons.first(where: { $0.lesson_order == lesson.lesson_order + 1 })
    }

    private func navigateToPrevious() {
        guard let currentLesson, let previous = previousLesson(for: currentLesson) else { return }
        self.currentLesson = previous
        updateUI()
    }

    private func navigateToNext() {
        guard let currentLesson, let next = nextLesson(for: currentLesson), isUnlocked(next) else { return }
        self.currentLesson = next
        updateUI()
    }

    private func handleCompleteButtonTapped() {
        if isCourseFullyCompleted {
            presentCourseCompletionSuccess()
            return
        }
        guard let currentLesson else { return }
        if completedLessonIDs.contains(currentLesson.id) {
            navigateToNext()
            return
        }
        let shouldAdvanceToNextLesson = nextLesson(for: currentLesson) != nil
        markCurrentLessonCompleted(showSuccessMessage: false, advanceToNextLesson: shouldAdvanceToNextLesson)
    }

    private func markCurrentLessonCompleted(showSuccessMessage: Bool, advanceToNextLesson: Bool = false) {
        if isAdminPreviewMode {
            showSuccess(message: L10n.tr("lesson.detail.adminPreview.complete"))
            return
        }
        guard let course, let currentLesson else { return }
        let completedLesson = currentLesson
        Task { @MainActor in
            do {
                _ = try await ProgressService.shared.updateProgress(lessonId: completedLesson.id, courseId: course.id)
                completedLessonIDs.insert(completedLesson.id)
                didAutoTrackCurrentLesson = true
                if advanceToNextLesson,
                   let next = nextLesson(for: completedLesson),
                   isUnlocked(next) {
                    self.currentLesson = next
                }
                updateUI()
                if isCourseFullyCompleted {
                    presentCourseCompletionSuccess()
                } else if showSuccessMessage {
                    showSuccess(message: L10n.tr("lesson.detail.autoProgressUpdated"))
                }
            } catch {
                showError(message: error.localizedDescription)
            }
        }
    }

    private func presentCourseCompletionSuccess() {
        guard let course else { return }
        Task { @MainActor in
            try? await EnrollmentService.shared.updateStatus(courseId: course.id, status: "completed")
            showSuccess(
                title: L10n.tr("course.completion.title"),
                message: L10n.tr("course.completion.message", course.displayTitle)
            )
        }
    }

    private func loadMedia(for lesson: Lesson) {
        playerController?.willMove(toParent: nil)
        playerController?.view.removeFromSuperview()
        playerController?.removeFromParent()
        if let webView {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: youtubeMessageName)
            webView.configuration.userContentController.removeScriptMessageHandler(forName: youtubeErrorMessageName)
            webView.removeFromSuperview()
        }
        webView = nil

        mediaContainerView.subviews.forEach { $0.removeFromSuperview() }
        let fallbackImageURL = lesson.thumbnail_url ?? course?.thumbnail
        guard let source = MediaURLResolver.mediaSource(from: lesson.video_url) else {
            showMediaPlaceholder(
                message: L10n.tr("lesson.detail.videoUnavailable"),
                imageURLString: fallbackImageURL
            )
            playerController = nil
            return
        }

        switch source {
        case .bundled(let url), .player(let url):
            attachPlayer(with: url)
        case .youtube(let videoID):
            attachYouTubePlayer(videoID: videoID)
        case .web(let url):
            attachWebView(with: url)
        }
    }

    private func attachPlayer(with url: URL) {
        let playerController = AVPlayerViewController()
        let player = AVPlayer(url: url)
        playerController.player = player
        playerController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(playerController)
        mediaContainerView.addSubview(playerController.view)
        playerController.view.pinEdges(to: mediaContainerView)
        playerController.didMove(toParent: self)
        self.playerController = playerController
        player.play()
    }

    private func attachYouTubePlayer(videoID: String) {
        let userContentController = WKUserContentController()
        userContentController.add(WeakScriptMessageHandler(target: self), name: youtubeMessageName)
        userContentController.add(WeakScriptMessageHandler(target: self), name: youtubeErrorMessageName)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        mediaContainerView.addSubview(webView)
        webView.pinEdges(to: mediaContainerView)
        self.webView = webView
        playerController = nil

        let html = """
        <!doctype html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
        html, body {
            margin: 0;
            padding: 0;
            background: #000000;
            width: 100%;
            height: 100%;
            overflow: hidden;
        }
        #player {
            position: absolute;
            inset: 0;
            width: 100%;
            height: 100%;
        }
        </style>
        </head>
        <body>
        <div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
        var player;
        function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
                host: 'https://www.youtube-nocookie.com',
                videoId: '\(videoID)',
                playerVars: {
                    playsinline: 1,
                    rel: 0,
                    modestbranding: 1,
                    controls: 1,
                    autoplay: 1,
                    enablejsapi: 1
                },
                events: {
                    onReady: onPlayerReady,
                    onStateChange: onPlayerStateChange,
                    onError: onPlayerError
                }
            });
        }
        function onPlayerReady(event) {
            event.target.playVideo();
        }
        function onPlayerStateChange(event) {
            if (event.data === YT.PlayerState.ENDED) {
                window.webkit.messageHandlers.\(youtubeMessageName).postMessage('ended');
            }
        }
        function onPlayerError(event) {
            window.webkit.messageHandlers.\(youtubeErrorMessageName).postMessage(String(event.data));
        }
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com/embed/\(videoID)"))
    }

    private func attachWebView(with url: URL) {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        mediaContainerView.addSubview(webView)
        webView.pinEdges(to: mediaContainerView)
        webView.load(URLRequest(url: url))
        self.webView = webView
        playerController = nil
    }

    private func showMediaPlaceholder(message: String, imageURLString: String?) {
        mediaContainerView.subviews.forEach { $0.removeFromSuperview() }

        let hasFallbackImage = !(imageURLString?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if hasFallbackImage {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = AppTheme.textPrimary.withAlphaComponent(0.35)
            mediaContainerView.addSubview(imageView)
            imageView.pinEdges(to: mediaContainerView)
            ImageLoader.shared.loadImage(
                from: imageURLString,
                into: imageView,
                placeholder: UIImage(systemName: "photo.on.rectangle.angled")
            )

            let overlay = UIView()
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.38)
            mediaContainerView.addSubview(overlay)
            overlay.pinEdges(to: mediaContainerView)
        }

        let label = UIFactory.makeSubtitleLabel(message)
        label.textColor = .white
        label.textAlignment = .center
        mediaContainerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: mediaContainerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: mediaContainerView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: mediaContainerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: mediaContainerView.trailingAnchor, constant: -16)
        ])
    }

    private func showYouTubeFallback(videoID: String, errorCode: String?) {
        let message = [
            L10n.tr("lesson.detail.youtubeBlocked"),
            errorCode.map { L10n.tr("lesson.detail.youtubeError", $0) },
            L10n.tr("lesson.detail.youtubeOpenHint")
        ]
            .compactMap { $0 }
            .joined(separator: "\n")

        let fallbackImageURL = MediaURLResolver.youtubeThumbnailURL(for: videoID)?.absoluteString
            ?? currentLesson?.thumbnail_url
            ?? course?.thumbnail

        showMediaPlaceholder(message: message, imageURLString: fallbackImageURL)

        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.applyPrimaryStyle()
        openButton.setTitle(L10n.tr("lesson.detail.openYoutube"), for: .normal)
        openButton.addAction(UIAction { [weak self] _ in
            self?.openYouTube(videoID: videoID)
        }, for: .touchUpInside)
        mediaContainerView.addSubview(openButton)

        NSLayoutConstraint.activate([
            openButton.centerXAnchor.constraint(equalTo: mediaContainerView.centerXAnchor),
            openButton.bottomAnchor.constraint(equalTo: mediaContainerView.bottomAnchor, constant: -20),
            openButton.leadingAnchor.constraint(greaterThanOrEqualTo: mediaContainerView.leadingAnchor, constant: 20),
            openButton.trailingAnchor.constraint(lessThanOrEqualTo: mediaContainerView.trailingAnchor, constant: -20),
            openButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func openYouTube(videoID: String) {
        let appURL = URL(string: "youtube://www.youtube.com/watch?v=\(videoID)")
        let webURL = MediaURLResolver.youtubeWatchURL(for: videoID)

        if let appURL {
            UIApplication.shared.open(appURL, options: [:]) { success in
                guard !success, let webURL else { return }
                UIApplication.shared.open(webURL)
            }
            return
        }

        if let webURL {
            UIApplication.shared.open(webURL)
        }
    }


    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == youtubeMessageName {
            guard !isAdminPreviewMode else { return }
            guard message.body as? String == "ended" else { return }
            guard !didAutoTrackCurrentLesson else { return }
            markCurrentLessonCompleted(showSuccessMessage: true)
            return
        }

        if message.name == youtubeErrorMessageName,
           let currentLesson,
           let videoURL = currentLesson.video_url,
           let videoID = MediaURLResolver.extractedYouTubeVideoID(from: videoURL) {
            let code = String(describing: message.body)
            showYouTubeFallback(videoID: videoID, errorCode: code)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lessons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LessonRowTableViewCell.reuseIdentifier, for: indexPath) as? LessonRowTableViewCell else {
            return UITableViewCell()
        }
        let lesson = lessons[indexPath.row]
        cell.configure(
            lesson: lesson,
            completed: completedLessonIDs.contains(lesson.id),
            locked: !isUnlocked(lesson),
            current: lesson.id == currentLesson?.id
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let lesson = lessons[indexPath.row]
        if isAdminPreviewMode {
            currentLesson = lesson
            updateUI()
            return
        }
        guard isUnlocked(lesson) else {
            showError(message: L10n.tr("lesson.detail.lockedError"))
            return
        }
        currentLesson = lesson
        updateUI()
    }
}
