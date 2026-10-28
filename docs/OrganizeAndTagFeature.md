# Organize & Tag Feature

## Overview

This feature enables users to import metadata from external sources (specifically dvdcompare.net) and organize their media collections. The feature integrates with the existing NFO parsing and management system to provide organization workflow.

### Key Capabilities
- **Import metadata** from dvdcompare.net paste content (handles various encoding issues)
- **Create proper NFO files** for both movies and TV shows following Jellyfin standards
- **Organize directory structures** with proper season/episode hierarchy
- **Handle multi-disc TV shows** with season.nfo duplication across disc directories
- **Separate extras** (commentaries, deleted scenes, music videos, trailers) into organized subdirectories
- **Smart file detection** to identify main content vs. extras based on duration and naming patterns
- **Merge with existing files** - intelligently detects and merges with existing NFO files
- **Conflict resolution** strategies for handling duplicate or conflicting metadata
- **User customization** of organization rules and file naming conventions
- **Preview before execution** - shows what will be created/moved before any changes
- **Partial success handling** - continues processing even if some files fail

### Integration with Existing Features
- Leverages the existing **NFO parsing feature** for metadata extraction
- Uses the **FileSystem class** for all file operations (consistent with project architecture)
- Follows the **MVVM pattern** established in the project
- Compatible with existing **media library scanning** and **metadata management** workflows

## User Flow

### 1. Input Method
User can paste content from dvdcompare.net into a multiline text field in the MediaManager application. The content typically includes content like the examples that follow. The encoding issues that are present are on purpose, the pasted in content could have these issues (so parsing should be used to take them into account):

#### TV Show Examples:
First Example
```
Parks and Recreation: Season 1 (TV) (2009)
Episodes:
- "Pilot" (21:32)
- "Canvassing" (21:25)
- "The Reporter" (21:47)
- "Boys' Club" (21:34)
- "The Banquet" (21:26)
- "Rock Show" [Original cut] (21:48)
- "Rock Show" [Producer's extended cut] (26:48)
Commentaries:
- "Pilot" with Greg Daniels, Rashida Jones and Michael Schur
- "Canvassing" with Dan Goor, Seth Gordon, Nick Offerman and Michael Schur
Deleted Scenes:
- "Pilot" (8:20)
- "Canvassing" (5:52)
```

Second Example
```
Star Trek: Enterprise: Season 1 (TV) (2001-2002)
Episodes
- �Broken Bow� (86:42)
- �Fight or Flight� (44:16)
- �Strange New World� (44:16)
Audio commentary by series creators Rick Berman and Brannon Braga on �Broken Bow�
Text commentary by scenic art supervisors Michael and Denise Okuda on �Broken Bow�
Broken Bow Deleted Scenes (with Play All) (3:07)
- Scene 92 (1:31)
- Scene 99 (0:40)
- Scene 154-155 (0:55)
Fight or Flight Deleted Scenes (with Play All) (2:15)
- Scene 5 (0:57)
- Scene 28 (1:18)
```

Third Example
```
Star Trek: Enterprise: Season 1 (TV) (2001-2002)
4 Episodes:
�Bound� (40:57)
�In a Mirror, Darkly, Part I� (41:02)
�In a Mirror, Darkly, Part II� (41:00)
�Demons� (41:04)
Supplements:
Audio commentary by writer Mike Sussman and StarTrek.com editorial director Tim Gaskill on �In a Mirror, Darkly, Part I�
Audio commentary by writer Mike Sussman and StarTrek.com editorial director Tim Gaskill on �In a Mirror, Darkly, Part II�
Text commentary by scenic art supervisors Michael and Denise Okuda on �In a Mirror, Darkly, Part II�
In a Mirror, Darkly, Part II Deleted scene:
- Scene 77 (2:19)
```

