import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var engine: PracticeEngine

    var body: some View {
        VStack(spacing: 18) {
            topBar
            promptCard
            KeyboardLayoutView(expectedKey: engine.expectedNextKey, errorKey: engine.errorKey)
        }
        .padding(22)
        .background(appBackground)
        .overlay {
            KeyCaptureView { key in
                engine.handle(key)
            }
            .frame(width: 0, height: 0)
        }
    }

    private var topBar: some View {
        HStack(spacing: 28) {
            stat(engine.accuracyText)
            stat("字/分 \(engine.charactersPerMinute)")
            stat("键/分 \(engine.keysPerMinute)")
            stat("历史最佳 \(engine.bestKeysPerMinute)")

            Spacer()

            modePicker

            Text("⌘⌥K 参考 · TAB 提示 · SPACE 分隔/下一题 · ESC 清空")
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
}

#Preview {
    ContentView()
        .environmentObject(PracticeEngine())
}
