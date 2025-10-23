import 'package:flutter/foundation.dart';

import '../../../data/datasources/remote/alquran_cloud_api.dart';
import '../../../data/datasources/remote/api_service.dart';
import '../../../data/models/alquran_cloud_models.dart';
import '../../../data/models/surah_model.dart';
import '../../../data/models/verse_model.dart';
import '../../../data/repositories/integrated_quran_repository.dart';
import '../../../data/models/word_by_word_model.dart';

class SurahViewState {
  SurahViewState({
    required this.loading,
    this.error,
    this.surah,
    this.verses = const [],
    this.arabic = const [],
    this.audio = const [],
    this.audioEdition = 'ar.alafasy',
    this.juzStarts = const [],
    this.hizbStarts = const [],
    this.rukuStarts = const [],
    this.manzilStarts = const [],
    this.pageStarts = const [],
    this.wordByWord = const {},
    this.currentAyahIndex = 0,
    this.repeatMode = RepeatMode.off,
    this.repeatRange,
    this.wordByWordAvailable = true,
    this.showWordByWordError = false,
  });

  final bool loading;
  final String? error;
  final SurahModel? surah;
  final List<VerseModel> verses;
  final List<AqcAyah> arabic;
  final List<AqcAyah> audio;
  final String audioEdition;
  final List<int> juzStarts;
  final List<int> hizbStarts;
  final List<int> rukuStarts;
  final List<int> manzilStarts;
  final List<int> pageStarts;
  final Map<String, List<WordByWordModel>> wordByWord;
  final int currentAyahIndex; // 0-based
  final RepeatMode repeatMode;
  final (int, int)? repeatRange; // inclusive 1-based
  final bool wordByWordAvailable;
  final bool showWordByWordError;

  SurahViewState copyWith({
    bool? loading,
    String? error,
    SurahModel? surah,
    List<VerseModel>? verses,
    List<AqcAyah>? arabic,
    List<AqcAyah>? audio,
    String? audioEdition,
    List<int>? juzStarts,
    List<int>? hizbStarts,
    List<int>? rukuStarts,
    List<int>? manzilStarts,
    List<int>? pageStarts,
    Map<String, List<WordByWordModel>>? wordByWord,
    int? currentAyahIndex,
    RepeatMode? repeatMode,
    (int, int)? repeatRange,
    bool? wordByWordAvailable,
    bool? showWordByWordError,
  }) {
    return SurahViewState(
      loading: loading ?? this.loading,
      error: error,
      surah: surah ?? this.surah,
      verses: verses ?? this.verses,
      arabic: arabic ?? this.arabic,
      audio: audio ?? this.audio,
      audioEdition: audioEdition ?? this.audioEdition,
      juzStarts: juzStarts ?? this.juzStarts,
      hizbStarts: hizbStarts ?? this.hizbStarts,
      rukuStarts: rukuStarts ?? this.rukuStarts,
      manzilStarts: manzilStarts ?? this.manzilStarts,
      pageStarts: pageStarts ?? this.pageStarts,
      wordByWord: wordByWord ?? this.wordByWord,
      currentAyahIndex: currentAyahIndex ?? this.currentAyahIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      repeatRange: repeatRange ?? this.repeatRange,
      wordByWordAvailable: wordByWordAvailable ?? this.wordByWordAvailable,
      showWordByWordError: showWordByWordError ?? this.showWordByWordError,
    );
  }
}

class SurahController extends ChangeNotifier {
  SurahController({required ApiService apiService, required AlQuranCloudApi aqc})
      : _repo = IntegratedQuranRepository(apiService: apiService, aqc: aqc);

  final IntegratedQuranRepository _repo;
  SurahViewState state = SurahViewState(loading: false);

  Future<void> load({required int surahNumber, required String audioEdition}) async {
    state = SurahViewState(loading: true, audioEdition: audioEdition);
    notifyListeners();
    try {
      final surah = await _repo.getSurahMeta(surahNumber);
      final verses = await _repo.getSupabaseVerses(surahNumber);
      // Only load audio data, not Arabic text (we use local Arabic text instead)
      final audio = await _repo.getAudioOnly(surahNumber, audioEdition);
      
      // Try to load word-by-word data, but don't fail the entire load if it fails
      Map<String, List<WordByWordModel>> wbw = {};
      bool wordByWordAvailable = true;
      try {
        wbw = await _repo.getWordByWordForSurah(surahNumber);
        wordByWordAvailable = wbw.isNotEmpty;
      } catch (e) {
        // Log the error but continue with the rest of the data
        print('Word-by-word data unavailable: $e');
        wordByWordAvailable = false;
        // Keep empty wbw map - the UI will handle this gracefully
      }

      // compute section starts (1-based ayah indices)
      List<int> startsFor(List<int?> series) {
        final res = <int>[];
        int? last;
        for (var i = 0; i < series.length; i++) {
          final v = series[i];
          if (v == null) continue;
          if (last == null || v != last) {
            res.add(i + 1);
            last = v;
          }
        }
        return res;
      }

      final juzStarts = startsFor(verses.map((v) => v.juz).toList());
      final hizbStarts = startsFor(verses.map((v) => v.juz).toList()); // Using juz as fallback
      final rukuStarts = startsFor(verses.map((v) => v.juz).toList()); // Using juz as fallback
      final manzilStarts = startsFor(verses.map((v) => v.juz).toList()); // Using juz as fallback
      final pageStarts = startsFor(verses.map((v) => v.page).toList());

      state = SurahViewState(
        loading: false,
        surah: surah,
        verses: verses,
        arabic: const [], // No Arabic text from remote API
        audio: audio,
        audioEdition: audioEdition,
        juzStarts: juzStarts,
        hizbStarts: hizbStarts,
        rukuStarts: rukuStarts,
        manzilStarts: manzilStarts,
        pageStarts: pageStarts,
        wordByWord: wbw,
        currentAyahIndex: 0,
        wordByWordAvailable: wordByWordAvailable,
        showWordByWordError: false,
      );
      notifyListeners();
    } catch (e) {
      state = SurahViewState(loading: false, error: e.toString());
      notifyListeners();
    }
  }

  Future<void> changeAudioEdition({required int surahNumber, required String audioEdition}) async {
    await load(surahNumber: surahNumber, audioEdition: audioEdition);
  }

  void setCurrentAyahIndex(int index) {
    state = state.copyWith(currentAyahIndex: index);
    notifyListeners();
  }

  void showWordByWordError() {
    state = state.copyWith(showWordByWordError: true);
    notifyListeners();
  }

  void hideWordByWordError() {
    state = state.copyWith(showWordByWordError: false);
    notifyListeners();
  }
}

enum RepeatMode { off, ayah, range, ruku, hizbQuarter }

