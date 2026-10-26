# Cut & Paste Feature for MediaManager

## Overview
This document describes the implementation of a cut and paste feature for the MediaManager macOS application, allowing users to move files between directories with proper conflict resolution.

## User Flow

### 1. Cut Operation
1. User selects one or more files in the current directory view
2. User clicks "Cut" button or uses keyboard shortcut (⌘X)
3. Selected files are stored in a temporary "cut buffer"
4. User can cancel the cut operation at any point before pasting
5. UI shows visual feedback that files are in "cut" mode

### 2. Navigate to Destination
1. User clicks "Select Directory" button or uses keyboard shortcut (⌘O)
2. File picker opens allowing selection of destination directory
3. User navigates through directory hierarchy as needed
4. User can cancel the operation at any point

### 3. Paste Operation
1. User clicks "Paste" button or uses keyboard shortcut (⌘V)
2. For each file in the cut buffer:
   - Check if file already exists at destination
   - If **no conflict**: Copy file to destination
   - If **conflict exists**: Show prompt with options:
     - **Replace**: Overwrite existing file
     - **Keep Both**: Rename destination file (add timestamp or counter)
     - **Skip**: Don't move this file
3. Show progress indicator for large operations
4. Display success/failure summary

## Key Components

### CutPasteViewModel
- Manages cut buffer (array of FileItem with original paths)
- Tracks paste operation state (in progress, complete, failed)
- Handles conflict detection and resolution
- Provides undo capability for cut operations

### CutPasteView (UI)
- "Cut" button with keyboard shortcut
- "Paste" button with keyboard shortcut
- Cut status indicator (shows number of files in buffer)
- Cancel button during paste operation
- Progress indicator during paste operation
- Conflict resolution prompt

### FileConflictResolver
- Detects naming conflicts
- Generates safe filenames (with timestamps/counter)
- Handles replacement logic
- Provides user feedback on conflict resolution

## Data Structures

### CutBufferItem
```swift
struct CutBufferItem: Identifiable {
    let id: UUID
    let file: FileItem
    let originalPath: URL
    let isCancelled: Bool
}
```

### PasteOperationResult
```swift
enum PasteOperationResult {
    case success
    case skipped
    case failed(Error)
    case conflictResolved(String) // New filename
}
```

## Conflict Resolution Strategies

### Replace
- Directly overwrites existing file
- User must confirm before overwriting
- No backup created

### Keep Both
- Renames destination file to avoid collision
- Naming convention: `{original_name}_{timestamp}_{counter}.extension`
- Example: `movie.mkv` → `movie_20260101_120000_1.mkv`

### Skip
- File remains in cut buffer
- Can be retried later
- User is notified which files were skipped

## Error Handling

### Permissions Errors
- Check read/write permissions before operation
- Show clear error message if access denied
- Allow user to retry or cancel

### Disk Space Errors
- Estimate required space before operation
- Warn user if insufficient space
- Cancel operation if space unavailable

### File Lock Errors
- Detect if file is currently open/locked
- Suggest closing application using file
- Retry after user confirmation

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Cut Selected Files | ⌘X |
| Paste Files | ⌘V |
| Cancel Operation | ⌘Escape |
| Select Directory | ⌘O |

## Visual Indicators

### Cut Mode
- Selected items appear with semi-transparent overlay
- "X" icon on selected items
- Status bar shows "X file(s) cut - ready to paste"
- Cut button appears disabled (files are already cut)

### Paste Mode
- Progress bar showing completion percentage
- Current operation status text
- Cancel button visible during operation
- Success/failure count in status

### Conflict Resolution
- Modal dialog with three clear options
- Preview of what will happen with each option
- "Keep Both" shows proposed new filename

## Implementation Notes

1. **Security**: All file operations must respect the security-scoped resource model
2. **Undo**: Cut operation should support undo until paste is completed
3. **Batch Operations**: Support moving multiple files efficiently
4. **Progress**: Show real-time progress for large file operations
5. **Logging**: Log all operations for debugging and audit trail
6. **Transaction**: Consider atomic operations to prevent partial moves

## Future Enhancements

- Drag and drop support between directories
- Keyboard-only workflow (no mouse required)
- Preview files before confirming move
- Support for moving to trash (with restore capability)
- Batch rename during paste operation
- Undo paste operation
