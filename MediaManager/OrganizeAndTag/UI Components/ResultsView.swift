//
//  ResultsView.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI

/// View for displaying organization results
struct ResultsView: View {
   let results: OrganizationResults
   
   var body: some View {
      ScrollView {
         VStack(alignment: .leading, spacing: 16) {
            // Summary
            Text("Organization Complete")
               .font(.title2)
               .fontWeight(.bold)
            
            Text(results.summary)
               .font(.caption)
               .foregroundColor(.secondary)
            
            // Files Moved
            if !results.filesMoved.isEmpty {
               Section("Files Moved") {
                  ForEach(results.filesMoved) { file in
                     Text(file.name)
                  }
               }
            }
            
            // NFO Files Created
            if !results.nfoFilesCreated.isEmpty {
               Section("NFO Files Created") {
                  ForEach(results.nfoFilesCreated, id: \.self) { url in
                     Text(url.lastPathComponent)
                  }
               }
            }
            
            // Warnings
            if !results.warnings.isEmpty {
               Section("Warnings") {
                  ForEach(results.warnings, id: \.self) { warning in
                     Text(warning)
                        .foregroundColor(.orange)
                  }
               }
            }
            
            // Errors
            if !results.errors.isEmpty {
               Section("Errors") {
                  ForEach(results.errors, id: \.self) { error in
                     Text(error)
                        .foregroundColor(.red)
                  }
               }
            }
         }
         .padding()
      }
   }
}

