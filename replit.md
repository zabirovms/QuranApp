# Tajik Quran App - Flutter Web Edition

## Project Overview
This is a comprehensive Flutter application for reading the Quran with Tajik translation. The app has been configured to run as a web application in the Replit environment.

**Original Purpose**: Mobile Quran app (Android/iOS) with advanced features  
**Current State**: Running as a Flutter web application on Replit  
**Last Updated**: October 16, 2025

## Project Architecture

### Technology Stack
- **Framework**: Flutter 3.22+ (Dart 3.5+)
- **State Management**: Riverpod & Provider
- **Navigation**: GoRouter
- **Local Storage**: Hive & SharedPreferences
- **Network**: Dio for HTTP requests
- **Audio Playback**: just_audio
- **UI**: Material Design with custom theming

### Clean Architecture Layers
```
lib/
├── app/              # App configuration and routing
├── core/             # Core services (theme, performance, utilities)
├── data/             # Data layer (models, repositories, API services)
├── domain/           # Business logic (use cases, repository interfaces)
├── presentation/     # UI layer (pages, widgets, providers)
└── shared/           # Shared widgets and utilities
```

## Features
- Complete Quran reading with Tajik translation
- Audio playback with multiple reciters (AlQuran Cloud API)
- Islamic tools:
  - Tasbeeh counter
  - Word learning module
  - Quranic Duas
- Search and bookmarks functionality
- Comprehensive settings and theme customization
- Offline support with local data storage

## Development Setup

### Environment
- **Platform**: Replit (NixOS Linux)
- **Flutter SDK Location**: `/home/runner/flutter/`
- **Server Port**: 5000 (configured for Replit)
- **Host**: 0.0.0.0 (allows all hosts for Replit proxy)

### Running the App
The app runs automatically via the configured workflow:
- **Workflow Name**: Flutter Web Server
- **Command**: `./run_flutter_web.sh`
- **Access**: Opens in webview on port 5000

### Manual Commands
```bash
# Add Flutter to PATH
export PATH="/home/runner/flutter/bin:$PATH"

# Get dependencies
flutter pub get

# Run web server
flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0

# Build for production
flutter build web --release
```

## Configuration Files

### Key Files
- `pubspec.yaml` - Flutter dependencies and assets
- `run_flutter_web.sh` - Web server startup script
- `setup_flutter.sh` - Initial Flutter web setup script
- `web/index.html` - Web app entry point
- `lib/main.dart` - Application entry point

### Dependencies
- State management: provider, riverpod, flutter_riverpod
- Network: dio, connectivity_plus
- UI: flutter_screenutil, cached_network_image, shimmer, lottie
- Audio: just_audio, audio_service
- Storage: shared_preferences, hive_flutter
- Navigation: go_router

## Data Sources
- **Remote API**: AlQuran Cloud API for audio and additional content
- **Local JSON**: Pre-loaded data for duas, tasbeehs, and word learning
- **SQLite/Hive**: Local storage for bookmarks and user preferences

## Deployment
The app is configured for Replit deployment with autoscale settings for web hosting.

## Recent Changes
- **Oct 18, 2025**: Mushaf Page Improvements
  - Implemented authentic Mushaf-style layout with continuous inline verse flow
  - Fixed text justification for proper right-left alignment
  - Optimized page layout with FittedBox to fit all content without scrolling
  - Fixed RTL page navigation (swipe right to advance, page appears from left)
  - Corrected Basmala display (excluded Surah 1 and 9, centered first verse)
  - Removed surah name repetition - appears only at surah start, not on every page
  - Reduced horizontal padding (20px → 8px) for better text space utilization
  - Simplified page header to show only Juz number (removed redundant surah name)
  - **Theme Integration**: Updated Mushaf page to match app's design system
    - Changed from beige/gold theme to app's green color scheme
    - Using AppTheme constants: backgroundColor, surfaceColor, primaryColor, arabicTextColor
    - Made page/juz indicators subtle (light gray text, no colored backgrounds)
    - Green gradient surah headers matching app's primary/secondary colors
    - Arabic text remains the main visual focus
    - Fully integrated design - no longer feels like a separate mini-app

- **Oct 16, 2025**: Initial Replit setup
  - Installed Flutter SDK from stable branch
  - Enabled Flutter web support
  - Created web directory with necessary files
  - Configured web server to run on port 5000 with 0.0.0.0 binding
  - Set up workflow for automatic web server startup
  - Updated .gitignore for Replit environment
  - Fixed web compatibility issues:
    - Removed dart:io dependencies in performance_optimizer.dart
    - Added web-safe conditionals for File/Directory operations in audio_service.dart
    - Disabled AudioService on web (not supported)
    - Initialized Hive properly in main.dart
    - Created web stub files for mobile-only APIs
  - Configured deployment for autoscale with Flutter web build

## User Preferences
- None specified yet

## Known Issues and Limitations

### Critical Web Compatibility Issues
- **UI Rendering**: The app loads successfully on port 5000 but shows a blank screen in the browser. The Flutter framework loads all 846 scripts correctly, but the UI doesn't render.
- **Potential Causes**: 
  - Deep integration with mobile-specific packages that don't have full web support
  - Possible initialization errors that aren't being surfaced in browser console
  - Some Riverpod providers or data services may not be initializing correctly on web

### Package Limitations
- Some packages have newer versions available but are incompatible with current dependency constraints
- AudioService package is disabled on web (background audio not supported in browsers)
- File system operations (downloading audio, caching) are disabled on web
- Path provider functionality is limited on web

### Performance Considerations
- Web performance may vary based on browser and device capabilities
- No offline storage capability on web (Hive works but with browser storage limits)
- Memory monitoring features disabled on web

## Troubleshooting

### If the app doesn't load:
1. Check that Flutter Web Server workflow is running
2. Verify port 5000 is accessible
3. Try hard refresh in browser (Ctrl+Shift+R or Cmd+Shift+R)
4. Check browser console for JavaScript errors

### For development:
```bash
# Hot reload (if workflow is running)
# Press 'r' in the terminal where flutter run is active

# Hot restart
# Press 'R' in the terminal

# Stop and restart workflow
# Use Replit workflows panel
```

## Notes
- **Important**: This is primarily a mobile app (Android/iOS) that has been adapted for web. The web version has significant limitations and may not be fully functional.
- The backend server runs correctly and serves the app, but UI rendering on web needs additional work
- For full functionality, this app should be run as a mobile application using Flutter's mobile build targets
- The app uses clean architecture principles with proper separation of concerns
- Audio playback uses the AlQuran Cloud API for recitations
- Local data includes Quranic duas, tasbeehs, and top 100 words for learning

## Recommendations for Full Web Support
To make this app fully functional on web, the following changes would be needed:
1. Replace mobile-specific packages with web-compatible alternatives
2. Implement web-specific storage solutions (IndexedDB via Hive)
3. Add error boundaries and better error handling for web platform
4. Test and fix all Riverpod providers for web compatibility
5. Implement progressive web app (PWA) features for offline support
6. Consider using Flutter's `kIsWeb` flag throughout to provide platform-specific implementations
