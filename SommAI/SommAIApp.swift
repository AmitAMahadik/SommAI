//
//  SommAIApp.swift
//  SommAI
//
//  Created by Mahadik, Amit on 10/4/25.
//

import SwiftUI
import AppIntents

@main
struct SommAIApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                ChatView()
            }
        }
    }
}

#if os(iOS)
// MARK: - App Intent for Action Button Shortcut
import Foundation

@available(iOS 17.0, *)
struct ActionButtonWinePairingIntent: AppIntent, Sendable {
    static var title: LocalizedStringResource = "Wine Pairing for Now"
    static var description = IntentDescription("Ask SommAI for a wine pairing suitable for the current time of day.")
    static var openAppWhenRun: Bool = true

    static var parameterSummary: some ParameterSummary {
        Summary("Request a time-aware wine pairing")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Notify the running app (if active) to trigger the time-aware pairing flow.
        // Your ChatView/ChatViewModel can observe this and call `send("")`.
        NotificationCenter.default.post(name: .triggerWinePairingNow, object: nil)
        return .result(dialog: "Requesting a time-aware wine pairing…")
    }
}

extension Notification.Name {
    static let triggerWinePairingNow = Notification.Name("TriggerWinePairingNow")
}

// MARK: - App Shortcuts Provider (compat-friendly)

@available(iOS 17.0, *)
struct SommAIShortcuts: AppShortcutsProvider, Sendable {
    //static var shortcutTileColor: ShortcutTileColor = .red

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ActionButtonWinePairingIntent(),
            phrases: ["Wine pairing now in \(.applicationName)"],
            shortTitle: "Wine Pairing (Now)",
            systemImageName: "wineglass.fill"
        )
    }
}
#endif



