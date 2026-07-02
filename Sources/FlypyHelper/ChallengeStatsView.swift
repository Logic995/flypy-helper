import Charts
import SwiftUI

struct ChallengeStatsView: View {
    @ObservedObject var store: ChallengeHistoryStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var presentedDays: [DailyChallengeStats] = []

    private var recentDays: [DailyChallengeStats] {
        Array(store.days.suffix(30))
    }

    var body: some View {
        VStack(spacing: 18) {
            header
            summary
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 6)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.24), value: appeared)

            if store.days.isEmpty {
                ContentUnavailableView(
                    "还没有挑战记录",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("完成一局 60 秒挑战后，这里会显示每日趋势。")
                )
                .frame(maxHeight: .infinity)
                .opacity(appeared ? 1 : 0)
            } else {
                charts
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.28).delay(0.06), value: appeared)
                historyList
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.28).delay(0.12), value: appeared)
            }
        }
        .padding(22)
        .frame(width: 760, height: 540)
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear(perform: presentContent)
        .onChange(of: store.days) { _, _ in
            updatePresentedDays()
        }
    }

    private var header: some View {
        HStack {
            Text("挑战统计")
                .font(.system(size: 24, weight: .semibold, design: .serif))

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(.primary.opacity(0.06), in: Circle())
            }
            .buttonStyle(StatsCloseButtonStyle())
            .accessibilityLabel("关闭统计")
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            StatsSummaryCard(title: "今日局数", value: "\(store.today?.rounds ?? 0)")
            StatsSummaryCard(title: "今日字速", value: "\(store.today?.averageCharactersPerMinute ?? 0)")
            StatsSummaryCard(title: "连续练习", value: "\(store.currentStreak) 天")
            StatsSummaryCard(title: "历史最佳", value: "\(store.allTimeBestCPM) 字/分")
            StatsSummaryCard(title: "累计时间", value: durationText(store.totalDuration))
        }
    }

    private var charts: some View {
        HStack(spacing: 12) {
            StatsChartCard(title: "近 30 天字速") {
                Chart(presentedDays) { stats in
                    LineMark(
                        x: .value("日期", stats.day),
                        y: .value("字/分", stats.averageCharactersPerMinute)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日期", stats.day),
                        y: .value("字/分", stats.averageCharactersPerMinute)
                    )
                    .foregroundStyle(.blue)
                }
            }

            StatsChartCard(title: "每日正确字数") {
                Chart(presentedDays) { stats in
                    BarMark(
                        x: .value("日期", stats.day),
                        y: .value("正确字数", stats.correctCharacters),
                        width: .fixed(8)
                    )
                    .foregroundStyle(.purple.opacity(0.65))
                    .cornerRadius(3)
                }
            }
        }
        .frame(height: 150)
    }

    private var historyList: some View {
        VStack(spacing: 0) {
            historyHeader
            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.days.reversed()) { stats in
                        ChallengeHistoryRow(stats: stats)

                        Divider().opacity(0.5)
                    }
                }
            }
        }
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var historyHeader: some View {
        HStack {
            Text("日期").frame(width: 78, alignment: .leading)
            Text("局数")
            Spacer()
            Text("平均速度").frame(width: 88, alignment: .trailing)
            Text("准确率").frame(width: 58, alignment: .trailing)
            Text("最高分").frame(width: 96, alignment: .trailing)
            Text("正确字数").frame(width: 72, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 30)
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let minutes = Int((duration / 60).rounded())
        return minutes < 60 ? "\(minutes) 分钟" : String(format: "%.1f 小时", duration / 3600)
    }

    private func presentContent() {
        if reduceMotion {
            appeared = true
            presentedDays = recentDays
            return
        }

        presentedDays = []
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.24)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                presentedDays = recentDays
            }
        }
    }

    private func updatePresentedDays() {
        if reduceMotion {
            presentedDays = recentDays
        } else {
            withAnimation(.easeOut(duration: 0.35)) {
                presentedDays = recentDays
            }
        }
    }
}

private struct StatsSummaryCard: View {
    let title: String
    let value: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(isHovered ? 0.065 : 0.045), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(isHovered ? 0.22 : 0), lineWidth: 1)
        }
        .offset(y: isHovered && !reduceMotion ? -1 : 0)
        .shadow(color: .black.opacity(isHovered ? 0.07 : 0), radius: 7, y: 3)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) {
                isHovered = hovering
            }
        }
    }
}

private struct StatsChartCard<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isHovered ? Color.blue : Color.secondary)
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.primary.opacity(isHovered ? 0.052 : 0.035), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(isHovered ? 0.18 : 0), lineWidth: 1)
        }
        .offset(y: isHovered && !reduceMotion ? -1 : 0)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) {
                isHovered = hovering
            }
        }
    }
}

private struct ChallengeHistoryRow: View {
    let stats: DailyChallengeStats
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        HStack {
            Text(stats.day, format: .dateTime.month().day())
                .frame(width: 78, alignment: .leading)
            Text("\(stats.rounds) 局")
            Spacer()
            Text("\(stats.averageCharactersPerMinute) 字/分")
                .frame(width: 88, alignment: .trailing)
            Text("\(Int((stats.accuracy * 100).rounded()))%")
                .frame(width: 58, alignment: .trailing)
            Text("最高 \(stats.bestScore)")
                .frame(width: 96, alignment: .trailing)
            Text("\(stats.correctCharacters) 字")
                .frame(width: 72, alignment: .trailing)
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Color.blue.opacity(isHovered ? 0.07 : 0))
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }
}

private struct StatsCloseButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? Color.primary : Color.secondary)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
