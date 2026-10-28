import SwiftUI
import AVFoundation
import ImageIO

struct FileMetadataView: View {
   @ObservedObject var viewModel: FileMetadataViewModel
   
   @Binding var selectedFileID: FileItem.ID?
   @Binding var showMetadataPanel: Bool
        
      var body: some View {
         List {
            VStack(alignment: .leading, spacing: 0) {
               Upper(viewModel: viewModel,selectedFileID: $selectedFileID,showMetadataPanel: $showMetadataPanel)
               
               Divider()
                  .padding(.vertical, 5)
            
               VStack(alignment: .leading, spacing: 8) {
                  // Basic File Information
                  BasicInformation(viewModel: viewModel)
                  
                  ContentInformation(viewModel: viewModel)
                  
                  Spacer()
               }
               .padding(0)
            }
            .padding(0)
         }
         .padding(0)
         .listStyle(.plain)
    }
}

struct Upper: View {
   @ObservedObject var viewModel: FileMetadataViewModel

   @Binding var selectedFileID: FileItem.ID?
   @Binding var showMetadataPanel: Bool

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
   
   private func dismiss() {
      selectedFileID = nil
      showMetadataPanel = false
   }

   var body: some View {
      HStack(spacing: 0) {
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
         .padding(0)
      }
      .padding(0)
   }
}

struct ContentInformation: View {
   @ObservedObject var viewModel: FileMetadataViewModel
   
   var body: some View {
      // File-Specific Metadata
      let contentType = viewModel.contentType(file: viewModel.file)
      switch contentType {
      case .mkv, .mp4, .avi, .unknown:
         // Video/Audio metadata
         if let videoMetadata = viewModel.videoMetadata {
            VideoInformation(contentType: contentType,videoMetadata: videoMetadata)
         }
         
         // Image metadata
         if let imageMetadata = viewModel.imageMetadata {
            ImageInformation(contentType: contentType,imageMetadata: imageMetadata)
         }
      case .nfo:
         // NFO Metadata
         if let nfoMetadata = viewModel.nfoMetadata {
            NFOInformation(nfoMetadata: nfoMetadata)
         }
      case .binary:
         Placeholder()
      case .html:
         Placeholder()
      case .jpeg:
         Placeholder()
      case .markdown:
         Placeholder()
      case .mp3:
         Placeholder()
      case .png:
         Placeholder()
      case .text:
         Placeholder()
      case .xml:
         Placeholder()
      case .wav:
         Placeholder()
      }
   }
}

struct BasicInformation: View {
   @ObservedObject var viewModel: FileMetadataViewModel

   private func formatDate(_ date: Date?) -> String {
      guard let date = date else { return "N/A" }
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .short
      return formatter.string(from: date)
   }

   private func getFileTypeDescription(_ url: URL?) -> String {
      guard let url = url else { return "N/A" }
      let contentType = viewModel.fileSystem.identifyFileType(at: url)
      return contentType.description
   }

   var body: some View {
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
            Label("Size", systemImage: "arrow.up.left.and.arrow.down.right.square")
               .font(.subheadline)
               .foregroundColor(.secondary)
            Text(viewModel.file?.formattedSize ?? "N/A")
               .font(.body)
               .foregroundColor(.primary)
         }
         
         VStack(alignment: .leading, spacing: 4) {
            Label("Path", systemImage: "ellipsis.rectangle")
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
   }
}

struct VideoInformation: View {
   @State var contentType: FileSystem.FileContentType
   @State var videoMetadata: VideoMetadata
   
   private func getContainerName(_ contentType: FileSystem.FileContentType) -> String {
      switch contentType {
      case .mkv: return "Matroska (MKV)"
      case .mp4: return "MPEG-4"
      case .avi: return "AVI"
      case .mp3, .wav, .jpeg, .png: return "N/A"
      default: return "N/A"
      }
   }

   private func formatDuration(_ seconds: TimeInterval) -> String {
      let hours = Int(seconds) / 3600
      let minutes = (Int(seconds) % 3600) / 60
      let secs = Int(seconds) % 60
      
      if hours > 0 {
         return String(format: "%02d:%02d:%02d hours", hours, minutes, secs)
      } else {
         return String(format: "%02d:%02d mins", minutes, secs)
      }
   }
   
   private func formatFrameRate(_ frameRate: Double) -> String {
      return String(format: "%.2f fps", frameRate)
   }
   
   private func formatBitrate(_ bitrate: Int) -> String {
      let formatter = ByteCountFormatter()
      formatter.countStyle = .binary
      return formatter.string(fromByteCount: Int64(bitrate))
   }

   private func formatResolution(_ resolution: CGSize) -> String {
      let width = Int(round(resolution.width))
      let height = Int(round(resolution.height))
      return "\(width) × \(height)"
   }

