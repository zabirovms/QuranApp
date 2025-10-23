import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _apiDio; // For web API endpoints
  late Dio _supabaseDio; // For direct Supabase calls (if needed)
  late Dio _alquranDio;

  // Supabase REST API configuration
  static const String _apiBaseUrl = 'https://bwymwoomylotjlnvawlr.supabase.co/rest/v1';
  static const String _supabaseUrl = 'https://bwymwoomylotjlnvawlr.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3eW13b29teWxvdGpsbnZhd2xyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4MDM2ODUsImV4cCI6MjA2MjM3OTY4NX0.0LP8whhfrlt15EUgtrzRox25oiApzg9ZGy8kgiV1NP8';
  
  // AlQuran Cloud API for audio
  static const String _alquranBaseUrl = 'https://api.alquran.cloud/v1';

  ApiService._internal() {
    // Supabase REST API client (primary)
    _apiDio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'apikey': _supabaseAnonKey,
        'Authorization': 'Bearer $_supabaseAnonKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Supabase client (for direct calls if needed)
    _supabaseDio = Dio(BaseOptions(
      baseUrl: _supabaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'apikey': _supabaseAnonKey,
        'Authorization': 'Bearer $_supabaseAnonKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // AlQuran Cloud client
    _alquranDio = Dio(BaseOptions(
      baseUrl: _alquranBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for all clients
    _addInterceptors(_apiDio);
    _addInterceptors(_supabaseDio);
    _addInterceptors(_alquranDio);
  }

  factory ApiService() => _instance;

  // Add interceptors helper method
  void _addInterceptors(Dio dio) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => print(object),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // Check internet connectivity
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Get all surahs from web API
  Future<Response> getAllSurahs() async {
    try {
      final response = await _apiDio.get('/surahs?select=*&order=number.asc');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get specific surah by number from Supabase
  Future<Response> getSurah(int surahNumber) async {
    try {
      final response = await _apiDio.get('/surahs?number=eq.$surahNumber&select=*');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get verses for a specific surah from Supabase
  Future<Response> getSurahVerses(int surahNumber) async {
    try {
      // First get the surah to get its ID
      final surahResponse = await _apiDio.get('/surahs?number=eq.$surahNumber&select=id');
      final surahs = surahResponse.data as List;
      
      if (surahs.isEmpty) {
        return Response(requestOptions: RequestOptions(), data: []);
      }
      
      final surahId = surahs.first['id'];
      final response = await _apiDio.get('/verses?surah_id=eq.$surahId&select=*&order=verse_number');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get specific verse by surah and verse number from Supabase
  Future<Response> getVerse(int surahNumber, int verseNumber) async {
    try {
      // First get the surah to get its ID
      final surahResponse = await _apiDio.get('/surahs?number=eq.$surahNumber&select=id');
      final surahs = surahResponse.data as List;
      
      if (surahs.isEmpty) {
        return Response(requestOptions: RequestOptions(), data: []);
      }
      
      final surahId = surahs.first['id'];
      final response = await _apiDio.get('/verses?surah_id=eq.$surahId&verse_number=eq.$verseNumber&select=*');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Search verses from Supabase
  Future<Response> searchVerses(String query, {String language = 'both', int? surahId}) async {
    try {
      // Use RPC function for robust search (created in your schema)
      // Fallback to simple ilike if RPC not available
      try {
        final response = await _supabaseDio.post('/rest/v1/rpc/search_verses', data: {
          'search_query': query,
          'search_lang': language == 'arabic' ? 'arabic' : language == 'tajik' ? 'tajik' : 'both',
          'surah_id': surahId,
        });
        return response;
      } catch (_) {
        String url = '/verses?select=*';
        final escaped = query.replaceAll('%', '\\%').replaceAll('*', '');
        if (language == 'arabic' || language == 'both') {
          url += '&arabic_text=ilike.*$escaped*';
        }
        if (language == 'tajik' || language == 'both') {
          url += '&tajik_text=ilike.*$escaped*';
        }
        if (surahId != null) {
          url += '&surah_id=eq.$surahId';
        }
        final response = await _apiDio.get(url);
        return response;
      }
      // Unreachable in success paths; keep for completeness
      throw Exception('Search failed');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get word-by-word analysis from Supabase
  Future<Response> getWordAnalysis(int surahNumber, int verseNumber) async {
    try {
      final verseKey = '$surahNumber:$verseNumber';
      final response = await _apiDio.get('/word_by_word?unique_key=eq.$verseKey&order=word_number');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Batch fetch word-by-word by unique keys
  Future<Response> getWordByWordByKeys(List<String> uniqueKeys) async {
    try {
      if (uniqueKeys.isEmpty) {
        return Response(requestOptions: RequestOptions(), data: []);
      }
      final keys = uniqueKeys.map((k) => '"$k"').join(',');
      final url = '/word_by_word?unique_key=in.($keys)&order=unique_key,word_number';
      final response = await _apiDio.get(url);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get audio URL for surah from AlQuran Cloud API
  Future<String> getSurahAudioUrl(int surahNumber, {String reciter = 'Abdul_Basit_Murattal'}) async {
    try {
      // Use the correct AlQuran Cloud API endpoint for audio
      final response = await _alquranDio.get('/surah/$surahNumber/$reciter');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['data'] != null) {
          // The API returns the full surah data, but we need to construct the audio URL
          // AlQuran Cloud provides audio URLs in a specific format
          final surahData = data['data'];
          final surahName = surahData['englishName'].toString().toLowerCase().replaceAll(' ', '');
          final audioUrl = 'https://cdn.islamic.network/quran/audio-surah/128/$reciter/$surahNumber.mp3';
          return audioUrl;
        }
      }
      throw Exception('Failed to fetch audio for surah $surahNumber');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get audio URL for verse from AlQuran Cloud API
  Future<String> getVerseAudioUrl(int surahNumber, int verseNumber, {String reciter = 'Abdul_Basit_Murattal'}) async {
    try {
      final response = await _alquranDio.get('/ayah/$surahNumber:$verseNumber/$reciter');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return data['data']['audio'];
        }
      }
      throw Exception('Failed to fetch audio for verse $surahNumber:$verseNumber');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Download file (for audio caching)
  Future<Response> downloadFile(String url, String savePath) async {
    try {
      final response = await _alquranDio.download(url, savePath);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get verses by surah (alias for getSurahVerses)
  Future<Response> getVersesBySurah(int surahNumber) async {
    return getSurahVerses(surahNumber);
  }

  // Get surah by number (alias for getSurah)
  Future<Response> getSurahByNumber(int number) async {
    return getSurah(number);
  }

  // Get word-by-word data for a specific surah
  Future<Response> getWordByWordForSurah(int surahNumber) async {
    try {
      final response = await _apiDio.get('/word_by_word?unique_key=like.$surahNumber:%&order=unique_key,word_number');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get word-by-word data for specific verses
  Future<Response> getWordByWordForVerses(List<String> verseKeys) async {
    try {
      if (verseKeys.isEmpty) {
        return Response(requestOptions: RequestOptions(), data: []);
      }
      final keys = verseKeys.map((k) => '"$k"').join(',');
      final response = await _apiDio.get('/word_by_word?unique_key=in.($keys)&order=unique_key,word_number');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Search history operations
  Future<Response> addSearchHistory(Map<String, dynamic> searchData) async {
    try {
      final response = await _supabaseDio.post('/rest/v1/search_history', data: searchData);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getSearchHistoryByUser(String userId) async {
    try {
      final response = await _supabaseDio.get('/rest/v1/search_history?user_id=eq.$userId&order=created_at.desc');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // User data management
  Future<Response> clearUserBookmarks(String userId) async {
    try {
      final response = await _supabaseDio.delete('/rest/v1/bookmarks?user_id=eq.$userId');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> clearUserSearchHistory(String userId) async {
    try {
      final response = await _supabaseDio.delete('/rest/v1/search_history?user_id=eq.$userId');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Bookmark operations
  Future<Response> getBookmarksByUser(String userId) async {
    try {
      final response = await _apiDio.get('/bookmarks?user_id=eq.$userId&select=*');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> addBookmark(Map<String, dynamic> bookmark) async {
    try {
      final response = await _apiDio.post('/bookmarks', data: bookmark);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> removeBookmark(int bookmarkId) async {
    try {
      final response = await _apiDio.delete('/bookmarks?id=eq.$bookmarkId');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> updateBookmark(int bookmarkId, Map<String, dynamic> bookmark) async {
    try {
      final response = await _apiDio.patch('/bookmarks?id=eq.$bookmarkId', data: bookmark);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.sendTimeout:
        return Exception('Send timeout. Please try again.');
      case DioExceptionType.receiveTimeout:
        return Exception('Receive timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return Exception('Bad request. Please check your input.');
          case 401:
            return Exception('Unauthorized. Please check your credentials.');
          case 403:
            return Exception('Forbidden. You do not have permission to access this resource.');
          case 404:
            return Exception('Resource not found.');
          case 500:
            return Exception('Internal server error. Please try again later.');
          default:
            return Exception('An error occurred: ${error.message}');
        }
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      case DioExceptionType.connectionError:
        return Exception('Connection error. Please check your internet connection.');
      case DioExceptionType.badCertificate:
        return Exception('Bad certificate. Please check your connection.');
      case DioExceptionType.unknown:
      default:
        return Exception('An unknown error occurred: ${error.message}');
    }
  }
}
