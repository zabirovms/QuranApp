import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/global_quran_page_repository.dart';
import '../../data/models/surah_model.dart';

final globalQuranPageRepositoryProvider = Provider<GlobalQuranPageRepository>((ref) {
  return GlobalQuranPageRepository();
});

final globalQuranPageProvider = FutureProvider.family<QuranPage, int>((ref, pageNumber) async {
  final repository = ref.watch(globalQuranPageRepositoryProvider);
  return await repository.getPage(pageNumber);
});

final surahFirstPageProvider = FutureProvider.family<int, int>((ref, surahNumber) async {
  final repository = ref.watch(globalQuranPageRepositoryProvider);
  return await repository.getFirstPageOfSurah(surahNumber);
});

final surahInfoProvider = FutureProvider.family<SurahModel?, int>((ref, surahNumber) async {
  final repository = ref.watch(globalQuranPageRepositoryProvider);
  return await repository.getSurahInfo(surahNumber);
});
