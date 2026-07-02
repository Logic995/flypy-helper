import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject private var engine: ChallengeEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onReturn: () -> Void
    let onShowStats: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            topBar
            promptCard
            KeyboardLayoutView(expectedKey: engine.expectedNextKey, errorKey: engine.errorKey)
        }
        .padding(22)
        .background(appBackground)
        .overlay {
            KeyCaptureView(
                onKey: { engine.handle($0) },
                onEscape: onClose
            )
            .frame(width: 0, height: 0)
        }
    }

    private var topBar: some View {
        HStack(spacing: 22) {
            stat(timeText, width: 88)
            stat(engine.accuracyText, width: 100)
            stat("字/分 \(engine.charactersPerMinute)", width: 68)
            stat("得分 \(engine.score)", width: 84)

            Text("连击 \(engine.combo)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(width: 80)
                .background(.orange.opacity(0.12), in: Capsule())
                .opacity(engine.combo > 0 ? 1 : 0)
                .offset(y: engine.combo > 0 ? 0 : 2)
                .accessibilityHidden(engine.combo == 0)

            Spacer()

            if engine.phase != .running {
                Button("统计", action: onShowStats)
                    .buttonStyle(ChallengeTopButtonStyle())
                    .accessibilityLabel("查看挑战统计")
            }

            Button("返回练习", action: onReturn)
                .buttonStyle(ChallengeTopButtonStyle())
                .accessibilityLabel("返回普通练习")
        }
        .padding(.horizontal, 12)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: engine.combo)
    }

    private func stat(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
            .lineLimit(1)
    }

    private var promptCard: some View {
        Group {
            switch engine.phase {
            case .ready:
                readyCard
                    .transition(.opacity.combined(with: .offset(y: 5)))
            case .running:
                runningCard
                    .transition(.opacity.combined(with: .offset(y: 5)))
            case .finished:
                resultCard
                    .transition(.opacity.combined(with: .offset(y: 5)))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 320)
        .background(promptBackground, in: RoundedRectangle(cornerRadius: 32))
        .overlay {
            RoundedRectangle(cornerRadius: 32)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 18, y: 10)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: engine.phase)
    }

    private var readyCard: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            Text("60 秒挑战")
                .font(.system(size: 38, weight: .semibold, design: .serif))

            Text("高频词与弱项加权 · 连续正确可提高得分倍率")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Button("开始挑战") {
                engine.start()
            }
            .buttonStyle(ChallengePrimaryButtonStyle())

            Spacer()

            Text("SPACE 开始 · TAB 提示 · SPACE 跳过 · ESC 关闭")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var runningCard: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            if engine.hintKey != nil {
                Text(engine.currentHint)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                Text(" ").font(.system(size: 18))
            }

            Text(engine.practice.text)
                .font(.system(size: 76, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .id(engine.practice.id)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 7)),
                        removal: .opacity.combined(with: .offset(y: -7))
                    )
                )

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Text(engine.inputProgressText)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(engine.errorKey == nil ? Color.blue : Color.red)
                    .frame(minHeight: 32)

                progressLine
            }

            HStack {
                Text(engine.feedback)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(engine.errorKey == nil ? Color.secondary : Color.red)

                Spacer()

                Text("最高连击 \(engine.maxCombo)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: engine.practice.id)
    }

    private var progressLine: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.08))
                Capsule()
                    .fill(Color.blue.opacity(0.75))
                    .frame(width: proxy.size.width * engine.progress)
            }
        }
        .frame(width: 180, height: 3)
        .animation(reduceMotion ? nil : .linear(duration: 0.12), value: engine.progress)
        .accessibilityLabel("剩余时间")
        .accessibilityValue(timeText)
    }

    private var resultCard: some View {
        VStack(spacing: 18) {
            Text("挑战完成")
                .font(.system(size: 30, weight: .semibold, design: .serif))

            HStack(spacing: 34) {
                resultMetric("得分", "\(engine.score)")
                resultMetric("字/分", "\(engine.latestResult?.charactersPerMinute ?? 0)")
                resultMetric("准确率", resultAccuracy)
                resultMetric("最高连击", "\(engine.maxCombo)")
            }

            Text(resultSummary)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("再来一局") { engine.start() }
                    .buttonStyle(ChallengePrimaryButtonStyle())

                Button("查看统计", action: onShowStats)
                    .buttonStyle(ChallengeSecondaryButtonStyle())

                Button("返回练习", action: onReturn)
                    .buttonStyle(ChallengeSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func resultMetric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 78)
    }

    private var resultAccuracy: String {
        guard let result = engine.latestResult else { return "0%" }
        return "\(Int((result.accuracy * 100).rounded()))%"
    }

    private var resultSummary: String {
        guard let result = engine.latestResult else { return "" }
        return "正确 \(result.correctCharacters) 字 · 错误 \(result.wrongCodes) 次 · 跳过 \(result.skippedPrompts) 题 · 提示 \(result.hintsUsed) 次"
    }

    private var timeText: String {
        String(format: "剩余 %.1f 秒", engine.timeRemaining)
    }

    private var appBackground: some ShapeStyle {
        LinearGradient(
            colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var promptBackground: some ShapeStyle {
        LinearGradient(
            colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ChallengeTopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(.primary.opacity(configuration.isPressed ? 0.10 : 0.06), in: Capsule())
    }
}

private struct ChallengePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(Color.blue.opacity(configuration.isPressed ? 0.72 : 0.88), in: RoundedRectangle(cornerRadius: 11))
    }
}

private struct ChallengeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(.primary.opacity(configuration.isPressed ? 0.10 : 0.06), in: RoundedRectangle(cornerRadius: 11))
    }
}
