import SwiftUI
import Foundation
import AVFoundation
import Combine
import UniformTypeIdentifiers

class FileMetadataViewModel: ObservableObject {
   @Published var file: FileItem?
   @Published var videoMetadata: VideoMetadata?
   @Published var imageMetadata: ImageMetadata?
   @Published var audioMetadata: AudioMetadata?
   @Published var metadataText: String = ""

   let fileSystem: FileSystem
   private var cancellables = Set<AnyCancellable>()

   init(_ rootURL: URL?) {
      self.fileSystem = FileSystem(rootURL)
   }
   
   func updateMetadata(for fileItem: FileItem) {
      self.file = fileItem
      videoMetadata = nil
      imageMetadata = nil
      
      Task {
         do {
            try await extractMetadata(fileItem.url)
         } catch {
            logError(error)
         }
      }
   }
   
   // Method to retrieve a file by its ID (needed for multiselect)
   func file(for fileID: FileItem.ID) -> FileItem? {
       // This will be called from the view which has access to the items array
       // For now, return nil - the view should handle this differently
       return nil
   }
   
   func contentType(file: FileItem?) -> FileSystem.FileContentType {
      if let file {
         return fileSystem.identifyFileType(at: file.url)
      } else {
         return .unknown
      }
   }
   
   func extractMetadata(_ url: URL) async throws {
      // Extract basic metadata
      //let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
      
      // Extract file type
      let contentType = fileSystem.identifyFileType(at: url)
      
      // Extract video metadata
      extractVideoMetadata(url, contentType: contentType)
      
      // Extract image metadata
      extractImageMetadata(url, contentType: contentType)
      
      // Generate metadata text
      generateMetadataText()
   }

   private func extractVideoMetadata(_ url: URL, contentType: FileSystem.FileContentType) {
      guard contentType == .mkv || contentType == .mp4 || contentType == .avi else {
         return
      }
      
      if ( contentType == .mkv ) {
         fileSystem.accessURL(url, { url in
            if let url {
               do {
                  let parser = try DirectMKVParser(fileURL: url)

                  let metadata = parser.parseContent()
                  debug("duration:\((metadata?.durationInSeconds ?? 0)/60)")

                  self.videoMetadata = VideoMetadata(
                     duration: metadata?.durationInSeconds ?? 0,
                     //resolution: videoTrack.naturalSize,
                     //frameRate: Double(videoTrack.nominalFrameRate),
                     //videoCodec: videoTrack.mediaSubtype
                  )
               } catch {
                  logError(error)
               }
            }
         })
         
         return
      }
      
      let asset = AVURLAsset(url: url)
      
      // Load asset metadata
      Task {
         await MainActor.run {
            self.extractVideoMetadataSync(url, asset)
         }
      }
   }

   //   private func extractVideoMetadata(_ url: URL, contentType: FileSystem.FileContentType) {
//      guard contentType == .mkv || contentType == .mp4 || contentType == .avi else {
//         return
//      }
//      
//      let asset = AVURLAsset(url: url)
//      let loadOptions: [String: Any] = [
//         .allowsMediaSelection: false,
//         .preferredMaximumMediaBitrate: 0
//      ]
//      
//      let assetLoadPromise = asset.load(.from: .none, options: loadOptions)
//
//      assetLoadPromise.whenComplete { _ in
//         Task {
//            await MainActor.run {
//               self.extractVideoMetadataSync(asset)
//            }
//         }
//      }
//   }

    private func extractVideoMetadataSync(_ url: URL,_ asset: AVAsset) {
       let metadata = asset.metadata
       let tracks = asset.tracks(withMediaType: .video)
       let audioTracks = asset.tracks(withMediaType: .audio)
       
       // Get duration
       let duration = asset.duration
       if duration.seconds > 0 {
          self.videoMetadata = VideoMetadata(duration: duration.seconds)
       }
       
       // Get video track information
       if let videoTrack = tracks.first {
          let trackDuration = videoTrack.timeRange
          if trackDuration.duration.seconds > 0 {
             self.videoMetadata = VideoMetadata(
               duration: trackDuration.duration.seconds,
               resolution: videoTrack.naturalSize,
               frameRate: Double(videoTrack.nominalFrameRate),
               //videoCodec: videoTrack.mediaSubtype
             )
          }
       }
       
       // Get audio track information
       if let audioTrack = audioTracks.first {
          let trackDuration = audioTrack.timeRange
          if trackDuration.duration.seconds > 0 {
             self.videoMetadata = VideoMetadata (
               //audioCodec: audioTrack.mediaSubtype
               //videoMetadata.audioBitrate = audioTrack.nominalBitrate
             )
          }
       }
       
       do {
          // Get container information
          self.videoMetadata?.container = try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType
       } catch {
          logError(error)
       }
    }
    
