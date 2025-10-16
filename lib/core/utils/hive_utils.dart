import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class HiveUtils {
  static Future<void> init() async {
    // Register adapters for custom types
    // Hive.registerAdapter(SurahAdapter());
    // Hive.registerAdapter(VerseAdapter());
    // Hive.registerAdapter(BookmarkAdapter());
    
    // Open boxes
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.bookmarksBox);
    await Hive.openBox(AppConstants.userPreferencesBox);
    await Hive.openBox(AppConstants.searchHistoryBox);
    await Hive.openBox(AppConstants.tasbeehBox);
    await Hive.openBox(AppConstants.wordLearningBox);
  }
  
  // Settings Box
  static Box get settingsBox => Hive.box(AppConstants.settingsBox);
  
  // Bookmarks Box
  static Box get bookmarksBox => Hive.box(AppConstants.bookmarksBox);
  
  // User Preferences Box
  static Box get userPreferencesBox => Hive.box(AppConstants.userPreferencesBox);
  
  // Search History Box
  static Box get searchHistoryBox => Hive.box(AppConstants.searchHistoryBox);
  
  // Tasbeeh Box
  static Box get tasbeehBox => Hive.box(AppConstants.tasbeehBox);
  
  // Word Learning Box
  static Box get wordLearningBox => Hive.box(AppConstants.wordLearningBox);
  
  // Generic methods for all boxes
  static Future<void> put(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }
  
  static T? get<T>(String boxName, String key) {
    final box = Hive.box(boxName);
    return box.get(key);
  }
  
  static Future<void> delete(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }
  
  static Future<void> clear(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }
  
  static List<dynamic> getAll(String boxName) {
    final box = Hive.box(boxName);
    return box.values.toList();
  }
  
  static Map<dynamic, dynamic> getAllAsMap(String boxName) {
    final box = Hive.box(boxName);
    return box.toMap();
  }
}
