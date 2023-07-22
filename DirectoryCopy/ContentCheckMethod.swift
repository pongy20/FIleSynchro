//
//  ContentCheckMethod.swift
//  DirectoryCopy
//
//  Created by Eric Dupont on 22.07.23.
//

import Foundation

public enum ContentCheckMethod: String, CaseIterable, Identifiable {
    case sha256 = "SHA-256"
    case directComparison = "Direct Comparison"
    
    public var id: String { self.rawValue }
}
