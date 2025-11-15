import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/image_data.dart';

class ImageApiException implements Exception {
  final String message;
  ImageApiException(this.message);
  
  @override
  String toString() => message;
}

class ImageApiService {
  static const String _baseUrl = 'https://storage.googleapis.com/storage/v1/b/quran-tajik/o?prefix=pictures/';
  
  /// Fetches all image data (URL and name) from Google Cloud Storage
  Future<List<ImageData>> fetchImageData() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        
        // Filter for image files and extract download URLs with names
        final imageDataList = items
            .where((item) {
              final name = item['name'] as String? ?? '';
              return name.toLowerCase().endsWith('.jpg') ||
                     name.toLowerCase().endsWith('.jpeg') ||
                     name.toLowerCase().endsWith('.png') ||
                     name.toLowerCase().endsWith('.gif') ||
                     name.toLowerCase().endsWith('.webp');
            })
            .map((item) {
              // Construct the public download URL with proper encoding
              final name = item['name'] as String? ?? '';
              final encodedName = Uri.encodeComponent(name);
              final url = 'https://storage.googleapis.com/quran-tajik/$encodedName';
              
              // Extract clean name from filename
              final nameWithoutExt = name.split('/').last.split('.').first;
              final cleanName = nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ');
              
              return ImageData(
                url: url,
                name: cleanName,
              );
            })
            .toList();
        
        return imageDataList;
      } else {
        throw ImageApiException('Failed to load images: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw ImageApiException('Network is unreachable. Please check your internet connection.');
    } on HttpException catch (e) {
      throw ImageApiException('HTTP error: ${e.message}');
    } on FormatException {
      throw ImageApiException('Invalid response format from server.');
    } catch (e) {
      throw ImageApiException('Unexpected error: $e');
    }
  }
  
  /// Fetches all image URLs from Google Cloud Storage (for backward compatibility)
  Future<List<String>> fetchImageUrls() async {
    final imageData = await fetchImageData();
    return imageData.map((data) => data.url).toList();
  }
  
  /// Extracts image title from URL
  String getImageTitle(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final fileName = pathSegments.last;
      final nameWithoutExt = fileName.split('.').first;
      return nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ');
    }
    return 'Image';
  }
}
