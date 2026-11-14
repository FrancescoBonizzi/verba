import Foundation

/// Writes a result as a `.txt` file next to the file it came from.
public enum TextOutput {
    /// Writes `text` beside `source` as `<name>.txt`, or `<name> 2.txt`, `<name> 3.txt`… when the name is taken,
    /// like Finder does. Never overwrites an existing file. Returns where the text was written.
    public static func write(_ text: String, besideSourceAt source: URL) throws -> URL {
        let directory = source.deletingLastPathComponent()
        let baseName = source.deletingPathExtension().lastPathComponent
        let data = Data(text.utf8)

        for attempt in 1... {
            let name = attempt == 1 ? baseName : "\(baseName) \(attempt)"
            let candidate = directory.appendingPathComponent(name).appendingPathExtension("txt")
            do {
                // Checking existence first and then writing would race with another writer: the exclusive
                // create fails instead of replacing a file that appeared in between.
                try data.write(to: candidate, options: .withoutOverwriting)
                return candidate
            } catch CocoaError.fileWriteFileExists {
                continue
            }
        }
        preconditionFailure("unreachable: the loop above only exits by returning or throwing")
    }
}
