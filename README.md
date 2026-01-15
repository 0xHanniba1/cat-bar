# CatBar 养猫

> 一只住在 Mac 状态栏的像素猫，靠你专注工作来喂养

CatBar 是一款 macOS 菜单栏应用，将番茄钟专注计时与虚拟宠物养成相结合。完成专注工作来喂养你的像素猫咪，让时间管理变得有趣。

## 特性

- **像素猫咪** - 一只可爱的像素猫在菜单栏奔跑，会根据饥饿程度改变行为
- **番茄钟计时** - 支持 15/25/45/60 分钟专注，可自定义时长
- **饱食度系统** - 完成专注喂养猫咪，猫咪会随时间饥饿
- **倒计时显示** - 专注中在菜单栏显示剩余时间
- **数据统计** - 追踪专注时间、番茄数、连续天数

## 截图

<!-- TODO: 添加应用截图 -->

## 安装

### 系统要求

- macOS 13.0 或更高版本

### 从源码构建

1. 克隆仓库：
   ```bash
   git clone https://github.com/your-username/cat-bar.git
   cd cat-bar
   ```

2. 使用 Xcode 打开项目：
   ```bash
   open CatBar.xcodeproj
   ```

3. 在 Xcode 中选择 `Product > Build` 构建项目

4. 运行应用或将构建产物复制到 `/Applications` 目录

## 使用方法

### 基本操作

1. 启动应用后，猫咪会出现在状态栏
2. 点击猫咪打开菜单，选择专注时长开始计时
3. 完成专注后猫咪会获得食物，饱食度上升
4. 保持猫咪吃饱，它会在菜单栏来回奔跑

### 饱食度说明

| 状态 | 饱食度 | 猫咪表现 |
|-----|-------|---------|
| 活泼 | 70-100% | 快速奔跑 |
| 普通 | 30-70% | 正常移动 |
| 饥饿 | 0-30% | 缓慢移动 |

### 饱食度衰减与奖励规则

- **符号定义**：
  - `S`：当前饱食度（0-100）
  - `t`：距离上次喂食的分钟数（可为离线累计分钟）
  - `d`：衰减速率（0.5 %/分钟）
  - `m`：一次专注的分钟数
- **饱食度衰减公式**：
  - `S' = clamp(S - d * t, 0, 100)`
- **专注奖励公式**（完成一次专注后可喂食获得饱食度）：
  - `reward(m) = 15`，当 `0 <= m < 20`
  - `reward(m) = 25`，当 `20 <= m < 40`
  - `reward(m) = 40`，当 `40 <= m < 55`
  - `reward(m) = 50`，当 `m >= 55`
  - 喂食后：`S'' = clamp(S' + reward(m), 0, 100)`

## 项目结构

```
CatBar/
├── Sources/
│   ├── CatBarApp.swift          # 应用入口
│   ├── AppDelegate.swift        # 应用生命周期
│   ├── CatState.swift           # 猫咪状态管理
│   ├── TimerManager.swift       # 计时器逻辑
│   ├── StatusBarController.swift # 状态栏控制
│   ├── PixelCatView.swift       # 像素猫渲染
│   ├── SettingsView.swift       # 设置界面
│   └── StatsView.swift          # 统计界面
├── Resources/                    # 资源文件
└── Info.plist                   # 应用配置
```

## 技术栈

- Swift 5
- SwiftUI + AppKit
- UserDefaults (本地存储)
- UserNotifications (系统通知)
- Charts (数据可视化)

## 文档

- [功能描述文档](docs/FEATURES.md) - 详细的功能说明
- [设计文档](docs/plans/2026-01-14-cat-bar-design.md) - 产品设计规格

## 开发

### 构建

```bash
# 使用 xcodebuild 构建
xcodebuild -project CatBar.xcodeproj -scheme CatBar -configuration Release build
```

### 调试

在 Xcode 中打开项目，选择目标设备后点击运行按钮。

## 已知问题

- 暂无

## 待办

- 需要更合适的应用图标（待补）

## 许可证

MIT License

## 致谢

- 灵感来源于番茄工作法和虚拟宠物游戏
- 感谢所有为提高工作效率而努力的人们
- 猫咪素材来源于 https://github.com/Kyome22/RunCat365
