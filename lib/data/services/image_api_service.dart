import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageApiService {
  static const String _baseUrl = 'https://storage.googleapis.com/storage/v1/b/quran-tajik/o?prefix=pictures/';
  
  /// Fetches all image URLs from Google Cloud Storage
  Future<List<String>> fetchImageUrls() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        
        // Filter for image files and extract download URLs
        final imageUrls = items
            .where((item) {
              final name = item['name'] as String? ?? '';
              return name.toLowerCase().endsWith('.jpg') ||
                     name.toLowerCase().endsWith('.jpeg') ||
                     name.toLowerCase().endsWith('.png') ||
                     name.toLowerCase().endsWith('.gif') ||
                     name.toLowerCase().endsWith('.webp');
            })
            .map((item) {
              // Construct the public download URL
              final name = item['name'] as String? ?? '';
              return 'https://storage.googleapis.com/quran-tajik/$name';
            })
            .toList();
        
        return imageUrls;
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching images: $e');
    }
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
