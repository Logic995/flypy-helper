import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let profile = PracticeProfile()
    private lazy var engine = PracticeEngine(profile: profile)
    private lazy var challengeEngine = ChallengeEngine(profile: profile)

    private var referencePanelController: ReferencePanelController?
    private var hotKeyManager: HotKeyManager?
    private var practiceWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        let referencePanelController = ReferencePanelController()
        referencePanelController.setActions(
            openPractice: { [weak self] in
                self?.openPracticeWindow()
            },
            willOpenReference: { [weak self] in
                self?.closePracticeWindow()
            }
        )
        self.referencePanelController = referencePanelController

        let hotKeyManager = HotKeyManager()
        hotKeyManager.setActions(
            reference: { [weak self] in
                self?.referencePanelController?.toggleFromHotKey()
            },
            practice: { [weak self] in
                self?.openPracticeWindow()
            }
        )
        self.hotKeyManager = hotKeyManager
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func openPracticeWindow() {
        referencePanelController?.closeReferencePanel()

        let window = practiceWindow ?? makePracticeWindow()
        practiceWindow = window

        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func closePracticeWindow() {
        practiceWindow?.orderOut(nil)
    }

    private func makePracticeWindow() -> NSWindow {
        let size = NSSize(width: 980, height: 720)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = ""
        window.identifier = NSUserInterfaceItemIdentifier("main")
        window.isReleasedWhenClosed = false
        window.contentMinSize = size
        window.contentMaxSize = size
        window.contentView = NSHostingView(
            rootView: ContentView(onClose: { [weak self] in
                self?.closePracticeWindow()
            })
                .environmentObject(engine)
                .environmentObject(challengeEngine)
                .frame(width: size.width, height: size.height)
        )
        window.center()

        return window
    }
}
