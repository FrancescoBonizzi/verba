import SwiftUI

struct ContentView: View {
    var body: some View {
        ContentUnavailableView(
            "Verba",
            systemImage: "waveform",
            description: Text("Transcription and OCR are coming in the next versions.")
        )
        .frame(width: 420, height: 280)
    }
}

#Preview {
    ContentView()
}
