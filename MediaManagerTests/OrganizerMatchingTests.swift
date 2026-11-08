//
//  OrganizerMatchingTests.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Testing
import Foundation
@testable import MediaManager

struct OrganizerMatchingTests {
   @Test func redDwarfS5D1() async throws {
      let content = await DVDCompareParser.parse(redDwarfS5D1,startingEpisode: 1)
      
      #expect(content.parsingWarnings.isEmpty)
      #expect(!content.episodes.isEmpty)
      
      #expect("Holoship" == content.episodes[0].title)
      #expect(1 == content.episodes[0].episodeNumber)
      #expect(1678 == content.episodes[0].duration)
      #expect(false == content.episodes[0].isAlternativeCut)
      
      await content.episodes.forEach({ episode in
         #expect(episode.duration != nil && episode.duration! > 0)
      })
      
      let fileItems = fileMetadata.map({ $0.asFileItem() })
      let basePath: URL = URL(filePath: "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5")
      let results = await FileOrganizer.organizeTVShow(preview: true, files: fileItems, content: content, basePath: basePath, mergeStrategy: .replace)

      #expect(results.warnings.isEmpty)
      #expect(results.errors.isEmpty)
      #expect(!results.filesMoved.isEmpty)
      #expect(!results.nfoFilesCreated.isEmpty)
   }
   
   @Test func redDwarfS7D1() async throws {
      let content = await DVDCompareParser.parse(redDwarfS7D1,startingEpisode: 1)
      
      #expect(content.parsingWarnings.isEmpty)
      #expect(!content.episodes.isEmpty)
      
      #expect("Tikka To Ride" == content.episodes[0].title)
      #expect(1 == content.episodes[0].episodeNumber)
      #expect((37.0*60.0+15.0) == content.episodes[0].duration)
      #expect(true == content.episodes[0].isAlternativeCut)
      
      await content.episodes.forEach({ episode in
         #expect(episode.duration != nil && episode.duration! > 0)
      })
      
      let fileItems = fileMetadataS7D1.map({ $0.asFileItem() })
      let basePath: URL = URL(filePath: "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7")
      let results = await FileOrganizer.organizeTVShow(preview: true, files: fileItems, content: content, basePath: basePath, mergeStrategy: .replace)
      
      #expect(results.warnings.isEmpty)
      #expect(results.errors.isEmpty)
      #expect(!results.filesMoved.isEmpty)
      #expect(!results.nfoFilesCreated.isEmpty)
   }

   struct FileMetadata {
      var name: String
      var type: String
      var duration: String
      var size: String
      var path: String
      
      init(_ name: String,_ type: String,_ duration: String,_ size: String,_ path: String) {
         self.name = name
         self.type = type
         self.duration = duration
         self.size = size
         self.path = path
      }
      
      func asFileItem() -> FileItem {
         let url: URL = URL(filePath: path)
         let contentType = FileSystem.FileContentType.get(from: type)
         let duration: TimeInterval? = (duration != "--") ? DurationParser.parse(duration) : nil
         return FileItem(url: url,
                         name: name,
                         isDirectory: false,
                         path: path,
                         size: 0,
                         type: "",
                         creationDate: nil,
                         modifiedDate: nil,
                         contentType: contentType,
                         durationInSeconds: duration)
      }
   }

   let redDwarfS5D1: String =
   """
   Red Dwarf: Series 5 (TV) (1992) 
   Mr. Flibble is very cross!
   Director: Juliet May, Grant Naylor
   Episodes (Play All - 166:23):
   - "Holoship" (27:58)
   - "Inquisitor" (28:17)
   - "Terrorform" (27:13)
   - "Quarantine" (28:23)
   - "Demons & Angels" (26:58)
   - "Back to Reality" (27:23)
   (1.) Audio commentary on all episodes by actors Chris Barrie, Hattie Hayridge, Danny John Jules and Robert Llewellyn (2004)
   (2.) Audio commentary on "Back to Reality" by Fans Ruth Latchford, Jason Mercer, Claire Thompson, Simon Wigg and DVD Associate Producer Andrew Ellard (2004)
   """

