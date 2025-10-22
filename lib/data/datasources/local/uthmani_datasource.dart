import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import '../../models/uthmani_models.dart';

class UthmaniDataSource {
  static Database? _database;
  static const String _databaseName = 'uthmani.db';

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

  /// Get a word by its ID
  Future<UthmaniWord?> getWordById(int id) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToUthmaniWord(maps.first);
  }

  /// Get words by ID range
  Future<List<UthmaniWord>> getWordsByIdRange(int firstId, int lastId) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'id BETWEEN ? AND ?',
      whereArgs: [firstId, lastId],
      orderBy: 'id ASC',
    );

    return maps.map((map) => _mapToUthmaniWord(map)).toList();
  }

  /// Get words by Surah and Ayah
  Future<List<UthmaniWord>> getWordsBySurahAyah(int surah, int ayah) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      orderBy: 'word ASC',
    );

    return maps.map((map) => _mapToUthmaniWord(map)).toList();
  }

  /// Get all words for a specific Surah
  Future<List<UthmaniWord>> getWordsBySurah(int surah) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'surah = ?',
      whereArgs: [surah],
      orderBy: 'ayah ASC, word ASC',
    );

    return maps.map((map) => _mapToUthmaniWord(map)).toList();
  }

  /// Search words by text
  Future<List<UthmaniWord>> searchWords(String searchText) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'text LIKE ?',
      whereArgs: ['%$searchText%'],
      orderBy: 'surah ASC, ayah ASC, word ASC',
    );

    return maps.map((map) => _mapToUthmaniWord(map)).toList();
  }

  /// Get total number of words
  Future<int> getTotalWordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get word count for a specific Surah
  Future<int> getWordCountBySurah(int surah) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM words WHERE surah = ?',
      [surah],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Safely convert database map to UthmaniWord
  UthmaniWord _mapToUthmaniWord(Map<String, dynamic> map) {
    return UthmaniWord(
      id: map['id'] as int,
      location: map['location'] as String,
      surah: map['surah'] as int,
      ayah: map['ayah'] as int,
      word: map['word'] as int,
      text: map['text'] as String,
    );
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
