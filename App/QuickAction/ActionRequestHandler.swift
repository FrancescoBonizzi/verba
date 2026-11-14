import Foundation

final class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        // TODO: hand the selected files to the app, which does the transcription (M2 in ROADMAP.md). An
        // extension has tight time and memory limits, so the work itself does not belong here.
        context.completeRequest(returningItems: [], completionHandler: nil)
    }
}
