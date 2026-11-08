//
//  Movie.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

// MARK: - Movie Struct
struct Movie: Codable, Identifiable {
   var id: UUID// = { UUID() }
   //var id: String { title }
   
   var title: String
   var plot: String?
   var year: Int?
   var director: String?
   var runtime: TimeInterval?
   var genre: [String]?
   var cast: [Cast]
   
   init(title: String, plot: String? = nil, year: Int? = nil, director: String? = nil, runtime: TimeInterval? = nil, genre: [String]? = nil, cast: [Cast] = []) {
      self.id = UUID()
      self.title = title
      self.plot = plot
      self.year = year
      self.director = director
      self.runtime = runtime
      self.genre = genre
      self.cast = cast
   }
}