   var body: some View {
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
}

struct ImageInformation: View {
   @State var contentType: FileSystem.FileContentType
   @State var imageMetadata: ImageMetadata

   private func formatResolution(_ resolution: CGSize) -> String {
      let width = Int(round(resolution.width))
      let height = Int(round(resolution.height))
      return "\(width) × \(height)"
   }

   private func getImageFormatName(_ contentType: FileSystem.FileContentType) -> String {
      switch contentType {
      case .jpeg: return "JPEG"
      case .png: return "PNG"
      default: return "Unknown"
      }
   }
   
   var body: some View {
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
}

struct Placeholder: View {
   var body: some View {
      Text("Information")
         .font(.headline)
      Text("No additional metadata available for this file type.")
         .foregroundColor(.secondary)
   }
}

struct NFOInformation: View {
   @State var nfoMetadata: NFOMetadata
   
   var body: some View {
         Section {
            // Basic NFO Info
            VStack(alignment: .leading, spacing: 4) {
               Label("Title", systemImage: "text.badge.plus")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.title ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Plot", systemImage: "doc.text")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.plot ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
                  .lineLimit(3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Year", systemImage: "calendar")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.year ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            if let seasonNumber = nfoMetadata.seasonNumber {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Season", systemImage: "calendar")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  Text("\(seasonNumber)")
                     .font(.body)
                     .foregroundColor(.primary)
               }
            }
            
            if let episodeNumber = nfoMetadata.episodeNumber {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Episode", systemImage: "calendar")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  Text("\(episodeNumber)")
                     .font(.body)
                     .foregroundColor(.primary)
               }
            }
            
            if let episodeCount = nfoMetadata.episodeCount {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Episodes", systemImage: "calendar")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  Text("\(episodeCount)")
                     .font(.body)
                     .foregroundColor(.primary)
               }
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Rating", systemImage: "star")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.rating ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Genre", systemImage: "list.bullet.clipboard")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.genre ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Director", systemImage: "person.fill")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.director ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Writer", systemImage: "pencil")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.writer ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Studio", systemImage: "building.2")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.studio ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Runtime", systemImage: "clock")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.runtime ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
               Label("Tagline", systemImage: "quote.bubble")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               Text(nfoMetadata.tagline ?? "N/A")
                  .font(.body)
                  .foregroundColor(.primary)
            }
            
            // Cast
            if !nfoMetadata.cast.isEmpty {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Cast", systemImage: "person.3")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  ForEach(nfoMetadata.cast, id: \.name) { cast in
                     HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                           .font(.caption)
                        Text("\(cast.name)")
                           .font(.body)
                           .foregroundColor(.primary)
                        if !cast.role.isEmpty {
                           Text(" - \(cast.role)")
                              .font(.caption)
                              .foregroundColor(.secondary)
                        }
                     }
                  }
               }
            }
            
            // Actors
            if !nfoMetadata.actors.isEmpty {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Actors", systemImage: "person.3")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  ForEach(nfoMetadata.actors, id: \.self) { actor in
                     Text(actor)
                        .font(.body)
                        .foregroundColor(.primary)
                  }
               }
            }
            
            // Languages
            if !nfoMetadata.languages.isEmpty {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Languages", systemImage: "globe")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  ForEach(nfoMetadata.languages, id: \.self) { lang in
                     Text(lang)
                        .font(.body)
                        .foregroundColor(.primary)
                  }
               }
            }
            
            // Countries
            if !nfoMetadata.countries.isEmpty {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Countries", systemImage: "globe.americas")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  ForEach(nfoMetadata.countries, id: \.self) { country in
                     Text(country)
                        .font(.body)
                        .foregroundColor(.primary)
                  }
               }
            }
            
            // Additional info
            if !nfoMetadata.additionalInfo.isEmpty {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Additional Info", systemImage: "info.circle")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  //                                        ForEach(nfoMetadata.additionalInfo, id: \.key) { key, value in
                  //                                            HStack {
                  //                                                Text(key)
                  //                                                    .font(.caption)
                  //                                                    .foregroundColor(.secondary)
                  //                                                Spacer()
                  //                                                Text(value)
                  //                                                    .font(.caption)
                  //                                                    .foregroundColor(.primary)
                  //                                            }
                  //                                        }
               }
            }
            
            // Image references
            if let poster = nfoMetadata.poster {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Poster", systemImage: "photo.on.rectangle")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  Text(poster)
                     .font(.caption)
                     .foregroundColor(.secondary)
               }
            }
            
            if let fanart = nfoMetadata.fanart {
               VStack(alignment: .leading, spacing: 4) {
                  Label("Fanart", systemImage: "paintbrush")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                  Text(fanart)
                     .font(.caption)
                     .foregroundColor(.secondary)
               }
            }
         } header: {
            Text("NFO Metadata")
               .font(.headline)
         }
   }
}
