# MediaManager Architecture

## Project Structure
- **MyApp.swift**: Entry point and main application setup
- **ContentView.swift**: Root view for the application
- **FileBrowserView.swift**: File browsing interface implementation
- **FileSystem.swift**: Core file system operations
- **extURL.swift**: URL handling and network operations
- **Logging.swift**: Logging utility implementation
- **Errors/**: Directory containing custom error types
- **Assets.xcassets**: Resource assets

## Key Components
1. **SwiftUI-Based UI**: Uses SwiftUI for macOS interface development
2. **File Management**: Implements file browsing, metadata access, and operations
3. **URL Handling**: Supports external URL interactions
4. **Error Handling**: Custom error types for robustness
5. **Logging System**: Centralized logging for debugging and monitoring