#### Movie Examples:
First Example
```
007 - Skyfall (2012)
Bond�s loyalty to M is tested when her past comes back to haunt her. Whilst MI6 comes under attack, 007 must track down and destroy the threat, no matter how personal the cost.
Director: Sam Mendes
"Shooting Bond" featurettes (w/ play all option) (12:25)
- "Working the Titles: The Title Sequence" (2:56)
- "Behind the Wheel: DB5" (1:36)
- "The Good, the Bad and the Beautiful: Women" (4:27)
- "Licence to Travel: Locations" (3:24)
Soundtrack Promotional Spot (0:40)
```

Second Example
```
When Harry Met Sally... (1989)
Can Two Friends Sleep Together And Still Love Each Other In The Morning?
Director: Rob Reiner
Audio Commentary by Director Rob Reiner
Extras:"How Harry Met Sally" documentary (33:18)
Deleted Scenes:
- "Harry Does Impressions" (0:33)
- "How Many Men Have You Slept With?" (1:00)
- "Sally's Bad Date" (0:59)
- "Sleepless Night" (0:34)
- "I Blew It" (0:26)
- "Harry Sally On The Couch" (1:46)
- "I Was Just Walking Down The Street" (1:51)
Rob Reiner Theatrical Trailers:
- "The Princess Bride" (2:20)
- "This Is Spinal Tap" (1:35)
- "When Harry Met Sally" (2:05)
Music Video:
- Harry Connick, Jr. "It Had To Be You" (2:48)
```

### 2. Processing Logic

#### TV Shows
1. **Parse the input** to extract:
   - Show title (from NFO file or user input)
   - Season number (if specified)
   - Episode list with titles and durations
   - Extras (commentaries, deleted scenes, music videos, etc.)

2. **Create directory structure**:
   **Note on season.nfo**: For multi-disc TV shows, a season.nfo file should be placed in each disc directory (e.g., `Season 1/Disc 1/season.nfo`, `Season 1/Disc 2/season.nfo`) to ensure proper metadata discovery by media servers.
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

3. **Generate NFO files** for each episode with:
   - Show title
   - Episode title
   - Season and episode numbers
   - Runtime
   - Plot description (if available)
   - Cast information (if available)

