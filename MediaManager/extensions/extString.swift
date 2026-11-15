//
//  extString.swift
//  MediaManager
//
//  Created by Joshua V Sherwood on 11/1/26.
//

import Foundation

extension String {
   public func components(separatedBy separators: Array<String>) -> Array<String> {
      var output: Array<String> = [self]
      for separator in separators {
         output = output.flatMap { $0.components(separatedBy: separator) }
      }
      return output.map { $0 }
   }
   
   // lowerBound
   func boundedBy(lower range: NSRange) -> String? {
      if let actualRange = self.range(range) {
         return String(self[(actualRange.lowerBound)...])
      } else {
         return nil
      }
   }
   
   // Conversion
   func range(_ range: NSRange) -> Range<String.Index>? {
      return Range(range, in: self)
   }
   
   // Direct usage
   func subString(_ range: NSRange) -> Substring? {
      if let stringRange = Range(range, in: self) {
         return self[stringRange]
      } else {
         return nil
      }
   }
   
   func string(_ range: NSRange) -> String? {
      if let stringRange = Range(range, in: self) {
         return String(self[stringRange])
      } else {
         return nil
      }
   }
   
   func index(of substring: String) -> String.Index? {
      guard let range = self.range(of: substring) else { return nil }
      
      // Check if the substring exists
      if range.lowerBound >= self.endIndex {
         return nil
      } else {
         return range.lowerBound
      }
   }
}
