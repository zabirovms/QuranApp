import '../../../core/utils/compressed_json_loader.dart';
import '../../models/asmaul_husna_model.dart';

class AsmaulHusnaLocalDataSource {
  static const String _asmaulHusnaJsonPath = 'assets/data/99_Names_Of_Allah.json';

  /// Load all Asmaul Husna from JSON file
  Future<List<AsmaulHusnaModel>> getAllNames() async {
    try {
      final Map<String, dynamic> jsonData = await CompressedJsonLoader.loadJsonAsMap(_asmaulHusnaJsonPath);
      final List<dynamic> dataList = jsonData['data'] as List<dynamic>;
      return dataList.map((json) => AsmaulHusnaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load Asmaul Husna data: $e');
    }
  }
}

