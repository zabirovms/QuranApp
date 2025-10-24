import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/dua_model.dart';
import '../../../data/services/image_api_service.dart';
import '../../../data/services/image_permission_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../widgets/image_permission_dialog.dart';
import '../../../core/utils/compressed_json_loader.dart';

// Providers
final quranicDuasProvider = FutureProvider<List<DuaModel>>((ref) async {
  final List<dynamic> jsonList = await CompressedJsonLoader.loadCompressedJsonAsList('assets/data/quranic_duas.json.gz');
  return jsonList.map((json) => DuaModel.fromJson(json)).toList();
});

// Removed duaImagesProvider - using permission-aware cachedImagesProvider instead

// Cached image list state - persists across tab switches
final cachedImagesProvider = StateNotifierProvider<CachedImagesNotifier, CachedImagesState>((ref) => CachedImagesNotifier());

class CachedImagesState {
  final List<String> imageUrls;
  final bool isLoading;
  final String? error;
  final bool hasPermission;
  final bool permissionAsked;
  final bool isNetworkError;
  final bool hasAttemptedLoad;

  CachedImagesState({
    this.imageUrls = const [],
    this.isLoading = false,
    this.error,
    this.hasPermission = false,
    this.permissionAsked = false,
    this.isNetworkError = false,
    this.hasAttemptedLoad = false,
  });

  CachedImagesState copyWith({
    List<String>? imageUrls,
    bool? isLoading,
    String? error,
    bool? hasPermission,
    bool? permissionAsked,
    bool? isNetworkError,
    bool? hasAttemptedLoad,
  }) {
    return CachedImagesState(
      imageUrls: imageUrls ?? this.imageUrls,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasPermission: hasPermission ?? this.hasPermission,
      permissionAsked: permissionAsked ?? this.permissionAsked,
      isNetworkError: isNetworkError ?? this.isNetworkError,
      hasAttemptedLoad: hasAttemptedLoad ?? this.hasAttemptedLoad,
    );
  }
}

class CachedImagesNotifier extends StateNotifier<CachedImagesState> {
  final ImagePermissionService _permissionService = ImagePermissionService();

  CachedImagesNotifier() : super(CachedImagesState()) {
    _initializePermissionAsync();
  }

  void _initializePermissionAsync() async {
    await _initializePermission();
  }

  Future<void> _initializePermission() async {
    final hasPermission = await _permissionService.hasImageDownloadPermission();
    final permissionAsked = await _permissionService.hasAskedForPermission();
    
    state = state.copyWith(
      hasPermission: hasPermission,
      permissionAsked: permissionAsked,
    );
  }

  Future<void> loadImages() async {
    // If already loaded, don't reload
    if (state.imageUrls.isNotEmpty) return;

    // If no permission, don't load images
    if (!state.hasPermission) return;

    // If already attempted and failed with network error, don't retry automatically
    if (state.hasAttemptedLoad && state.isNetworkError) return;

    state = state.copyWith(
      isLoading: true, 
      error: null,
      hasAttemptedLoad: true,
    );

    try {
      final imageApiService = ImageApiService();
      final urls = await imageApiService.fetchImageUrls();
      state = state.copyWith(
        imageUrls: urls,
        isLoading: false,
        error: null,
        isNetworkError: false,
      );
    } on ImageApiException catch (e) {
      final isNetworkError = e.message.contains('Network is unreachable') || 
                            e.message.contains('internet connection') ||
                            e.message.contains('SocketException');
      
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        isNetworkError: isNetworkError,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Хатогии номаълум: $e',
        isNetworkError: false,
      );
    }
  }

  Future<void> requestPermission() async {
    state = state.copyWith(permissionAsked: true);
    await _permissionService.setPermissionAsked(true);
  }

  Future<void> grantPermission() async {
    await _permissionService.setImageDownloadPermission(true);
    state = state.copyWith(hasPermission: true);
    // Load images after permission is granted
    await loadImages();
  }

  Future<void> denyPermission() async {
    await _permissionService.setImageDownloadPermission(false);
    state = state.copyWith(hasPermission: false);
  }

  Future<void> retryLoadImages() async {
    // Reset the attempt flag to allow retry
    state = state.copyWith(
      hasAttemptedLoad: false,
      isNetworkError: false,
      error: null,
    );
    await loadImages();
  }

  void clearCache() {
    state = CachedImagesState();
    _initializePermission();
  }

  Future<void> resetPermissions() async {
    await _permissionService.resetPermissionState();
    state = CachedImagesState();
    await _initializePermission();
  }
}

