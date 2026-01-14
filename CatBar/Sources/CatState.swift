import Foundation
import Combine

enum HungerLevel {
    case full    // 70-100%
    case normal  // 30-70%
    case hungry  // 0-30%
}

enum CatType: String, Codable, CaseIterable {
    case orange = "橘猫"
    case black = "黑猫"
    case white = "白猫"
    case cow = "奶牛猫"

    var unlockHours: Double {
        switch self {
        case .orange: return 0
        case .black: return 5
        case .white: return 15
        case .cow: return 30
        }
    }
}

class CatState: ObservableObject {
    // 饱食度 0-100
    @Published var satiety: Double {
        didSet {
            UserDefaults.standard.set(satiety, forKey: "satiety")
        }
    }

    // 当前选择的猫咪
    @Published var currentCat: CatType {
        didSet {
            UserDefaults.standard.set(currentCat.rawValue, forKey: "currentCat")
        }
    }

    // 解锁的猫咪
    @Published var unlockedCats: Set<CatType> {
        didSet {
            let array = unlockedCats.map { $0.rawValue }
            UserDefaults.standard.set(array, forKey: "unlockedCats")
        }
    }

    // 累计专注时长（分钟）
    @Published var totalFocusMinutes: Int {
        didSet {
            UserDefaults.standard.set(totalFocusMinutes, forKey: "totalFocusMinutes")
            checkUnlocks()
        }
    }

    // 累计完成的番茄钟数
    @Published var totalPomodoros: Int {
        didSet {
            UserDefaults.standard.set(totalPomodoros, forKey: "totalPomodoros")
        }
    }

    // 待领取的食物
    @Published var pendingFood: Bool = false

    // 待领取食物的价值（恢复多少饱食度）
    @Published var pendingFoodValue: Double = 0

    // 上次喂食时间
    private var lastFeedTime: Date

    // 饥饿衰减定时器
    private var hungerTimer: Timer?

    // 连续专注天数
    @Published var streakDays: Int {
        didSet {
            UserDefaults.standard.set(streakDays, forKey: "streakDays")
        }
    }

    // 上次专注日期
    private var lastFocusDate: Date? {
        didSet {
            if let date = lastFocusDate {
                UserDefaults.standard.set(date, forKey: "lastFocusDate")
            }
        }
    }

    var hungerLevel: HungerLevel {
        if satiety >= 70 {
            return .full
        } else if satiety >= 30 {
            return .normal
        } else {
            return .hungry
        }
    }

    init() {
        // 从 UserDefaults 加载数据 - 必须先初始化所有存储属性
        let savedSatiety = UserDefaults.standard.double(forKey: "satiety")
        self.satiety = savedSatiety == 0 ? 100 : savedSatiety // 新用户初始满饱食度

        let catName = UserDefaults.standard.string(forKey: "currentCat") ?? "橘猫"
        self.currentCat = CatType(rawValue: catName) ?? .orange

        let unlockedArray = UserDefaults.standard.stringArray(forKey: "unlockedCats") ?? ["橘猫"]
        var cats = Set(unlockedArray.compactMap { CatType(rawValue: $0) })
        if cats.isEmpty {
            cats.insert(.orange)
        }
        self.unlockedCats = cats

        self.totalFocusMinutes = UserDefaults.standard.integer(forKey: "totalFocusMinutes")
        self.totalPomodoros = UserDefaults.standard.integer(forKey: "totalPomodoros")
        self.streakDays = UserDefaults.standard.integer(forKey: "streakDays")
        self.lastFocusDate = UserDefaults.standard.object(forKey: "lastFocusDate") as? Date
        self.lastFeedTime = UserDefaults.standard.object(forKey: "lastFeedTime") as? Date ?? Date()

        // 计算离线期间的饥饿衰减（所有属性初始化完成后）
        let now = Date()
        let minutesSinceLastFeed = now.timeIntervalSince(lastFeedTime) / 60
        let decay = minutesSinceLastFeed * 0.5
        self.satiety = max(0, self.satiety - decay)
    }

    func startHungerDecay() {
        // 每分钟降低 0.5% 饱食度
        hungerTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.satiety = max(0, self.satiety - 0.5)
        }
    }

    private func calculateOfflineHungerDecay() {
        let now = Date()
        let minutesSinceLastFeed = now.timeIntervalSince(lastFeedTime) / 60

        // 每分钟降低 0.5%
        let decay = minutesSinceLastFeed * 0.5
        satiety = max(0, satiety - decay)
    }

    func completeFocus(minutes: Int) {
        // 计算食物价值
        switch minutes {
        case 0..<20:
            pendingFoodValue = 15
        case 20..<40:
            pendingFoodValue = 25
        case 40..<55:
            pendingFoodValue = 40
        default:
            pendingFoodValue = 50
        }

        pendingFood = true

        // 更新统计
        totalFocusMinutes += minutes
        totalPomodoros += 1

        // 更新连续天数
        updateStreak()
    }

    func feed() {
        guard pendingFood else { return }

        satiety = min(100, satiety + pendingFoodValue)
        pendingFood = false
        pendingFoodValue = 0
        lastFeedTime = Date()

        UserDefaults.standard.set(lastFeedTime, forKey: "lastFeedTime")
    }

    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = lastFocusDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // 连续
                streakDays += 1
            } else if daysDiff > 1 {
                // 断了
                streakDays = 1
            }
            // daysDiff == 0 表示今天已经专注过，不变
        } else {
            streakDays = 1
        }

        lastFocusDate = Date()
    }

    private func checkUnlocks() {
        let totalHours = Double(totalFocusMinutes) / 60

        for catType in CatType.allCases {
            if totalHours >= catType.unlockHours && !unlockedCats.contains(catType) {
                unlockedCats.insert(catType)
                // TODO: 显示解锁通知
            }
        }
    }

    func save() {
        UserDefaults.standard.set(satiety, forKey: "satiety")
        UserDefaults.standard.set(currentCat.rawValue, forKey: "currentCat")
        UserDefaults.standard.set(Array(unlockedCats.map { $0.rawValue }), forKey: "unlockedCats")
        UserDefaults.standard.set(totalFocusMinutes, forKey: "totalFocusMinutes")
        UserDefaults.standard.set(totalPomodoros, forKey: "totalPomodoros")
        UserDefaults.standard.set(lastFeedTime, forKey: "lastFeedTime")
    }
}
