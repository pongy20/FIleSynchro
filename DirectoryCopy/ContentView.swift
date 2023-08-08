//
//  ContentView.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 21.07.23.
//

import SwiftUI
import CryptoKit

struct ContentView: View {
    @ObservedObject var syncManager = SyncManager()
    
    @State private var src: URL? = nil
    @State private var dest: URL? = nil
    @State private var isSourcePickerShown: Bool = false
    @State private var isDestinationPickerShown: Bool = false
    @State private var isAlertShown: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var alertConfirmationText: String = "Ok"
    @State private var isSyncing: Bool = false
    @State private var shouldCheckContent = true
    @State private var checkMethod: ContentCheckMethod = .sha256
    @State private var shouldDelete: Bool = true
    @State private var showAdvancedOptions = false

    var body: some View {
        VStack() {
            Text("app_title")
                .bold()
                .font(.title)
            
            Spacer()
            
            if (isSyncing) {
                Text(syncManager.currentTask)
                ProgressView(value: Double(syncManager.processedFiles), total: Double(syncManager.totalFiles))
                .progressViewStyle(.linear)
            }
            FilePickerView(url: $src, buttonText: LocalizedStringKey("choose_source_button").stringValue(), labelText: LocalizedStringKey("source_text").stringValue())
            FilePickerView(url: $dest, buttonText: LocalizedStringKey("choose_dest_button").stringValue(), labelText: LocalizedStringKey("dest_text").stringValue())
            
            OptionsView(shouldDelete: $shouldDelete, shouldCheckContent: $shouldCheckContent, checkMethod: $checkMethod)
            
            Spacer()
            
            SynchronizeButtonView(isSyncing: $isSyncing, shouldDeleteFilesInDest: shouldDelete, src: src, dest: dest, shouldCheckContent: shouldCheckContent, checkMethod: checkMethod, syncManager: syncManager, showAlert: showAlert(title:message:confirmationText:))
        }
        .padding()
        .alert(isPresented: $isAlertShown) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  primaryButton: .default(Text(alertConfirmationText)),
                  secondaryButton: .cancel())
        }
    }


    func showAlert(title: String, message: String, confirmationText: String?) {
        alertTitle = title
        alertMessage = message
        alertConfirmationText = confirmationText ?? "Ok"
        isAlertShown = true
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 500, height: 300)
    }
}

