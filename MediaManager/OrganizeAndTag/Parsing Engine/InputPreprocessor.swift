//
//  InputPreprocessor.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Preprocesses input text to handle encoding issues and normalize characters
struct InputPreprocessor {
    
    /// Preprocesses raw input text to normalize encoding and characters
    /// - Parameter input: Raw input string that may have encoding issues
    /// - Returns: Cleaned and normalized string
    static func preprocess(_ input: String) -> String {
        var processed = input
        
        // Convert from Windows-1252 encoding if needed
        if let data = processed.data(using: .windowsCP1252),
           let utf8String = String(data: data, encoding: .utf8) {
            processed = utf8String
        }
        
        // Convert from MacRoman encoding if needed
        if let data = processed.data(using: .macOSRoman),
           let utf8String = String(data: data, encoding: .utf8) {
            processed = utf8String
        }
        
        // Replace mojibake characters (replacement character �)
        processed = processed.replacingOccurrences(of: "\u{FFFD}", with: "\"", options: .regularExpression)
        processed = processed.replacingOccurrences(of: "�", with: "\"", options: .regularExpression)
        
        // Normalize quotes
        processed = normalizeQuotes(in: processed)
        
        // Normalize whitespace
        processed = normalizeWhitespace(in: processed)
        
        return processed
    }
    
    /// Normalizes various quote types to standard ASCII quotes
    private static func normalizeQuotes(in text: String) -> String {
        var result = text
        // Replace smart quotes with standard quotes
        result = result.replacingOccurrences(of: "“", with: "\"", options: .regularExpression)
        result = result.replacingOccurrences(of: "”", with: "\"", options: .regularExpression)
        result = result.replacingOccurrences(of: "‘", with: "'", options: .regularExpression)
        return result
    }
    
    /// Normalizes whitespace (non-breaking spaces, multiple spaces, etc.)
    private static func normalizeWhitespace(in text: String) -> String {
        var result = text
        
        // Replace non-breaking spaces with regular spaces
        result = result.replacingOccurrences(of: "\u{00A0}", with: " ", options: .regularExpression)
        
        // Replace multiple spaces with single space (but preserve spaces after colons in durations)
        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        
        // Trim leading and trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return result
    }
    
    /// Detects the likely encoding of input data
    /// - Parameter data: Raw data to analyze
    /// - Returns: Suggested encoding
    static func detectEncoding(from data: Data) -> String.Encoding {
        // Try UTF-8 first
        if let string = String(data: data, encoding: .utf8) {
            // Check if it looks valid (contains mostly printable characters)
           if !string.isEmpty && !string.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) {
            //if string.count > 0 && !string.contains(where: { $0.isUnicodeScalar(in: .controlCharacters) }) {
                return .utf8
            }
        }
        
        // Try Windows-1252
        if let string = String(data: data, encoding: .windowsCP1252) {
           if !string.isEmpty && !string.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) {
              //if string.count > 0 && !string.contains(where: { $0.isUnicodeScalar(in: .controlCharacters) }) {
                return .windowsCP1252
            }
        }
        
        // Default to UTF-8
        return .utf8
    }
}
