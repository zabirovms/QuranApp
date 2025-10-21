import 'package:dio/dio.dart';

/// Service for fetching images from external APIs
class ImageApiService {
  final Dio _dio;

  ImageApiService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Fetch image from URL
  Future<String> fetchImage(String url) async {
    try {
      final response = await _dio.get(url);
      return response.data.toString();
    } catch (e) {
      throw ImageApiException('Failed to fetch image: $e');
    }
  }

  /// Get random Islamic image
  Future<String> getRandomIslamicImage() async {
    // Placeholder implementation
    return 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Islamic+Image';
  }

  /// Fetch image URLs for duas
  Future<List<String>> fetchImageUrls() async {
    // Placeholder implementation
    return [
      'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Dua+1',
      'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Dua+2',
      'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Dua+3',
    ];
  }

  /// Get image title
  String getImageTitle(int index) {
    return 'Dua Image ${index + 1}';
  }
}

/// Exception for image API errors
class ImageApiException implements Exception {
  final String message;
  ImageApiException(this.message);

  @override
  String toString() => 'ImageApiException: $message';
}
