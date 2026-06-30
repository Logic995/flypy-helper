import AppKit
import SwiftUI

@MainActor
final class ReferencePanelController: NSObject, ObservableObject, NSPopoverDelegate {
    private enum Layout {
        static let width: CGFloat = 704
        static let height: CGFloat = 322
    }

    private enum Palette {
        static let glassTint = NSColor(
            calibratedRed: 0.045,
            green: 0.048,
            blue: 0.058,
            alpha: 0.42
        )
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()

    private var openPracticeAction: () -> Void = {}
    private var willOpenReferenceAction: () -> Void = {}
    private var appToRestoreAfterReference: NSRunningApplication?

    override init() {
        super.init()

        configureStatusItem()
        configurePopover()
        updateContent()
    }

    func setActions(openPractice: @escaping () -> Void, willOpenReference: @escaping () -> Void) {
        openPracticeAction = openPractice
        willOpenReferenceAction = willOpenReference
    }

    func toggleFromStatusItem() {
        toggleReferencePanel(restoreFocusOnClose: true)
    }

    func toggleFromHotKey() {
        toggleFromStatusItem()
    }

    func closeReferencePanel() {
        closePopover(restoreFocus: false)
    }

    nonisolated func popoverDidClose(_ notification: Notification) {
        Task { @MainActor in
            self.statusItem.button?.highlight(false)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = MenuBarIcon.image
        button.imagePosition = .imageOnly
        button.toolTip = "小鹤双拼键位参考（⌘⌥K）"
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.delegate = self
        popover.animates = false
        popover.contentSize = NSSize(width: Layout.width, height: Layout.height)
        popover.appearance = NSAppearance(named: .darkAqua)
    }

    private func updateContent() {
        let hostingController = NSHostingController(
            rootView: ReferencePopoverView(
                openPractice: { [weak self] in
                    guard let self else { return }
                    self.closePopover(restoreFocus: false)
                    self.openPracticeAction()
                },
                closeReference: { [weak self] in
                    self?.closePopover(restoreFocus: true)
                },
                quitApplication: {
                    NSApplication.shared.terminate(nil)
                }
            )
            .frame(width: Layout.width, height: Layout.height)
        )

        hostingController.view.frame = NSRect(
            origin: .zero,
            size: NSSize(width: Layout.width, height: Layout.height)
        )
        hostingController.view.appearance = NSAppearance(named: .darkAqua)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        hostingController.view.layoutSubtreeIfNeeded()
        popover.contentViewController = hostingController
    }

    private func toggleReferencePanel(restoreFocusOnClose: Bool) {
        if popover.isShown {
            closePopover(restoreFocus: restoreFocusOnClose)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        rememberCurrentAppBeforeOpeningReference()
        willOpenReferenceAction()

        guard let button = statusItem.button else { return }

        NSApplication.shared.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        applyStablePopoverChrome()
        button.highlight(true)
    }

    private func applyStablePopoverChrome() {
        guard let window = popover.contentViewController?.view.window else {
            return
        }

        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = .clear
        window.isOpaque = false

        tintPopoverHierarchy(window.contentView?.superview ?? window.contentView)
    }

    private func tintPopoverHierarchy(_ view: NSView?) {
        guard let view else { return }

        view.appearance = NSAppearance(named: .darkAqua)
        view.wantsLayer = true

        if let effectView = view as? NSVisualEffectView {
            effectView.material = .hudWindow
            effectView.blendingMode = .behindWindow
            effectView.state = .active
            effectView.layer?.backgroundColor = Palette.glassTint.cgColor
        } else if String(describing: type(of: view)).contains("Popover") {
            view.layer?.backgroundColor = Palette.glassTint.cgColor
        }

        for subview in view.subviews {
            tintPopoverHierarchy(subview)
        }
    }

    private func closePopover(restoreFocus: Bool) {
        guard popover.isShown else { return }

        popover.performClose(nil)
        statusItem.button?.highlight(false)

        if restoreFocus {
            restorePreviousAppFocus()
        }
    }

    private func rememberCurrentAppBeforeOpeningReference() {
        let current = NSWorkspace.shared.frontmostApplication

        if current?.bundleIdentifier != Bundle.main.bundleIdentifier {
            appToRestoreAfterReference = current
        }
    }

    private func restorePreviousAppFocus() {
        guard let app = appToRestoreAfterReference, !app.isTerminated else {
            return
        }

        app.activate()
        appToRestoreAfterReference = nil
    }

    @objc
    private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard NSApplication.shared.currentEvent?.type == .rightMouseUp else {
            toggleFromStatusItem()
            return
        }

        let menu = NSMenu()
        let quitItem = NSMenuItem(
            title: "退出 FlypyHelper",
            action: #selector(quitApplication),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)

        if let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: sender)
        }
    }

    @objc
    private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
}
