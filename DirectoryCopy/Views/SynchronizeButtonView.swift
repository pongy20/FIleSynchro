//
//  SynchronizeButtonView.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 22.07.23.
//

import SwiftUI

struct SynchronizeButtonView: View {
    @Binding var isSyncing: Bool
    
    @State var statistics: SyncStatistics = SyncStatistics(filesInSource: 0, directoriesInSource: 0, copiedFiles: 0, overwrittenFiles: 0, deletedFilesInDestination: 0, duration: 0)
    @State var isAlertPresented: Bool = false
    
    var shouldDeleteFilesInDest: Bool
    var src: URL?
    var dest: URL?
    var shouldCheckContent: Bool
    var checkMethod: ContentCheckMethod
    var syncManager: SyncManager

    
    let showAlert: (String, String, String) -> Void
    
    var body: some View {
        Button("sync_button") {
            if let src = self.src, let dest = self.dest {
                self.isSyncing = true
                DispatchQueue.global().async {
                    statistics = syncManager.findChanges(src: src.path, dest: dest.path, shouldCheckContent: shouldCheckContent, checkMethod: checkMethod, deleteFilesInDest: shouldDeleteFilesInDest)
                    DispatchQueue.main.async {
                        self.isSyncing = false
                    }
                }
                self.isAlertPresented = true
            } else {
                showAlert(LocalizedStringKey("no_directory_choosen_alert_title").stringValue(), LocalizedStringKey("no_directory_choosen_alert_text").stringValue(), "Ok")
            }
        }
        .disabled(isSyncing)
        .alert(isPresented: $isAlertPresented) {
            Alert(title: Text("Analyse"),
                  message: Text(createChangesFoundMessage()),
                  primaryButton: .default(syncManager.changes.isEmpty ? Text("Ok") : Text("Änderungen vornehmen")) {
                    syncManager.applyChanges()
                },
                  secondaryButton: .cancel())
        }
    }
    
    func createChangesFoundMessage() -> String {
        var message = String(format: NSLocalizedString("stats_files_in_source", comment: ""), statistics.filesInSource) + "\n"
        message += String(format: NSLocalizedString("stats_directories_in_source", comment: ""), statistics.directoriesInSource) + "\n"
        message += String(format: NSLocalizedString("stats_copied_files", comment: ""), statistics.copiedFiles) + "\n"
        message += String(format: NSLocalizedString("stats_overwritten_files", comment: ""), statistics.overwrittenFiles) + "\n"
        if shouldDeleteFilesInDest {
            message += String(format: NSLocalizedString("stats_deleted_files_in_destination", comment: ""), statistics.deletedFilesInDestination) + "\n"
        }
        message += String(format: NSLocalizedString("stats_duration", comment: ""), statistics.duration)
        return message
    }
    
}
