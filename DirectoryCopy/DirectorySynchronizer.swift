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

func syncDirectories(src: String, dest: String, shouldCheckContent: Bool, checkMethod: ContentCheckMethod, deleteFilesInDest: Bool) -> SyncStatistics {
    Thread.sleep(forTimeInterval: 1.5)
    
    var stats: SyncStatistics = SyncStatistics(filesInSource: 0, directoriesInSource: 0, copiedFiles: 0, overwrittenFiles: 0, deletedFilesInDestination: 0, duration: 0)
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
                            do {
                                let isEqual: Bool
                                switch checkMethod {
                                case .sha256:
                                    let srcData = try Data(contentsOf: srcFile)
                                    let destData = try Data(contentsOf: destFile)
                                    isEqual = SHA256.hash(data: srcData) == SHA256.hash(data: destData)
                                case .directComparison:
                                    let srcData = try Data(contentsOf: srcFile)
                                    let destData = try Data(contentsOf: destFile)
                                    isEqual = srcData == destData
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
                            } catch {
                                print("Error comparing or copying files: \(error)")
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
            }
        }
    }
    let endTime = Date()
    stats.duration = endTime.timeIntervalSince(startTime)
    return stats
}
