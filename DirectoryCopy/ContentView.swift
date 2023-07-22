//
//  ContentView.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 21.07.23.
//

import SwiftUI

struct ContentView: View {
    @State private var src: URL? = nil
    @State private var dest: URL? = nil
    @State private var isSourcePickerShown: Bool = false
    @State private var isDestinationPickerShown: Bool = false
    @State private var isAlertShown: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var isSyncing: Bool = false
    @State private var shouldDelete: Bool = false

    var body: some View {
        VStack() {
            Text("Verzeichnis-Synchro")
                .bold()
                .font(.title)
            if (isSyncing) {
                ProgressView() {
                   Text("Synchronisiere Verzeichnisse...")
                }.progressViewStyle(.linear)
            }
            HStack {
                Button("Quellverzeichnis auswählen (A)") {
                    self.isSourcePickerShown = true
                }
                Text("Quelle (A): \(self.src?.path ?? "nicht ausgewählt")")
            }
            .fileImporter(isPresented: $isSourcePickerShown, allowedContentTypes: [.folder]) { result in
                switch result {
                case .success(let url):
                    self.src = url
                case .failure(let error):
                    print("Error selecting source directory: \(error)")
                }
            }

            HStack {
                Button("Zielverzeichnis auswählen (B)") {
                    self.isDestinationPickerShown = true
                }
                Text("Ziel (B): \(self.dest?.path ?? "nicht ausgewählt")")
            }
            .fileImporter(isPresented: $isDestinationPickerShown, allowedContentTypes: [.folder]) { result in
                switch result {
                case .success(let url):
                    self.dest = url
                case .failure(let error):
                    print("Error selecting destination directory: \(error)")
                }
            }
            
            Toggle(isOn: $shouldDelete) {
                Text("Objekte im Zielverzeichnis löschen, die nicht im Quellverzeichnis vorhanden sind")
            }

            VStack {
                Button("Verzeichnisse Synchronisieren") {
                    if let src = self.src, let dest = self.dest {
                        self.isSyncing = true
                        DispatchQueue.global().async {
                            self.syncDirectories(src: src.path, dest: dest.path)
                            DispatchQueue.main.async {
                                self.isSyncing = false
                            }
                        }
                    } else {
                        showAlert(title: "Keine Verzeichnisse ausgewählt", message: "Bitte wähle zuerst Verzeichnisse aus!")
                    }
                }
            }
        }
        .padding()
        .alert(isPresented: $isAlertShown) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("Ok")))
        }
    }

    func syncDirectories(src: String, dest: String) {
        let fileManager = FileManager.default
        Thread.sleep(forTimeInterval: 1)

        do {
            // Prüfe und lösche Dateien und Ordner, die in dest aber nicht in src sind
            if shouldDelete {
                let destContents = try fileManager.contentsOfDirectory(atPath: dest)
                for item in destContents {
                    let itemPath = "\(dest)/\(item)"
                    if !fileManager.fileExists(atPath: "\(src)/\(item)") {
                            try fileManager.removeItem(atPath: itemPath)
                    }
                }
            }

            // Kopiere Dateien und Ordner von src nach dest, wenn sie noch nicht existieren
            let srcContents = try fileManager.contentsOfDirectory(atPath: src)
            for item in srcContents {
                let itemPath = "\(src)/\(item)"
                if !fileManager.fileExists(atPath: "\(dest)/\(item)") {
                    if fileManager.fileExists(atPath: itemPath) {
                        try fileManager.copyItem(atPath: itemPath, toPath: "\(dest)/\(item)")
                    }
                }
            }
            showAlert(title: "Dateien synchronisiert", message: "Dateien wurden erfolgreich synchronisiert!")
        } catch {
            showAlert(title: "Fehler", message: "Es ist ein Fehler aufgetreten. Dateien wurden nicht synchronisiert.")
        }
    }
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        isAlertShown = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

