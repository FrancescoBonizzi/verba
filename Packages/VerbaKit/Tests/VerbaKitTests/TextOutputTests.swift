import Foundation
import Testing

@testable import VerbaKit

struct TextOutputTests {
    private let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TextOutputTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    @Test func writesBesideTheSourceWithTheSameName() throws {
        let source = directory.appendingPathComponent("voice note.ogg")

        let written = try TextOutput.write("ciao", besideSourceAt: source)

        #expect(written.lastPathComponent == "voice note.txt")
        #expect(try String(contentsOf: written, encoding: .utf8) == "ciao")
    }

    // The user's own notes may already sit next to the recording under the same name.
    @Test func neverOverwritesAnExistingFile() throws {
        let source = directory.appendingPathComponent("voice note.ogg")
        let existing = directory.appendingPathComponent("voice note.txt")
        try Data("mine".utf8).write(to: existing)
        try Data("mine too".utf8).write(to: directory.appendingPathComponent("voice note 2.txt"))

        let written = try TextOutput.write("transcript", besideSourceAt: source)

        #expect(written.lastPathComponent == "voice note 3.txt")
        #expect(try String(contentsOf: existing, encoding: .utf8) == "mine")
    }
}
