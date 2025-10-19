import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/paginated_surah_models.dart';
import '../../data/repositories/paginated_surah_repository.dart';

final paginatedSurahRepositoryProvider = Provider<PaginatedSurahRepository>((ref) {
  return PaginatedSurahRepository();
});

final paginatedSurahDataProvider = FutureProvider.family<PaginatedSurahData, int>((ref, surahNumber) async {
  final repository = ref.watch(paginatedSurahRepositoryProvider);
  return await repository.getSurahPaginatedData(surahNumber);
});

final surahPageProvider = FutureProvider.family<SurahPage, SurahPageParams>((ref, params) async {
  final repository = ref.watch(paginatedSurahRepositoryProvider);
  return await repository.getSurahPage(params.surahNumber, params.pageNumber);
});

final pageNumberForVerseProvider = FutureProvider.family<int, VerseParams>((ref, params) async {
  final repository = ref.watch(paginatedSurahRepositoryProvider);
  return await repository.getPageNumberForVerse(params.surahNumber, params.verseNumber);
});

class SurahPageParams {
  final int surahNumber;
  final int pageNumber;

  const SurahPageParams(this.surahNumber, this.pageNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurahPageParams &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          pageNumber == other.pageNumber;

  @override
  int get hashCode => surahNumber.hashCode ^ pageNumber.hashCode;
}

class VerseParams {
  final int surahNumber;
  final int verseNumber;

  const VerseParams(this.surahNumber, this.verseNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseParams &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          verseNumber == other.verseNumber;

  @override
  int get hashCode => surahNumber.hashCode ^ verseNumber.hashCode;
}
