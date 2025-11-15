import '../../../core/utils/compressed_json_loader.dart';
import '../../models/prophet_model.dart';

class ProphetLocalDataSource {
  static const String _prophetsJsonPath = 'assets/data/Prophets.json';

  /// Load all prophets from JSON file
  Future<List<ProphetModel>> getAllProphets() async {
    try {
      final List<dynamic> jsonList = await CompressedJsonLoader.loadJsonAsList(_prophetsJsonPath);
      return jsonList.map((json) => ProphetModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load prophets data: $e');
    }
  }
}

