//
//  OptionsView.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 22.07.23.
//

import SwiftUI

struct OptionsView: View {
    
    @Binding var shouldDelete: Bool
    @Binding var shouldCheckContent: Bool
    @Binding var checkMethod: ContentCheckMethod
    
    var body: some View {
        Toggle(isOn: $shouldDelete) {
            Text("should_delete_toggle")
        }
        
        Toggle(isOn: $shouldCheckContent) {
            Text("check_existing_files_toggle")
        }
        
        if shouldCheckContent {
            Picker("check_method_picker", selection: $checkMethod) {
                Text("sha256_text").tag(ContentCheckMethod.sha256)
                Text("direct_comparism_text").tag(ContentCheckMethod.directComparison)
            }
            .padding(.leading)
            Text("check_method_hint_text")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
