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
                     
