//
//  ConfirmationDialog.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI

/// Confirmation dialog before executing organization
struct ConfirmationDialog: View {
    let results: OrganizationResults
    let mediaType: MediaType
    let title: String
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Summary
            Text("Confirm Organization")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This will:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            List {
               let filesMoved = results.filesMoved.count// {
               Text("• Move \(filesMoved) file\(filesMoved == 1 ? "" : "s")")
               let nfoFiles = results.nfoFilesCreated.count //{
               Text("• Create \(nfoFiles) NFO file\(nfoFiles == 1 ? "" : "s")")
               if !results.warnings.isEmpty {
                  Text("• \(results.warnings.count) warning\(results.warnings.count == 1 ? "" : "s")")
                     .foregroundColor(.orange)
               }
               if !results.errors.isEmpty {
                  Text("• \(results.errors.count) error\(results.errors.count == 1 ? "" : "s")")
                     .foregroundColor(.red)
               }
            }
            .listStyle(.inset)
            
            // Warning/Error Messages
            if !results.warnings.isEmpty || !results.errors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !results.warnings.isEmpty {
                        Text("Warnings:")
                            .font(.headline)
                            .foregroundColor(.orange)
                       ForEach(results.warnings, id: \.self) { warning in
                          Text("  • \(warning)")
                             .foregroundColor(.orange)
                       }
                    }
                    if !results.errors.isEmpty {
                        Text("Errors:")
                            .font(.headline)
                            .foregroundColor(.red)
                       ForEach(results.errors, id: \.self) { error in
                            Text("  ✗ \(error)")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Confirm") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

#Preview {
    ConfirmationDialog(
        results: OrganizationResults(),
        mediaType: .tvShow,
        title: "Test Show"
    )
}
