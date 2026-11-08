//
//  MediaManagerTests.swift
//  MediaManagerTests
//
//  Created by Joshua V Sherwood on 11/1/26.
//

import Testing
import Foundation

struct MediaManagerTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // Swift Testing Documentation
        // https://developer.apple.com/documentation/testing
    }
   
   @Test func intervalParsing() async throws {
      let duration:TimeInterval = 1678.0
      
      let divDuration3600 = duration.truncatingRemainder(dividingBy: 3600.0)
      let divDuration60 = duration.truncatingRemainder(dividingBy: 60.0)
      
      //let r1 = String(format: "%d:%02d", duration / 3600.0, divDuration3600 / 60.0)
      //let r2 = String(format: "%02d:%02d", (duration / 60.0).truncatingRemainder(dividingBy: 60.0), divDuration60)
      let _ = String(format: "%d:%02d", Int(duration / 3600.0), Int(divDuration3600 / 60.0))
      let _ = String(format: "%02d:%02d", Int((duration / 60.0).truncatingRemainder(dividingBy: 60.0)), Int(divDuration60))

//      let runtime = duration > 3600 ?
//      String(format: "%d:%02d", duration / 3600.0, divDuration3600 / 60.0) :
//      String(format: "%02d:%02d", (duration / 60.0).truncatingRemainder(dividingBy: 60.0), divDuration60)
   }

}
