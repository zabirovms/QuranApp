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

  /// Load a regular (non-compressed) JSON file and parse it as a List
  static Future<List<dynamic>> loadJsonAsList(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      return json.decode(jsonString) as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load JSON from $assetPath: $e');
    }
  }

  /// Load a regular (non-compressed) JSON file and parse it as a Map
  static Future<Map<String, dynamic>> loadJsonAsMap(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load JSON from $assetPath: $e');
    }
  }
}
