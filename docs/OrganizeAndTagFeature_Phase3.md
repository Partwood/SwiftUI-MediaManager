# OrganizeAndTag Feature - Phase 3: Integration & Completion

## Overview
Phase 3 focuses on completing the integration of the OrganizeAndTag feature with the main MediaManager application, ensuring all components work together seamlessly, and adding final polish to the user experience.

## Goals
- **Complete Integration**: Ensure OrganizeAndTag feature integrates properly with FileBrowserView
- **Error Handling**: Add comprehensive error handling and user feedback
- **Edge Case Handling**: Handle unusual inputs and file scenarios
- **Documentation**: Add usage documentation and examples
- **Testing**: Add sample data and test cases

## Phase 3 Components

### 1. Integration with Main App ✅ COMPLETE
- `OrganizeAndTagView.swift` - Main view controller with TabView interface
- Integration with `FileBrowserView` - Organize & Tag button added
- State management for organizing operations

### 2. Error Handling & Recovery ⚠️ NEEDS COMPLETION
- Improve error messages for users
- Add retry functionality for failed operations
- Implement rollback/undo capability
- Add detailed logging for debugging

### 3. Edge Case Handling ⚠️ NEEDS COMPLETION
- Empty input handling
- Malformed input recovery
- File permission errors
- Disk space warnings
- Conflicting file names resolution

### 4. Enhanced Features ⚠️ PLANNED
- Batch processing for multiple files
- Progress indicators for long operations
- File conflict resolution UI
- Preview mode improvements

## Implementation Tasks

### Task 1: Error Handling Improvements
- [ ] Add detailed error messages in `OrganizeAndTagViewModel`
- [ ] Implement retry mechanism for failed file operations
- [ ] Add error recovery suggestions
- [ ] Create error logging utility

### Task 2: Edge Case Handling
- [ ] Handle empty or invalid input gracefully
- [ ] Add file permission error handling
- [ ] Implement disk space checking
- [ ] Add conflict resolution dialog for duplicate files

### Task 3: Progress & Feedback
- [ ] Add progress indicator during organization
- [ ] Show detailed operation status
- [ ] Implement cancel operation support
- [ ] Add operation completion summary

### Task 4: Documentation
- [ ] Add README for feature usage
- [ ] Create example input files
- [ ] Document merge strategy options
- [ ] Add troubleshooting guide

### Task 5: Testing & Validation
- [ ] Add sample input data for testing
- [ ] Create test cases for edge cases
- [ ] Validate NFO file generation
- [ ] Test with various file types

## File Updates Needed

### OrganizeAndTagViewModel.swift
- Add detailed error handling
- Implement retry logic
- Add progress tracking

### FileOrganizer.swift  
- Add edge case handling
- Improve file matching logic
- Add disk space checking

### ImportPanelView.swift
- Add validation for required fields
- Improve user feedback

### OrganizationPreviewView.swift
- Add warnings display
- Improve preview accuracy

## Integration Points

### FileBrowserView.swift
```swift
// Button to open Organize & Tag panel
Button(action: { isShowingOrganizePanel = true }) {
    Label("Organize & Tag", systemImage: "tag.fill")
}
.buttonStyle(.bordered)

if isShowingOrganizePanel {
    OrganizeAndTagView()
        .frame(minWidth: 600, minHeight: 400)
}
```

### State Management
- `isShowingOrganizePanel` - Controls panel visibility
- `organizeViewModel` - Coordinates operations
- `organizeContent` - User input
- `organizeShowTitle` - Show/movie title
- `organizeMediaType` - TV Show or Movie
- `organizeSeasonNumber` - Season for TV shows
- `organizeBasePath` - Target directory
- `organizeMergeStrategy` - File conflict handling
- `organizeOrganizationPreview` - Preview data
- `organizeProcessingState` - Operation status
- `organizeErrorMessages` - Error display
- `organizeShowConfirmationDialog` - Confirmation UI

## Usage Flow

### Step 1: Open Organize & Tag Panel
1. Navigate to a directory with media files
2. Click "Organize & Tag" button in FileBrowserView header
3. OrganizeAndTagView opens in a sheet

### Step 2: Input Content
1. Select content type (TV Show or Movie)
2. Enter show/movie title
3. Paste dvdcompare.net content
4. Select base directory for organization
5. Choose merge strategy (Replace, Skip, Rename, Merge Metadata)

### Step 3: Preview
1. Click "Parse & Preview"
2. Review detected episodes, commentaries, deleted scenes, etc.
3. Verify organization structure
4. Make adjustments if needed

### Step 4: Confirm & Execute
1. Review summary of operations
2. Click "Confirm & Organize"
3. Wait for completion
4. View results in Results tab

## Testing Checklist

- [ ] Parse valid TV show input
- [ ] Parse valid movie input  
- [ ] Handle empty input
- [ ] Handle malformed input
- [ ] Test with special characters
- [ ] Test file permission errors
- [ ] Test disk space issues
- [ ] Test conflict resolution
- [ ] Verify NFO file generation
- [ ] Verify file movement
- [ ] Test all merge strategies
- [ ] Test cancel operation
- [ ] Test error recovery

## Future Enhancements

1. **API Integration**: Direct dvdcompare.net API access
2. **Metadata Enrichment**: Fetch from TMDB, TheTVDB
3. **Image Download**: Automatic poster/fanart retrieval
4. **Batch Processing**: Multiple shows/movies at once
5. **Undo Support**: Rollback organization operations
6. **Templates**: Pre-defined format templates
7. **Custom Rules**: User-defined organization rules

## Dependencies

- **XML Parser**: Foundation.XMLParser for NFO validation
- **File System**: FileManager for operations
- **Time Utilities**: Duration parsing helpers
- **Path Utilities**: Path manipulation helpers

## Security Considerations

1. **File Access**: Only operate within selected directory
2. **User Confirmation**: Always require confirmation
3. **No Deletion**: Files only moved, never deleted
4. **Backup Option**: Offer backup of original structure
