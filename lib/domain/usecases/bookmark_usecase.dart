import '../repositories/quran_repository.dart';
import '../../data/models/bookmark_model.dart';

class BookmarkUseCase {
  final QuranRepository _repository;

  BookmarkUseCase(this._repository);

  Future<int> addBookmark(BookmarkModel bookmark) async {
    return await _repository.addBookmark(bookmark);
  }

  Future<List<BookmarkModel>> getBookmarksByUser(String userId) async {
    return await _repository.getBookmarksByUser(userId);
  }

  Future<bool> removeBookmark(int bookmarkId) async {
    return await _repository.removeBookmark(bookmarkId);
  }
}
