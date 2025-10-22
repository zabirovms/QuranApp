import 'package:equatable/equatable.dart';

/// Model representing a mushaf page with SVG content
class SvgMushafPage extends Equatable {
  final int pageNumber;
  final String svgContent;
  final int juz;
  final List<String> surahNames;
  final bool isLoaded;
  final DateTime? lastModified;

  const SvgMushafPage({
    required this.pageNumber,
    required this.svgContent,
    required this.juz,
    required this.surahNames,
    this.isLoaded = true,
    this.lastModified,
  });

  /// Create a loading state page
  factory SvgMushafPage.loading(int pageNumber) {
    return SvgMushafPage(
      pageNumber: pageNumber,
      svgContent: '',
      juz: 1,
      surahNames: [],
      isLoaded: false,
    );
  }

  /// Create an error state page
  factory SvgMushafPage.error(int pageNumber, String error) {
    return SvgMushafPage(
      pageNumber: pageNumber,
      svgContent: _generateErrorSvg(error),
      juz: 1,
      surahNames: [],
      isLoaded: true, // Set to true so it displays the error SVG
    );
  }

  /// Generate a simple error SVG
  static String _generateErrorSvg(String error) {
    return '''
<svg width="400" height="600" xmlns="http://www.w3.org/2000/svg">
  <rect width="400" height="600" fill="#f5f5f5" stroke="#ddd" stroke-width="2"/>
  <text x="200" y="300" text-anchor="middle" font-family="Arial" font-size="16" fill="#666">
    Error loading page
  </text>
  <text x="200" y="330" text-anchor="middle" font-family="Arial" font-size="12" fill="#999">
    $error
  </text>
</svg>
''';
  }

  /// Copy with new values
  SvgMushafPage copyWith({
    int? pageNumber,
    String? svgContent,
    int? juz,
    List<String>? surahNames,
    bool? isLoaded,
    DateTime? lastModified,
  }) {
    return SvgMushafPage(
      pageNumber: pageNumber ?? this.pageNumber,
      svgContent: svgContent ?? this.svgContent,
      juz: juz ?? this.juz,
      surahNames: surahNames ?? this.surahNames,
      isLoaded: isLoaded ?? this.isLoaded,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Check if the SVG content is valid
  bool get hasValidSvgContent {
    return svgContent.isNotEmpty && 
           svgContent.contains('<svg') && 
           svgContent.contains('</svg>');
  }

  @override
  List<Object?> get props => [
        pageNumber,
        svgContent,
        juz,
        surahNames,
        isLoaded,
        lastModified,
      ];
}

/// Model representing SVG mushaf data
class SvgMushafData extends Equatable {
  final Map<int, SvgMushafPage> pageCache;
  final DateTime lastUpdated;

  const SvgMushafData({
    required this.pageCache,
    required this.lastUpdated,
  });

  /// Get page by number
  SvgMushafPage? getPage(int pageNumber) {
    return pageCache[pageNumber];
  }

  /// Add or update page in cache
  SvgMushafData addPage(SvgMushafPage page) {
    final newCache = Map<int, SvgMushafPage>.from(pageCache);
    newCache[page.pageNumber] = page;
    
    return SvgMushafData(
      pageCache: newCache,
      lastUpdated: DateTime.now(),
    );
  }

  /// Remove page from cache
  SvgMushafData removePage(int pageNumber) {
    final newCache = Map<int, SvgMushafPage>.from(pageCache);
    newCache.remove(pageNumber);
    
    return SvgMushafData(
      pageCache: newCache,
      lastUpdated: DateTime.now(),
    );
  }

  /// Clear all cached pages
  SvgMushafData clearCache() {
    return SvgMushafData(
      pageCache: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Get cache size
  int get cacheSize => pageCache.length;

  /// Check if page is cached
  bool isPageCached(int pageNumber) {
    return pageCache.containsKey(pageNumber);
  }

  @override
  List<Object?> get props => [pageCache, lastUpdated];
}
