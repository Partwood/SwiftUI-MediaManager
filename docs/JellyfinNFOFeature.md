# Jellyfin/NFO File Support for MediaManager

## Overview
This document describes the implementation of Jellyfin/NFO file support for the MediaManager macOS application. NFO files (Note FOundation) are XML-based metadata files commonly used in media collections (movies, TV shows) to store information like plot summaries, cast, crew, ratings, and more.

## User Flow

### 1. NFO File Detection
1. User browses directories in MediaManager
2. File system scans files and detects XML files (including NFO files)
3. NFO files are identified by their XML structure and extension (.nfo)
4. NFO files are displayed in the file browser with appropriate icon/type

### 2. Metadata Display
1. User clicks on an NFO file in the file browser
2. Side panel slides in from the right side
3. Side panel displays parsed metadata from the NFO file
4. Metadata is organized into logical sections for easy reading

### 3. Metadata Editing (Future Enhancement)
1. User clicks "Edit" button in side panel
2. NFO file opens in external text editor (or integrated editor)
3. User can modify metadata fields
4. Changes are saved back to the NFO file
5. Side panel updates with new metadata

## Displayed Information

### NFO File Structure
NFO files are XML documents following a specific structure. Common NFO types include:
- **Movie NFO**: `movie.nfo` - Contains movie metadata
- **TV Show NFO**: `tv.nfo` - Contains series metadata
- **Season NFO**: `season-N.nfo` - Contains season-specific metadata

### Basic File Information (All Files)
- **Filename**: NFO file name
- **Size**: File size in human-readable format
- **Path**: Full file path
- **Modified Date**: Last modification date and time
- **File Type**: NFO file indicator

### Metadata Sections (Parsed from XML)

#### Movie Metadata
- **Title**: Movie title
- **Plot**: Synopsis/plot summary
- **Year**: Release year
- **Director**: Director name(s)
- **Writer**: Writer name(s)
- **Actors**: Cast members
- **Rating**: Rating (e.g., PG-13, R)
- **Genre**: Genre(s)
- **Runtime**: Runtime in minutes
- **Studio**: Production studio
- **Tagline**: Marketing tagline
- **Poster**: Poster image path (if referenced)
- **Fanart**: Background image path (if referenced)
- **IMDB ID**: IMDb identifier
- **TVDB ID**: TheTVDB identifier
- **OMDB ID**: OMDB identifier

#### TV Show Metadata
- **Title**: Show title
- **Plot**: Series synopsis
- **Year**: First aired year
- **Ended**: Last aired year (if applicable)
- **Network**: TV network
- **Status**: Ongoing/Ended
- **Genre**: Genre(s)
- **Rating**: Rating
- **Aired**: Airing information
- **Runtime**: Episode runtime
- **Poster**: Poster image path
- **Fanart**: Background image path
- **IMDB ID**: IMDb identifier
- **TVDB ID**: TheTVDB identifier

#### Season Metadata
- **Season Number**: Season identifier
- **Episode Count**: Number of episodes
- **Plot**: Season-specific synopsis
- **Aired**: Season airing information

#### Cast & Crew
- **Director**: Director name
- **Writer**: Writer name
- **Star**: Lead actor
- **Guest Stars**: Guest actors
- **Composer**: Music composer

#### Additional Information
- **Languages**: Language(s) used
- **Countries**: Country of origin
- **Aspect Ratio**: Screen aspect ratio
- **Resolution**: Video resolution
- **Screenshots**: Screenshot paths
- **Disc Art**: Disc art paths

## UI Design

### Layout
- **Position**: Right side of main window (same as other metadata panels)
- **Width**: ~350-400 pixels
- **Height**: Matches main window height
- **Animation**: Smooth slide-in/slide-out animation
- **State**: Hidden by default, shown when NFO file is selected

### Visual Design
- **Background**: Semi-transparent or blurred background for context
- **Header**: Shows "NFO Metadata" with NFO icon and close button
- **Sections**: Grouped information with clear section headers
- **Typography**: Clean, readable font with appropriate hierarchy
- **Icons**: Small icons next to each metadata field for visual clarity
- **Syntax Highlighting**: XML tags shown in monospace font with color coding

### Interactions
- **Close Button**: Top-right corner to dismiss panel
- **Copy to Clipboard**: Button to copy specific fields or all metadata
- **Show Source**: Button to reveal raw XML content
- **Edit NFO**: Button to open NFO file in text editor
- **Save Changes**: Button to save modifications (if editing)
- **Expand/Collapse Sections**: Accordion for less-used metadata

## Technical Implementation

### File Type Detection

#### XML Detection
- Check file extension (.xml, .nfo)
- Check file header for XML declaration (`<?xml version="1.0"?>`)
- Validate XML structure using XML parser

#### NFO-Specific Detection
- Check for NFO-specific XML namespaces
- Look for common NFO root elements:
  - `<movie>`, `<tvshow>`, `<season>`
  - `<episodedetails>`
  - `<cast>`, `<director>`, `<writer>`
  - `<plot>`, `<rating>`, `<genre>`

### Data Sources

#### File Attributes
- `FileManager.attributesOfItem(atPath:)` for basic file info

#### XML Parsing
- `XMLParser` or `XMLDocument` from Foundation
- Parse XML structure and extract metadata fields
- Handle nested elements and attributes
- Support for both simple and complex NFO structures

