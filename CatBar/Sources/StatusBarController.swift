import Cocoa
import SwiftUI

// MARK: - 猫咪速度状态
enum CatSpeedState: String {
    case stopped = "cat-stop"      // 饿昏了 (饱食度 < 20%)
    case slow = "catrun-a"         // 慢速跑 (饱食度 20-50%)
    case normal = "catrun-b"       // 正常跑 (饱食度 50-70%)
    case fast = "catrun-c"         // 快速跑 (饱食度 > 70%)

    // 帧数
    var frameCount: Int {
        switch self {
        case .stopped: return 8
        case .slow: return 5
        case .normal: return 5
        case .fast: return 5
        }
    }

    // 动画速度（秒/帧）
    var animationInterval: TimeInterval {
        switch self {
        case .stopped: return 0.3
        case .slow: return 0.15
        case .normal: return 0.1
        case .fast: return 0.07
        }
    }

    var frameNames: [String] {
        return (0..<frameCount).map { "\(rawValue)-\($0)" }
    }
}

// MARK: - 状态栏控制器
class StatusBarController: NSObject {
    private enum RunDirection {
        case left
        case right
    }

    private var statusItem: NSStatusItem!
    private var timerStatusItem: NSStatusItem!
    private var catState: CatState
    private var timerManager: TimerManager
    private var animationTimer: Timer?
    private let animationEnabled = true
    private let statusItemPadding: CGFloat = 2
    private let overlayGroundOffset: CGFloat = -3
    private let statusItemHiddenImage = NSImage(size: NSSize(width: 1, height: 1))
    private var overlayWindow: NSWindow?
    private var overlayImageView: NSImageView?
    private var overlayPositionX: CGFloat = 0
    private var overlayImageSize: NSSize = .zero
    private var overlayStartX: CGFloat?
    private var overlayLeftInset: CGFloat = 1000 {
        didSet {
            UserDefaults.standard.set(overlayLeftInset, forKey: "overlayLeftInset")
        }
    }
    private var runDirection: RunDirection = .left

    // 动画状态
    private var currentFrame = 0
    private var currentSpeedState: CatSpeedState = .fast

    // 缓存的帧图片
    private var frameImages: [CatSpeedState: [NSImage]] = [:]
    private var leftFrameImages: [CatSpeedState: [NSImage]] = [:]

    // 弹出窗口
    private var statsWindow: NSWindow?
    private var settingsWindow: NSWindow?

    init(catState: CatState, timerManager: TimerManager) {
        self.catState = catState
        self.timerManager = timerManager
        super.init()

        let savedInset = UserDefaults.standard.double(forKey: "overlayLeftInset")
        if savedInset > 0 {
            overlayLeftInset = savedInset
        }

        loadFrameImages()
        setupStatusBar()
        setupOverlayWindow()
        if animationEnabled {
            startAnimation()
        } else {
            updateSpeedState()
            currentFrame = 0
            updateButtonImage()
        }
    }

    // MARK: - 加载帧图片
    private func loadFrameImages() {
        for state in [CatSpeedState.stopped, .slow, .normal, .fast] {
            var frames: [NSImage] = []
            for name in state.frameNames {
                if let image = NSImage(named: name) {
                    frames.append(image)
                }
            }
            frameImages[state] = frames
        }

        var leftFastFrames: [NSImage] = []
        for i in 0..<CatSpeedState.fast.frameCount {
            if let image = NSImage(named: "catrun-c-left-\(i)") {
                leftFastFrames.append(image)
            }
        }
        if !leftFastFrames.isEmpty {
            leftFrameImages[.fast] = leftFastFrames
        }

        var leftSlowFrames: [NSImage] = []
        for i in 0..<CatSpeedState.slow.frameCount {
            if let image = NSImage(named: "catrun-a-left-\(i)") {
                leftSlowFrames.append(image)
            }
        }
        if !leftSlowFrames.isEmpty {
            leftFrameImages[.slow] = leftSlowFrames
        }

        var leftNormalFrames: [NSImage] = []
        for i in 0..<CatSpeedState.normal.frameCount {
            if let image = NSImage(named: "catrun-b-left-\(i)") {
                leftNormalFrames.append(image)
            }
        }
        if !leftNormalFrames.isEmpty {
            leftFrameImages[.normal] = leftNormalFrames
        }
    }

    // MARK: - 设置状态栏
    private func setupStatusBar() {
        timerStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let timerButton = timerStatusItem.button {
            timerButton.imagePosition = .imageOnly
            timerButton.title = ""
        }
        timerStatusItem.isVisible = false

        if let button = statusItem.button {
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleNone
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            // 设置初始图片
            updateButtonImage()
        }
    }

