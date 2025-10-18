import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mushaf_models.dart';
import '../../data/repositories/mushaf_repository.dart';

final mushafRepositoryProvider = Provider<MushafRepository>((ref) {
  return MushafRepository();
});

final mushafDataProvider = FutureProvider<MushafData>((ref) async {
  final repository = ref.watch(mushafRepositoryProvider);
  return await repository.loadMushafData();
});

final mushafPageProvider = FutureProvider.family<MushafPage, int>((ref, pageNumber) async {
  final repository = ref.watch(mushafRepositoryProvider);
  return await repository.getPage(pageNumber);
});

final mushafPageRangeProvider = FutureProvider.family<List<MushafPage>, PageRange>((ref, range) async {
  final repository = ref.watch(mushafRepositoryProvider);
  return await repository.getPageRange(range.start, range.end);
});

final mushafPageForVerseProvider = FutureProvider.family<int, VerseLocation>((ref, location) async {
  final repository = ref.watch(mushafRepositoryProvider);
  return await repository.getPageForVerse(location.surahNumber, location.verseNumber);
});

class PageRange {
  final int start;
  final int end;

  const PageRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRange && runtimeType == other.runtimeType && start == other.start && end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class VerseLocation {
  final int surahNumber;
  final int verseNumber;

  const VerseLocation(this.surahNumber, this.verseNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseLocation &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          verseNumber == other.verseNumber;

  @override
  int get hashCode => surahNumber.hashCode ^ verseNumber.hashCode;
}
