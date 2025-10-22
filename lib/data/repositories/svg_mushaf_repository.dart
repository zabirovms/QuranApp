import '../models/svg_mushaf_models.dart';
import '../services/svg_mushaf_service.dart';

class SvgMushafRepository {
  final SvgMushafService _svgService;
  SvgMushafData _data;

  SvgMushafRepository({SvgMushafService? svgService})
      : _svgService = svgService ?? SvgMushafService(),
        _data = SvgMushafData(pageCache: {}, lastUpdated: DateTime.now());

  /// Get a specific page by number
  Future<SvgMushafPage> getPage(int pageNumber) async {
    // Validate page number
    if (pageNumber < 1 || pageNumber > _svgService.totalPages) {
      return SvgMushafPage.error(pageNumber, 'Invalid page number: $pageNumber');
    }

    // Check if page is already cached
    if (_data.isPageCached(pageNumber)) {
      final cachedPage = _data.getPage(pageNumber);
      if (cachedPage != null && cachedPage.isLoaded) {
        return cachedPage;
      }
    }

    try {
      // Load SVG content
      print('Loading SVG for page $pageNumber...');
      final svgContent = await _svgService.getSvgContent(pageNumber);
      print('SVG content loaded, length: ${svgContent.length}');
      
      // Determine Juz and Surah names based on page number
      final juz = _getJuzForPage(pageNumber);
      final surahNames = _getSurahNamesForPage(pageNumber);

      final page = SvgMushafPage(
        pageNumber: pageNumber,
        svgContent: svgContent,
        juz: juz,
        surahNames: surahNames,
        isLoaded: true,
        lastModified: DateTime.now(),
      );

      // Cache the page
      _data = _data.addPage(page);
      
      return page;
    } catch (e) {
      print('Error loading SVG for page $pageNumber: $e');
      return SvgMushafPage.error(pageNumber, e.toString());
    }
  }

  /// Get multiple pages
  Future<List<SvgMushafPage>> getPages(List<int> pageNumbers) async {
    final futures = pageNumbers.map((pageNumber) => getPage(pageNumber));
    return await Future.wait(futures);
  }

  /// Get a range of pages
  Future<List<SvgMushafPage>> getPageRange(int startPage, int endPage) async {
    final pageNumbers = <int>[];
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(i);
    }
    return await getPages(pageNumbers);
  }

  /// Preload pages around a specific page
  Future<void> preloadPagesAround(int centerPage, {int range = 2}) async {
    final startPage = (centerPage - range).clamp(1, _svgService.totalPages);
    final endPage = (centerPage + range).clamp(1, _svgService.totalPages);
    
    final pageNumbers = <int>[];
    for (int i = startPage; i <= endPage; i++) {
      if (!_data.isPageCached(i)) {
        pageNumbers.add(i);
      }
    }
    
    if (pageNumbers.isNotEmpty) {
      await _svgService.preloadPages(pageNumbers);
    }
  }

  /// Get total pages count
  int get totalPages => _svgService.totalPages;

  /// Clear cache
  Future<void> clearCache() async {
    await _svgService.clearCache();
    _data = _data.clearCache();
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    return await _svgService.getCacheSize();
  }

  /// Check if page is cached
  Future<bool> isPageCached(int pageNumber) async {
    return await _svgService.isPageCached(pageNumber);
  }

  /// Get Juz number for a specific page
  int _getJuzForPage(int pageNumber) {
    // Juz mapping based on traditional Quran page layout
    // This is a simplified mapping - in reality, Juz boundaries don't always align with pages
    if (pageNumber <= 20) return 1;
    if (pageNumber <= 40) return 2;
    if (pageNumber <= 60) return 3;
    if (pageNumber <= 80) return 4;
    if (pageNumber <= 100) return 5;
    if (pageNumber <= 120) return 6;
    if (pageNumber <= 140) return 7;
    if (pageNumber <= 160) return 8;
    if (pageNumber <= 180) return 9;
    if (pageNumber <= 200) return 10;
    if (pageNumber <= 220) return 11;
    if (pageNumber <= 240) return 12;
    if (pageNumber <= 260) return 13;
    if (pageNumber <= 280) return 14;
    if (pageNumber <= 300) return 15;
    if (pageNumber <= 320) return 16;
    if (pageNumber <= 340) return 17;
    if (pageNumber <= 360) return 18;
    if (pageNumber <= 380) return 19;
    if (pageNumber <= 400) return 20;
    if (pageNumber <= 420) return 21;
    if (pageNumber <= 440) return 22;
    if (pageNumber <= 460) return 23;
    if (pageNumber <= 480) return 24;
    if (pageNumber <= 500) return 25;
    if (pageNumber <= 520) return 26;
    if (pageNumber <= 540) return 27;
    if (pageNumber <= 560) return 28;
    if (pageNumber <= 580) return 29;
    return 30;
  }

  /// Get Surah names for a specific page
  List<String> _getSurahNamesForPage(int pageNumber) {
    // This is a simplified mapping - in reality, you'd need the actual page-to-surah mapping
    // For now, return empty list as the SVG should contain the Surah information
    return [];
  }
}
