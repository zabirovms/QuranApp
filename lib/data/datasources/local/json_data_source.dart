import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:quran_app/data/models/tasbeeh_model.dart';
import 'package:quran_app/data/models/dua_model.dart';
import 'package:quran_app/data/models/word_learning_model.dart';

class JsonDataSource {
  // Tasbeeh data
  Future<List<TasbeehModel>> getTasbeehData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/tasbeehs.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => TasbeehModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load tasbeeh data: $e');
    }
  }

  // Duas data
  Future<List<DuaModel>> getDuasData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/quranic_duas.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => DuaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load duas data: $e');
    }
  }

  // Word learning data
  Future<List<WordLearningModel>> getWordLearningData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/top_100_words.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => WordLearningModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load word learning data: $e');
    }
  }

  // Uthmani Quran data
  Future<Map<String, dynamic>> getUthmaniQuranData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/uthmani.json');
      return json.decode(jsonString);
    } catch (e) {
      throw Exception('Failed to load Uthmani Quran data: $e');
    }
  }
}
