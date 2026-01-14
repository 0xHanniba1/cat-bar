import SwiftUI

struct SettingsView: View {
    @ObservedObject var catState: CatState
    @ObservedObject var timerManager: TimerManager

    @State private var newDuration: String = ""

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

                HStack {
                    TextField("自定义分钟数", text: $newDuration)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)

                    Button("添加") {
                        if let minutes = Int(newDuration), minutes > 0, minutes <= 180 {
                            timerManager.addDuration(minutes)
                            newDuration = ""
                        }
                    }
                    .disabled(Int(newDuration) == nil)
                }
            }

            // 猫咪选择
            Section("选择猫咪") {
                ForEach(CatType.allCases, id: \.self) { catType in
                    HStack {
                        catIcon(for: catType)

                        VStack(alignment: .leading) {
                            Text(catType.rawValue)
                                .fontWeight(catState.currentCat == catType ? .bold : .regular)

                            if !catState.unlockedCats.contains(catType) {
                                Text("需要 \(Int(catType.unlockHours)) 小时专注解锁")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if catState.unlockedCats.contains(catType) {
                            if catState.currentCat == catType {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Button("选择") {
                                    catState.currentCat = catType
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                            }
                        } else {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
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
        }
        .formStyle(.grouped)
        .frame(minWidth: 320)
    }

    private func catIcon(for type: CatType) -> some View {
        let emoji: String
        switch type {
        case .orange: emoji = "🐱"
        case .black: emoji = "🐈‍⬛"
        case .white: emoji = "🐈"
        case .cow: emoji = "🐄"
        }

        return Text(emoji)
            .font(.title2)
            .grayscale(catState.unlockedCats.contains(type) ? 0 : 1)
    }

    private func formatHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60
        return String(format: "%.1f 小时", hours)
    }
}

#Preview {
    SettingsView(catState: CatState(), timerManager: TimerManager(catState: CatState()))
}