4. **Handle special cases**:
   - Episodes with alternative cuts (Original cut, Producer's extended cut) get unique identifiers
   - Commentaries and deleted scenes move to `extras/` subdirectory
   - Music videos and trailers move to `extras/Music Videos/` or `extras/Trailers/`

#### Movies
1. **Parse the input** to extract:
   - Movie title (from NFO file or user input)
   - Main movie duration
   - Extras list with durations

2. **Organize files**:
   - Keep the longest MKV file (presumed to be the main movie) in the main directory
   - Move all shorter MKV files to `extras/` subdirectory

3. **Generate NFO file** for the main movie with:
   - Movie title
   - Plot description
   - Director, writer, cast information
   - Runtime
   - Studio information
   - Image references (poster, fanart)
   
### 3. Parsing Engine (Enhanced)
The parsing engine handles various input formats and encoding issues commonly found in dvdcompare.net exports.

#### Encoding & Character Handling

##### Common Encoding Issues
- **Mojibake**: Characters displayed incorrectly due to encoding mismatch (e.g., `�` instead of proper Unicode)
- **Mixed encodings**: Input may contain a mix of UTF-8 and Windows-1252 characters
- **Smart quotes**: Windows smart quotes (`"`, `'`) vs. standard ASCII quotes
- **Non-breaking spaces**: Spaces that render as non-breaking characters

##### Detection & Resolution
- **Auto-detect encoding**: Use `String(data:encoding:)` with multiple encoding attempts
- **Character validation**: Replace invalid Unicode characters with question mark or appropriate fallback
- **Quote normalization**: Convert all quote types to standard ASCII quotes
- **Whitespace normalization**: Replace non-breaking spaces with regular spaces

##### Example Handling
```swift
// Convert Windows-1252 encoded string to proper Unicode
if let data = inputString.data(using: .windowsCP1252) {
    if let cleanString = String(data: data, encoding: .utf8) {
        inputString = cleanString
    }
}

// Replace mojibake characters
let mojibakeChars = CharacterSet(charactersIn: "�")
inputString = inputString.replacingOccurrences(
    of: "[\\uFFFD]",
    with: "",
    options: .regularExpression
)
```

#### Input Handling
- **Encoding detection**: Automatically detect and handle various encodings (UTF-8, Windows-1252, MacRoman)
- **Section identification**: Identify sections like "Episodes:", "Commentaries:", "Deleted Scenes:", "Extras:", "Supplements:"
- **Episode number assignment**: Auto-assign episode numbers based on order or detect from input (e.g., "Part I", "Part II")
- **Alternative cut handling**: Detect and flag episodes with alternative cuts (Original cut, Producer's extended cut)

#### Regular Expressions
```swift
let episodeRegex = try! NSRegularExpression(
    pattern: "-\\s*\"?([^\"\\n]+)\"?\\s*\\((\\d{1,2}):(\\d{2})\\)",
    options: .caseInsensitive
)

let commentaryRegex = try! NSRegularExpression(
    pattern: "-\\s*\"?([^\"\\n]+)\"?\\s*with\\s+([^\\n]+)",
    options: .caseInsensitive
)
```

#### Enhanced DVDCompareContent Struct
```swift
struct DVDCompareContent {
    var type: MediaType // Movie or TVShow
    var title: String
    var season: Int?
    var year: Int? // Extracted from title or input
    var plot: String? // For movies
    
    // For TV Shows
    var episodes: [(title: String, duration: TimeInterval, episodeNumber: Int, alternativeCut: Bool?, isDeletedScene: Bool?)]
    var commentaries: [(title: String, duration: TimeInterval, episodeNumber: Int?, episodeTitle: String?)]
    var deletedScenes: [(title: String, duration: TimeInterval, episodeNumber: Int?, episodeTitle: String?)]
    var musicVideos: [(title: String, duration: TimeInterval)]
    var trailers: [(title: String, duration: TimeInterval)]
    
    // For Movies
    var mainMovie: (title: String, duration: TimeInterval)
    var extras: [(title: String, duration: TimeInterval, type: ExtraType)]
    
    // Metadata
    var director: String?
    var writers: [String]?
    var cast: [(name: String, role: String)?]
    var genre: [String]?
    var rating: String?
}
```

#### ExtraType Enum

```swift
enum ExtraType: String, CaseIterable {
    case commentary
    case deletedScene
    case musicVideo
    case trailer
    case featurette

    case behindTheScenes
    case makingOf
    case interview
    case documentary
    case other
    
    var displayName: String {
        switch self {
        case .commentary: return "Commentary"
        case .deletedScene: return "Deleted Scene"
        case .musicVideo: return "Music Video"
        case .trailer: return "Trailer"
        case .featurette: return "Featurette"
        case .behindTheScenes: return "Behind the Scenes"
        case .makingOf: return "Making Of"
        case .interview: return "Interview"
        case .documentary: return "Documentary"
        case .other: return "Other"
        }
    }
}
```

### 4. Merge Strategies

When organizing files, the feature supports several merge strategies for handling existing files:

#### Merge Strategy Options

1. **Replace**: Overwrite existing files with the same name
   - Use when you're certain the new metadata is correct
   - Risk: May lose existing NFO data or file modifications

2. **Skip**: Leave existing files unchanged
   - Use when you want to preserve existing organization
   - Risk: May result in duplicate files or inconsistent metadata

3. **Rename**: Rename existing files to avoid conflicts
   - Adds a suffix like " (Old)" to existing files
   - Use when you want to keep both old and new versions

4. **Merge Metadata**: Combine existing NFO data with new data
   - Preserves existing metadata fields
   - Updates or adds new fields from the parsed content
   - Best for incremental updates

#### Merge Strategy Selection UI

```
┌─────────────────────────────────────────┐
│  Merge Strategy                         │
├─────────────────────────────────────────┤
│  How to handle existing files:          │
│  ┌─────────────────────────────────┐   │
│  │ ○ Replace                        │   │
│  │ ○ Skip                           │   │
│  │ ○ Rename                         │   │
│  │ ● Merge Metadata                 │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```    

### 5. File Naming Conventions

Consistent file naming is crucial for media server compatibility. The following conventions are used:

#### Episode Files
```
Format: "[Episode Number] - [Episode Title].mkv"
Examples:
- "01 - Pilot.mkv"
- "02 - Canvassing.mkv"
- "S01E03 - The Reporter.mkv"
```

#### Alternative Cut Episodes
```
Format: "[Episode Number] - [Title] - [Cut Type].mkv"
Examples:
- "01 - Rock Show - Original Cut.mkv"
- "02 - Rock Show - Producer's Extended Cut.mkv"
- "S01E05 - Rock Show (Original).mkv"
```

#### Commentary Tracks
```
Format: "Commentary - [Episode Title].mkv"
Examples:
- "Commentary - Pilot.mkv"
- "Commentary - Broken Bow.mkv"
```

#### Deleted Scenes
```
Format: "Deleted Scene - [Scene Description].mkv"
Examples:
- "Deleted Scene - Pilot (8:20).mkv"
- "Deleted Scene - Scene 92 (1:31).mkv"
```

```swift
let deletedSceneRegex = try! NSRegularExpression(
    pattern: "-\\s*Scene\\s*(\\d+(?:-\\d+)?)\\s*\\((\\d{1,2}):(\\d{2})\\)",
    options: .caseInsensitive
)
```

#### Music Videos
```
Format: "[Artist] - [Song Title].mkv"
Examples:
- "Pit - Ann.mkv"
- "Harry Connick Jr - It Had To Be You.mkv"
```

#### Trailers
```
Format: "Trailer - [Movie/Show Title].mkv"
Examples:
- "Trailer - Skyfall.mkv"
- "Trailer - When Harry Met Sally.mkv"
```

#### Featurettes and Behind-the-Scenes
```
Format: "[Type] - [Title].mkv"
Examples:
- "Featurette - Shooting Bond.mkv"
- "Behind the Scenes - DB5.mkv"
- "Making Of - The Title Sequence.mkv"
```

#### NFO File Naming
```
Format: Same as the video file name (without extension)
Examples:
- "01 - Pilot.nfo"
- "Commentary - Pilot.nfo"
- "extras/Deleted Scene - Pilot.nfo"
```

#### Duration Parsing
- Convert "HH:MM" format to `TimeInterval` for calculations
- Handle variations like "H:MM", "MM:SS"
- Parse "H:MM:SS" for longer durations

#### TV Show Parsing Strategy
1. Identify season header (e.g., "Season 1", "Season 1 (TV)")
2. Extract show title from header
3. Parse episode list with durations
4. Parse commentary entries (linked to episodes)
5. Parse deleted scenes (linked to episodes or standalone)
6. Parse music videos and trailers
7. Assign episode numbers sequentially or detect from input

#### Movie Parsing Strategy
1. Identify movie title from header (format: "Title (Year)")
2. Extract plot description (if present)
3. Identify director/creator information
4. Parse extras list with durations
5. Determine main movie by finding longest duration file
6. Categorize extras by type (commentary, featurette, deleted scene, etc.)
   - Plot description
   - Director, writer, cast information
   - Runtime
   - Studio information
   - Image references (poster, fanart)

## Feature Components

### 1. Import Interface
- **Multiline text field** for pasting dvdcompare.net content
- **Toggle/selector** to specify content type (Movie or TV Show)
- **Show title input** field (required for both types)
- **Season input** field (for TV shows, optional)
- **Base directory selection** - where to organize the files
- **Merge strategy selection** - How to handle existing files (replace, skip, rename)
- **Preview mode** - Show what will be created without making changes


### 2. Parsing Engine

The parsing engine uses a multi-pass approach to handle the varied formats from dvdcompare.net:

#### Pass 1: Pre-processing
- **Encoding normalization**: Convert various encodings (UTF-8, Windows-1252, MacRoman) to UTF-8
- **Character replacement**: Replace malformed characters (e.g., `�`) with proper Unicode equivalents
- **Whitespace normalization**: Trim leading/trailing whitespace and normalize internal spacing
- **Case normalization**: Standardize capitalization for consistent matching

#### Pass 2: Section Detection
- **Header identification**: Detect section headers like "Episodes:", "Commentaries:", "Deleted Scenes:", "Extras:", "Supplements:"
- **Content type detection**: Determine if input is a movie or TV show based on structure
- **Title extraction**: Extract show/movie title from the header line

#### Pass 3: Content Parsing
- **Episode parsing**: Extract episode titles and durations using regex patterns
- **Extra categorization**: Classify extras by type (commentary, deleted scene, music video, trailer, featurette)
- **Metadata extraction**: Pull director, writer, cast, and other metadata from input

#### Pass 4: Post-processing
- **Episode numbering**: Auto-assign sequential episode numbers or detect from input (e.g., "Part I", "Part II")
- **Link resolution**: Associate commentaries and deleted scenes with their parent episodes
- **Validation**: Ensure all required fields are populated

### 3. File Organization Logic
```swift
enum FileOrganizer {
    func organizeTVShow(
        files: [FileItem],
        content: DVDCompareContent,
        basePath: URL
    ) throws
    
    func organizeMovie(
        files: [FileItem],
        content: DVDCompareContent,
        basePath: URL
    ) throws
}
```

### 4. NFO File Generator
```swift
struct NFOGenerator {
    func generateEpisodeNFO(
        episode: Episode,
        showTitle: String,
        season: Int,
        basePath: URL
    ) throws -> URL
    
    func generateMovieNFO(
        movie: Movie,
        basePath: URL
    ) throws -> URL
    
    func generateExtrasNFO(
        extras: [Extra],
        basePath: URL
    ) throws -> URL?
}
```

### 5. UI Components
- **ImportPanelView**: Main UI for input and configuration
- **ParsingProgressView**: Shows parsing progress and detected structure
- **OrganizationPreviewView**: Shows what will be created before executing
- **ConfirmationDialog**: Final confirmation before file operations

## Technical Implementation

### Input Parsing
1. **Regular expressions** to identify:
   - Episode entries: `"- "Episode Title" (HH:MM)"`
   - Commentary entries: `"- "Episode Title" with ...`
   - Duration parsing: Convert "HH:MM" to TimeInterval
   - Section headers: "Episodes:", "Commentaries:", etc.

2. **TV Show parsing**:
   ```swift
   let episodeRegex = try! NSRegularExpression(
       pattern: "-\\s*\"?([^\"\\n]+)\"?\\s*\\((\\d{1,2}):(\\d{2})\\)",
       options: .caseInsensitive
   )
   ```

3. **Movie parsing**:
   - Identify longest duration file as main movie
   - Move shorter files to extras

### Directory Operations
```swift
extension FileOrganizer {
    func createExtrasDirectory(at path: URL) throws -> URL {
        let extrasURL = path.appendingPathComponent("extras")
        try FileManager.default.createDirectory(
            at: extrasURL,
            withIntermediateDirectories: true
        )
        return extrasURL
    }
    
    func moveFile(from source: URL, to destination: URL) throws {
        try FileManager.default.moveItem(at: source, to: destination)
    }
}
```

### NFO File Generation
Following Jellyfin NFO specifications:

#### TV Episode NFO:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<episodedetails>
    <title>Episode Title</title>
    <showtitle>Show Title</showtitle>
    <season>1</season>
    <episode>1</episode>
    <plot>Episode plot description</plot>
    <runtime>21:32</runtime>
    <rating>TV-14</rating>
</episodedetails>
```

#### Movie NFO:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<movie>
    <title>Movie Title</title>
    <plot>Movie plot description</plot>
    <year>2023</year>
    <director>Director Name</director>
    <actor>Actor Name</actor>
    <genre>Action</genre>
    <runtime>120</runtime>
    <poster>poster.jpg</poster>
</movie>
```

## User Experience

### Step 1: Select Content Type
```
┌─────────────────────────────────────────┐
│  Import Metadata                        │
├─────────────────────────────────────────┤
│  Content Type: [TV Show ▼]              │
│                                         │
│  Show Title: [____________________]     │
│  Season:   [1    ]                      │
│                                         │
│  Paste content from dvdcompare.net:     │
│  ┌─────────────────────────────────┐   │
│  │ Episodes:                       │   │
│  │ - "Pilot" (21:32)               │   │
│  │ - "Episode 2" (22:15)           │   │
│  │ ...                             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [Parse & Preview] [Cancel]             │
└─────────────────────────────────────────┘
```

### Step 2: Preview Organization
```
┌─────────────────────────────────────────┐
│  Organization Preview                   │
├─────────────────────────────────────────┤
│  TV Show: "The Office"                  │
│  Season: 1                              │
│                                         │
│  Will create:                           │
│  └── Season 1/                          │
│      ├── Pilot.mkv                      │
│      ├── Canvassing.mkv                 │
│      └── extras/                        │
│          ├── Commentary - Pilot.mkv     │
│          ├── Deleted Scene - Pilot.mkv  │
│          └── Music Videos/              │
│              ├── Pit.mkv                │
│              └── Ann.mkv                │
│                                         │
│  NFO files to be created:               │
│  - Pilot.nfo                            │
│  - Canvassing.nfo                       │
│  - extras/Commentary - Pilot.nfo        │
│  - extras/Deleted Scene - Pilot.nfo     │
│  - extras/Music Videos/Pit.nfo          │
│                                         │
│  [Confirm & Organize] [Edit]            │
└─────────────────────────────────────────┘
```

### Step 3: Confirmation
```
┌─────────────────────────────────────────┐
│  Confirm Organization                   │
├─────────────────────────────────────────┤
│  This will:                             │
│  • Move 7 episode files to Season 1/    │
│  • Move 12 extra files to extras/       │
│  • Create 14 NFO files                  │
│  • Rename files with proper titles      │
│                                         │
│  Files will NOT be deleted, only        │
│  moved and renamed.                     │
│                                         │
│  [Cancel] [Confirm]                     │
└─────────────────────────────────────────┘
```

## Error Handling

1. **Invalid input format**: Show helpful error message with example
2. **Missing show title**: Prompt user to enter required field
3. **No files found**: Inform user that no matching files were detected
4. **Permission denied**: Clear error message about file access
5. **Duplicate filenames**: Offer to rename or skip

## Future Enhancements

1. **API Integration**: Direct integration with dvdcompare.net API instead of manual paste
2. **Batch Processing**: Organize multiple TV shows/movies at once
3. **Metadata Enrichment**: Fetch additional metadata from TMDB, TheTVDB, OMDB
4. **Image Download**: Automatically download posters and fanart
5. **Validation**: Check NFO file syntax before writing
6. **Undo Support**: Ability to undo organization if needed
7. **Templates**: Pre-defined templates for common formats
8. **Custom Rules**: Allow users to define their own organization rules

## Dependencies

- **XML Parser**: Foundation.XMLParser or XMLDocument for NFO generation
- **File System**: macOS FileManager for file operations
- **Time Utilities**: Custom helpers for time parsing and formatting
- **Path Utilities**: Custom helpers for path manipulation

## Security Considerations

1. **File Access**: Only operate within selected root directory
2. **User Confirmation**: Always require confirmation before file operations
3. **No Deletion**: Ensure files are only moved, never deleted
4. **Backup**: Consider offering backup of original structure

## Testing

1. **Unit Tests**:
   - Input parsing with various formats
   - Duration parsing edge cases
   - Directory creation failures

2. **Integration Tests**:
   - Full organization workflow
   - NFO file generation
   - File movement operations

3. **Manual Testing**:
   - Various input formats
   - Edge cases (empty input, malformed data)
   - Large collections

## Related Documentation

- [Jellyfin NFO Documentation](https://jellyfin.org/docs/general/server/metadata/nfo/)
- [TV Show NFO Format](https://jellyfin.org/docs/general/server/metadata/nfo/#tv-show-nfo)
- [Movie NFO Format](https://jellyfin.org/docs/general/server/metadata/nfo/#movie-nfo)
- [dvdcompare.net Database](https://www.dvdcompare.net/)
