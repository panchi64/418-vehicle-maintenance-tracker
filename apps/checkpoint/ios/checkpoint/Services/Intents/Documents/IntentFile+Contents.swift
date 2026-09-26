//
//  IntentFile+Contents.swift
//  checkpoint
//
//  The bytes of a file Siri or Shortcuts hands an intent. A file picked in
//  Shortcuts (Files, "On My iPhone") arrives as a security-scoped URL, and
//  its `data` reads empty until the app opens that scope. Every intent that
//  takes an `IntentFile` reads it through here.
//

import AppIntents
import Foundation

extension IntentFile {

    /// The file's bytes: `data` when it already holds them, else the file at
    /// `fileURL`, read inside its security scope. Empty when neither yields any.
    nonisolated var contents: Data {
        if !data.isEmpty { return data }
        guard let url = fileURL else { return Data() }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return (try? Data(contentsOf: url)) ?? Data()
    }
}

extension DocumentImport.File {

    /// An intent's file, read through `IntentFile.contents`.
    init(_ file: IntentFile) {
        self.init(data: file.contents, fileName: file.filename)
    }
}
