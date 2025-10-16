# Quran Flutter App

This is the Flutter mobile application for the Tajik Quran project.

## 📁 Project Structure

```
quran-flutter-app/
├── android/                 # Android platform files
├── ios/                     # iOS platform files
├── lib/                     # Flutter app source code
│   ├── app/                 # App configuration
│   ├── core/                # Core services and utilities
│   ├── data/                # Data layer (models, repositories, services)
│   ├── domain/              # Business logic layer
│   ├── presentation/        # UI layer (pages, widgets, providers)
│   └── shared/              # Shared widgets and utilities
├── test/                    # Unit and widget tests
├── integration_test/        # Integration tests
├── assets/                  # App assets (images, data, fonts)
├── pubspec.yaml            # Flutter dependencies
├── analysis_options.yaml   # Dart analyzer configuration
└── README-FLUTTER.md       # Flutter app documentation
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development)

### Installation
1. Navigate to the Flutter app directory:
   ```bash
   cd quran-flutter-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Production
- **Android APK**: `flutter build apk --release`
- **iOS IPA**: `flutter build ios --release`

## 📱 Features
- Complete Quran reading with Tajik translation
- Audio playback with multiple reciters
- Islamic tools (Tasbeeh counter, Word learning, Duas)
- Search and bookmarks functionality
- Comprehensive settings and customization

## 🔧 Development
This Flutter app is built using:
- **Clean Architecture** with proper separation of concerns
- **Riverpod** for state management
- **GoRouter** for navigation
- **SQLite** for local data storage
- **Supabase** for remote data
- **AlQuran Cloud API** for audio

## 📄 License
This project is part of the Tajik Quran project and follows the same license terms.
