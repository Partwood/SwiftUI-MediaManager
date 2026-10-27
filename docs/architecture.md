# MediaManager Architecture

## Project Structure

### Core Architecture
- **MVVM Pattern**: Views (FileBrowserView, FileMetadataView, CutPasteView) with corresponding ViewModels
- **SwiftUI-Based UI**: All interfaces built with SwiftUI for macOS
- **FileSystem Layer**: Custom FileSystem class for file operations with security-scoped resource support
- **Multiselect Support**: FileBrowserView supports Ctrl/Cmd+Click and Shift+Click for multi-selection
- **Cut/Paste Operations**: CutPasteViewModel manages cut buffer and paste operations with conflict resolution
- **File Metadata Side Panel**: FileMetadataView displays detailed file metadata when a file is selected
- **New Folder Creation**: Context menu allows creating new directories within the browser
- **Custom Sorting**: Array extension with `sorted(using:)` method ensures \"..\" (parent directory) always sorts to the top

### Data Models
- **FileItem**: Represents files in the browser with properties like name, size, type, path, duration
- **FileAttributes**: Extended attributes from FileSystem (fileType, creationDate, modifiedDate, permissions, fileSize)
- **CutBufferItem**: Represents files in the cut buffer for paste operations

### Key Features
- **Multiselect**: Users can select multiple files using modifier keys
- **Cut/Paste**: Full cut and paste functionality with conflict resolution dialogs
- **New Folder**: Right-click context menu to create new directories
- **File Metadata Side Panel**: Detailed metadata display for images, videos (including MKV), and audio files
- **Parent Directory Navigation**: \"..\" folder always appears at the top of sorted lists

### Key Components
1. **SwiftUI-Based UI**: Uses SwiftUI for macOS interface development
2. **File Management**: Implements file browsing, metadata access, and operations
3. **URL Handling**: Supports external URL interactions
4. **Error Handling**: Custom error types for robustness
5. **Logging System**: Centralized logging for debugging and monitoring

### File Organization
- **docs/**: Architecture documentation, feature specifications
- **MyApp.swift**: Entry point and main application setup
- **ContentView.swift**: Root view for the application
- **FileBrowserView.swift**: File browsing interface implementation
- **FileSystem.swift**: Core file system operations
- **extURL.swift**: URL handling and network operations
- **Logging.swift**: Logging utility implementation
- **Errors/**: Directory containing custom error types
- **Assets.xcassets**: App resources and icons
