//
//  RegExError.swift
//  MediaManager
//
//  Created by Joshua V Sherwood on 10/17/26.
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
