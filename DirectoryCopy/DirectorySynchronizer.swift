//
//  DirectorySynchronizer.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 22.07.23.
//

import Foundation
import CryptoKit

class SyncStatistics {
    var filesInSource: Int
    var directoriesInSource: Int
    var copiedFiles: Int
    var overwrittenFiles: Int
    var deletedFilesInDestination: Int
    var duration: TimeInterval
    
    init(filesInSource: Int, directoriesInSource: Int, copiedFiles: Int, overwrittenFiles: Int, deletedFilesInDestination: Int, duration: TimeInterval) {
        self.filesInSource = filesInSource
        self.directoriesInSource = directoriesInSource
        self.copiedFiles = copiedFiles
        self.overwrittenFiles = overwrittenFiles
        self.deletedFilesInDestination = deletedFilesInDestination
        self.duration = duration
    }
}

enum FileChangeType {
    case copy
    case overwrite
    case delete
}

struct FileChange {
    let type: FileChangeType
    let sourceFile: URL
    let destinationFile: URL
}

class SyncManager: ObservableObject {
    @Published var totalFiles = 0
    @Published var processedFiles = 0
    @Published var currentTask: String = "Bereite vor..."
    @Published var changes: [FileChange] = []
    
    func findChanges(src: String, dest: String, shouldCheckContent: Bool, checkMethod: ContentCheckMethod, deleteFilesInDest: Bool) -> SyncStatistics {
        changes = []
        var stats: SyncStatistics = SyncStatistics(filesInSource: 0, directoriesInSource: 0, copiedFiles: 0, overwrittenFiles: 0, deletedFilesInDestination: 0, duration: 0)
        
        DispatchQueue.main.async {
            self.currentTask = "Bereite vor..."
            self.totalFiles = self.calculateFiles(src: URL(string: src))
            self.processedFiles = 0
        }
        
        
        let startTime = Date()

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: src) else { return stats }

        // Lösche die Dateien im Zielverzeichnis, die nicht im Quellverzeichnis vorhanden sind
        if deleteFilesInDest {
            guard let destEnumerator = fileManager.enumerator(atPath: dest) else { return stats }
            while let element = destEnumerator.nextObject() as? String {
                if (element.hasSuffix(".DS_Store")) { continue }
                let destFile = URL(fileURLWithPath: dest).appendingPathComponent(element)
                let srcFile = URL(fileURLWithPath: src).appendingPathComponent(element)
                if !fileManager.fileExists(atPath: srcFile.path) {
                    changes.append(FileChange(type: .delete, sourceFile: srcFile, destinationFile: destFile))
                    stats.deletedFilesInDestination += 1
                }
            }
        }

