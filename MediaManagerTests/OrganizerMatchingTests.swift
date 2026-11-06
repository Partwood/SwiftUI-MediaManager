//
//  OrganizerMatchingTests.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Testing
@testable import MediaManager

struct OrganizerMatchingTests {
   @Test func redDwarfS1D1() async throws {
      let content = await DVDCompareParser.parse(redDwarfS1D1)
      let results = FileOrganizer.organizeTVShow(preview: true, files: <#T##[FileItem]#>, content: <#T##DVDCompareContent#>, basePath: <#T##URL#>, mergeStrategy: .replace)
   }
   
   let redDwarfS1D1: String =
   """
   Red Dwarf: Series 1 (TV) (1988)
   All 6 unremastered episodes:
   - "The End"
   - "Future Echoes"
   - "Balance Of Power"
   - "Waiting For God"
   - "Confidence & Paranoia"
   - "Me�"
   Audio commentary by actors Chris Barrie (Rimmer), Norman Lovett (Holly), Danny John Jules (The Cat) and Craig Charles (Lister)
   Commentary by Writers Rob Grant, Doug Naylor and Director Ed Bye (on The End episode)
   """
}
