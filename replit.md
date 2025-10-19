# Tajik Quran App - Flutter Web Edition

## Overview
This project is a comprehensive Flutter application designed for reading the Quran with Tajik translation. Originally conceived as a mobile app, it has been adapted to run as a web application within the Replit environment. The app aims to provide a rich Quran reading experience with features like audio playback, Islamic tools (Tasbeeh, Duas, word learning), search, bookmarks, and extensive customization. The long-term ambition is to deliver a robust and user-friendly Quran platform across multiple devices.

## User Preferences
- None specified yet

## System Architecture

### Technology Stack
- **Framework**: Flutter 3.22+ (Dart 3.5+)
- **State Management**: Riverpod & Provider
- **Navigation**: GoRouter
- **Local Storage**: Hive & SharedPreferences
- **Network**: Dio for HTTP requests
- **Audio Playback**: just_audio
- **UI**: Material Design with custom theming

### Clean Architecture Layers
The project adheres to Clean Architecture principles with the following layer separation:
- `app/`: Application configuration and routing.
- `core/`: Core services including theme management, performance optimization, and utilities.
- `data/`: Data layer, managing models, repositories, and API interactions.
- `domain/`: Business logic, defining use cases and repository interfaces.
- `presentation/`: User Interface layer, comprising pages, widgets, and Riverpod providers.
- `shared/`: Reusable widgets and common utilities.

### UI/UX Decisions
The application emphasizes a modern, polished interface with full dark mode support and consistent theming. Key UI/UX decisions include:
- **Unified Quran Reader**: A single screen combines Mushaf (Arabic pages) and Translation modes with seamless toggling and page synchronization.
- **Distraction-Free Reading**: Controls are hidden by default, appearing on tap, for an immersive reading experience.
- **Elegant FAB Redesign**: A minimal, theme-aware Floating Action Button provides expandable quick actions (mode toggle, audio, settings) with smooth animations.
- **Improved Page Navigation**: Features a centered page indicator with clear navigation buttons and smooth transitions.
- **Theming**: All UI components are integrated with `Theme.of(context)` for proper light/dark mode support and consistent color schemes.

### Feature Specifications
- Complete Quran reading with Tajik translation.
- Audio playback with multiple reciters (via AlQuran Cloud API).
- Integrated Islamic tools: Tasbeeh counter, word learning module, and Quranic Duas.
- Search and bookmarks functionality.
- Comprehensive settings and theme customization.
- Offline support (limited on web due to platform constraints).
- Global continuous pagination (1-604 pages) across all surahs, with inline surah headers.
- Authentic Mushaf-style layout with proper text justification and RTL navigation.

### System Design Choices
- **Replit Environment**: Configured to run as a web application on Replit, listening on port 5000.
- **Web Compatibility**: Adaptations made for web deployment, such as removing `dart:io` dependencies and disabling mobile-specific features where necessary.
- **Data Handling**: Combines remote API data with local JSON assets for Quran content and translations.

## External Dependencies

- **AlQuran Cloud API**: Used for fetching audio recitations and potentially other content.
- **Local JSON Files**:
    - `alquran_cloud_complete_quran.json`: Contains complete Quran data with page and juz metadata.
    - `surah_verses.json`: Stores Tajik translations, transliterations, and tafsir.
    - Pre-loaded data for duas, tasbeehs, and word learning modules.
- **Hive**: Used for local data storage, particularly for bookmarks and user preferences.
- **SharedPreferences**: Utilized for lightweight key-value pair storage.
- **just_audio**: For robust audio playback capabilities.
- **Dio**: HTTP client for network requests.
- **GoRouter**: For declarative routing and navigation within the application.