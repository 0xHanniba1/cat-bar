import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var catState: CatState!
    var timerManager: TimerManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化猫咪状态和计时器
        catState = CatState()
        timerManager = TimerManager(catState: catState)

        // 创建状态栏控制器
        statusBarController = StatusBarController(catState: catState, timerManager: timerManager)

        // 开始饥饿值衰减
        catState.startHungerDecay()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 保存状态
        catState.save()
    }
}
