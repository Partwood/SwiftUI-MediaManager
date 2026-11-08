//
//  DVDCompareParserTests.swift
//  MediaManagerTests
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Testing
import Foundation
@testable import MediaManager

struct DVDCompareParserTests {

    @Test func testEpisodeParsing() async throws {
       let t1 = "- \"My Title\" (35:25)"
       let t2 = "\"My Title\" (35:25)"
       let t3 = "- \"My Title\" extended (35:25)"
       let t4 = "- \"My Title\" extended"
       let t5 = "\"My Title\" extended"
       
       let expectedDuration: TimeInterval = (35.0*60.0+25.0)
       
       let e1 = await DVDCompareParser.parseEpisodeLine(t1)
       await debug("\(e1!)")
       #expect( "My Title" == e1?.title )
       #expect( expectedDuration == e1?.duration )
       #expect( false == e1?.isAlternativeCut )
       
       let e2 = await DVDCompareParser.parseEpisodeLine(t2)
       await debug("\(e2!)")
       #expect( "My Title" == e2?.title )
       #expect( expectedDuration == e2?.duration )
       #expect( false == e2?.isAlternativeCut )
       
       let e3 = await DVDCompareParser.parseEpisodeLine(t3)
       await debug("\(e3!)")
       #expect( "My Title" == e3?.title )
       #expect( expectedDuration == e3?.duration )
       #expect( true == e3?.isAlternativeCut )
       
       let e4 = await DVDCompareParser.parseEpisodeLine(t4)
       await debug("\(e4!)")
       #expect( "My Title" == e4?.title )
       #expect( nil == e4?.duration )
       #expect( true == e4?.isAlternativeCut )
       
       let e5 = await DVDCompareParser.parseEpisodeLine(t5)
       await debug("\(e5!)")
       #expect( "My Title" == e5?.title )
       #expect( nil == e5?.duration )
       #expect( true == e5?.isAlternativeCut )

       let t6 = "- \"Tikka To Ride\" extended (37:15)"
       
       let expectedDuration1: TimeInterval = (37.0*60.0+15.0)
       let e6 = await DVDCompareParser.parseEpisodeLine(t6)
       await debug("\(e6!)")
       #expect( "Tikka To Ride" == e6?.title )
       #expect( expectedDuration1 == e6?.duration )
       #expect( true == e6?.isAlternativeCut )
       #expect( "Extended cut" == e6?.alternativeCut )
       
       let t7 = "- \"Identity Within - The Lost Episode\" (performed by Chris Barrie in storyboard form) (44:04)"

       let expectedDuration2: TimeInterval = (44.0*60.0+4.0)
       let e7 = await DVDCompareParser.parseEpisodeLine(t7)
       await debug("\(e7!)")
       #expect( "Identity Within - The Lost Episode" == e7?.title )
       #expect( expectedDuration2 == e7?.duration )
       #expect( false == e7?.isAlternativeCut )
    }

}
