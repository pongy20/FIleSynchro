//
//  Extensions.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 22.07.23.
//

import Foundation
import SwiftUI

public extension LocalizedStringKey {
    var stringKey: String? {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String
    }
}

public extension String {
    static func localizedString(for key: String,
                                locale: Locale = .current) -> String {
        
        let language = locale.languageCode
        let path = Bundle.main.path(forResource: language, ofType: "lproj")!
        let bundle = Bundle(path: path)!
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        
        return localizedString
    }
}

public extension LocalizedStringKey {
    func stringValue(locale: Locale = .current) -> String {
        return .localizedString(for: self.stringKey ?? "", locale: locale)
    }
}
