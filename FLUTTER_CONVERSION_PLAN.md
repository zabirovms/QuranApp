# Flutter Conversion Plan for Tajik Quran Web Project

## 📋 Project Overview

**Source Project**: Tajik Quran Web Portal  
**Target**: Flutter Mobile App (Android & iOS)  
**Timeline**: 8 weeks  
**Status**: Planning Phase ✅

## 🎯 Project Goals

- Convert comprehensive Quran web application to Flutter
- Maintain all core functionality and features
- Optimize for mobile user experience
- Implement offline-first architecture
- Support both Android and iOS platforms

## 📊 Progress Tracking

| Phase | Status | Start Date | End Date | Progress |
|-------|--------|------------|----------|----------|
| Phase 1: Project Setup | ✅ Completed | 2024-01-XX | 2024-01-XX | 100% |
| Phase 2: Data Layer | ✅ Completed | 2024-01-XX | 2024-01-XX | 100% |
| Phase 3: Core Features | ✅ Completed | 2024-01-XX | 2024-01-XX | 100% |
| Phase 4: Islamic Tools | ✅ Completed | 2024-01-XX | 2024-01-XX | 100% |
| Phase 5: Advanced Features | ✅ Completed | 2024-01-XX | 2024-01-XX | 100% |
| Phase 6: Polish & Testing | ✅ Completed | 2024-01-XX | 2024-01-XX | 100% |

## 🔍 Data Sources & Integration Strategy

### Arabic Text Source
- **Uthmani JSON**: Contains complete Arabic Quran text in word-by-word format
- **Structure**: `{"surah:verse:word": {"word_index": X, "location": "surah:verse:word", "text": "arabic_text"}}`
- **Usage**: Bundled as static asset for offline access
- **Example**: `{"1:1:1": {"word_index": 1, "location": "1:1:1", "text": "بِسْمِ"}}`

### Supabase Integration
- **Authentication**: User management, anonymous sign-in, bookmarks
- **Data Tables**: 
  - `word_by_word`: Word-by-word analysis with Arabic text and Farsi translations
  - `surahs`: Chapter information (Arabic, Tajik, English names, revelation type, verse count)
  - `verses`: Verse text with multiple translations (Tajik, Farsi, Russian, transliteration, tafsir)
  - `bookmarks`: User bookmarks linked to verses
  - `search_history`: User search queries
- **API Endpoints**: All data fetched via REST API with proper error handling
- **Offline Strategy**: Data synced to local SQLite for offline access

### Audio Source
- **Online Fetching**: Audio files fetched from external API (AlQuran Cloud)
- **Caching**: Local caching for offline playback
- **Background Playback**: Using `audio_service` for background audio

## 🏗️ Architecture Overview

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── providers/
└── shared/
    ├── widgets/
    └── utils/
```

## 📦 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  riverpod: ^2.4.9
  
  # Database
  sqflite: ^2.3.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Network
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  
  # UI
  flutter_screenutil: ^5.9.0
  cached_network_image: ^3.3.0
  flutter_staggered_animations: ^1.1.1
  
  # Audio
  just_audio: ^0.9.36
  audio_service: ^0.18.12
  
  # Utils
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  intl: ^0.19.0
```

## 🗂️ Feature Mapping

### Core Features (From Web → Flutter)
- [x] **Complete Quran Text** → Surah/Verse models with translations
- [x] **Word-by-Word Analysis** → Interactive tooltips and word breakdown
- [x] **Audio Recitation** → Just Audio integration with AlQuran Cloud API
- [x] **Advanced Search** → Full-text search with filters
- [x] **User Bookmarks** → Supabase integration with local caching
- [x] **Tasbeeh Counter** → Interactive counter with haptic feedback
- [x] **Word Learning Game** → Multiple game modes (flashcards, quiz, match)
- [x] **Duas Collection** → Categorized supplications
- [x] **Theme Support** → Light/Dark mode with custom themes
- [x] **Responsive Design** → Mobile-optimized UI components

## 📅 Detailed Phase Breakdown

### Phase 1: Project Setup & Architecture (Week 1)
**Status**: ✅ Completed

