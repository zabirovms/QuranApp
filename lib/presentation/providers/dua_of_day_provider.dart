import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dua_model.dart';
import '../../../core/utils/compressed_json_loader.dart';

/// Get dua of the day based on the day of the year
/// Uses a deterministic algorithm to select the same dua for the same day
final duaOfDayProvider = FutureProvider<DuaModel>((ref) async {
  try {
    // Load rabbano duas from quranic_duas.json
    final List<dynamic> jsonList = await CompressedJsonLoader.loadJsonAsList('assets/data/quranic_duas.json');
    if (jsonList.isEmpty) {
      throw Exception('Duas JSON file is empty or has no data');
    }
    
    final allDuas = jsonList.map((json) {
      try {
        return DuaModel.fromJson(json);
      } catch (e) {
        return null;
      }
    }).whereType<DuaModel>().toList();
    
    if (allDuas.isEmpty) {
      throw Exception('No valid duas found in JSON file after parsing');
    }
    
    // Get day of year (1-365/366)
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;
    
    // Select dua based on day of year (cycle through duas)
    final duaIndex = (dayOfYear - 1) % allDuas.length;
    final selectedDua = allDuas[duaIndex];
    
    return selectedDua;
  } catch (e) {
    if (e.toString().contains('does not exist') || e.toString().contains('empty')) {
      throw Exception('Duas JSON file does not exist or has empty data. Please ensure assets/data/quranic_duas.json exists.');
    }
    throw Exception('Failed to load duas JSON file: $e');
  }
});

