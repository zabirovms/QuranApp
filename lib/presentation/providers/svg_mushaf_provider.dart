import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/svg_mushaf_models.dart';
import '../../data/repositories/svg_mushaf_repository.dart';
import '../../data/services/svg_mushaf_service.dart';

// Service provider
final svgMushafServiceProvider = Provider<SvgMushafService>((ref) {
  return SvgMushafService();
});

// Repository provider
final svgMushafRepositoryProvider = Provider<SvgMushafRepository>((ref) {
  final service = ref.watch(svgMushafServiceProvider);
  return SvgMushafRepository(svgService: service);
});

// Individual page provider
final svgMushafPageProvider = FutureProvider.family<SvgMushafPage, int>((ref, pageNumber) async {
  final repository = ref.watch(svgMushafRepositoryProvider);
  return await repository.getPage(pageNumber);
});

// Multiple pages provider
final svgMushafPagesProvider = FutureProvider.family<List<SvgMushafPage>, List<int>>((ref, pageNumbers) async {
  final repository = ref.watch(svgMushafRepositoryProvider);
  return await repository.getPages(pageNumbers);
});

// Page range provider
final svgMushafPageRangeProvider = FutureProvider.family<List<SvgMushafPage>, PageRange>((ref, range) async {
  final repository = ref.watch(svgMushafRepositoryProvider);
  return await repository.getPageRange(range.start, range.end);
});

// Cache management provider
final svgMushafCacheProvider = StateNotifierProvider<SvgMushafCacheNotifier, SvgMushafCacheState>((ref) {
  final repository = ref.watch(svgMushafRepositoryProvider);
  return SvgMushafCacheNotifier(repository);
});

// Page range class
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

// Cache state
class SvgMushafCacheState {
  final int cacheSize;
  final bool isLoading;
  final String? error;

  const SvgMushafCacheState({
    this.cacheSize = 0,
    this.isLoading = false,
    this.error,
  });

  SvgMushafCacheState copyWith({
    int? cacheSize,
    bool? isLoading,
    String? error,
  }) {
    return SvgMushafCacheState(
      cacheSize: cacheSize ?? this.cacheSize,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Cache notifier
class SvgMushafCacheNotifier extends StateNotifier<SvgMushafCacheState> {
  final SvgMushafRepository _repository;

  SvgMushafCacheNotifier(this._repository) : super(const SvgMushafCacheState()) {
    _updateCacheSize();
  }

  Future<void> _updateCacheSize() async {
    try {
      final size = await _repository.getCacheSize();
      state = state.copyWith(cacheSize: size);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> clearCache() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.clearCache();
      await _updateCacheSize();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> preloadPagesAround(int centerPage, {int range = 2}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.preloadPagesAround(centerPage, range: range);
      await _updateCacheSize();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> isPageCached(int pageNumber) async {
    return await _repository.isPageCached(pageNumber);
  }
}

// Total pages provider
final svgMushafTotalPagesProvider = Provider<int>((ref) {
  final repository = ref.watch(svgMushafRepositoryProvider);
  return repository.totalPages;
});
