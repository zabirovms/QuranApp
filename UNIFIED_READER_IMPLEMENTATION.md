# Unified Quran Reader Implementation

## Overview
This document describes the implementation of the unified Quran reader screen that allows users to seamlessly switch between Mushaf mode (Arabic Mushaf pages) and Translation mode (translations, tafsir, transliteration).

## Implementation Date
October 19, 2025

## Key Features

### 1. Unified Screen Architecture
- **File**: `lib/presentation/pages/unified_reader/unified_quran_reader_page.dart`
- **Purpose**: Single screen that combines both Mushaf and Translation reading modes
- **Default Mode**: Mushaf (Arabic pages)

### 2. Mode Switching
- **Toggle Button**: Users can switch between modes using a button in the app bar or settings
- **State Preservation**: When switching modes, the current page number is preserved
- **Visual Indicator**: Current mode is displayed with a badge showing "Мусҳаф" or "Тарҷума"

### 3. Navigation Flow
- **From Home Screen**: Clicking a surah from the surah list opens the unified reader at the page where that surah starts
- **From Search**: Clicking a search result opens the unified reader at the specific verse's page
- **From Bookmarks**: Clicking a bookmark opens the unified reader at the bookmarked verse
- **From Duas**: Clicking a Quranic dua opens the unified reader at the verse

### 4. Paging Logic
Both modes use the same paging logic:
- **Page Range**: 1-604 (matching the Quran Mushaf pagination)
- **Page Grouping**: Based on JSON "page" field
- **Mushaf Mode**: Horizontal swipe navigation (left/right) between pages
- **Translation Mode**: Horizontal swipe to change pages, vertical scroll within a page

### 5. Page Controller
- Single `PageController` shared between both modes
- Preserves current page when switching modes
- Supports navigation to specific pages and verses

### 6. Display Features

#### Mushaf Mode
- RTL horizontal scrolling
- Full Arabic text with verse numbers
- Continuous flow of surahs across pages
- Surah headers appear inline when a new surah starts
- Page and Juz indicators
- Tap to show/hide controls

#### Translation Mode
- Vertical scrolling within pages
- Horizontal swipe for page navigation
- Translations (Tajik, Farsi, Russian)
- Transliteration (optional)
- Word-by-word translation (optional)
- Tafsir (expandable)
- Audio playback controls
- Bookmark functionality

### 7. Settings Integration
The unified reader integrates with the existing settings:
- Translation language selection
- Transliteration display toggle
- Word-by-word mode toggle
- Audio reciter selection
- Mode switching toggle

## Technical Implementation

### Route Configuration
New routes added to `lib/app/app.dart`:

```dart
// Unified Quran Reader (Mushaf + Translation)
'/quran/:surahNumber' → UnifiedQuranReaderPage with surah number
'/quran/:surahNumber/verse/:verseNumber' → UnifiedQuranReaderPage with specific verse
'/quran/page/:page' → UnifiedQuranReaderPage with specific page
```

Legacy routes preserved for backward compatibility:
```dart
'/surah/:surahNumber' → SurahPage (old translation-only page)
'/surah/:surahNumber/verse/:verseNumber' → SurahPage with verse
```

### Navigation Updates
All navigation throughout the app has been updated:
- **HomePage**: Surah list items navigate to `/quran/{number}`
- **Mushaf Tab**: Opens unified reader at page 1 (`/quran/page/1`)
- **SearchPage**: Search results navigate to `/quran/{surah}/verse/{verse}`
- **DuasPage**: Quranic duas navigate to `/quran/{surah}/verse/{verse}`
- **BookmarksPage**: Bookmarks navigate to `/quran/{surah}/verse/{verse}`

### Components Reused
The unified reader leverages existing components:
- `MushafPageView`: Displays individual Mushaf pages
- `GlobalQuranPageView`: Displays translation pages with verses
- `AudioPlayerWidget`: Audio playback controls
- Existing providers: `mushafProvider`, `globalQuranPageProvider`, `surahInfoProvider`

### State Management
- `ReaderMode` enum: Tracks current mode (mushaf/translation)
- Settings persistence: Translation language, transliteration, word-by-word mode
- Page state: Current page number preserved across mode switches

## User Experience

### Default Flow
1. User clicks a surah from home screen
2. Unified reader opens in Mushaf mode at the surah's first page
3. User can read Arabic Mushaf pages with horizontal swiping
4. User can tap the translation icon to switch to Translation mode
5. Same page is displayed with translations, transliteration, and other features
6. User can switch back to Mushaf mode at any time

### Mode Toggle
- **In Mushaf Mode**: Translation icon in top bar
- **In Translation Mode**: Mushaf icon in app bar
- **In Settings**: Toggle switch for mode preference
- Visual badge shows current mode

### Page Synchronization
- Both modes display the same page number (1-604)
- Page indicator shows "Саҳифаи X аз 604"
- Juz information displayed in both modes
- Switching modes preserves exact page position

## Modular Design Benefits

### Future Enhancements
The modular implementation enables:
- Audio synchronization across both modes
- Bookmarks working in both modes
- Search highlighting in both modes
- Night mode theming
- Custom font sizes
- Reading progress tracking
- Sharing functionality
- Deep linking support

### Code Maintainability
- Single source of truth for page data
- Reusable components
- Separation of concerns
- Easy to add new features
- Clean architecture principles

## Testing Considerations

### Test Scenarios
1. Navigate from surah list to unified reader
2. Switch between Mushaf and Translation modes
3. Navigate to specific verse from search
4. Navigate to bookmarked verse
5. Page navigation in both modes
6. Settings changes (translation language, etc.)
7. Audio playback in both modes
8. Mode preservation during navigation

### Edge Cases
- First page (page 1)
- Last page (page 604)
- Surahs that span multiple pages
- Pages with multiple surahs
- Navigation with invalid parameters
- Settings persistence

## Performance Optimizations

### Lazy Loading
- Pages loaded on demand
- Providers cache loaded pages
- Efficient memory management

### Smooth Transitions
- PageController provides smooth animations
- State preserved during mode switches
- Minimal rebuilds when switching modes

## Backward Compatibility

### Legacy Routes
Old routes (`/surah/...`) still work and direct to the old `SurahPage`:
- Existing bookmarks continue to work
- Deep links remain functional
- Gradual migration path available

### Migration Path
Apps can migrate from old routes to new unified reader:
1. Update navigation calls to use `/quran/...` routes
2. Test thoroughly
3. Remove legacy routes when ready
4. Update documentation

## Conclusion

The unified Quran reader provides a seamless experience for users to switch between Mushaf and Translation modes while maintaining consistent pagination and navigation. The modular implementation ensures maintainability and allows for future enhancements.
