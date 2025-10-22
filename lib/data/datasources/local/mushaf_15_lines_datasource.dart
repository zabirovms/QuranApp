import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import '../../models/uthmani_models.dart';

class Mushaf15LinesDataSource {
  static Database? _database;
  static const String _databaseName = 'uthmani-15-lines.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the database file from assets
    final dbPath = await _copyDatabaseFromAssets();
    
    return await openDatabase(
      dbPath,
      readOnly: true,
    );
  }

  Future<String> _copyDatabaseFromAssets() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    // Check if database already exists
    if (await databaseExists(path)) {
      return path;
    }

    // Copy database from assets
    final data = await rootBundle.load('assets/data/$_databaseName');
    final bytes = data.buffer.asUint8List();
    await File(path).writeAsBytes(bytes);

    return path;
  }

  /// Get Mushaf info
  Future<MushafInfo> getMushafInfo() async {
    final db = await database;
    final maps = await db.query('info', limit: 1);
    
    if (maps.isEmpty) {
      throw Exception('Mushaf info not found');
    }
    
    return MushafInfo.fromMap(maps.first);
  }

  /// Get all lines for a specific page
  Future<List<MushafLine>> getLinesForPage(int pageNumber) async {
    final db = await database;
    final maps = await db.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );

    return maps.map((map) => _mapToMushafLine(map)).toList();
  }

  /// Get a specific line
  Future<MushafLine?> getLine(int pageNumber, int lineNumber) async {
    final db = await database;
    final maps = await db.query(
      'pages',
      where: 'page_number = ? AND line_number = ?',
      whereArgs: [pageNumber, lineNumber],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToMushafLine(maps.first);
  }

  /// Get lines by type for a specific page
  Future<List<MushafLine>> getLinesByType(int pageNumber, String lineType) async {
    final db = await database;
    final maps = await db.query(
      'pages',
      where: 'page_number = ? AND line_type = ?',
      whereArgs: [pageNumber, lineType],
      orderBy: 'line_number ASC',
    );

    return maps.map((map) => _mapToMushafLine(map)).toList();
  }

  /// Get Surah names on a specific page
  Future<List<MushafLine>> getSurahNamesOnPage(int pageNumber) async {
    return getLinesByType(pageNumber, 'surah_name');
  }

  /// Get Bismillah lines on a specific page
  Future<List<MushafLine>> getBismillahOnPage(int pageNumber) async {
    return getLinesByType(pageNumber, 'bismillah');
  }

  /// Get all pages for a specific Surah
  Future<List<int>> getPagesForSurah(int surahNumber) async {
    final db = await database;
    final maps = await db.query(
      'pages',
      columns: ['DISTINCT page_number'],
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'page_number ASC',
    );

    return maps
        .map((map) => _parseIntSafely(map['page_number']))
        .where((page) => page != null)
        .cast<int>()
        .toList();
  }

  /// Get the first page of a Surah
  Future<int?> getFirstPageOfSurah(int surahNumber) async {
    final pages = await getPagesForSurah(surahNumber);
    return pages.isNotEmpty ? pages.first : null;
  }

  /// Get the last page of a Surah
  Future<int?> getLastPageOfSurah(int surahNumber) async {
    final pages = await getPagesForSurah(surahNumber);
    return pages.isNotEmpty ? pages.last : null;
  }

  /// Get total number of pages
  Future<int> getTotalPages() async {
    final info = await getMushafInfo();
    return info.numberOfPages;
  }

  /// Get page range for a specific Surah
  Future<Map<String, int?>> getPageRangeForSurah(int surahNumber) async {
    final firstPage = await getFirstPageOfSurah(surahNumber);
    final lastPage = await getLastPageOfSurah(surahNumber);
    
    return {
      'first': firstPage,
      'last': lastPage,
    };
  }

  /// Get all Surah numbers that appear on a specific page
  Future<List<int>> getSurahsOnPage(int pageNumber) async {
    final db = await database;
    final maps = await db.query(
      'pages',
      columns: ['DISTINCT surah_number'],
      where: 'page_number = ? AND surah_number IS NOT NULL',
      whereArgs: [pageNumber],
      orderBy: 'surah_number ASC',
    );

    return maps
        .map((map) => _parseIntSafely(map['surah_number']))
        .where((surah) => surah != null)
        .cast<int>()
        .toList();
  }

  /// Get Juz information for a page (derived from Surah numbers)
  Future<int> getJuzForPage(int pageNumber) async {
    // This is a simplified implementation
    // In a real implementation, you might want to store Juz info in the database
    final surahs = await getSurahsOnPage(pageNumber);
    if (surahs.isEmpty) return 1;
    
    // Basic Juz calculation based on Surah numbers
    final firstSurah = surahs.first;
    if (firstSurah <= 2) return 1;
    if (firstSurah <= 4) return 2;
    if (firstSurah <= 6) return 3;
    if (firstSurah <= 9) return 4;
    if (firstSurah <= 11) return 5;
    if (firstSurah <= 14) return 6;
    if (firstSurah <= 16) return 7;
    if (firstSurah <= 18) return 8;
    if (firstSurah <= 20) return 9;
    if (firstSurah <= 22) return 10;
    if (firstSurah <= 25) return 11;
    if (firstSurah <= 27) return 12;
    if (firstSurah <= 29) return 13;
    if (firstSurah <= 32) return 14;
    if (firstSurah <= 34) return 15;
    if (firstSurah <= 36) return 16;
    if (firstSurah <= 38) return 17;
    if (firstSurah <= 40) return 18;
    if (firstSurah <= 42) return 19;
    if (firstSurah <= 45) return 20;
    if (firstSurah <= 47) return 21;
    if (firstSurah <= 50) return 22;
    if (firstSurah <= 52) return 23;
    if (firstSurah <= 54) return 24;
    if (firstSurah <= 56) return 25;
    if (firstSurah <= 58) return 26;
    if (firstSurah <= 61) return 27;
    if (firstSurah <= 64) return 28;
    if (firstSurah <= 66) return 29;
    if (firstSurah <= 68) return 30;
    return 30;
  }

  /// Safely convert database map to MushafLine
  MushafLine _mapToMushafLine(Map<String, dynamic> map) {
    return MushafLine(
      pageNumber: map['page_number'] as int,
      lineNumber: map['line_number'] as int,
      lineType: map['line_type'] as String,
      isCentered: (map['is_centered'] as int) == 1,
      firstWordId: _parseIntSafely(map['first_word_id']) ?? 0,
      lastWordId: _parseIntSafely(map['last_word_id']) ?? 0,
      surahNumber: _parseIntSafely(map['surah_number']),
    );
  }

  /// Safely parse integer from dynamic value
  int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  /// Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