    private func extractImageMetadata(_ url: URL, contentType: FileSystem.FileContentType) {
//        guard contentType == .jpeg || contentType == .png else {
//            return
//        }
//        
//        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
//            return
//        }
//        
//        //defer { CGImageSourceRelease(source) }
//        
//        // Get image properties
//        if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
//            // Get dimensions
//            if let width = props[kCGImagePropertyPixelWidth as String] as? Int,
//               let height = props[kCGImagePropertyPixelHeight as String] as? Int {
//               self.imageMetadata = ImageMetadata(
//                    dimensions: CGSize(width: Double(width), height: Double(height)),
//                    //colorSpace: props[kCGImagePropertyColorSpaceName as String] as? String,
//                    //bitDepth: props[kCGImagePropertyBitsPerComponent as String] as? String
//                )
//            }
//        }
    }
    
    private func generateMetadataText() {
//        var text = "=== File Metadata ===\n\n"
//        
//        if let file = file {
//            text.append("Basic Information:\n")
//            text.append("- Name: \(file.name)\n")
//            text.append("- Type: \(file.type)\n")
//            text.append("- Size: \(file.formattedSize)\n")
//            text.append("- Path: \(file.path)\n")
//            
////            if let attributes = file.attributes {
////                text.append("- Created: \(formatDate(attributes.creationDate))\n")
////                text.append("- Modified: \(formatDate(attributes.modifiedDate))\n")
////            }
//            text.append("\n")
//        }
//        
//       if let videoMetadata = self.videoMetadata {
//            text.append("Video Information:\n")
//            text.append("- Duration: \(formatDuration(videoMetadata.duration))\n")
//            text.append("- Resolution: \(formatResolution(videoMetadata.resolution))\n")
//            text.append("- Frame Rate: \(formatFrameRate(videoMetadata.frameRate))\n")
//            text.append("- Video Codec: \(videoMetadata.videoCodec ?? "N/A")\n")
//            if let audioCodec = videoMetadata.audioCodec {
//                text.append("- Audio Codec: \(audioCodec)\n")
//            }
//            text.append("- Container: \(getContainerName(file?.contentType))\n")
//            text.append("\n")
//        }
//        
//       if let imageMetadata = self.imageMetadata {
//            text.append("Image Information:\n")
//            text.append("- Dimensions: \(formatResolution(imageMetadata.dimensions))\n")
//            text.append("- Color Space: \(imageMetadata.colorSpace ?? "N/A")\n")
//            text.append("- Bit Depth: \(imageMetadata.bitDepth ?? "N/A")\n")
//            text.append("\n")
//        }
//        
//        metadataText = text
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
    
    private func getContainerName(_ contentType: FileSystem.FileContentType) -> String {
        switch contentType {
        case .mkv: return "Matroska (MKV)"
        case .mp4: return "MPEG-4"
        case .avi: return "AVI"
        case .mp3, .wav, .jpeg, .png: return "N/A"
        default: return "N/A"
        }
    }
}

struct VideoMetadata {
    var duration: TimeInterval = 0
    var resolution: CGSize = .zero
    var frameRate: Double = 0
    var videoCodec: String?
    var audioCodec: String?
    var videoBitrate: Int = 0
    var audioBitrate: Int = 0
    var container: FileAttributeType?
}

struct ImageMetadata {
    var dimensions: CGSize
    var colorSpace: String?
    var bitDepth: String?
}

struct AudioMetadata {
   var duration: TimeInterval = 0
   var resolution: CGSize = .zero
   var frameRate: Double = 0
   var videoCodec: String?
   var audioCodec: String?
   var videoBitrate: Int = 0
   var audioBitrate: Int = 0
   var container: FileAttributeType?
}

extension FileItem {
//    var contentType: FileSystem.FileContentType {
//        //FileSystem().identifyFileType(at: url)
//    }
}
