//
//  Cast.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

struct Cast: Codable, Identifiable {
   //var id: String { name }
   var id: UUID// = { UUID() }
   
   var name: String
   var role: String
   
   init(name: String, role: String) {
      self.id = UUID()
      self.name = name
      self.role = role
   }
}
