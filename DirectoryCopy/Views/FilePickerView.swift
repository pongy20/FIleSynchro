//
//  FilePicker.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 22.07.23.
//

import SwiftUI

struct FilePickerView: View {
    @State var isPickerShown: Bool = false
    @Binding var url: URL?
    
    var buttonText: String
    var labelText: String
    
    var body: some View {
        HStack {
            Button(buttonText) {
                isPickerShown = true
            }
            Text("\(labelText) \(self.url?.path ?? LocalizedStringKey("not_choosen_text").stringValue())")
        }
        .fileImporter(isPresented: $isPickerShown, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url):
                self.url = url
            case .failure(let error):
                print("Error selecting source directory: \(error)")
            }
        }
    }
}
