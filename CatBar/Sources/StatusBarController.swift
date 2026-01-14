import Cocoa
import SwiftUI

// MARK: - 像素猫视图
class PixelCatView: NSView {
    var currentFrame = 0
    var facingRight = true
    var pixelSize: CGFloat = 2

    // 橘猫颜色
    private let orangeColor = NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    private let blackColor = NSColor.black
    private let pinkColor = NSColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0)

    // 像素猫跑动帧 (0=透明, 1=橘色, 2=深橘色条纹, 4=黑色眼睛, 5=粉色鼻子)
    // 侧面跑动的猫：头在左边，尾巴在右边，向右跑
    private let runFrames: [[[Int]]] = [
        // 帧1 - 前腿伸出，后腿蹬地
        [
            [0,0,1,1,0,0,0,0,0,0,0,0,0,0,0],
            [0,1,1,1,1,0,0,0,0,0,0,0,1,1,0],
            [0,1,4,1,1,0,0,0,0,0,0,1,1,1,1],
            [0,0,1,5,1,0,0,0,0,0,0,0,1,1,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,1,0,0,0,0,1,0,0,0,0,0,0],
            [0,0,1,1,0,0,0,0,0,1,0,0,0,0,0],
        ],
        // 帧2 - 腿收拢
        [
            [0,0,1,1,0,0,0,0,0,0,0,0,0,0,0],
            [0,1,1,1,1,0,0,0,0,0,0,0,0,1,1],
            [0,1,4,1,1,0,0,0,0,0,0,0,1,1,1],
            [0,0,1,5,1,0,0,0,0,0,0,1,1,1,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,0,0,0,0,0],
            [0,0,0,0,1,1,1,1,0,0,0,0,0,0,0],
            [0,0,0,0,1,0,0,1,0,0,0,0,0,0,0],
        ],
        // 帧3 - 腾空
        [
            [0,0,1,1,0,0,0,0,0,0,0,0,0,0,0],
            [0,1,1,1,1,0,0,0,0,0,0,0,0,0,1],
            [0,1,4,1,1,0,0,0,0,0,0,0,0,1,1],
            [0,0,1,5,1,0,0,0,0,0,0,0,1,1,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
            [0,0,0,1,1,0,0,0,1,1,0,0,0,0,0],
            [0,0,1,0,0,0,0,0,0,0,1,0,0,0,0],
        ],
        // 帧4 - 后腿伸出，前腿收
        [
            [0,0,1,1,0,0,0,0,0,0,0,0,0,0,0],
            [0,1,1,1,1,0,0,0,0,0,0,0,1,1,0],
            [0,1,4,1,1,0,0,0,0,0,0,0,1,1,1],
            [0,0,1,5,1,0,0,0,0,0,0,1,1,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,0,0,0,0,0],
            [0,0,0,0,1,0,0,0,0,1,1,0,0,0,0],
            [0,0,0,0,1,0,0,0,0,0,1,1,0,0,0],
        ],
    ]

    override var isFlipped: Bool { return true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard currentFrame < runFrames.count else { return }

        let frameData = runFrames[currentFrame]

        for (rowIndex, row) in frameData.enumerated() {
            for (colIndex, pixel) in row.enumerated() {
                if pixel == 0 { continue }

                let color: NSColor
                switch pixel {
                case 1: color = orangeColor
                case 4: color = blackColor
                case 5: color = pinkColor
                default: continue
                }

                color.setFill()

                let x: CGFloat
                if facingRight {
                    x = CGFloat(colIndex) * pixelSize
                } else {
                    x = CGFloat(row.count - 1 - colIndex) * pixelSize
                }
                let y = CGFloat(rowIndex) * pixelSize

                let rect = NSRect(x: x, y: y, width: pixelSize, height: pixelSize)
                rect.fill()
            }
        }
    }

    func nextFrame() {
        currentFrame = (currentFrame + 1) % runFrames.count
        needsDisplay = true
    }

    func setDirection(right: Bool) {
        if facingRight != right {
            facingRight = right
            needsDisplay = true
        }
    }
}

