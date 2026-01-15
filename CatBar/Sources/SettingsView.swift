import SwiftUI

struct SettingsView: View {
    @ObservedObject var catState: CatState
    @ObservedObject var timerManager: TimerManager

    @State private var newDuration: String = ""
    @State private var debugSatietyText: String = ""
    @State private var debugLeftInsetText: String = ""

    var body: some View {
        Form {
            // 通知设置
            Section("通知") {
                Toggle("系统通知", isOn: $timerManager.notificationEnabled)
                Toggle("音效提示", isOn: $timerManager.soundEnabled)
            }

            // 专注时长设置
            Section("专注时长") {
                ForEach(timerManager.availableDurations, id: \.self) { duration in
                    HStack {
                        Text("\(duration) 分钟")
                        Spacer()
                        if timerManager.availableDurations.count > 1 {
                            Button(action: {
                                timerManager.removeDuration(duration)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("自定义分钟数")
                        .frame(width: 110, alignment: .leading)
                    TextField("例如 25", text: $newDuration)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                    Spacer()
                    Button("添加") {
                        if let minutes = Int(newDuration), minutes > 0, minutes <= 180 {
                            timerManager.addDuration(minutes)
                            newDuration = ""
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(minWidth: 56)
                    .disabled(Int(newDuration) == nil)
                }
            }

            // 关于
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("累计专注")
                    Spacer()
                    Text(formatHours(catState.totalFocusMinutes))
                        .foregroundColor(.secondary)
                }
            }

            // 调试
            Section("调试（测试用）") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 12) {
                        Text("饱食度")
                            .frame(width: 70, alignment: .leading)
                        TextField("0-100", text: $debugSatietyText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        Spacer()
                        Button("应用") {
                            if let value = Double(debugSatietyText) {
                                catState.satiety = max(0, min(100, value))
                                catState.save()
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(alignment: .center, spacing: 12) {
                        Text("左侧起点")
                            .frame(width: 70, alignment: .leading)
                        TextField("像素", text: $debugLeftInsetText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        Spacer()
                        Button("应用") {
                            if let value = Double(debugLeftInsetText) {
                                UserDefaults.standard.set(max(0, value), forKey: "overlayLeftInset")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Text("用于测试动画状态与跑动范围，重启应用后生效。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 320)
    }

    private func formatHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60
        return String(format: "%.1f 小时", hours)
    }
}

#Preview {
    SettingsView(catState: CatState(), timerManager: TimerManager(catState: CatState()))
}