        while let element = enumerator.nextObject() as? String {
            if (element.hasSuffix(".DS_Store")) { continue }
            let srcFile = URL(fileURLWithPath: src).appendingPathComponent(element)
            let destFile = URL(fileURLWithPath: dest).appendingPathComponent(element)

            var isDirectory1: ObjCBool = false
            var isDirectory2: ObjCBool = false
            if fileManager.fileExists(atPath: srcFile.path, isDirectory: &isDirectory1) {
                // Es handelt sich um ein Verzeichnis
                if isDirectory1.boolValue {
                    stats.directoriesInSource += 1
                    do {
                        try fileManager.createDirectory(at: destFile, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print("Error creating directory: \(error)")
                    }
                } else {
                    // Es handelt sich um eine Datei
                    stats.filesInSource += 1
                    if fileManager.fileExists(atPath: destFile.path, isDirectory: &isDirectory2) {
                        // Datei existiert bereits im Zielverzeichnis
                        if !isDirectory2.boolValue {
                            // Es ist eine Datei
                            if shouldCheckContent {
                                // Überprüfung der Dateien auf Gleichheit
                                let isEqual: Bool
                                switch checkMethod {
                                case .sha256:
                                    isEqual = fileSHA256Hash(srcFile: srcFile, destFile: destFile)
                                case .metadataComparison:  // Neuer Fall
                                    do {
                                        let srcAttributes = try fileManager.attributesOfItem(atPath: srcFile.path)
                                        let destAttributes = try fileManager.attributesOfItem(atPath: destFile.path)
                                        isEqual = srcAttributes[.size] as? Int == destAttributes[.size] as? Int &&
                                                  srcAttributes[.creationDate] as? Date == destAttributes[.creationDate] as? Date &&
                                                  srcAttributes[.modificationDate] as? Date == destAttributes[.modificationDate] as? Date
                                    } catch {
                                        print("Error getting metadata: \(error)")
                                        continue
                                    }
                                    
                                case .directComparison:
                                    do {
                                        let srcData = try Data(contentsOf: srcFile)
                                        let destData = try Data(contentsOf: destFile)
                                        isEqual = srcData == destData
                                    } catch {
                                        print("Error: \(error)")
                                        continue
                                    }
                                    
                                }
                                // Kopiere Datei nur, wenn sie nicht gleich sind
                                if !isEqual {
                                    do {
                                        try fileManager.removeItem(at: destFile)
                                        try fileManager.copyItem(at: srcFile, to: destFile)
                                        stats.overwrittenFiles += 1
                                    } catch {
                                        print("Error copying file: \(error)")
                                    }
                                }
                            } else {
                                // Wenn der Inhalt nicht überprüft wird, kopiere die Datei nicht
                            }
                        } else {
                            // Es ist ein Verzeichnis, also machen wir nichts
                        }
                    } else {
                        // Die Datei existiert noch nicht im Zielverzeichnis, also kopieren wir sie
                        do {
                            try fileManager.copyItem(at: srcFile, to: destFile)
                            stats.copiedFiles += 1
                        } catch {
                            print("Error copying file: \(error)")
                        }
                    }
                    DispatchQueue.main.async {
                        self.processedFiles += 1
                        self.currentTask = "Verarbeite Datei #\(self.processedFiles + 1) von \(self.totalFiles)"
                    }
                }
            }
        }
        let endTime = Date()
        stats.duration = endTime.timeIntervalSince(startTime)
        return stats
    }
    
