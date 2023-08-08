//
//  SettingsSave.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 23.07.23.
//

import Foundation

struct UserSettings {
    var src: URL?
    var dest: URL?
    var deleteFiles: Bool
    var shouldCheck: Bool
    var checkMethod: ContentCheckMethod
}

func checkSettingsInitialized() {
    let defaults = UserDefaults.standard
    if (!checkIfSettingsPropertyExists(key: "deleteFiles") || !checkIfSettingsPropertyExists(key: "deleteFiles") || !checkIfSettingsPropertyExists(key: "deleteFiles")) {
        saveSettings(settings: UserSettings(deleteFiles: true, shouldCheck: true, checkMethod: .sha256))
    }
}

func checkIfSettingsPropertyExists(key: String) -> Bool {
    let defaults = UserDefaults.standard
    return defaults.object(forKey: key) == nil
}

func saveSettings(settings: UserSettings) {
    let defaults = UserDefaults.standard
    defaults.set(settings.src?.absoluteString, forKey: "srcURL")
    defaults.set(settings.dest?.absoluteString, forKey: "destURL")
    defaults.set(settings.deleteFiles, forKey: "deleteFiles")
    defaults.set(settings.shouldCheck, forKey: "shouldCheck")
    defaults.set(settings.checkMethod.rawValue, forKey: "checkMethod")
}

func loadSettings() -> UserSettings {
    let defaults = UserDefaults.standard
    let srcURL = defaults.object(forKey: "srcURL") as? String
    let destURL = defaults.object(forKey: "destURL") as? String
    let deleteFiles = defaults.bool(forKey: "deleteFiles")
    let shouldCheck = defaults.bool(forKey: "shouldCheck")
    if let checkMethodRaw = defaults.object(forKey: "checkMethod") as? ContentCheckMethod.RawValue,
       let checkMethod = ContentCheckMethod(rawValue: checkMethodRaw) {
        return UserSettings(src: URL(string: srcURL ?? ""), dest: URL(string: destURL ?? ""), deleteFiles: deleteFiles, shouldCheck: shouldCheck, checkMethod: checkMethod)
    }
    return UserSettings(src: URL(string: srcURL ?? ""), dest: URL(string: destURL ?? ""), deleteFiles: deleteFiles, shouldCheck: shouldCheck, checkMethod: .sha256)
}


