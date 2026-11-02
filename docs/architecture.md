# MediaManager Architecture

## ProjecArchitecture
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
- **MediaManager/**: Main source code directory containing all Swift files
  - **Core files**: MyApp.swift, FileBrowserView.swift, FileSystem.swift, FileItem.swift, Logging.swift, extURL.swift
  - **CutAndPaste/**: Cut and paste operation implementation (CutPasteView.swift, CutPasteViewModel.swift)
  - **MetadataView/**: File metadata display (FileMetadataView.swift, FileMetadataViewModel.swift)
  - **OrganizeAndTag/**: Organize and tag feature implementation
    - **Data Models/**:
      - `MediaType.swift`: Enum for media types (movie, tvShow)
      - `Episode.swift`: Struct for TV episode data
      - `Extra.swift`: Struct for extra content (commentaries, deleted scenes, etc.)
      - `ExtraType.swift`: Enum for extra content types with subdirectory mapping
      - `MergeStrategy.swift`: Enum for handling existing files (replace, skip, rename, mergeMetadata)
      - `DVDCompareContent.swift`: Struct for parsed dvdcompare.net content
    - **File Organization/**:
      - `FileOrganizer.swift`: Core logic for organizing TV shows and movies
      - `NFOGenerator.swift`: Generates Jellyfin-compatible NFO files
      - `OrganizationResults.swift`: Struct for tracking organization results
    - **Parsing Engine/**:
      - `DVDCompareParser.swift`: Parses dvdcompare.net content with encoding handling
      - `DurationParser.swift`: Converts duration strings to TimeInterval
      - `InputPreprocessor.swift`: Preprocesses input for encoding issues
    - **UI Components/**:
      - `ImportPanelView.swift`: Main UI panel for input and configuration
      - `OrganizationPreviewView.swift`: Preview of what will be organized
      - `ConfirmationDialog.swift`: Final confirmation dialog
    - **ViewModel**:
      - `ImportPanelViewModel.swift`: ViewModel for import panel operations
  - **TypeParsers/**: File type parsing (NFO.swift, Markov.swift)
  - **Errors/**: Custom error types (FileIOError.swift, URLError.swift, RegExError.swift)
  - **Assets.xcassets/**: App resources and icons
- **docs/**: Architecture documentation, feature specifications
- **MediaManager.xcodeproj/**: Xcode project files
- **README.md**: Project overview and getting started guide
- **guidelines.md**: Development guidelines
- **system_prompt.md**: System configuration