    func applyChanges() {
        let fileManager = FileManager.default
        for change in changes {
            switch change.type {
            case .copy:
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: change.sourceFile.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        try? fileManager.createDirectory(at: change.destinationFile, withIntermediateDirectories: true, attributes: nil)
                    } else {
                        try? fileManager.copyItem(at: change.sourceFile, to: change.destinationFile)
                    }
                }
            case .overwrite:
                try? fileManager.removeItem(at: change.destinationFile)
                try? fileManager.copyItem(at: change.sourceFile, to: change.destinationFile)
            case .delete:
                try? fileManager.removeItem(at: change.destinationFile)
            }
        }
    }


 
    func syncDirectories(src: String, dest: String, shouldCheckContent: Bool, checkMethod: ContentCheckMethod, deleteFilesInDest: Bool) -> SyncStatistics {

        var stats: SyncStatistics = SyncStatistics(filesInSource: 0, directoriesInSource: 0, copiedFiles: 0, overwrittenFiles: 0, deletedFilesInDestination: 0, duration: 0)
        
        DispatchQueue.main.async {
            self.currentTask = "Bereite vor..."
            self.totalFiles = self.calculateFiles(src: URL(string: src))
            self.processedFiles = 0
        }
        
        
        let startTime = Date()

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: src) else { return stats }

        // Lösche die Dateien im Zielverzeichnis, die nicht im Quellverzeichnis vorhanden sind
        if deleteFilesInDest {
            guard let destEnumerator = fileManager.enumerator(atPath: dest) else { return stats }
            while let element = destEnumerator.nextObject() as? String {
                if (element.hasSuffix(".DS_Store")) { continue }
                let destFile = URL(fileURLWithPath: dest).appendingPathComponent(element)
                let srcFile = URL(fileURLWithPath: src).appendingPathComponent(element)
                if !fileManager.fileExists(atPath: srcFile.path) {
                    do {
                        try fileManager.removeItem(at: destFile)
                        stats.deletedFilesInDestination += 1
                    } catch {
                        print("Error deleting file: \(error)")
                    }
                }
            }
        }

        while let element = enumerator.nextObject() as? String {
            if (element.hasSuffix(".DS_Store")) { continue }
            let srcFile = URL(fileURLWithPath: src).appendingPathComponent(element)
            let destFile = URL(fileURLWithPath: dest).appendingPathComponent(element)

            var isDirectory1: ObjCBool = false
            var isDirectory2: ObjCBool = false
            if fileManager.fileExists(atPath: srcFile.path, isDirectory: &isDirectory1) {
                // Es handelt sich um ein Verzeichnis
                if isDirectory1.boolValue {
                    // Es handelt sich um ein Verzeichnis
                    stats.directoriesInSource += 1
                    changes.append(FileChange(type: .copy, sourceFile: srcFile, destinationFile: destFile))
                } else {
                    // Es handelt sich um eine Datei
                    // Es handelt sich um eine Datei
                    stats.filesInSource += 1
                    if fileManager.fileExists(atPath: destFile.path, isDirectory: &isDirectory2) {
                        // Datei existiert bereits im Zielverzeichnis
                        if !isDirectory2.boolValue {
                            // Es ist eine Datei
                            if shouldCheckContent {
                                // Überprüfung der Dateien auf Gleichheit
                                let isEqual: Bool
                                switch checkMethod {
                                case .sha256:
                                    isEqual = fileSHA256Hash(srcFile: srcFile, destFile: destFile)
                                case .metadataComparison:  // Neuer Fall
                                    do {
                                        let srcAttributes = try fileManager.attributesOfItem(atPath: srcFile.path)
                                        let destAttributes = try fileManager.attributesOfItem(atPath: destFile.path)
                                        isEqual = srcAttributes[.size] as? Int == destAttributes[.size] as? Int &&
                                                  srcAttributes[.creationDate] as? Date == destAttributes[.creationDate] as? Date &&
                                                  srcAttributes[.modificationDate] as? Date == destAttributes[.modificationDate] as? Date
                                    } catch {
                                        print("Error getting metadata: \(error)")
                                        continue
                                    }
                                case .directComparison:
                                    do {
                                        let srcData = try Data(contentsOf: srcFile)
                                        let destData = try Data(contentsOf: destFile)
                                        isEqual = srcData == destData
                                    } catch {
                                        print("Error: \(error)")
                                        continue
                                    }
                                }
                                // Füge eine Überschreib-Änderung hinzu, wenn sie nicht gleich sind
                                if !isEqual {
                                    changes.append(FileChange(type: .overwrite, sourceFile: srcFile, destinationFile: destFile))
                                    stats.overwrittenFiles += 1
                                }
                            }
                        } else {
                            // Es ist ein Verzeichnis, also machen wir nichts
                        }
                    } else {
                        // Die Datei existiert noch nicht im Zielverzeichnis, also fügen wir eine Kopier-Änderung hinzu
                        changes.append(FileChange(type: .copy, sourceFile: srcFile, destinationFile: destFile))
                        stats.copiedFiles += 1
                    }
                    DispatchQueue.main.async {
                        self.processedFiles += 1
                        self.currentTask = "Verarbeite Datei #\(self.processedFiles + 1) von \(self.totalFiles)"
                    }
                }
            }
        }
        let endTime = Date()
        stats.duration = endTime.timeIntervalSince(startTime)
        return stats
    }

    func fileSHA256Hash(srcFile: URL, destFile: URL) -> Bool {
        if let srcStream = InputStream(url: srcFile),
           let destStream = InputStream(url: destFile) {
            srcStream.open()
            destStream.open()
            var srcContext = SHA256()
            var destContext = SHA256()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            while srcStream.hasBytesAvailable, destStream.hasBytesAvailable {
                let srcBytesRead = srcStream.read(buffer, maxLength: bufferSize)
                if srcBytesRead < 0 { /* handle error here */ }
                srcContext.update(data: Data(bytes: buffer, count: srcBytesRead))
                let destBytesRead = destStream.read(buffer, maxLength: bufferSize)
                if destBytesRead < 0 { /* handle error here */ }
                destContext.update(data: Data(bytes: buffer, count: destBytesRead))
            }
            buffer.deallocate()
            srcStream.close()
            destStream.close()
            let srcHash = srcContext.finalize()
            let destHash = destContext.finalize()
            return srcHash == destHash
        } else {
            return false
        }
    }

    func calculateFiles(src: URL?) -> Int {
        var filesFound = 0
        let fileManager = FileManager.default
        guard let path = src?.path else { return 0 }
        guard let enumerator = fileManager.enumerator(atPath: path) else { return 0 }
        
        while let element = enumerator.nextObject() as? String {
            if (element.hasSuffix(".DS_Store")) { continue }
            
            let fullPath = (path as NSString).appendingPathComponent(element)
            
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
                if !isDirectory.boolValue {
                    // It's a file
                    filesFound += 1
                }
            }
        }
        
        return filesFound
    }

    
}
