import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Utility class for handling gzip-compressed JSON files
class CompressedJsonLoader {
  /// Load and decompress a gzip-compressed JSON file
  static Future<String> loadCompressedJson(String assetPath) async {
    try {
      // Load the compressed file as bytes
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List compressedBytes = data.buffer.asUint8List();
      
      // Decompress using gzip
      final List<int> decompressedBytes = gzip.decode(compressedBytes);
      
      // Convert back to string
      return utf8.decode(decompressedBytes);
    } catch (e) {
      throw Exception('Failed to load compressed JSON from $assetPath: $e');
    }
  }
  
  /// Load JSON and parse it directly
  static Future<Map<String, dynamic>> loadCompressedJsonAsMap(String assetPath) async {
    final String jsonString = await loadCompressedJson(assetPath);
    return json.decode(jsonString) as Map<String, dynamic>;
  }
  
  /// Load JSON array and parse it directly
  static Future<List<dynamic>> loadCompressedJsonAsList(String assetPath) async {
    final String jsonString = await loadCompressedJson(assetPath);
    return json.decode(jsonString) as List<dynamic>;
  }
}
