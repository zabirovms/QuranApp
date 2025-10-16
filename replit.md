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
- **Oct 16, 2025**: Initial Replit setup
  - Installed Flutter SDK from stable branch
  - Enabled Flutter web support
  - Created web directory with necessary files
  - Configured web server to run on port 5000 with 0.0.0.0 binding
  - Set up workflow for automatic web server startup
  - Updated .gitignore for Replit environment

## User Preferences
- None specified yet

## Known Issues
- Some packages have newer versions available but are incompatible with current constraints
- Web platform has limitations compared to mobile (e.g., some audio features may behave differently)
- Performance may vary based on browser and device capabilities

## Notes
- This is primarily a mobile app adapted for web. Some mobile-specific features may have limited functionality on web.
- The app uses clean architecture principles with proper separation of concerns.
- Audio playback uses the AlQuran Cloud API for recitations.
- Local data includes Quranic duas, tasbeehs, and top 100 words for learning.