final duasSearchProvider = StateNotifierProvider<DuasSearchNotifier, DuasSearchState>((ref) => DuasSearchNotifier());

// Search state model
class DuasSearchState {
  final String query;
  final List<DuaModel> filteredDuas;
  final List<String> filteredImages;
  final bool isSearching;
  final bool isQuranicInitialized;
  final bool isImagesInitialized;

  DuasSearchState({
    this.query = '',
    this.filteredDuas = const [],
    this.filteredImages = const [],
    this.isSearching = false,
    this.isQuranicInitialized = false,
    this.isImagesInitialized = false,
  });

  DuasSearchState copyWith({
    String? query,
    List<DuaModel>? filteredDuas,
    List<String>? filteredImages,
    bool? isSearching,
    bool? isQuranicInitialized,
    bool? isImagesInitialized,
  }) {
    return DuasSearchState(
      query: query ?? this.query,
      filteredDuas: filteredDuas ?? this.filteredDuas,
      filteredImages: filteredImages ?? this.filteredImages,
      isSearching: isSearching ?? this.isSearching,
      isQuranicInitialized: isQuranicInitialized ?? this.isQuranicInitialized,
      isImagesInitialized: isImagesInitialized ?? this.isImagesInitialized,
    );
  }
}

// Search notifier
class DuasSearchNotifier extends StateNotifier<DuasSearchState> {
  DuasSearchNotifier() : super(DuasSearchState());

  void initializeQuranicDuas(List<DuaModel> allDuas) {
    if (!state.isQuranicInitialized) {
      state = state.copyWith(
        filteredDuas: allDuas,
        isQuranicInitialized: true,
      );
    }
  }

  void initializeImages(List<String> allImages) {
    if (!state.isImagesInitialized) {
      state = state.copyWith(
        filteredImages: allImages,
        isImagesInitialized: true,
      );
    }
  }

