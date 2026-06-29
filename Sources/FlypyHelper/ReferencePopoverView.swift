import SwiftUI

struct ReferencePopoverView: View {
    let openPractice: () -> Void
    @State private var highlightedKey: String?
    @State private var pendingHighlightReset: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 10) {
            header
            keyboard
            footer
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)

                LinearGradient(
                    colors: [
                        ReferencePalette.panelTintTop,
                        ReferencePalette.panelTintBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .preferredColorScheme(.dark)
        .overlay {
            KeyCaptureView { key in
                handleReferenceKey(key)
            }
            .frame(width: 0, height: 0)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: MenuBarIcon.image)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(ReferencePalette.secondaryText)
                .frame(width: 18, height: 18)

            Text("小鹤双拼键位参考")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(ReferencePalette.primaryText)

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var keyboard: some View {
        KeyboardLayoutView(
            expectedKey: highlightedKey,
            errorKey: nil,
            keyWidth: 58,
            keyHeight: 63,
            keySpacing: 7,
            rowSpacing: 8,
            rowOffset: 30,
            outerPadding: 12,
            keyCornerRadius: 14,
            letterFontSize: 12.5,
            finalFontSize: 11.5,
            containerCornerRadius: 20,
            keyShadowOpacity: 0.08,
            containerOpacity: 1,
            keyBackgroundOpacity: 1,
            bottomRowLeadingAdjustment: -18,
            expectedBackgroundOpacity: 0.12,
            expectedBorderOpacity: 0.34,
            containerBackground: ReferencePalette.keyboardTray,
            containerBorder: ReferencePalette.keyboardTrayBorder,
            keyBaseBackground: ReferencePalette.keyFill,
            keyBaseBorder: ReferencePalette.keyBorder,
            finalTextColor: ReferencePalette.finalText,
            expectedFinalTextColor: ReferencePalette.finalTextHighlighted
        )
    }

    private var footer: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("⌘⌥K")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))

                Text("呼出/隐藏")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
            .foregroundStyle(ReferencePalette.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(ReferencePalette.controlFill, in: Capsule())

            Spacer()

            Button {
                openPractice()
            } label: {
                HStack(spacing: 8) {
                    Text("打开练习")

                    Text("⌘⌥P")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(ReferencePalette.shortcutText)
                }
            }
            .buttonStyle(FilledPanelButtonStyle())
            .keyboardShortcut("p", modifiers: [.command, .option])
            .accessibilityLabel("打开练习，快捷键 Command Option P")
        }
        .padding(.horizontal, 4)
    }

}

private extension ReferencePopoverView {
    func handleReferenceKey(_ key: CapturedKey) {
        guard case .letter(let letter) = key,
              ReferencePopoverView.referenceKeys.contains(letter)
        else {
            return
        }

        pendingHighlightReset?.cancel()
        highlightedKey = letter

        let task = DispatchWorkItem {
            highlightedKey = nil
        }
        pendingHighlightReset = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: task)
    }

    static let referenceKeys: Set<String> = [
        "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
        "a", "s", "d", "f", "g", "h", "j", "k", "l",
        "z", "x", "c", "v", "b", "n", "m"
    ]
}

private enum ReferencePalette {
    static let panelTintTop = Color(red: 0.055, green: 0.060, blue: 0.072).opacity(0.36)
    static let panelTintBottom = Color(red: 0.030, green: 0.033, blue: 0.044).opacity(0.48)
    static let primaryText = Color(red: 0.940, green: 0.945, blue: 0.960)
    static let secondaryText = Color(red: 0.670, green: 0.680, blue: 0.710)
    static let shortcutText = Color(red: 0.920, green: 0.940, blue: 1.000)
    static let controlFill = Color(red: 0.115, green: 0.122, blue: 0.142).opacity(0.62)
    static let keyboardTray = Color(red: 0.045, green: 0.048, blue: 0.058).opacity(0.68)
    static let keyboardTrayBorder = Color.white.opacity(0.075)
    static let keyFill = Color(red: 0.155, green: 0.160, blue: 0.178).opacity(0.88)
    static let keyBorder = Color.white.opacity(0.125)
    static let finalText = Color(red: 0.800, green: 0.700, blue: 0.540)
    static let finalTextHighlighted = Color(red: 0.900, green: 0.800, blue: 0.620)
    static let practiceButton = Color(red: 0.145, green: 0.158, blue: 0.190).opacity(0.74)
    static let practiceButtonPressed = Color(red: 0.120, green: 0.134, blue: 0.165).opacity(0.82)
}

private struct FilledPanelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.900, green: 0.915, blue: 0.940))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                configuration.isPressed ? ReferencePalette.practiceButtonPressed : ReferencePalette.practiceButton,
                in: RoundedRectangle(cornerRadius: 10)
            )
    }
}
