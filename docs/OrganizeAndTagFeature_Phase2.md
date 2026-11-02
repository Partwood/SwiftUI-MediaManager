# OrganizeAndTag Feature - Phase 2 Implementation

## Overview
Phase 2 builds upon Phase 1 (parsing engine) to add:
- UI components for user interaction
   - File organization logic
   - NFO file generation
   - Integration with main app
                     
## Phase 2 Components

### 1. UI Components
- `ImportPanelView.swift` - Main UI for input and configuration
- `OrganizationPreviewView.swift` - Preview what will be created
- `ConfirmationDialog.swift` - Final confirmation dialog

### 2. File Organization
- `FileOrganizer.swift` - Logic for organizing files
- `FileRenamer.swift` - Rename files according to conventions
- `DirectoryManager.swift` - Create and manage directory structure

### 3. NFO Generation
- `NFOGenerator.swift` - Generate NFO files for episodes and movies
- `NFOValidator.swift` - Validate NFO file syntax

### 4. Integration
- `OrganizeAndTagViewModel.swift` - ViewModel for coordinating operations
- `OrganizeAndTagView.swift` - Main view controller

## File Naming Conventions

### Episode Files
```
Format: "[Episode Number] - [Episode Title].mkv"
Examples:
   - "01 - Pilot.mkv"
- "S01E03 - The Reporter.mkv"
```

### Alternative Cut Episodes
```
Format: "[Episode Number] - [Title] - [Cut Type].mkv"
Examples:
   - "01 - Rock Show - Original Cut.mkv"
- "02 - Rock Show - Producer's Extended Cut.mkv"
```

### Commentary Tracks
```
Format: "Commentary - [Episode Title].mkv"
Examples:
   - "Commentary - Pilot.mkv"
```

### Deleted Scenes
```
Format: "Deleted Scene - [Scene Description].mkv"
Examples:
   - "Deleted Scene - Pilot (8:20).mkv"
- "Deleted Scene - Scene 92 (1:31).mkv"
```

### Music Videos
```
Format: "[Artist] - [Song Title].mkv"
Examples:
   - "Pit - Ann.mkv"
```

### Trailers
```
Format: "Trailer - [Movie/Show Title].mkv"
Examples:
   - "Trailer - Skyfall.mkv"
```

### Featurettes and Behind-the-Scenes
```
Format: "[Type] - [Title].mkv"
Examples:
   - "Featurette - Shooting Bond.mkv"
- "Behind the Scenes - DB5.mkv"
```

## NFO File Naming
```
Format: Same as the video file name (without extension)
Examples:
   - "01 - Pilot.nfo"
- "Commentary - Pilot.nfo"
- "extras/Deleted Scene - Pilot.nfo"
```

## Directory Structure

### TV Shows
```
/TV Shows/Show Name/Season 1/
├── Pilot.mkv
├── Canvassing.mkv
└── extras/
├── Commentary - Pilot.mkv
├── Deleted Scene - Pilot.mkv
└── Music Videos/
├── Pit.mkv
└── Ann.mkv
```

### Movies
```
/Movies/Movie Name/
├── Movie.mkv
└── extras/
├── Commentary - Movie.mkv
├── Deleted Scene - Movie.mkv
└── Featurettes/
└── Shooting Bond.mkv
```

## Implementation Priority

1. **NFOGenerator.swift** - Generate NFO files (core functionality)
2. **FileOrganizer.swift** - Organize files into proper structure
3. **ImportPanelView.swift** - UI for input
4. **OrganizationPreviewView.swift** - Preview before execution
5. **OrganizeAndTagViewModel.swift** - Coordinate operations
                     
### 5. Integration (NOT IMPLEMENTED)
- **MISSING**: `OrganizeAndTagViewModel.swift` - ViewModel for coordinating operations
- **MISSING**: `OrganizeAndTagView.swift` - Main view controller to integrate with main app
- **MISSING**: Integration with main `FileBrowserView` to trigger organization from file selection

### 6. Implementation Status

#### Phase 1 - Parsing Engine ✅ COMPLETE
- ✅ `DVDCompareParser.swift` - Main parser with encoding handling
- ✅ `InputPreprocessor.swift` - Preprocesses input for encoding issues
- ✅ `DurationParser.swift` - Converts duration strings to TimeInterval
- ✅ Data Models: `DVDCompareContent.swift`, `Episode.swift`, `Extra.swift`, `ExtraType.swift`, `MediaType.swift`, `MergeStrategy.swift`

#### Phase 2 - UI & Organization ⚠️ PARTIALLY IMPLEMENTED

**UI Components** ✅ COMPLETE:
- ✅ `ImportPanelView.swift` - Main UI for input and configuration
- ✅ `OrganizationPreviewView.swift` - Preview what will be created
- ✅ `ConfirmationDialog.swift` - Final confirmation dialog
- ✅ `ImportPanelViewModel.swift` - ViewModel for import panel operations

**File Organization** ⚠️ PARTIALLY IMPLEMENTED:
- ⚠️ `FileOrganizer.swift` - Core logic exists but needs completion
- ⚠️ `NFOGenerator.swift` - Exists but needs completion
- ✅ `OrganizationResults.swift` - Struct for tracking results
- ❌ **MISSING**: `FileRenamer.swift` - Rename files according to conventions
- ❌ **MISSING**: `DirectoryManager.swift` - Create and manage directory structure

**Integration** ❌ NOT STARTED:
- ❌ **MISSING**: `OrganizeAndTagViewModel.swift` - ViewModel for coordinating operations
- ❌ **MISSING**: `OrganizeAndTagView.swift` - Main view controller
- ❌ **MISSING**: Integration with main `FileBrowserView`

## Next Steps / Gaps

### Phase 2 Completion Priorities

1. **Complete NFOGenerator.swift** (High Priority)
   - Add `generateMovieNFO` method
   - Add `generateEpisodeNFOContent` method
   - Handle different NFO field requirements for movies vs TV shows

2. **Complete FileOrganizer.swift** (High Priority)
   - Finish `organizeEpisode` method
   - Implement `organizeMovie` method
   - Complete `organizeExtras` method
   - Implement `organizeCommentaries`, `organizeDeletedScenes`, etc.
   - Add file deletion logic for files that shouldn't exist

3. **Create Missing Files** (Medium Priority)
   - Create `FileRenamer.swift` - Implement file renaming logic
   - Create `DirectoryManager.swift` - Implement directory creation and management
   - Create `OrganizeAndTagViewModel.swift` - ViewModel to coordinate all operations
   - Create `OrganizeAndTagView.swift` - Main view controller

4. **Integration with Main App** (High Priority)
   - Add button or menu item in `FileBrowserView` to trigger organization
   - Allow users to select files from browser and organize them
   - Integrate with existing cut/paste workflow if applicable

5. **Enhance Features** (Low Priority)
   - Add support for multi-disc TV shows (season.nfo in each disc directory)
   - Add file conflict resolution UI
   - Add support for additional extra types
   - Add undo/rollback functionality