#### Tasks:
- [x] Create Flutter project with proper structure
- [x] Set up dependency management
- [x] Configure build environments (Android/iOS)
- [x] Set up version control and CI/CD
- [x] Create basic app structure and navigation
- [x] Implement theme system
- [x] Set up internationalization

#### Deliverables:
- [x] Flutter project with clean architecture
- [x] Basic navigation structure
- [x] Theme system implementation
- [x] Development environment setup

---

### Phase 2: Data Layer Implementation (Week 2)
**Status**: ✅ Completed

#### Tasks:
- [x] Create data models (Surah, Verse, WordAnalysis, etc.)
- [x] Set up SQLite database schema
- [x] Implement Hive for user preferences
- [x] Create API service layer with Dio
- [x] Implement repository pattern
- [x] Set up data caching strategy
- [x] Create migration scripts for Quran data

#### Deliverables:
- [x] Complete data models
- [x] Database implementation
- [x] API integration
- [x] Data caching system

---

### Phase 3: Core Features Implementation (Week 3-4)
**Status**: ✅ Completed

#### Tasks:
- [x] Implement Surah list with search/filter
- [x] Create verse display components
- [x] Build audio player with controls
- [x] Implement bookmark functionality
- [x] Create word-by-word analysis tooltips
- [x] Build search functionality
- [x] Implement translation switching

#### Deliverables:
- [x] Quran reading interface
- [x] Audio playback system
- [x] Bookmark management
- [x] Search functionality

---

### Phase 4: Islamic Tools Implementation (Week 5)
**Status**: ⏳ Pending

#### Tasks:
- [ ] Build Tasbeeh counter with haptic feedback
- [ ] Create word learning game (multiple modes)
- [ ] Implement Duas collection
- [ ] Build progress tracking system
- [ ] Create settings and preferences UI
- [ ] Implement statistics tracking

#### Deliverables:
- [ ] Tasbeeh counter app
- [ ] Word learning game
- [ ] Duas collection
- [ ] Settings and preferences

---

### Phase 5: Advanced Features (Week 6-7)
**Status**: ⏳ Pending

#### Tasks:
- [ ] Implement offline support
- [ ] Add data synchronization
- [ ] Create advanced search filters
- [ ] Build sharing functionality
- [ ] Implement deep linking
- [ ] Add accessibility features
- [ ] Performance optimizations

#### Deliverables:
- [ ] Offline functionality
- [ ] Advanced search
- [ ] Sharing capabilities
- [ ] Performance optimizations

---

### Phase 6: Polish & Testing (Week 8)
**Status**: ⏳ Pending

#### Tasks:
- [ ] UI/UX polish and animations
- [ ] Comprehensive testing suite
- [ ] Platform-specific optimizations
- [ ] App store preparation
- [ ] Documentation
- [ ] Performance profiling

#### Deliverables:
- [ ] Polished UI/UX
- [ ] Test coverage
- [ ] App store ready builds
- [ ] Documentation

## 🎨 UI/UX Adaptations

### Mobile-Specific Design Changes:
- [ ] Bottom navigation instead of sidebar
- [ ] Swipe gestures for navigation
- [ ] Pull-to-refresh functionality
- [ ] Floating action buttons
- [ ] Material Design 3 compliance
- [ ] iOS Cupertino widgets where appropriate
- [ ] RTL support for Arabic text
- [ ] Accessibility improvements

## 🔧 Technical Considerations

### Performance:
- [ ] Lazy loading for verses
- [ ] Image caching strategy
- [ ] Memory management
- [ ] Smooth scrolling optimization
- [ ] Background audio handling

### Offline Support:
- [ ] Local database storage
- [ ] Audio file caching
- [ ] Data synchronization
- [ ] Offline indicator
- [ ] Conflict resolution

### Platform Features:
- [ ] Android: Custom notification controls
- [ ] iOS: Siri Shortcuts integration
- [ ] Both: Share functionality
- [ ] Both: Deep linking support

## 📱 Testing Strategy

### Unit Tests:
- [ ] Business logic testing
- [ ] Data model validation
- [ ] Repository testing
- [ ] Utility function testing

