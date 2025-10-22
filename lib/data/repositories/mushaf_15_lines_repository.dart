import '../datasources/local/uthmani_datasource.dart';
import '../datasources/local/mushaf_15_lines_datasource.dart';
import '../models/uthmani_models.dart';

class Mushaf15LinesRepository {
  final UthmaniDataSource _uthmaniDataSource;
  final Mushaf15LinesDataSource _mushaf15LinesDataSource;

  Mushaf15LinesRepository({
    required UthmaniDataSource uthmaniDataSource,
    required Mushaf15LinesDataSource mushaf15LinesDataSource,
  }) : _uthmaniDataSource = uthmaniDataSource,
       _mushaf15LinesDataSource = mushaf15LinesDataSource;

  /// Get Mushaf info
  Future<MushafInfo> getMushafInfo() async {
    return await _mushaf15LinesDataSource.getMushafInfo();
  }

  /// Get a complete Mushaf page with all lines and their words
  Future<MushafPage15Lines> getPage(int pageNumber) async {
    // Get all lines for the page
    final lines = await _mushaf15LinesDataSource.getLinesForPage(pageNumber);
    
    // Get words for each line
    final linesWithWords = <MushafLine>[];
    for (final line in lines) {
      List<UthmaniWord> words = [];
      
      // Only fetch words if we have valid word IDs
      if (line.firstWordId > 0 && line.lastWordId > 0) {
        words = await _uthmaniDataSource.getWordsByIdRange(
          line.firstWordId,
          line.lastWordId,
        );
      }
      
      linesWithWords.add(MushafLine(
        pageNumber: line.pageNumber,
        lineNumber: line.lineNumber,
        lineType: line.lineType,
        isCentered: line.isCentered,
        firstWordId: line.firstWordId,
        lastWordId: line.lastWordId,
        surahNumber: line.surahNumber,
        words: words,
      ));
    }

    // Get Surahs on this page
    final surahsOnPage = await _mushaf15LinesDataSource.getSurahsOnPage(pageNumber);
    
    // Get Juz for this page
    final juz = await _mushaf15LinesDataSource.getJuzForPage(pageNumber);

    return MushafPage15Lines(
      pageNumber: pageNumber,
      lines: linesWithWords,
      juz: juz,
      surahsOnPage: surahsOnPage,
    );
  }

  /// Get a specific line with its words
  Future<MushafLine?> getLine(int pageNumber, int lineNumber) async {
    final line = await _mushaf15LinesDataSource.getLine(pageNumber, lineNumber);
    if (line == null) return null;

    List<UthmaniWord> words = [];
    
    // Only fetch words if we have valid word IDs
    if (line.firstWordId > 0 && line.lastWordId > 0) {
      words = await _uthmaniDataSource.getWordsByIdRange(
        line.firstWordId,
        line.lastWordId,
      );
    }

    return MushafLine(
      pageNumber: line.pageNumber,
      lineNumber: line.lineNumber,
      lineType: line.lineType,
      isCentered: line.isCentered,
      firstWordId: line.firstWordId,
      lastWordId: line.lastWordId,
      surahNumber: line.surahNumber,
      words: words,
    );
  }

  /// Get multiple pages
  Future<List<MushafPage15Lines>> getPages(List<int> pageNumbers) async {
    final pages = <MushafPage15Lines>[];
    for (final pageNumber in pageNumbers) {
      final page = await getPage(pageNumber);
      pages.add(page);
    }
    return pages;
  }

  /// Get page range
  Future<List<MushafPage15Lines>> getPageRange(int startPage, int endPage) async {
    final pageNumbers = List.generate(
      endPage - startPage + 1,
      (index) => startPage + index,
    );
    return getPages(pageNumbers);
  }

  /// Get the first page of a Surah
  Future<int?> getFirstPageOfSurah(int surahNumber) async {
    return await _mushaf15LinesDataSource.getFirstPageOfSurah(surahNumber);
  }

  /// Get the last page of a Surah
  Future<int?> getLastPageOfSurah(int surahNumber) async {
    return await _mushaf15LinesDataSource.getLastPageOfSurah(surahNumber);
  }

  /// Get all pages for a Surah
  Future<List<int>> getPagesForSurah(int surahNumber) async {
    return await _mushaf15LinesDataSource.getPagesForSurah(surahNumber);
  }

  /// Get total number of pages
  Future<int> getTotalPages() async {
    return await _mushaf15LinesDataSource.getTotalPages();
  }

  /// Search for text across all words
  Future<List<UthmaniWord>> searchWords(String searchText) async {
    return await _uthmaniDataSource.searchWords(searchText);
  }

  /// Get words by Surah and Ayah
  Future<List<UthmaniWord>> getWordsBySurahAyah(int surah, int ayah) async {
    return await _uthmaniDataSource.getWordsBySurahAyah(surah, ayah);
  }

  /// Get all words for a Surah
  Future<List<UthmaniWord>> getWordsBySurah(int surah) async {
    return await _uthmaniDataSource.getWordsBySurah(surah);
  }

  /// Get a specific word by ID
  Future<UthmaniWord?> getWordById(int id) async {
    return await _uthmaniDataSource.getWordById(id);
  }

  /// Get words by ID range
  Future<List<UthmaniWord>> getWordsByIdRange(int firstId, int lastId) async {
    return await _uthmaniDataSource.getWordsByIdRange(firstId, lastId);
  }

  /// Get Surah names on a specific page
  Future<List<MushafLine>> getSurahNamesOnPage(int pageNumber) async {
    final lines = await _mushaf15LinesDataSource.getSurahNamesOnPage(pageNumber);
    
    // Get words for each line
    final linesWithWords = <MushafLine>[];
    for (final line in lines) {
      final words = await _uthmaniDataSource.getWordsByIdRange(
        line.firstWordId,
        line.lastWordId,
      );
      
      linesWithWords.add(MushafLine(
        pageNumber: line.pageNumber,
        lineNumber: line.lineNumber,
        lineType: line.lineType,
        isCentered: line.isCentered,
        firstWordId: line.firstWordId,
        lastWordId: line.lastWordId,
        surahNumber: line.surahNumber,
        words: words,
      ));
    }
    
    return linesWithWords;
  }

  /// Get Bismillah on a specific page
  Future<List<MushafLine>> getBismillahOnPage(int pageNumber) async {
    final lines = await _mushaf15LinesDataSource.getBismillahOnPage(pageNumber);
    
    // Get words for each line
    final linesWithWords = <MushafLine>[];
    for (final line in lines) {
      final words = await _uthmaniDataSource.getWordsByIdRange(
        line.firstWordId,
        line.lastWordId,
      );
      
      linesWithWords.add(MushafLine(
        pageNumber: line.pageNumber,
        lineNumber: line.lineNumber,
        lineType: line.lineType,
        isCentered: line.isCentered,
        firstWordId: line.firstWordId,
        lastWordId: line.lastWordId,
        surahNumber: line.surahNumber,
        words: words,
      ));
    }
    
    return linesWithWords;
  }

  /// Close all databases
  Future<void> close() async {
    await _uthmaniDataSource.close();
    await _mushaf15LinesDataSource.close();
  }
}
