import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var engine: PracticeEngine
    @EnvironmentObject private var challengeEngine: ChallengeEngine
    let onClose: () -> Void
    @State private var showingChallenge = false
    @State private var showingStats = false

    var body: some View {
        Group {
            if showingChallenge {
                ChallengeView(
                    onReturn: returnToPractice,
                    onShowStats: { showingStats = true },
                    onClose: closeWindow
                )
            } else {
                practiceView
            }
        }
        .sheet(isPresented: $showingStats) {
            ChallengeStatsView(store: challengeEngine.history)
        }
    }

    private var practiceView: some View {
        VStack(spacing: 18) {
            topBar
            promptCard
            KeyboardLayoutView(expectedKey: engine.expectedNextKey, errorKey: engine.errorKey)
        }
        .padding(22)
        .background(appBackground)
        .overlay {
            KeyCaptureView(
                onKey: { key in engine.handle(key) },
                onEscape: onClose
            )
            .frame(width: 0, height: 0)
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            stat(engine.accuracyText)
            stat("字/分 \(engine.charactersPerMinute)")
            stat("键/分 \(engine.keysPerMinute)")
            stat("历史最佳 \(engine.bestKeysPerMinute)")

            Spacer()

            modePicker

            Button {
                challengeEngine.prepare()
                showingChallenge = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                    Text("60 秒挑战")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(.blue.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开六十秒挑战")

            Text("TAB 提示 · SPACE 下一题 · ESC 关闭")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
    }

    private func stat(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(PracticeMode.allCases) { mode in
                Button {
                    engine.switchMode(to: mode)
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(width: 28, height: 26)
                        .background(engine.mode == mode ? .blue.opacity(0.16) : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(engine.mode == mode ? .blue : .secondary)
            }
        }
    }

    private var promptCard: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            if engine.shouldShowHint, !engine.currentHint.isEmpty {
                Text(engine.currentHint)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                Text(" ")
                    .font(.system(size: 18))
            }

            Text(promptText)
                .font(promptFont)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .minimumScaleFactor(0.45)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Text(engine.inputProgressText)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(inputColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 32, maxHeight: 96)

                Rectangle()
                    .fill(inputColor.opacity(0.75))
                    .frame(width: 160, height: 3)
                    .clipShape(Capsule())
            }

            HStack {
                Text(engine.feedback)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(feedbackColor)

                Spacer()

                if let weak = engine.weakFinals.first {
                    Text("弱项 \(FlypyLayout.display(weak.0)) +\(weak.1)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(promptBackground, in: RoundedRectangle(cornerRadius: 32))
        .overlay {
            RoundedRectangle(cornerRadius: 32)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 18, y: 10)
    }

    private var promptFont: Font {
        switch engine.mode {
        case .character:
            .system(size: 112, weight: .semibold, design: .serif)
        case .phrase:
            .system(size: 76, weight: .semibold, design: .serif)
        case .sentence:
            .system(size: 42, weight: .semibold, design: .serif)
        case .article:
            .system(size: 30, weight: .medium, design: .serif)
        }
    }

    private var promptText: String {
        guard engine.mode == .article else {
            return engine.practice.text
        }

        return engine.practice.text
            .replacingOccurrences(of: "。", with: "。\n")
            .replacingOccurrences(of: "！", with: "！\n")
            .replacingOccurrences(of: "？", with: "？\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var inputColor: Color {
        engine.errorKey == nil ? .blue : .red
    }

    private var feedbackColor: Color {
        if engine.feedback == "正确" { return .green }
        if engine.errorKey != nil { return .red }
        return .secondary
    }

    private var appBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .controlBackgroundColor)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var promptBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.12),
                Color.purple.opacity(0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func returnToPractice() {
        challengeEngine.cancel()
        showingChallenge = false
    }

    private func closeWindow() {
        challengeEngine.cancel()
        showingChallenge = false
        onClose()
    }
}

#Preview {
    let profile = PracticeProfile()
    ContentView(onClose: {})
        .environmentObject(PracticeEngine(profile: profile))
        .environmentObject(ChallengeEngine(profile: profile))
}
