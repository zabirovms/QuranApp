import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SvgMushafService {
  static const int _totalPages = 604;
  
  // Cache directory for SVG files
  Directory? _cacheDir;
  
  Future<Directory> get _cacheDirectory async {
    if (_cacheDir != null) return _cacheDir!;
    
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'svg_cache'));
    
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    
    return _cacheDir!;
  }
  
  /// Get the SVG URL for a specific page
  String getSvgUrl(int pageNumber) {
    if (pageNumber < 1 || pageNumber > _totalPages) {
      throw ArgumentError('Page number must be between 1 and $_totalPages');
    }
    
    final paddedPageNumber = pageNumber.toString().padLeft(3, '0');
    return 'https://storage.googleapis.com/download/storage/v1/b/quran-tajik/o/quran-pages-svg%2F$paddedPageNumber.svg?alt=media';
  }
  
  /// Download and cache SVG file for a specific page
  Future<String> getSvgContent(int pageNumber) async {
    final cacheDir = await _cacheDirectory;
    final paddedPageNumber = pageNumber.toString().padLeft(3, '0');
    final cacheFile = File(path.join(cacheDir.path, '$paddedPageNumber.svg'));
    
    // Return cached file if it exists
    if (await cacheFile.exists()) {
      return await cacheFile.readAsString();
    }
    
    // Download from API
    final url = getSvgUrl(pageNumber);
    print('Downloading SVG from: $url');
    final response = await http.get(Uri.parse(url));
    
    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    
    if (response.statusCode == 200) {
      // Cache the file
      await cacheFile.writeAsString(response.body);
      print('SVG cached successfully for page $pageNumber');
      return response.body;
    } else {
      print('Failed to load SVG for page $pageNumber: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load SVG for page $pageNumber: ${response.statusCode}');
    }
  }
  
  /// Get SVG content as bytes (for direct display)
  Future<List<int>> getSvgBytes(int pageNumber) async {
    final cacheDir = await _cacheDirectory;
    final paddedPageNumber = pageNumber.toString().padLeft(3, '0');
    final cacheFile = File(path.join(cacheDir.path, '$paddedPageNumber.svg'));
    
    // Return cached file if it exists
    if (await cacheFile.exists()) {
      return await cacheFile.readAsBytes();
    }
    
    // Download from API
    final url = getSvgUrl(pageNumber);
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      // Cache the file
      await cacheFile.writeAsBytes(response.bodyBytes);
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load SVG for page $pageNumber: ${response.statusCode}');
    }
  }
  
  /// Preload multiple pages
  Future<void> preloadPages(List<int> pageNumbers) async {
    final futures = pageNumbers.map((pageNumber) => getSvgContent(pageNumber));
    await Future.wait(futures);
  }
  
  /// Clear cache
  Future<void> clearCache() async {
    final cacheDir = await _cacheDirectory;
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create(recursive: true);
    }
  }
  
  /// Get cache size
  Future<int> getCacheSize() async {
    final cacheDir = await _cacheDirectory;
    if (!await cacheDir.exists()) return 0;
    
    int totalSize = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
  
  /// Check if page is cached
  Future<bool> isPageCached(int pageNumber) async {
    final cacheDir = await _cacheDirectory;
    final paddedPageNumber = pageNumber.toString().padLeft(3, '0');
    final cacheFile = File(path.join(cacheDir.path, '$paddedPageNumber.svg'));
    return await cacheFile.exists();
  }
  
  /// Get total pages count
  int get totalPages => _totalPages;
}
