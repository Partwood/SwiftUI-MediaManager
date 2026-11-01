//
//  ImportPanelViewModel.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI
import Foundation
import Combine

/// ViewModel for the Import Panel
class ImportPanelViewModel: ObservableObject {
    @Published var parsedContent: DVDCompareContent?
    @Published var parsingWarnings: [String] = []
    @Published var organizationPreview: OrganizationPreview?
    
    /// Parses the input content
    func parse(content: String, title: String, mediaType: MediaType) {
        guard !content.isEmpty, !title.isEmpty else {
            parsingWarnings.append("Please enter both content and title")
            return
        }
        
        //do {
            var parsed = DVDCompareParser.parse(content)
            parsed.title = title
            parsed.type = mediaType
            parsed.parsingWarnings = self.parsingWarnings
            
            self.parsedContent = parsed
            self.parsingWarnings = parsed.parsingWarnings
            
            // Generate preview
            self.organizationPreview = generatePreview(
                content: parsed,
                mediaType: mediaType
            )
            
        //} catch {
            //parsingWarnings.append("Parsing error: \(error.localizedDescription)")
        //}
    }
    
    /// Generates a preview of what will be organized
    private func generatePreview(
        content: DVDCompareContent,
        mediaType: MediaType
    ) -> OrganizationPreview? {
        guard !content.episodes.isEmpty || !content.extras.isEmpty else {
            return nil
        }
        
        return OrganizationPreview(
            mediaType: mediaType,
            title: content.title,
            season: content.season,
            episodes: content.episodes,
            commentaries: content.commentaries,
            deletedScenes: content.deletedScenes,
            musicVideos: content.musicVideos,
            trailers: content.trailers,
            extras: content.extras,
            director: content.director,
            year: content.year
        )
    }
    
    /// Loads sample content for demonstration
    func loadSampleContent() {
        let sampleTVShow = """
        Parks and Recreation: Season 1 (TV) (2009)
        Episodes:
        - "Pilot" (21:32)
        - "Canvassing" (21:25)
        - "The Reporter" (21:47)
        Commentaries:
        - "Pilot" with Greg Daniels, Rashida Jones and Michael Schur
        Deleted Scenes:
        - "Pilot" (8:20)
        """
        
//        let sampleMovie = """
//        007 - Skyfall (2012)
//        Bond's loyalty to M is tested when her past comes back to haunt her.
//        Director: Sam Mendes
//        Extras:
//        "Shooting Bond" featurettes (w/ play all option) (12:25)
//        - "Working the Titles: The Title Sequence" (2:56)
//        """
        
        parsedContent = DVDCompareParser.parse(sampleTVShow)
        parsingWarnings = parsedContent?.parsingWarnings ?? []
    }
}
