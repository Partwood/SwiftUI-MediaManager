# File Metadata Side Panel Feature

## Overview
A side panel that displays detailed metadata information about selected files when the user clicks on a file in the file browser. This provides an enhanced viewing experience for file information beyond what is shown in the main table.

## User Flow
1. User clicks on a file in the main file browser table
2. Side panel slides in from the right side
3. Side panel displays comprehensive metadata for the selected file
4. User can navigate to file location or open file with default application

## Displayed Information

### Basic File Information (All Files)
- **Name**: File name
- **Type**: File type (image, video, audio, document, etc.)
- **Size**: File size in human-readable format
- **Path**: Full file path
- **Modified Date**: Last modification date and time
- **Created Date**: File creation date (if available)
- **Permissions**: File permissions (rwx for user/group/other)

### Image-Specific Metadata
- **Dimensions**: Width x Height (e.g., 1920x1080)
- **Color Space**: Color profile information
- **Format**: Image format (JPEG, PNG, TIFF, etc.)
- **Bit Depth**: Color bit depth
- **Exif Data**: Camera settings, GPS location, etc.

### Video-Specific Metadata
- **Duration**: Video length (e.g., 02:45:30)
- **Resolution**: Width x Height (e.g., 1920x1080)
- **Frame Rate**: FPS (e.g., 23.976 fps)
- **Codec**: Video codec (e.g., H.264, HEVC)
- **Audio Codec**: Audio codec (e.g., AAC, MP3)
- **Bitrate**: Video/audio bitrate
- **Container**: File container format (e.g., MP4, MKV, MOV)

### Audio-Specific Metadata
- **Duration**: Track length
- **Sample Rate**: Sample rate (e.g., 44.1 kHz)
- **Bit Depth**: Audio bit depth (e.g., 16-bit, 24-bit)
- **Channels**: Number of channels (e.g., Stereo, 5.1 Surround)
- **Codec**: Audio codec (e.g., AAC, FLAC, MP3)
- **Bitrate**: Audio bitrate
- **Album/Artist**: If ID3 tags available
- **Track Number**: Track number in album
- **Genre**: Music genre

### File Tagging Support
- **Tags**: Custom tags if available (e.g., Xattr on macOS)
- **Keywords**: Search keywords
- **Labels**: User-defined labels
- **Comments**: File comments

## UI Design

### Layout
- **Position**: Right side of main window
- **Width**: ~350-400 pixels
- **Height**: Matches main window height
- **Animation**: Smooth slide-in/slide-out animation
- **State**: Hidden by default, shown when file is selected

### Visual Design
- **Background**: Semi-transparent or blurred background for context
- **Header**: Shows "File Details" with close button
- **Sections**: Grouped information with clear section headers
- **Typography**: Clean, readable font with appropriate hierarchy
- **Icons**: Small icons next to each metadata field for visual clarity

### Interactions
- **Close Button**: Top-right corner to dismiss panel
- **Copy to Clipboard**: Button to copy specific fields or all metadata
- **Open File**: Button to open file with default application
- **Show in Finder**: Button to reveal file in macOS Finder
- **Expand/Collapse Sections**: Optional accordion for less-used metadata

## Technical Implementation

### Data Sources
- **File Attributes**: `FileManager.attributesOfItem(atPath:)`
- **Image Metadata**: `ImageIO` or `CGImageSource`
- **Video Metadata**: `AVAsset` or `AVURLAsset` with `AVAssetMetadataKey`
- **Audio Metadata**: `AVAsset` or `AVURLAsset` with `AVAssetMetadataKey`
- **Tags**: `FileManager.attributesOfItem(atPath:)` with `FileAttributeKey.finderTags`

### State Management
- Selected file ID stored in `FileBrowserView`
- Side panel view model holds metadata for selected file
- Reactive updates when selection changes

### Error Handling
- Gracefully handle files with unavailable metadata
- Display "N/A" for missing information
- Show error messages for inaccessible files

## Future Enhancements
- [ ] Search/filter metadata fields
- [ ] Export metadata to text file
- [ ] Edit tags/keywords
- [ ] Compare metadata between files
- [ ] Metadata history/changes tracking
- [ ] Integration with external metadata tools

## Dependencies
- macOS Foundation framework
- Core Image / ImageIO (for image metadata)
- AVFoundation (for video/audio metadata)
- UniformTypeIdentifiers (for type detection)