import AppKit
import SwiftUI

@main
struct TopScoreApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = MatchViewModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Explicit AppKit registration is reliable when the app is launched from
        // the command line as well as when launched by Finder.
        NSApp.setActivationPolicy(.accessory)

        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "soccerball", accessibilityDescription: "TopScore")
        button.image?.isTemplate = true
        button.title = " TS"
        button.toolTip = "TopScore"
        button.target = self
        button.action = #selector(togglePopover(_:))

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 340, height: 640)
        popover.contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(viewModel)
        )

        viewModel.startPolling()
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.stopPolling()
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
