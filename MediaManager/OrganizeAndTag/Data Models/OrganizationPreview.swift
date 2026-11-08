//
//  OrganizationPreview.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Preview data for organization operations
struct OrganizationPreview: Identifiable {
   var id: UUID // = { UUID() }

   let mediaType: MediaType
   let title: String
   let mainMovieDuration: TimeInterval?
   let season: Int?
   let episodes: [Episode]
   let commentaries: [Extra]
   let deletedScenes: [Extra]
   let musicVideos: [Extra]
   let trailers: [Extra]
   let extras: [Extra]
   let director: String?
   let year: Int?
   
   init(mediaType: MediaType, title: String, mainMovieDuration: TimeInterval?, season: Int?, episodes: [Episode], commentaries: [Extra], deletedScenes: [Extra], musicVideos: [Extra], trailers: [Extra], extras: [Extra], director: String?, year: Int?) {
      self.id = UUID()
      self.mediaType = mediaType
      self.title = title
      self.mainMovieDuration = mainMovieDuration
      self.season = season
      self.episodes = episodes
      self.commentaries = commentaries
      self.deletedScenes = deletedScenes
      self.musicVideos = musicVideos
      self.trailers = trailers
      self.extras = extras
      self.director = director
      self.year = year
   }
   
   init() {
      self.id = UUID()
      self.mediaType = .tvShow
      self.title = "title"
      self.season = nil
      self.mainMovieDuration = nil
      self.episodes = []
      self.commentaries = []
      self.deletedScenes = []
      self.musicVideos = []
      self.trailers = []
      self.extras = []
      self.director = nil
      self.year = nil
   }
}