### Metadata Extraction Strategy

1. **Parse XML Document**: Load and parse the NFO file
2. **Identify NFO Type**: Determine if it's a movie, TV show, or season NFO
3. **Extract Fields**: Iterate through XML elements and extract metadata
4. **Validate Data**: Ensure extracted data is valid and properly formatted
5. **Store in Model**: Create structured metadata objects

### State Management
- Selected NFO file ID stored in `FileBrowserView`
- Side panel view model holds parsed metadata for selected NFO file
- Reactive updates when selection changes
- Parse NFO file only when needed (lazy loading)

### Error Handling
- Gracefully handle malformed XML files
- Display "N/A" for missing information
- Show error messages for inaccessible files
- Provide fallback to display raw XML if parsing fails
- Support for both simple and complex NFO formats

## NFO File Formats Supported

### Simple Movie NFO
```xml
<?xml version="1.0" encoding="UTF-8"?>
<movie>
    <title>Example Movie</title>
    <plot>Movie plot summary...</plot>
    <year>2023</year>
    <director>Director Name</director>
    <actor>Actor Name</actor>
    <genre>Action</genre>
</movie>
```

### Complex Movie NFO (with images)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<movie>
    <title>Example Movie</title>
    <plot>Movie plot summary...</plot>
    <year>2023</year>
    <director>Director Name</director>
    <actor>Actor Name</actor>
    <genre>Action</genre>
    <poster>poster.jpg</poster>
    <fanart>fanart.jpg</fanart>
    <screenshots>
        <screenshot>
            <path>screen1.jpg</path>
            <thumb>thumb1.jpg</thumb>
        </screenshot>
    </screenshots>
</movie>
```

### TV Show NFO
```xml
<?xml version="1.0" encoding="UTF-8"?>
<tvshow>
    <title>Example Show</title>
    <plot>TV show synopsis...</plot>
    <year>2020</year>
    <ended>2023</ended>
    <network>Network Name</network>
    <genre>Drama</genre>
    <rating>TV-14</rating>
    <season>
        <number>1</number>
        <episodes>
            <episodedetails>
                <title>Episode 1</title>
                <plot>Episode plot...</plot>
                <season>1</season>
                <episode>1</episode>
            </episodedetails>
        </episodes>
    </season>
    <cast>
        <actor>
            <name>Actor Name</name>
            <role>Character Name</role>
        </actor>
    </cast>
    <director>Director Name</director>
    <writer>Writer Name</writer>
</tvshow>
```

## Future Enhancements

- [ ] **NFO Editing**: Integrated text editor for modifying NFO files
- [ ] **NFO Generation**: Auto-generate NFO files from metadata
- [ ] **Jellyfin Integration**: Direct integration with Jellyfin API
- [ ] **NFO Preview**: Thumbnail preview of NFO file content
- [ ] **NFO Validation**: Validate NFO files against schema
- [ ] **NFO Templates**: Support for different NFO templates
- [ ] **Batch Processing**: Process multiple NFO files at once
- [ ] **Import/Export**: Import NFO from external sources, export to other formats
- [ ] **Search**: Search within NFO files for specific content
- [ ] **Filter**: Filter files based on NFO metadata
- [ ] **Sync**: Sync NFO files between devices

## Related Documentation
- [File Metadata Side Panel Feature](./MetadataSidePanelFeature.md)
- [Cut & Paste Feature](./CutPasteFeature.md)
- [Architecture](./architecture.md)
## Implementation Status

### ✅ Completed
- **NFO File Detection**: XML/NFO files are detected by extension and content
- **NFOMetadata Structure**: Comprehensive struct with all common fields
- **NFOSection Structure**: For organizing parsed sections
- **XML Parsing Logic**: Basic parsing to extract metadata fields
- **Metadata Extraction**: Methods to extract title, plot, year, director, cast, etc.
- **UI Display**: NFO metadata displayed in side panel with sections

### 🔄 Current Implementation
The NFO parsing uses simple string-based XML tag extraction rather than a full XML parser. This works for most standard NFO files but may not handle:
- Complex nested structures
- Attributes within tags
- CDATA sections
- Malformed XML

### 📝 Notes
- The parsing is case-sensitive for tag names
- Self-closing tags are handled
- Nested tags are stripped to get text content
- Multiple cast entries are supported with name:role format
- Languages and countries are comma-separated lists

## Future Enhancements

### Improved XML Parsing
1. Use `XMLParser` or `XMLDocument` for robust parsing
2. Handle attributes properly
3. Support CDATA sections
4. Validate XML structure
5. Handle namespaces

### Additional Features
1. **Image Preview**: Display poster/fanart images if paths are available
2. **Metadata Editing**: Allow users to edit NFO files directly
3. **Validation**: Check for common NFO format issues
4. **Import/Export**: Support importing from other formats
5. **Search**: Search within NFO files for specific terms

### Error Handling
1. Better error messages for malformed XML
2. Fallback to raw XML display when parsing fails
3. Warning for incomplete NFO files

### UI Improvements
1. Collapsible sections for less-used metadata
2. Syntax highlighting for XML tags
3. Copy to clipboard for individual fields
4. Export metadata to JSON or other formats
5. Support for multiple NFO files in a season folder