  void searchQuranicDuas(String query, List<DuaModel> allDuas) {
    if (query.isEmpty) {
      state = state.copyWith(
        query: query,
        filteredDuas: allDuas,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    final filtered = allDuas.where((dua) {
      final lowerQuery = query.toLowerCase();
      return dua.arabic.toLowerCase().contains(lowerQuery) ||
          dua.transliteration.toLowerCase().contains(lowerQuery) ||
          dua.tajik.toLowerCase().contains(lowerQuery) ||
          '${dua.surah}:${dua.verse}'.contains(lowerQuery);
    }).toList();

    state = state.copyWith(
      query: query,
      filteredDuas: filtered,
      isSearching: false,
    );
  }

  void searchImages(String query, List<String> allImages) {
    if (query.isEmpty) {
      state = state.copyWith(
        query: query,
        filteredImages: allImages,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    final filtered = allImages.where((imageUrl) {
      final lowerQuery = query.toLowerCase();
      final title = _getImageTitle(imageUrl).toLowerCase();
      return title.contains(lowerQuery) || imageUrl.toLowerCase().contains(lowerQuery);
    }).toList();

    state = state.copyWith(
      query: query,
      filteredImages: filtered,
      isSearching: false,
    );
  }

  void clearSearch(List<DuaModel> allDuas, List<String> allImages) {
    state = state.copyWith(
      query: '',
      filteredDuas: allDuas,
      filteredImages: allImages,
      isSearching: false,
    );
  }

  String _getImageTitle(String imageUrl) {
    final imageApiService = ImageApiService();
    return imageApiService.getImageTitle(imageUrl);
  }
}

class DuasPage extends ConsumerStatefulWidget {
  const DuasPage({super.key});

  @override
  ConsumerState<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends ConsumerState<DuasPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _tabController.addListener(_onTabChangedForSearch);
  }

  void _onTabChanged() {
    // Show permission dialog when switching to Дигар tab
    if (_tabController.index == 1) {
      final cachedImagesState = ref.read(cachedImagesProvider);
      
      if (!cachedImagesState.permissionAsked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPermissionDialog();
        });
      }
    }
  }

  void _onTabChangedForSearch() {
    // Clear search when switching tabs
    _searchController.clear();
    _clearSearch();
    // Collapse search when switching tabs
    if (_isSearchExpanded) {
      setState(() {
        _isSearchExpanded = false;
      });
      _searchFocusNode.unfocus();
    }
    // Trigger rebuild to update hint text
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.removeListener(_onTabChangedForSearch);
    _tabController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    final quranicDuasAsync = ref.read(quranicDuasProvider);
    final cachedImagesState = ref.read(cachedImagesProvider);
    
    quranicDuasAsync.whenData((quranicDuas) {
      if (_tabController.index == 0) {
        // Search in Quranic duas
        ref.read(duasSearchProvider.notifier).searchQuranicDuas(value, quranicDuas);
      } else {
        // Search in images
        if (cachedImagesState.imageUrls.isNotEmpty) {
          ref.read(duasSearchProvider.notifier).searchImages(value, cachedImagesState.imageUrls);
        }
      }
    });
  }

  void _clearSearch() {
    final quranicDuasAsync = ref.read(quranicDuasProvider);
    final cachedImagesState = ref.read(cachedImagesProvider);
    
    quranicDuasAsync.whenData((quranicDuas) {
      ref.read(duasSearchProvider.notifier).clearSearch(quranicDuas, cachedImagesState.imageUrls);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quranicDuasAsync = ref.watch(quranicDuasProvider);
    final searchState = ref.watch(duasSearchProvider);

    return Scaffold(
        appBar: AppBar(
          title: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final searchWidth = _isSearchExpanded ? (availableWidth * 0.6).clamp(200.0, 300.0) : 40.0;
              
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (GoRouter.of(context).canPop()) {
                        GoRouter.of(context).pop();
                      } else {
                        GoRouter.of(context).go('/');
                      }
                    },
                  ),
                  const Text('Дуоҳо'),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: searchWidth,
                    child: _isSearchExpanded
                        ? TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: _tabController.index == 0 ? 'Ҷустуҷӯи дуоҳои Қуръонӣ...' : 'Ҷустуҷӯи дуо...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _clearSearch();
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _isSearchExpanded = false;
                                      });
                                      _searchController.clear();
                                      _clearSearch();
                                      _searchFocusNode.unfocus();
                                    },
                                  ),
                                ],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              _handleSearch(value);
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              setState(() {
                                _isSearchExpanded = true;
                              });
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _searchFocusNode.requestFocus();
                              });
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          centerTitle: false,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Қуръонӣ'),
              Tab(text: 'Дигар'),
            ],
          ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Qur'anic Duas Tab
          _buildQuranicTab(quranicDuasAsync, searchState),
          // Other Duas Tab (Images)
          _buildOtherTab(searchState),
        ],
      ),
    );
  }

  Widget _buildQuranicTab(AsyncValue<List<DuaModel>> quranicDuasAsync, DuasSearchState searchState) {
    return quranicDuasAsync.when(
      data: (quranicDuas) {
        // Initialize search only once
        if (!searchState.isQuranicInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(duasSearchProvider.notifier).initializeQuranicDuas(quranicDuas);
          });
        }

        return searchState.isSearching
            ? const Center(child: CircularProgressIndicator())
            : searchState.filteredDuas.isEmpty
                ? _buildEmptyState(true)
                : _buildQuranicDuasList(searchState.filteredDuas);
      },
      loading: () => const Center(
        child: LoadingCircularWidget(
          size: 50, // optional, adjust as needed
        ),
      ),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          message: 'Хатогии зеркашӣ: $error',
          onRetry: () => ref.refresh(quranicDuasProvider),
        ),
      ),
    );
  }

  Widget _buildOtherTab(DuasSearchState searchState) {
    final cachedImagesState = ref.watch(cachedImagesProvider);

    // Load images if permission granted and not already loaded
    if (cachedImagesState.hasPermission && 
        cachedImagesState.imageUrls.isEmpty && 
        !cachedImagesState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cachedImagesProvider.notifier).loadImages();
      });
    }

    // Initialize search with cached images
    if (cachedImagesState.imageUrls.isNotEmpty && !searchState.isImagesInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(duasSearchProvider.notifier).initializeImages(cachedImagesState.imageUrls);
      });
    }

    return _buildContent(cachedImagesState, searchState);
  }

  Widget _buildContent(CachedImagesState cachedImagesState, DuasSearchState searchState) {
    // If no permission granted, show placeholder mode
    if (!cachedImagesState.hasPermission) {
      return _buildPlaceholderMode();
    }

    // If loading
    if (cachedImagesState.isLoading) {
      return const Center(child: LoadingWidget());
    }

    // If error
    if (cachedImagesState.error != null) {
      return _buildNetworkErrorState(cachedImagesState.error!);
    }

    // If searching
    if (searchState.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no images found
    if (searchState.filteredImages.isEmpty) {
      return _buildEmptyState(false);
    }

    // Show image gallery
    return _buildImageGallery(searchState.filteredImages);
  }

  Widget _buildPlaceholderMode() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Тасвирҳо зеркашӣ нашудаанд',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Барои дидани тасвирҳо, иҷозаи зеркашӣ диҳед',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showPermissionDialog(),
              icon: const Icon(Icons.download),
              label: const Text('Иҷозаи зеркашӣ додан'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Баъд аз зеркашӣ метавонед дар ҳолати офлайн ҳам ба тасвирҳо дастрасӣ дошта бошед.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImagePermissionDialog(
        onAccept: () {
          Navigator.of(context).pop();
          ref.read(cachedImagesProvider.notifier).grantPermission();
        },
        onDecline: () {
          Navigator.of(context).pop();
          ref.read(cachedImagesProvider.notifier).denyPermission();
        },
      ),
    );
    ref.read(cachedImagesProvider.notifier).requestPermission();
  }

  Widget _buildNetworkErrorState(String error) {
    final isNetworkError = error.contains('Network is unreachable') || 
                          error.contains('internet connection') ||
                          error.contains('SocketException');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 80,
              color: isNetworkError ? Colors.orange[400] : Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              isNetworkError ? 'Интернет пайваст нест' : 'Хатогии зеркашӣ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isNetworkError ? Colors.orange[600] : Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isNetworkError 
                ? 'Лутфан интернетро тафтиш кунед ва дубора кӯшиш кунед'
                : error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(cachedImagesProvider.notifier).retryLoadImages();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Навсозӣ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(cachedImagesProvider.notifier).denyPermission();
                  },
                  icon: const Icon(Icons.offline_bolt),
                  label: const Text('Офлайн'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (isNetworkError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Дар ҳолати офлайн, танҳо тасвирҳои қаблан боргирӣшуда намоиш дода мешаванд',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuranicDuasList(List<DuaModel> duas) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: duas.length,
      itemBuilder: (context, index) {
        final dua = duas[index];
        return QuranicDuaCard(
          dua: dua,
          onTap: () => _navigateToVerse(dua),
        );
      },
    );
  }

  Widget _buildImageGallery(List<String> imageNames) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: imageNames.length,
      itemBuilder: (context, index) {
        final imageName = imageNames[index];
        return _buildImageCard(imageName);
      },
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cached network image with natural size
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain, // Maintain aspect ratio
              width: double.infinity, // Take full width
              placeholder: (context, url) => Container(
                height: 200, // Fixed height for loading state
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Тасвир боргирӣ мешавад...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200, // Fixed height for error state
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Тасвир боргирӣ нашуд',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Cache configuration
              memCacheWidth: null, // Don't resize in memory
              memCacheHeight: null, // Don't resize in memory
              maxWidthDiskCache: 2048, // Max width for disk cache
              maxHeightDiskCache: 2048, // Max height for disk cache
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _getImageTitle(imageUrl),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageTitle(String imageUrl) {
    final imageApiService = ImageApiService();
    return imageApiService.getImageTitle(imageUrl);
  }

  Widget _buildEmptyState(bool isQuranic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isQuranic ? Icons.menu_book : Icons.image,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isQuranic ? 'Дуо ёфт нашуд' : 'Ҳанӯз тасвире нест',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isQuranic
                ? 'Лутфан калимаҳои дигар кӯшиш кунед'
                : 'Дар ҳоли ҳозир тасвире барои ин категория нест',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToVerse(DuaModel dua) {
    context.push('/surah/${dua.surah}/verse/${dua.verse}');
  }
}

// Custom card widget for Qur'anic duas
class QuranicDuaCard extends StatelessWidget {
  final DuaModel dua;
  final VoidCallback? onTap;

  const QuranicDuaCard({
    super.key,
    required this.dua,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with reference and navigation icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dua.surah}:${dua.verse}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Arabic text (RTL)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  dua.arabic,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.8,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 12),
              
              // Transliteration (LTR)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  dua.transliteration,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 12),
              
              // Tajik translation (LTR)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  dua.tajik,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}