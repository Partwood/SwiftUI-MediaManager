# MediaManager

## Overview
MediaManager is a macOS application designed to provide a file browser-like experience for managing media files. It allows users to browse directories, view file previews, and access metadata for various file types (e.g., videos, music). Additionally, it supports restructuring operations to align with Jellyfin's organizational needs and generates XML-based NFO files for media metadata.

## Key Features
- **Directory Browsing**: Open and navigate through user directories (e.g., home directory or custom paths).
- **File Previews**: Display previews for supported media types (images, videos, audio).
- **Metadata Display**: Show general metadata (file size, type) and media-specific details (e.g., video duration, audio bitrate).
- **Restructuring Operations**:
  - Categorize directories as movies, TV shows, or extras.
  - Move files based on criteria (e.g., duration thresholds).
- **NFO File Generation**: Export XML-based metadata files for media organization.

## Future Plans
- Enhanced metadata parsing for additional file types.
- Integration with Jellyfin for automated library updates.
- Support for media conversion and tagging.
- User-defined presets for restructuring rules.

## Project Structure
- **MediaManager/**: Main source code directory
  - **Core files**: MyApp.swift, ContentView.swift, FileBrowserView.swift, FileSystem.swift, FileItem.swift, Logging.swift, extURL.swift, NewFolderView.swift
  - **CutAndPaste/**: Cut and paste operation implementation
  - **MetadataView/**: File metadata display side panel
  - **TypeParsers/**: File type parsing (NFO, Markov)
  - **Errors/**: Custom error types
  - **Assets.xcassets/**: App resources and icons
- **docs/**: Architecture documentation and feature specifications
- **MediaManager.xcodeproj/**: Xcode project files

## Key Features
- **Directory Browsing**: Open and navigate through user directories (e.g., home directory or custom paths).
- **File Previews**: Display previews for supported media types (images, videos, audio).
- **Metadata Display**: Show general metadata (file size, type) and media-specific details (e.g., video duration, audio bitrate).
- **Multiselect Support**: Select multiple files using Ctrl/Cmd+Click and Shift+Click.
- **Cut/Paste Operations**: Full cut and paste functionality with conflict resolution.
- **New Folder Creation**: Right-click context menu to create new directories.
- **File Metadata Side Panel**: Detailed metadata display for images, videos (including MKV), and audio files.
- **NFO File Support**: Detection and parsing of Jellyfin-compatible NFO files.
- **Restructuring Operations**:
  - Categorize directories as movies, TV shows, or extras.
  - Move files based on criteria (e.g., duration thresholds).

## Technologies
- Built with **Swift** and **SwiftUI** for macOS.
- Utilizes **MCP functions** for system operations (file management, web requests, etc.).

## Getting Started
1. Clone the repository: `git clone https://github.com/yourusername/MediaManager.git`
2. Open in Xcode and build for macOS.
3. Run the application and explore the file browser interface.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to add.

## License
MIT License - See [LICENSE](LICENSE) file for details.
