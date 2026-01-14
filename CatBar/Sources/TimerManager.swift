import Foundation
import UserNotifications
import Combine
import AppKit

class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0

    // 可用的专注时长（分钟）
    @Published var availableDurations: [Int] {
        didSet {
            UserDefaults.standard.set(availableDurations, forKey: "availableDurations")
        }
    }

    // 设置
    @Published var notificationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationEnabled, forKey: "notificationEnabled")
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }

    private var timer: Timer?
    private var catState: CatState

    var formattedTimeRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    init(catState: CatState) {
        self.catState = catState

        // 加载设置
        let savedDurations = UserDefaults.standard.array(forKey: "availableDurations") as? [Int]
        self.availableDurations = savedDurations ?? [15, 25, 45, 60]

        self.notificationEnabled = UserDefaults.standard.object(forKey: "notificationEnabled") as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true

        // 请求通知权限
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error)")
            }
        }
    }

    func start(minutes: Int) {
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0
        totalSeconds = 0
    }

    private func tick() {
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            complete()
        }
    }

    private func complete() {
        timer?.invalidate()
        timer = nil
        isRunning = false

        let completedMinutes = totalSeconds / 60

        // 通知猫咪状态
        catState.completeFocus(minutes: completedMinutes)

        // 发送通知
        if notificationEnabled {
            sendNotification()
        }

        // 播放声音
        if soundEnabled {
            playSound()
        }

        remainingSeconds = 0
        totalSeconds = 0
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "专注完成！"
        content.body = "猫咪的食物准备好了~ 点击状态栏喂食吧！"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func playSound() {
        // 使用系统声音
        NSSound(named: "Glass")?.play()
    }

    func addDuration(_ minutes: Int) {
        if !availableDurations.contains(minutes) {
            availableDurations.append(minutes)
            availableDurations.sort()
        }
    }

    func removeDuration(_ minutes: Int) {
        availableDurations.removeAll { $0 == minutes }
    }
}
