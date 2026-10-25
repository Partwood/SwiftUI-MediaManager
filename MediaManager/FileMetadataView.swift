import SwiftUI
import AVFoundation
import ImageIO

struct FileMetadataView: View {
    @ObservedObject var viewModel: FileMetadataViewModel
    @Binding var selectedFileID: FileItem.ID?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("File Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 8) {
                        if let fileURL = viewModel.file?.url {
                            Button(action: { showInFinder(fileURL) }) {
                                Image(systemName: "arrow.up.square")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .help("Show in Finder")
                            
                            Button(action: { openFile(fileURL) }) {
                                Image(systemName: "play.circle")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .help("Open File")
                            
                            Button(action: { copyMetadata() }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .help("Copy Metadata")
                        }
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Basic File Information
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Name", systemImage: "text.badge.plus")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(viewModel.file?.name ?? "N/A")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Type", systemImage: "square.grid.3x3")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(getFileTypeDescription(viewModel.file?.url))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Size", systemImage: "arrow.2.uparrow")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(viewModel.file?.formattedSize ?? "N/A")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Path", systemImage: "path")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(viewModel.file?.path ?? "N/A")
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Modified", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatDate(viewModel.file?.modifiedDate))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Created", systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatDate(viewModel.file?.creationDate))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Basic Information")
                        .font(.headline)
                }
                
                // File-Specific Metadata
               let contentType = viewModel.contentType(file: viewModel.file)
               //if let contentType = viewModel.contentType(file: viewModel.file) {
                    switch contentType {
                    case .mkv, .mp4, .avi, .unknown:
                        // Video/Audio metadata
                        if let videoMetadata = viewModel.videoMetadata {
                            Section {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Duration", systemImage: "play.circle")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatDuration(videoMetadata.duration))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Resolution", systemImage: "square.and.arrow.up")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatResolution(videoMetadata.resolution))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Frame Rate", systemImage: "clock.arrow.circlepath")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatFrameRate(videoMetadata.frameRate))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Video Codec", systemImage: "video")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(videoMetadata.videoCodec ?? "N/A")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Audio Codec", systemImage: "waveform")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(videoMetadata.audioCodec ?? "N/A")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Video Bitrate", systemImage: "network")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatBitrate(videoMetadata.videoBitrate))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                               let audioBitrate = videoMetadata.audioBitrate
                                if audioBitrate > 0 {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label("Audio Bitrate", systemImage: "network")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(formatBitrate(audioBitrate))
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Container", systemImage: "box")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(getContainerName(contentType))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            } header: {
                                Text("Video Information")
                                    .font(.headline)
                            }
                        }
                        
                        // Image metadata
                        if let imageMetadata = viewModel.imageMetadata {
                            Section {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Dimensions", systemImage: "square.and.arrow.up")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatResolution(imageMetadata.dimensions))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Color Space", systemImage: "paintbrush")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(imageMetadata.colorSpace ?? "N/A")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Format", systemImage: "doc.text")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(getImageFormatName(contentType))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Bit Depth", systemImage: "slider.horizontal.3")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(imageMetadata.bitDepth ?? "N/A")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            } header: {
                                Text("Image Information")
                                    .font(.headline)
                            }
                        }
                        
                    case .binary:
                       Text("Information")
                          .font(.headline)
                    case .html:
                       Text("Information")
                          .font(.headline)
                    case .jpeg:
                       Text("Information")
                          .font(.headline)
                    case .markdown:
                       Text("Information")
                          .font(.headline)
                    case .mp3:
                       Text("Information")
                          .font(.headline)
                    case .png:
                       Text("Information")
                          .font(.headline)
                    case .text:
                       Text("Information")
                          .font(.headline)
                    case .wav:
                       Text("Information")
                          .font(.headline)
                    }
                    
                    //break
                    //}
//                } else {
//                   // No specific metadata available
//                   Text("No additional metadata available for this file type.")
//                      .foregroundColor(.secondary)
                //}

                Spacer()
            }
            .navigationTitle("File Details")
            .padding(.bottom, 20)
        }
    }
    
    private func dismiss() {
        selectedFileID = nil
    }
    
    private func showInFinder(_ url: URL) {
       NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path(percentEncoded: false))
    }
    
    private func openFile(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
    
    private func copyMetadata() {
        let metadataText = viewModel.metadataText
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(metadataText, forType: .string)
    }
    
    private func getFileTypeDescription(_ url: URL?) -> String {
        guard let url = url else { return "N/A" }
       let contentType = viewModel.fileSystem.identifyFileType(at: url)
        
        switch contentType {
        case .mkv: return "MKV Video"
        case .mp4: return "MP4 Video"
        case .avi: return "AVI Video"
        case .jpeg: return "JPEG Image"
        case .png: return "PNG Image"
        case .mp3: return "MP3 Audio"
        case .wav: return "WAV Audio"
        case .html: return "HTML Document"
        case .markdown: return "Markdown Document"
        case .text: return "Text File"
        case .binary: return "Binary File"
        default: return "Unknown Type"
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private func formatResolution(_ resolution: CGSize) -> String {
        let width = Int(round(resolution.width))
        let height = Int(round(resolution.height))
        return "\(width) × \(height)"
    }
    
    private func formatFrameRate(_ frameRate: Double) -> String {
        return String(format: "%.2f fps", frameRate)
    }
    
    private func formatBitrate(_ bitrate: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
       return formatter.string(fromByteCount: Int64(bitrate))
    }
    
    private func getContainerName(_ contentType: FileSystem.FileContentType) -> String {
        switch contentType {
        case .mkv: return "Matroska (MKV)"
        case .mp4: return "MPEG-4"
        case .avi: return "AVI"
        case .mp3, .wav, .jpeg, .png: return "N/A"
        default: return "N/A"
        }
    }
    
    private func getImageFormatName(_ contentType: FileSystem.FileContentType) -> String {
        switch contentType {
        case .jpeg: return "JPEG"
        case .png: return "PNG"
        default: return "Unknown"
        }
    }
}
