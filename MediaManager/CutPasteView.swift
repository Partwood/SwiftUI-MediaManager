//
//  CutPasteView.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI

/// View for resolving file naming conflicts during paste operations
struct ConflictResolutionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CutPasteViewModel
    let existingFileName: String
    let proposedNewFileName: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            // Title
            Text("File Conflict")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Description
            Text("A file named \"\(existingFileName)\" already exists in the destination.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Options
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.handleConflict(.replace)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Replace Existing")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .help("Overwrite the existing file")
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.handleConflict(.keepBoth)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                        Text("Keep Both")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .help("Rename the new file to avoid conflict")
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.handleConflict(.skip)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "slash.circle")
                        Text("Skip This File")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .help("Don't move this file")
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

/// View showing the paste operation progress
struct PasteProgressView: View {
    @ObservedObject var viewModel: CutPasteViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
//            GeometryReader { geometry in
//                ZStack(alignment: .leading) {
//                    Rectangle()
//                        .fill(Color.gray.opacity(0.3))
//                        .frame(height: 8)
//                    
//                    Rectangle()
//                        .fill(Color.blue)
//                        .frame(width: geometry.size.width * CGFloat(viewModel.pasteProgress))
//                        .frame(height: 8)
//                }
//                .cornerRadius(4)
//            }
            
            // Status text
//            Text(viewModel.pasteStatusText)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
            
            // Counts
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Success")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.pasteSuccessCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Skipped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.pasteSkippedCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Failed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.pasteFailedCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    private var pasteProgress: Double {
        let total = max(1, viewModel.pasteSuccessCount + viewModel.pasteSkippedCount + viewModel.pasteFailedCount)
        return Double(viewModel.pasteSuccessCount + viewModel.pasteSkippedCount + viewModel.pasteFailedCount) / Double(total)
    }
    
    private var pasteStatusText: String {
        if viewModel.pasteComplete {
            return "Paste Complete"
        } else if viewModel.isPasteInProgress {
            return "Pasting Files..."
        } else {
            return "Ready to Paste"
        }
    }
}

/// Main cut/paste control view
struct CutPasteControls: View {
    @ObservedObject var viewModel: CutPasteViewModel
    @Binding var selectedFileIDs: Set<FileItem.ID>
    @Binding var currentPath: String
    let fileBrowserView: FileBrowserView
    
    var body: some View {
        HStack(spacing: 8) {
            // Cut button
            Button(action: {
                handleCut()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "scissors")
                    Text("Cut")
                }
                .font(.headline)
                .foregroundColor(.primary)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.cutBuffer.isEmpty)
            .keyboardShortcut(.delete, modifiers: [.command])
            
            // Paste button
            Button(action: {
                handlePaste()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                    Text("Paste")
                }
                .font(.headline)
                .foregroundColor(.primary)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.isCutMode || viewModel.isPasteInProgress)
            .keyboardShortcut(.return, modifiers: [.command])
            
            // Cancel button (shown during paste)
            if viewModel.isPasteInProgress || viewModel.pasteComplete {
                Button(action: {
                    viewModel.cancelPaste()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            // Status indicator
            if viewModel.isCutMode {
                HStack(spacing: 8) {
                    Image(systemName: "scissor")
                    Text("\(viewModel.cutBuffer.count) file(s) cut - ready to paste")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func handleCut() {
        if let selectedFiles = fileBrowserView.getSelectedFiles() {
            viewModel.cut(files: selectedFiles)
        }
    }
    
    private func handlePaste() {
        guard !viewModel.cutBuffer.isEmpty else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Paste Destination"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                viewModel.startPaste(at: url.path)
            }
        }
    }
}
