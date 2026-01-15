import Cocoa
import SwiftUI

// MARK: - 猫咪速度状态
enum CatSpeedState: String {
    case stopped = "cat-stop"      // 饿昏了 (饱食度 < 20%)
    case slow = "catrun-a"         // 慢速跑 (饱食度 20-50%)
    case normal = "catrun-b"       // 正常跑 (饱食度 50-70%)
    case fast = "catrun-c"         // 快速跑 (饱食度 > 70%)

    // 图片总宽度
    var totalWidth: CGFloat {
        switch self {
        case .stopped: return 112
        case .slow: return 56
        case .normal: return 63
        case .fast: return 84
        }
    }

    // 帧数
    var frameCount: Int {
        switch self {
        case .stopped: return 5     // cat-stop: 112px
        case .slow: return 4        // catrun-a: 56px
        case .normal: return 5      // catrun-b: 63px (约12.6px每帧)
        case .fast: return 5        // catrun-c: 84px (约16.8px每帧)
        }
    }

    // 每帧的宽度
    var frameWidth: CGFloat {
        return totalWidth / CGFloat(frameCount)
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
}

// MARK: - 状态栏控制器
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var catState: CatState
    private var timerManager: TimerManager
    private var animationTimer: Timer?

    // 动画状态
    private var currentFrame = 0
    private var currentSpeedState: CatSpeedState = .fast

    // 缓存的帧图片
    private var frameImages: [CatSpeedState: [NSImage]] = [:]

    // 弹出窗口
    private var statsWindow: NSWindow?
    private var settingsWindow: NSWindow?

    init(catState: CatState, timerManager: TimerManager) {
        self.catState = catState
        self.timerManager = timerManager
        super.init()

        loadFrameImages()
        setupStatusBar()
        startAnimation()
    }

    // MARK: - 加载帧图片
    private func loadFrameImages() {
        for state in [CatSpeedState.stopped, .slow, .normal, .fast] {
            if let spriteSheet = NSImage(named: state.rawValue) {
                var frames: [NSImage] = []
                let frameWidth = state.frameWidth
                let frameCount = state.frameCount
                let height = spriteSheet.size.height

                // 从精灵图中切分每一帧
                for i in 0..<frameCount {
                    let frameRect = NSRect(x: CGFloat(i) * frameWidth, y: 0, width: frameWidth, height: height)
                    let frameImage = NSImage(size: NSSize(width: frameWidth, height: height))
                    frameImage.lockFocus()
                    spriteSheet.draw(in: NSRect(x: 0, y: 0, width: frameWidth, height: height),
                                    from: frameRect,
                                    operation: .copy,
                                    fraction: 1.0)
                    frameImage.unlockFocus()
                    frames.append(frameImage)
                }

                frameImages[state] = frames
            }
        }
    }

    // MARK: - 设置状态栏
    private func setupStatusBar() {
        // 创建状态栏项目，使用固定宽度
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.imagePosition = .imageLeft
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])

            // 设置初始图片
            updateButtonImage()
        }
    }

    // MARK: - 更新按钮图片
    private func updateButtonImage() {
        guard let button = statusItem.button,
              let frames = frameImages[currentSpeedState],
              !frames.isEmpty else { return }

        let safeFrame = currentFrame % frames.count
        let image = frames[safeFrame]

        // 缩放图片以适应菜单栏（高度约18px）
        let targetHeight: CGFloat = 18
        let scale = targetHeight / image.size.height
        let targetWidth = image.size.width * scale

        let scaledImage = NSImage(size: NSSize(width: targetWidth, height: targetHeight))
        scaledImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        scaledImage.unlockFocus()

        button.image = scaledImage

        // 更新标题（显示状态信息）
        updateButtonTitle()
    }

    // MARK: - 更新按钮标题
    private func updateButtonTitle() {
        guard let button = statusItem.button else { return }

        var title = ""

        if catState.pendingFood {
            title = " 🐟"
        } else if timerManager.isRunning {
            title = " \(timerManager.formattedTimeRemaining)"
        }

        if catState.satiety < 30 {
            title += " 😿"
        }

        button.title = title
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
        }

        // 推进帧
        if let frames = frameImages[currentSpeedState] {
            currentFrame = (currentFrame + 1) % frames.count
        }

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

        // 猫咪状态
        let hungerText = String(format: "饱食度: %.0f%%", catState.satiety)
        menu.addItem(NSMenuItem(title: hungerText, action: nil, keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

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
