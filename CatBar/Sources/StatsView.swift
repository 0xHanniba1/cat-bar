import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var catState: CatState
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 今日概览
                todayOverview

                Divider()

                // 每日柱状图
                weeklyChart

                Divider()

                // 历史记录
                historySection
            }
            .padding()
        }
        .frame(minWidth: 380)
    }

    private var todayOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日概览")
                .font(.headline)

            HStack(spacing: 20) {
                StatCard(
                    title: "今日专注",
                    value: formatMinutes(todayFocusMinutes),
                    icon: "clock.fill"
                )

                StatCard(
                    title: "完成番茄钟",
                    value: "\(catState.totalPomodoros)",
                    icon: "checkmark.circle.fill"
                )

                StatCard(
                    title: "连续天数",
                    value: "\(catState.streakDays) 天",
                    icon: "flame.fill"
                )
            }
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("过去 7 天")
                .font(.headline)

            // 简单的柱状图（使用 Charts 框架）
            Chart(weeklyData) { item in
                BarMark(
                    x: .value("日期", item.day),
                    y: .value("分钟", item.minutes)
                )
                .foregroundStyle(Color.orange.gradient)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史记录")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("累计专注时长")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatMinutes(catState.totalFocusMinutes))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("累计番茄钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(catState.totalPomodoros) 个")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }

    // 计算今日专注时长（简化版，实际需要记录每日数据）
    private var todayFocusMinutes: Int {
        // TODO: 实现每日数据存储
        return catState.totalFocusMinutes // 暂时返回总时长
    }

    // 模拟周数据（实际需要从存储中读取）
    private var weeklyData: [DayData] {
        let days = ["一", "二", "三", "四", "五", "六", "日"]
        return days.enumerated().map { index, day in
            DayData(day: day, minutes: Int.random(in: 0...120)) // 模拟数据
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)小时\(mins)分钟"
        } else {
            return "\(mins)分钟"
        }
    }
}

struct DayData: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Int
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    StatsView(catState: CatState(), timerManager: TimerManager(catState: CatState()))
}
