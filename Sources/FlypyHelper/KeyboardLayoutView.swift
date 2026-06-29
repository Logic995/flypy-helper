import SwiftUI

struct KeyboardLayoutView: View {
    let expectedKey: String?
    let errorKey: String?
    var keyWidth: CGFloat = 78
    var keyHeight: CGFloat = 78
    var keySpacing: CGFloat = 12
    var rowSpacing: CGFloat = 14
    var rowOffset: CGFloat = 42
    var outerPadding: CGFloat = 20
    var keyCornerRadius: CGFloat = 18
    var letterFontSize: CGFloat = 15
    var finalFontSize: CGFloat = 15
    var containerCornerRadius: CGFloat = 28
    var keyShadowOpacity: CGFloat = 0.08
    var containerOpacity: CGFloat = 0.52
    var keyBackgroundOpacity: CGFloat = 0.86
    var bottomRowLeadingAdjustment: CGFloat = 0
    var expectedBackgroundOpacity: CGFloat = 0.12
    var expectedBorderOpacity: CGFloat = 0.75
    var containerBackground: Color?
    var containerBorder: Color?
    var keyBaseBackground: Color?
    var keyBaseBorder: Color?
    var finalTextColor: Color?
    var expectedFinalTextColor: Color?

    private let rows = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: keySpacing) {
                    ForEach(row, id: \.self) { key in
                        keyView(key)
                    }
                }
                .padding(.leading, leadingOffset(for: index))
            }
        }
        .padding(outerPadding)
        .frame(maxWidth: .infinity)
        .background(containerFill, in: RoundedRectangle(cornerRadius: containerCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: containerCornerRadius)
                .stroke(containerBorder ?? .primary.opacity(0.055), lineWidth: 1)
        }
    }

    private var containerFill: Color {
        containerBackground ?? Color(nsColor: .controlBackgroundColor).opacity(containerOpacity)
    }

    private func leadingOffset(for rowIndex: Int) -> CGFloat {
        let base = CGFloat(rowIndex) * rowOffset
        return rowIndex == 2 ? max(0, base + bottomRowLeadingAdjustment) : base
    }

    private func keyView(_ key: String) -> some View {
        let item = FlypyLayout.key(for: key)
        let isExpected = expectedKey == key
        let isError = errorKey == key
        let isCompact = keyWidth < 64
        let padding: CGFloat = isCompact ? 7 : 12

        return VStack(alignment: .leading, spacing: isCompact ? 5 : 8) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(key.uppercased())
                    .font(.system(size: letterFontSize, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 2)

                Text(item?.initial ?? key)
                    .font(.system(size: letterFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                    .allowsTightening(true)
            }
            .frame(height: isCompact ? 13 : 18)

            Spacer(minLength: 0)

            Text(displayFinals(for: key))
                .font(.system(size: finalFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(finalForeground(isExpected: isExpected, isError: isError))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .lineSpacing(isCompact ? -2 : -1)
                .minimumScaleFactor(0.56)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, minHeight: isCompact ? 24 : 32, alignment: .center)
                .layoutPriority(1)
        }
        .padding(padding)
        .frame(width: keyWidth, height: keyHeight)
        .background(keyBackground(isExpected: isExpected, isError: isError), in: RoundedRectangle(cornerRadius: keyCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: keyCornerRadius)
                .stroke(keyBorder(isExpected: isExpected, isError: isError), lineWidth: isExpected || isError ? 2 : 1)
        }
        .shadow(color: .black.opacity(keyShadowOpacity), radius: isCompact ? 3 : 5, y: isCompact ? 1 : 3)
    }

    private func displayFinals(for key: String) -> String {
        switch key {
        case "q": "iu"
        case "w": "ei"
        case "e": "e"
        case "r": "uan"
        case "t": "ue\nve"
        case "y": "un"
        case "u": "u"
        case "i": "i"
        case "o": "o\nuo"
        case "p": "ie"
        case "a": "a"
        case "s": "iong\nong"
        case "d": "ai"
        case "f": "en"
        case "g": "eng"
        case "h": "ang"
        case "j": "an"
        case "k": "ing\nuai"
        case "l": "iang\nuang"
        case "z": "ou"
        case "x": "ia\nua"
        case "c": "ao"
        case "v": "ui\nv"
        case "b": "in"
        case "n": "iao"
        case "m": "ian"
        default: ""
        }
    }

    private func keyBackground(isExpected: Bool, isError: Bool) -> Color {
        if isError { return .red.opacity(0.13) }
        if isExpected { return .blue.opacity(expectedBackgroundOpacity) }
        return keyBaseBackground ?? Color(nsColor: .windowBackgroundColor).opacity(keyBackgroundOpacity)
    }

    private func finalForeground(isExpected: Bool, isError: Bool) -> Color {
        if isError { return .red }
        if isExpected { return expectedFinalTextColor ?? .blue }
        return finalTextColor ?? .primary
    }

    private func keyBorder(isExpected: Bool, isError: Bool) -> Color {
        if isError { return .red.opacity(0.75) }
        if isExpected { return .blue.opacity(expectedBorderOpacity) }
        return keyBaseBorder ?? .primary.opacity(0.08)
    }
}
