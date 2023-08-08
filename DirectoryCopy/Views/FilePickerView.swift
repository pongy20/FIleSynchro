//
//  FilePicker.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 22.07.23.
//

import SwiftUI

struct FilePickerView: View {
    @State var isPickerShown: Bool = false
    @State var filesFound: Int = 0
    @Binding var url: URL?
    
    var buttonText: String
    var labelText: String
    
    var body: some View {
        VStack {
            HStack {
                Button(buttonText) {
                    isPickerShown = true
                }
                Text("\(filesFound) Objekte gefunden")
            }
            Text("\(labelText) \(self.url?.path ?? LocalizedStringKey("not_choosen_text").stringValue())")
        }
        .fileImporter(isPresented: $isPickerShown, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url):
                self.url = url
                calculateFiles()
            case .failure(let error):
                print("Error selecting source directory: \(error)")
            }
        }
    }
    
    func calculateFiles() {
        filesFound = 0
        let fileManager = FileManager.default
        guard let path = url?.path else { return }
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            filesFound = 0
            return
        }
        while let element = enumerator.nextObject() as? String {
            if (element.hasSuffix(".DS_Store")) { continue }
            filesFound += 1
        }
    }
    
}
