//
//  RegExError.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

enum RegExError: LocalizedError {
   case invalid_pattern(_ pattern: String)
   
   public var errorDescription: String? {
      return description
   }
}

extension RegExError: CustomStringConvertible {
   var description: String {
      switch(self) {
      case .invalid_pattern(let pattern):
         return NSLocalizedString("Operation error: Invalid wildcard pattern '\(pattern)'", comment: "Invalid pattern")
      }
   }
}