    private func setupOverlayWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .statusBar
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]

        let imageView = NSImageView(frame: window.contentView?.bounds ?? .zero)
        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignBottom
        imageView.animates = false
        window.contentView = imageView

        overlayWindow = window
        overlayImageView = imageView
    }

    // MARK: - 更新按钮图片
    private func updateButtonImage() {
        guard let button = statusItem.button,
              let frames = currentFrames(for: currentSpeedState),
              !frames.isEmpty else { return }

        let safeFrame = currentFrame % frames.count
        let image = frames[safeFrame]

        let barHeight = NSStatusBar.system.thickness
        let targetHeight = max(barHeight - statusItemPadding * 2, 1)
        let scale = targetHeight / image.size.height
        let targetWidth = image.size.width * scale

        let scaledImage = NSImage(size: NSSize(width: targetWidth, height: targetHeight))
        scaledImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        scaledImage.unlockFocus()
        scaledImage.isTemplate = false

        if currentSpeedState == .stopped {
            statusItem.length = max(NSStatusItem.squareLength, targetWidth + statusItemPadding * 2)
            button.image = scaledImage
            hideOverlayWindow()
        } else {
            statusItem.length = NSStatusItem.variableLength
            button.image = statusItemHiddenImage
            updateOverlayWindow(with: scaledImage, barHeight: barHeight)
        }

        // 更新标题（显示状态信息）
        updateButtonTitle()
    }

    // MARK: - 更新按钮标题
    private func updateButtonTitle() {
        guard let button = statusItem.button else { return }
        if timerManager.isRunning {
            button.imagePosition = .imageLeft
            button.title = ""
            timerStatusItem.button?.title = timerManager.formattedTimeRemaining
            timerStatusItem.isVisible = true
        } else {
            button.imagePosition = .imageOnly
            button.title = ""
            timerStatusItem.button?.title = ""
            timerStatusItem.isVisible = false
        }
    }

    // MARK: - 开始动画
    private func startAnimation() {
        updateSpeedState()
        restartAnimationTimer()
    }

    private func restartAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: currentSpeedState.animationInterval, repeats: true) { [weak self] _ in
            self?.advanceFrame()
        }
    }

    private func advanceFrame() {
        // 检查是否需要更新速度状态
        let oldState = currentSpeedState
        updateSpeedState()

        if oldState != currentSpeedState {
            currentFrame = 0
            restartAnimationTimer()
            if currentSpeedState == .stopped {
                overlayPositionX = 0
                overlayStartX = nil
                runDirection = .left
            }
        }

        // 推进帧
        if let frames = currentFrames(for: currentSpeedState) {
            currentFrame = (currentFrame + 1) % frames.count
        }

        advanceOverlayPosition()
        updateButtonImage()
    }

    private func updateSpeedState() {
        if catState.satiety < 20 {
            currentSpeedState = .stopped
        } else if catState.satiety < 50 {
            currentSpeedState = .slow
        } else if catState.satiety < 70 {
            currentSpeedState = .normal
        } else {
            currentSpeedState = .fast
        }
    }

    private func advanceOverlayPosition() {
        guard currentSpeedState != .stopped,
              let screenFrame = NSScreen.main?.frame,
              overlayImageSize.width > 0 else { return }
        let step: CGFloat
        switch currentSpeedState {
        case .slow:
            step = 2
        case .normal:
            step = 5
        case .fast:
            step = 7
        case .stopped:
            step = 0
        }
        let leftBound = screenFrame.minX + overlayLeftInset
        let startX = overlayStartX ?? screenFrame.maxX

        if runDirection == .left {
            overlayPositionX -= step
            if overlayPositionX <= leftBound - overlayImageSize.width {
                overlayPositionX = leftBound - overlayImageSize.width
                runDirection = .right
            }
        } else {
            overlayPositionX += step
            if overlayPositionX >= startX {
                overlayPositionX = startX
                runDirection = .left
            }
        }
    }

    private func updateOverlayWindow(with image: NSImage, barHeight: CGFloat) {
        guard let screenFrame = NSScreen.main?.frame,
              let window = overlayWindow,
              let imageView = overlayImageView else { return }
        let imageSize = image.size
        let statusMinX = statusItem.button?.window?.frame.minX ?? screenFrame.maxX
        overlayStartX = statusMinX
        if overlayImageSize == .zero {
            overlayImageSize = imageSize
            overlayPositionX = overlayStartX ?? screenFrame.maxX
            runDirection = .left
        } else {
            overlayImageSize = imageSize
        }

        let originY = screenFrame.maxY - barHeight + overlayGroundOffset
        let frame = NSRect(x: overlayPositionX, y: originY, width: imageSize.width, height: barHeight)
        window.setFrame(frame, display: true)
        imageView.frame = NSRect(x: 0, y: 0, width: imageSize.width, height: barHeight)
        imageView.image = image
        window.orderFrontRegardless()
    }

    private func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
    }

    private func currentFrames(for state: CatSpeedState) -> [NSImage]? {
        if state != .stopped, runDirection == .left, let frames = leftFrameImages[state], !frames.isEmpty {
            return frames
        }
        return frameImages[state]
    }

    // MARK: - 点击处理
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showMainMenu()
        } else {
            if catState.pendingFood {
                feedCat()
            } else {
                showMainMenu()
            }
        }
    }

    private func feedCat() {
        catState.feed()
        NSSound(named: "Pop")?.play()
        updateButtonTitle()
    }

    @objc private func setSatietyPreset(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        applySatiety(value)
    }

    @objc private func promptCustomSatiety() {
        let alert = NSAlert()
        alert.messageText = "设置饱食度"
        alert.informativeText = "输入 0-100 之间的数值"
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.placeholderString = "例如 60"
        alert.accessoryView = input
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let value = Double(input.stringValue) ?? 0
            applySatiety(value)
        }
    }

    private func applySatiety(_ value: Double) {
        let clamped = max(0, min(100, value))
        catState.satiety = clamped
        catState.save()
        updateSpeedState()
        currentFrame = 0
        updateButtonImage()
    }

    @objc private func setLeftInsetPreset(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        applyLeftInset(value)
    }

    @objc private func promptLeftInset() {
        let alert = NSAlert()
        alert.messageText = "设置左侧起点"
        alert.informativeText = "输入左侧起点偏移（像素）"
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.placeholderString = "例如 800"
        alert.accessoryView = input
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let value = Double(input.stringValue) ?? overlayLeftInset
            applyLeftInset(value)
        }
    }

    private func applyLeftInset(_ value: Double) {
        overlayLeftInset = max(0, value)
        if let screenFrame = NSScreen.main?.frame {
            overlayPositionX = (screenFrame.minX + overlayLeftInset) - overlayImageSize.width
        }
        runDirection = .left
        updateButtonImage()
    }

    // MARK: - 菜单
    private func showMainMenu() {
        let menu = NSMenu()

        // 专注选项
        let focusMenu = NSMenu()
        for duration in timerManager.availableDurations {
            let item = NSMenuItem(title: "\(duration) 分钟", action: #selector(startFocus(_:)), keyEquivalent: "")
            item.target = self
            item.tag = duration
            focusMenu.addItem(item)
        }

        let focusItem = NSMenuItem(title: "开始专注", action: nil, keyEquivalent: "")
        focusItem.submenu = focusMenu
        menu.addItem(focusItem)

        if timerManager.isRunning {
            let cancelItem = NSMenuItem(title: "取消专注", action: #selector(cancelFocus), keyEquivalent: "")
            cancelItem.target = self
            menu.addItem(cancelItem)
        }

        menu.addItem(NSMenuItem.separator())

        if timerManager.isRunning {
            let remainingText = "剩余时间: \(timerManager.formattedTimeRemaining)"
            menu.addItem(NSMenuItem(title: remainingText, action: nil, keyEquivalent: ""))
        }

        // 猫咪状态
        let hungerText = String(format: "饱食度: %.0f%%", catState.satiety)
        menu.addItem(NSMenuItem(title: hungerText, action: nil, keyEquivalent: ""))

        // 统计
        let statsItem = NSMenuItem(title: "统计", action: #selector(showStats), keyEquivalent: "s")
        statsItem.target = self
        menu.addItem(statsItem)

        // 设置
        let settingsItem = NSMenuItem(title: "设置", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func startFocus(_ sender: NSMenuItem) {
        let duration = sender.tag
        timerManager.start(minutes: duration)
        updateButtonTitle()
    }

    @objc private func cancelFocus() {
        timerManager.cancel()
        updateButtonTitle()
    }

    @objc private func showStats() {
        if statsWindow == nil {
            let statsView = StatsView(catState: catState, timerManager: timerManager)
            let hostingController = NSHostingController(rootView: statsView)

            statsWindow = NSWindow(contentViewController: hostingController)
            statsWindow?.title = "专注统计"
            statsWindow?.setContentSize(NSSize(width: 400, height: 500))
            statsWindow?.styleMask = [.titled, .closable, .miniaturizable]
            statsWindow?.center()
        }

        statsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(catState: catState, timerManager: timerManager)
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "设置"
            settingsWindow?.setContentSize(NSSize(width: 350, height: 400))
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.center()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        catState.save()
        NSApp.terminate(nil)
    }
}
