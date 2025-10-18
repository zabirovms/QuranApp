import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/bookmark_model.dart';

class BookmarkLocalDataSource {
  static Database? _database;
  static const String _tableName = 'bookmarks';
  static const String _databaseName = 'quran_bookmarks.db';
  static const int _databaseVersion = 1;

  // Database initialization
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        verse_id INTEGER NOT NULL,
        verse_key TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        arabic_text TEXT NOT NULL,
        tajik_text TEXT NOT NULL,
        surah_name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(user_id, verse_key)
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_bookmarks_user_id ON $_tableName(user_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_bookmarks_verse_key ON $_tableName(verse_key)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_bookmarks_surah_number ON $_tableName(surah_number)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here if needed
  }

  // Add a bookmark
  Future<int> addBookmark(BookmarkModel bookmark) async {
    final db = await database;
    
    try {
      final id = await db.insert(
        _tableName,
        bookmark.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  // Get all bookmarks for a user
  Future<List<BookmarkModel>> getBookmarksByUser(String userId) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => BookmarkModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to get bookmarks: $e');
    }
  }

  // Remove a bookmark by ID
  Future<bool> removeBookmark(int bookmarkId) async {
    final db = await database;
    
    try {
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [bookmarkId],
      );
      return result > 0;
    } catch (e) {
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  // Remove a bookmark by verse key and user ID
  Future<bool> removeBookmarkByVerseKey(String userId, String verseKey) async {
    final db = await database;
    
    try {
      final result = await db.delete(
        _tableName,
        where: 'user_id = ? AND verse_key = ?',
        whereArgs: [userId, verseKey],
      );
      return result > 0;
    } catch (e) {
      throw Exception('Failed to remove bookmark by verse key: $e');
    }
  }

  // Check if a verse is bookmarked
  Future<bool> isBookmarked(String userId, String verseKey) async {
    final db = await database;
    
    try {
      final result = await db.query(
        _tableName,
        where: 'user_id = ? AND verse_key = ?',
        whereArgs: [userId, verseKey],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check bookmark status: $e');
    }
  }

  // Get bookmark by verse key and user ID
  Future<BookmarkModel?> getBookmarkByVerseKey(String userId, String verseKey) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ? AND verse_key = ?',
        whereArgs: [userId, verseKey],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return BookmarkModel.fromJson(maps.first);
    } catch (e) {
      throw Exception('Failed to get bookmark by verse key: $e');
    }
  }

  // Get bookmarks by surah
  Future<List<BookmarkModel>> getBookmarksBySurah(String userId, int surahNumber) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ? AND surah_number = ?',
        whereArgs: [userId, surahNumber],
        orderBy: 'verse_number ASC',
      );

      return maps.map((map) => BookmarkModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to get bookmarks by surah: $e');
    }
  }

  // Clear all bookmarks for a user
  Future<bool> clearUserBookmarks(String userId) async {
    final db = await database;
    
    try {
      final result = await db.delete(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return result >= 0;
    } catch (e) {
      throw Exception('Failed to clear user bookmarks: $e');
    }
  }

  // Get total bookmark count for a user
  Future<int> getBookmarkCount(String userId) async {
    final db = await database;
    
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ?',
        [userId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get bookmark count: $e');
    }
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
