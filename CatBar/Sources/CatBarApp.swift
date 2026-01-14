import SwiftUI

@main
struct CatBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 使用 Settings 场景来避免显示主窗口
        Settings {
            EmptyView()
        }
    }
}