// MARK: - 状态栏控制器
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var catState: CatState
    private var timerManager: TimerManager
    private var animationTimer: Timer?
    private var positionTimer: Timer?

    // 猫咪窗口（覆盖在菜单栏上）
    private var catWindow: NSWindow!
    private var catView: PixelCatView!

    // 猫咪位置和方向
    private var catPosition: CGFloat = 100
    private var movingRight = true
    private var catSpeed: CGFloat = 3.0

    // 弹出菜单
    private var statsWindow: NSWindow?
    private var settingsWindow: NSWindow?

    // 屏幕边界
    private var minX: CGFloat = 0
    private var maxX: CGFloat = 0

    init(catState: CatState, timerManager: TimerManager) {
        self.catState = catState
        self.timerManager = timerManager
        super.init()

        setupStatusBar()
        setupCatWindow()
        startAnimations()
    }

    private func setupStatusBar() {
        // 状态栏只显示倒计时和菜单入口
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🐱"
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupCatWindow() {
        // 获取主屏幕
        guard let screen = NSScreen.main else { return }

        let menuBarHeight: CGFloat = 24
        let catWidth: CGFloat = 30  // 15像素 * 2
        let catHeight: CGFloat = 18 // 9像素 * 2

        // 计算边界（留出一些边距）
        minX = 10
        maxX = screen.frame.width - 100  // 留出状态栏图标的空间

        // 创建透明窗口，覆盖在菜单栏上
        let windowRect = NSRect(
            x: catPosition,
            y: screen.frame.height - menuBarHeight,
            width: catWidth,
            height: catHeight
        )

        catWindow = NSWindow(
            contentRect: windowRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // 设置窗口属性
        catWindow.isOpaque = false
        catWindow.backgroundColor = .clear
        catWindow.level = .statusBar  // 和状态栏同层级
        catWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        catWindow.ignoresMouseEvents = true  // 鼠标穿透

        // 创建像素猫视图
        catView = PixelCatView(frame: NSRect(x: 0, y: 0, width: catWidth, height: catHeight))
        catView.pixelSize = 2

        catWindow.contentView?.addSubview(catView)
        catWindow.orderFront(nil)
    }

    private func startAnimations() {
        // 猫咪跑动动画（帧切换）- 快速切换模拟跑步
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCatFrame()
        }

        // 猫咪位置移动 - 流畅移动
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateCatPosition()
        }
    }

    private func updateCatFrame() {
        catView.nextFrame()
        catView.setDirection(right: movingRight)
    }

    private func updateCatPosition() {
        // 根据饥饿状态调整速度
        switch catState.hungerLevel {
        case .full:
            catSpeed = 2.0
        case .normal:
            catSpeed = 1.2
        case .hungry:
            catSpeed = 0.5
        }

        // 移动猫咪
        if movingRight {
            catPosition += catSpeed
            if catPosition >= maxX {
                movingRight = false
                catView.setDirection(right: false)
            }
        } else {
            catPosition -= catSpeed
            if catPosition <= minX {
                movingRight = true
                catView.setDirection(right: true)
            }
        }

        // 更新窗口位置
        var frame = catWindow.frame
        frame.origin.x = catPosition
        catWindow.setFrame(frame, display: true)

        // 更新状态栏显示
        updateStatusBarDisplay()
    }

    private func updateStatusBarDisplay() {
        guard let button = statusItem.button else { return }

        var displayText = ""

        // 如果有待领取的食物
        if catState.pendingFood {
            displayText = "🐟 点击喂食"
        } else if timerManager.isRunning {
            // 显示倒计时
            displayText = "⏱ \(timerManager.formattedTimeRemaining)"
        } else {
            displayText = "🐱"
        }

        // 如果猫咪饿了
        if catState.hungerLevel == .hungry {
            displayText += " 😿"
        }

        button.title = displayText
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showMainMenu()
        } else {
            // 左键点击
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
        updateStatusBarDisplay()
    }

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
        updateStatusBarDisplay()
    }

    @objc private func cancelFocus() {
        timerManager.cancel()
        updateStatusBarDisplay()
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