   var fileMetadata: [FileMetadata] = [
      FileMetadata("C5_t01.mkv",
                   "MKV Video",
                   "27:58",
                   "1.83 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/C5_t01.mk1"),
      FileMetadata("D5_t02.mkv",
                   "MKV Video",
                   "28:17",
                   "1.71 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/D5_t02.mkv"),
      FileMetadata("E5_t03.mkv",
                   "MKV Video",
                   "27:13",
                   "1.72 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/E5_t03.mkv"),
      FileMetadata("F5_t04.mkv",
                   "MKV Video",
                   "28:25",
                   "1.77 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/F5_t04.mkv"),
      FileMetadata("H5_t05.mkv",
                   "MKV Video",
                   "26:59",
                   "1.99 GB",
                   "Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/H5_t05.mkv"),
      FileMetadata("I5_t06.mkv",
                   "MKV Video",
                   "27:25",
                   "2.06 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/15_t06.mkv"),
      FileMetadata("J5_t07.mkv",
                   "MKV Video",
                   "05:49",
                   "169.7 MB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/J5_t07.mkv"),
      FileMetadata("DISC_READY.txt",
                   "Text File",
                   "--",
                   "498 bytes",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/DISC_READY.txt"),
      FileMetadata("C5_t01.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/C5_t01.nfo"),
      FileMetadata("D5_t02.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/D5_t02.nfo"),
      FileMetadata("E5_t03.nfo",
                   "NFO File",
                   "-",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/E5_t03.nfo"),
      FileMetadata("F5_t04.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/F5_t04.nfo"),
      FileMetadata("H5_t05.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/H5_t05.nfo"),
      FileMetadata("15_t06.nto",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/15_t06.nfo"),
      FileMetadata("J5_t07.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 5/J5_t07.nfo"),
   ]


   let redDwarfS7D1: String = """
      Red Dwarf: Series 7 (TV) (1997)
      After a temporary bout of deadness, the Dwarfers are back!
      Episodes:
      - "Tikka To Ride" extended (37:15)
      - "Tikka To Ride" (28:41)
      - "Stoke Me A Clipper" (29:14)
      - "Ouroboros" (29:37)
      - "Ouroboros" extended (32:44)
      - "Identity Within - The Lost Episode" (performed by Chris Barrie in storyboard form) (44:04)
      Audio commentary by actors Craig Charles (Lister), Chris Barrie (Rimmer), Danny John Jules (The Cat), Robert Llewellyn (Kryten) and Chloe Annett (Kochanski)
      """
   
   var fileMetadataS7D1: [FileMetadata] = [
      FileMetadata("B1_t02.mkv",
                   "MKV Video",
                   "01:27:33",
                   "6.9 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/B1_t02.mkv"),
      FileMetadata("C1_t00.mkv",
                   "MKV Video",
                   "37:16",
                   "2.83 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/C1_t00.mkv"),
      FileMetadata("G1_t04.mkv",
                   "MKV Video",
                   "28:44",
                   "2.13 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/G1_t04.mkv"),
      FileMetadata("H1_t06.mkv",
                   "MKV Video",
                   "29:13",
                   "2.21 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/H1_t06.mkv"),
      FileMetadata("I1_t07.mkv",
                   "MKV Video",
                   "29:34",
                   "2.56 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/11_t07.mkv"),
      FileMetadata("F1_t08.mkv",
                   "MKV Video",
                   "32:46",
                   "2.98 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/F1_t08.mkv"),
      FileMetadata("K1_t09.mkv",
                   "MKV Video",
                   "44:04",
                   "1.33 GB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/K1_t09.mkv"),
      FileMetadata("DISC_READY.txt",
                   "Text File",
                   "--",
                   "498 bytes",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/DISC_READY.txt"),
      FileMetadata("B1_t02.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/B1_t02.nfo"),
      FileMetadata("C1_t00.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/C1_t00.nfo"),
      FileMetadata("F1_t08.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/F1_t08.nfo"),
      FileMetadata("G1_t04.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/G1_t04.nfo"),
      FileMetadata("H1_t06.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/H1_t06.nfo"),
      FileMetadata("I1_t07.nfo",
                   "NFO File",
                   "--",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/11_t07.nfo"),
      FileMetadata("K1_t09.nfo",
                   "NFO File",
                   "ーー",
                   "1 KB",
                   "/Volumes/HDD-Storage/Media/TV Shows/Red Dwarf/Season 7/K1_t09.nfo"),
   ]
}
