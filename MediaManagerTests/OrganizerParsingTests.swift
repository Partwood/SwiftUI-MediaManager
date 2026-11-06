//
//  OrganizerParsingTests.swift
//  OrganizerParsingTests
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Testing
@testable import MediaManager

struct OrganizerParsingTests {

    @Test func simpleEpisode() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // Swift Testing Documentation
        // https://developer.apple.com/documentation/testing
       let content = await DVDCompareParser.parse(simpleEpisode)
       #expect(content.title == "Parks and Recreation")
       #expect(content.year == 2009)
       #expect(content.type == .tvShow)
       #expect(content.season == 1)
       
       #expect(content.episodes.count == 7)
    }

   @Test func complexEpisode() async throws {
      // Write your test here and use APIs like `#expect(...)` to check expected conditions.
      // Swift Testing Documentation
      // https://developer.apple.com/documentation/testing
      let content = await DVDCompareParser.parse(complexEpisode)
      #expect(content.title == "Star Trek: Enterprise")
      #expect(content.year == 2001)
      #expect(content.type == .tvShow)
      #expect(content.season == 1)
      
      #expect(content.episodes.count == 3)
   }

   @Test func variantEpisode() async throws {
      // Write your test here and use APIs like `#expect(...)` to check expected conditions.
      // Swift Testing Documentation
      // https://developer.apple.com/documentation/testing
      let content = await DVDCompareParser.parse(variantEpisode)
      #expect(content.title == "Star Trek: Enterprise")
      #expect(content.year == 2001)
      #expect(content.type == .tvShow)
      #expect(content.season == 1)
      
      #expect(content.episodes.count == 4)
   }

   @Test func redDwarfS1D1() async throws {
      // Write your test here and use APIs like `#expect(...)` to check expected conditions.
      // Swift Testing Documentation
      // https://developer.apple.com/documentation/testing
      let content = await DVDCompareParser.parse(redDwarfS1D1)
      #expect(content.title == "Red Dwarf")
      #expect(content.year == 1988)
      #expect(content.type == .tvShow)
      #expect(content.season == 1)
      
      #expect(content.episodes.count == 6)
   }

   @Test func redDwarfS1D1Indented() async throws {
      // Write your test here and use APIs like `#expect(...)` to check expected conditions.
      // Swift Testing Documentation
      // https://developer.apple.com/documentation/testing
      let content = await DVDCompareParser.parse(redDwarfS1D1Indented)
      #expect(content.title == "Red Dwarf")
      #expect(content.year == 1988)
      #expect(content.type == .tvShow)
      #expect(content.season == 1)
      
      #expect(content.episodes.count == 6)
   }

   @Test func movie1() async throws {
      // Write your test here and use APIs like `#expect(...)` to check expected conditions.
      // Swift Testing Documentation
      // https://developer.apple.com/documentation/testing
      let content = await DVDCompareParser.parse(movie1)
      #expect(content.title == "007 - Skyfall")
      #expect(content.year == 2012)
      #expect(content.type == .movie)
   }
   
   @Test func movie2() async throws {
      // Write your test here and use APIs like `#expect(...)` to check expected conditions.
      // Swift Testing Documentation
      // https://developer.apple.com/documentation/testing
      let content = await DVDCompareParser.parse(movie2)
      #expect(content.title == "When Harry Met Sally...")
      #expect(content.year == 1989)
      #expect(content.type == .movie)
   }

   let simpleEpisode: String =
   """
   Parks and Recreation: Season 1 (TV) (2009)
   Episodes:
   - "Pilot" (21:32)
   - "Canvassing" (21:25)
   - "The Reporter" (21:47)
   - "Boys' Club" (21:34)
   - "The Banquet" (21:26)
   - "Rock Show" [Original cut] (21:48)
   - "Rock Show" [Producer's extended cut] (26:48)
   Commentaries:
   - "Pilot" with Greg Daniels, Rashida Jones and Michael Schur
   - "Canvassing" with Dan Goor, Seth Gordon, Nick Offerman and Michael Schur
   Deleted Scenes:
   - "Pilot" (8:20)
   - "Canvassing" (5:52)
   """
   
   let complexEpisode: String =
   """
   Star Trek: Enterprise: Season 1 (TV) (2001-2002)
   Episodes
   - �Broken Bow� (86:42)
   - �Fight or Flight� (44:16)
   - �Strange New World� (44:16)
   Audio commentary by series creators Rick Berman and Brannon Braga on �Broken Bow�
   Text commentary by scenic art supervisors Michael and Denise Okuda on �Broken Bow�
   Broken Bow Deleted Scenes (with Play All) (3:07)
   - Scene 92 (1:31)
   - Scene 99 (0:40)
   - Scene 154-155 (0:55)
   Fight or Flight Deleted Scenes (with Play All) (2:15)
   - Scene 5 (0:57)
   - Scene 28 (1:18)
   """
   
   let variantEpisode: String =
   """
   Star Trek: Enterprise: Season 1 (TV) (2001-2002)
   4 Episodes:
   �Bound� (40:57)
   �In a Mirror, Darkly, Part I� (41:02)
   �In a Mirror, Darkly, Part II� (41:00)
   �Demons� (41:04)
   Supplements:
   Audio commentary by writer Mike Sussman and StarTrek.com editorial director Tim Gaskill on �In a Mirror, Darkly, Part I�
   Audio commentary by writer Mike Sussman and StarTrek.com editorial director Tim Gaskill on �In a Mirror, Darkly, Part II�
   Text commentary by scenic art supervisors Michael and Denise Okuda on �In a Mirror, Darkly, Part II�
   In a Mirror, Darkly, Part II Deleted scene:
   - Scene 77 (2:19)
   """
   
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
   
   let redDwarfS1D1Indented: String =
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
   
   let movie1: String =
   """
   007 - Skyfall (2012)
   Bond�s loyalty to M is tested when her past comes back to haunt her. Whilst MI6 comes under attack, 007 must track down and destroy the threat, no matter how personal the cost.
   Director: Sam Mendes
   "Shooting Bond" featurettes (w/ play all option) (12:25)
   - "Working the Titles: The Title Sequence" (2:56)
   - "Behind the Wheel: DB5" (1:36)
   - "The Good, the Bad and the Beautiful: Women" (4:27)
   - "Licence to Travel: Locations" (3:24)
   Soundtrack Promotional Spot (0:40)
   """
   
   let movie2: String =
   """
   When Harry Met Sally... (1989)
   Can Two Friends Sleep Together And Still Love Each Other In The Morning?
   Director: Rob Reiner
   Audio Commentary by Director Rob Reiner
   Extras:"How Harry Met Sally" documentary (33:18)
   Deleted Scenes:
   - "Harry Does Impressions" (0:33)
   - "How Many Men Have You Slept With?" (1:00)
   - "Sally's Bad Date" (0:59)
   - "Sleepless Night" (0:34)
   - "I Blew It" (0:26)
   - "Harry Sally On The Couch" (1:46)
   - "I Was Just Walking Down The Street" (1:51)
   Rob Reiner Theatrical Trailers:
   - "The Princess Bride" (2:20)
   - "This Is Spinal Tap" (1:35)
   - "When Harry Met Sally" (2:05)
   Music Video:
   - Harry Connick, Jr. "It Had To Be You" (2:48)
   """
}