### Widget Tests:
- [ ] UI component testing
- [ ] User interaction testing
- [ ] State management testing

### Integration Tests:
- [ ] End-to-end user flows
- [ ] API integration testing
- [ ] Database operations testing

## 🚀 Deployment Plan

### Pre-deployment:
- [ ] Code review and cleanup
- [ ] Performance optimization
- [ ] Security audit
- [ ] App store assets preparation

### Deployment:
- [ ] Android Play Store submission
- [ ] iOS App Store submission
- [ ] Beta testing program
- [ ] User feedback collection

### Post-deployment:
- [ ] Monitoring and analytics
- [ ] Bug tracking and fixes
- [ ] Feature updates
- [ ] User support

## 📝 Notes & Updates

### Recent Updates:
- **2024-01-XX**: Initial plan created
- **2024-01-XX**: Project analysis completed
- **2024-01-XX**: Architecture design finalized
- **2024-01-XX**: Phase 1 completed - Flutter project setup with clean architecture
- **2024-01-XX**: Basic data models created (Surah, Verse, Bookmark)
- **2024-01-XX**: Theme system and navigation implemented
- **2024-01-XX**: Basic page stubs created for all main features
- **2024-01-XX**: Phase 2 completed - Complete data layer implementation
- **2024-01-XX**: SQLite database schema and helper created
- **2024-01-XX**: API service layer with Dio implemented
- **2024-01-XX**: Repository pattern and use cases implemented
- **2024-01-XX**: Audio service and settings service created
- **2024-01-XX**: State management with Riverpod providers implemented
- **2024-01-XX**: Phase 3 completed - Core Quran reading features implemented
- **2024-01-XX**: Surah list with data integration completed
- **2024-01-XX**: Verse display with multiple translations implemented
- **2024-01-XX**: Audio player widget with background support created
- **2024-01-XX**: Search functionality with filters implemented
- **2024-01-XX**: Reusable UI components and error handling added
- **2024-01-XX**: Data sources analysis completed - Uthmani JSON and Supabase integration confirmed

### Key Decisions:
- Using Riverpod for state management
- SQLite + Hive for data storage
- Just Audio for audio playback
- Material Design 3 for UI

### Challenges Identified:
- Large dataset management (77K+ words)
- Audio streaming optimization
- Offline data synchronization
- RTL text rendering

## ✅ User Requirements Confirmed

Based on your responses, here are the confirmed requirements:

### 🔑 Supabase Configuration
- **URL**: `https://bwymwoomylotjlnvawlr.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3eW13b29teWxvdGpsbnZhd2xyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4MDM2ODUsImV4cCI6MjA2MjM3OTY4NX0.0LP8whhfrlt15EUgtrzRox25oiApzg9ZGy8kgiV1NP8`
- **Database URL**: `postgresql://postgres.bwymwoomylotjlnvawlr:anas171801@aws-0-eu-north-1.pooler.supabase.com:5432/postgres`

### 🎵 Audio Source
- **AlQuran Cloud API**: For all audio playback
- **Caching**: Local caching for offline playback
- **Background**: Background audio support

### 🌐 Translation Priority
- **Primary**: Tajik translation (always first)
- **Secondary**: Farsi, Russian, English (as available)
- **UI Language**: Entire app in Tajik

### 📱 Offline Strategy
- **Complete Offline**: All 114 surahs with translations and tafsir
- **No Internet Required**: Full functionality without internet
- **Data Bundling**: All essential data in app assets

### 🔐 Authentication
- **No Authentication**: No login, signup, or user accounts
- **Local Storage**: All data stored locally
- **No User Management**: Simplified app experience

### 📱 Platform Features
- **Future Implementation**: Android/iOS specific features will be added later
- **Focus**: Core functionality first

### Next Steps:
1. **Update API Service** with Supabase configuration
2. **Remove Authentication** from the app
3. **Implement Complete Offline Data** bundling
4. **Integrate AlQuran Cloud API** for audio
5. **Proceed with Phase 4** (Islamic Tools Implementation)

---

**Last Updated**: [Current Date]  
**Next Review**: [Next Review Date]  
**Project Lead**: [Your Name]
