import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/uthmani_datasource.dart';
import '../../data/datasources/local/mushaf_15_lines_datasource.dart';
import '../../data/repositories/mushaf_15_lines_repository.dart';
import '../../data/models/uthmani_models.dart';

// Data source providers
final uthmaniDataSourceProvider = Provider<UthmaniDataSource>((ref) {
  return UthmaniDataSource();
});

final mushaf15LinesDataSourceProvider = Provider<Mushaf15LinesDataSource>((ref) {
  return Mushaf15LinesDataSource();
});

// Repository provider
final mushaf15LinesRepositoryProvider = Provider<Mushaf15LinesRepository>((ref) {
  final uthmaniDataSource = ref.watch(uthmaniDataSourceProvider);
  final mushaf15LinesDataSource = ref.watch(mushaf15LinesDataSourceProvider);
  
  return Mushaf15LinesRepository(
    uthmaniDataSource: uthmaniDataSource,
    mushaf15LinesDataSource: mushaf15LinesDataSource,
  );
});

// Mushaf info provider
final mushafInfoProvider = FutureProvider<MushafInfo>((ref) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getMushafInfo();
});

// Page provider
final mushaf15LinesPageProvider = FutureProvider.family<MushafPage15Lines, int>((ref, pageNumber) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getPage(pageNumber);
});

// Page range provider
final mushaf15LinesPageRangeProvider = FutureProvider.family<List<MushafPage15Lines>, PageRange>((ref, range) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getPageRange(range.start, range.end);
});

// Line provider
final mushaf15LinesLineProvider = FutureProvider.family<MushafLine?, LineLocation>((ref, location) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getLine(location.pageNumber, location.lineNumber);
});

// Surah pages provider
final mushaf15LinesSurahPagesProvider = FutureProvider.family<List<int>, int>((ref, surahNumber) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getPagesForSurah(surahNumber);
});

// Surah first page provider
final mushaf15LinesSurahFirstPageProvider = FutureProvider.family<int?, int>((ref, surahNumber) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getFirstPageOfSurah(surahNumber);
});

// Total pages provider
final mushaf15LinesTotalPagesProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getTotalPages();
});

// Search provider
final mushaf15LinesSearchProvider = FutureProvider.family<List<UthmaniWord>, String>((ref, searchText) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.searchWords(searchText);
});

// Surah names on page provider
final mushaf15LinesSurahNamesOnPageProvider = FutureProvider.family<List<MushafLine>, int>((ref, pageNumber) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getSurahNamesOnPage(pageNumber);
});

// Bismillah on page provider
final mushaf15LinesBismillahOnPageProvider = FutureProvider.family<List<MushafLine>, int>((ref, pageNumber) async {
  final repository = ref.watch(mushaf15LinesRepositoryProvider);
  return await repository.getBismillahOnPage(pageNumber);
});

// Helper classes
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

class LineLocation {
  final int pageNumber;
  final int lineNumber;

  const LineLocation(this.pageNumber, this.lineNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineLocation &&
          runtimeType == other.runtimeType &&
          pageNumber == other.pageNumber &&
          lineNumber == other.lineNumber;

  @override
  int get hashCode => pageNumber.hashCode ^ lineNumber.hashCode;
}
