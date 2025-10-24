import 'package:quran_app/data/models/tasbeeh_model.dart';
import 'package:quran_app/data/models/dua_model.dart';
import '../../../core/utils/compressed_json_loader.dart';

class JsonDataSource {
  // Tasbeeh data
  Future<List<TasbeehModel>> getTasbeehData() async {
    try {
      final List<dynamic> jsonList = await CompressedJsonLoader.loadCompressedJsonAsList('assets/data/tasbeehs.json.gz');
      return jsonList.map((json) => TasbeehModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load tasbeeh data: $e');
    }
  }

  // Duas data
  Future<List<DuaModel>> getDuasData() async {
    try {
      final List<dynamic> jsonList = await CompressedJsonLoader.loadCompressedJsonAsList('assets/data/quranic_duas.json.gz');
      return jsonList.map((json) => DuaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load duas data: $e');
    }
  }

}
