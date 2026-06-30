import SwiftUI
import AppKit

enum CapturedKey {
    case letter(String)
    case delete
    case space
    case tab
}

struct KeyCaptureView: NSViewRepresentable {
    let onKey: (CapturedKey) -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> CaptureNSView {
        let view = CaptureNSView()
        view.onKey = onKey
        view.onEscape = onEscape
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ view: CaptureNSView, context: Context) {
        view.onKey = onKey
        view.onEscape = onEscape
        DispatchQueue.main.async {
            if view.window?.firstResponder !== view {
                view.window?.makeFirstResponder(view)
            }
        }
    }
}

final class CaptureNSView: NSView {
    var onKey: ((CapturedKey) -> Void)?
    var onEscape: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) || event.modifierFlags.contains(.option) {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 49:
            onKey?(.space)
        case 51:
            onKey?(.delete)
        case 53:
            onEscape?()
        case 48:
            onKey?(.tab)
        default:
            guard let char = event.charactersIgnoringModifiers?.lowercased(),
                  char.count == 1,
                  let scalar = char.unicodeScalars.first,
                  CharacterSet.lowercaseLetters.contains(scalar)
            else {
                return
            }
            onKey?(.letter(char))
        }
    }
}
