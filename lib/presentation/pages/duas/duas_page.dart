import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../data/models/dua_model.dart';
import '../../../data/models/verse_model.dart';
import '../../../data/models/image_data.dart';
import '../../../data/services/image_api_service.dart';
import '../../../data/services/image_permission_service.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../widgets/image_permission_dialog.dart';
import '../../../core/utils/compressed_json_loader.dart';
import '../../../data/datasources/local/verse_local_datasource.dart';

// Helper function to check if a dua has empty fields
bool _hasEmptyFields(DuaModel dua) {
  return (dua.arabic.isEmpty || dua.arabic.trim().isEmpty) ||
         (dua.tajik.isEmpty || dua.tajik.trim().isEmpty) ||
         (dua.transliteration.isEmpty || dua.transliteration.trim().isEmpty);
}

// Providers
final quranicDuasProvider = FutureProvider<List<DuaModel>>((ref) async {
  final verseDataSource = VerseLocalDataSource();
  
  // Load from raw JSON file
  List<DuaModel> allDuas = [];
  try {
    final List<dynamic> jsonList = await CompressedJsonLoader.loadJsonAsList('assets/data/quranic_duas.json');
    if (jsonList.isEmpty) {
      throw Exception('Duas JSON file is empty or has no data');
    }
    allDuas = jsonList.map((json) {
      try {
        return DuaModel.fromJson(json);
      } catch (e) {
        // Skip invalid entries
        return null;
      }
    }).whereType<DuaModel>().toList();
    
    if (allDuas.isEmpty) {
      throw Exception('No valid duas found in JSON file after parsing');
    }
  } catch (e) {
    // Provide more specific error message
    if (e.toString().contains('does not exist') || e.toString().contains('empty')) {
      throw Exception('Duas JSON file does not exist or has empty data. Please ensure assets/data/quranic_duas.json exists.');
    }
    throw Exception('Failed to load duas JSON file: $e');
  }
  
  // Group duas by surah to optimize verse loading
  final Map<int, List<DuaModel>> duasBySurah = {};
  for (final dua in allDuas) {
    if (!duasBySurah.containsKey(dua.surah)) {
      duasBySurah[dua.surah] = [];
    }
    duasBySurah[dua.surah]!.add(dua);
  }
  
  // Fill in empty entries from verse data
  final List<DuaModel> filledDuas = [];
  
  for (final entry in duasBySurah.entries) {
    final surahNumber = entry.key;
    final duasInSurah = entry.value;
    
    // Check if any dua in this surah needs verse data
    final needsVerseData = duasInSurah.any((dua) => _hasEmptyFields(dua));
    
    // Load all verses for this surah if needed
    Map<int, VerseModel>? verseMap;
    if (needsVerseData) {
      try {
        final verses = await verseDataSource.getVersesBySurah(surahNumber);
        if (verses.isEmpty) {
          // If no verses found, we can't fill the duas, but continue with what we have
          verseMap = null;
        } else {
          // Create a map for quick lookup by verse number
          verseMap = {for (var v in verses) v.verseNumber: v};
        }
      } catch (e) {
        // If error loading verses, we'll skip filling those duas but continue
        verseMap = null;
      }
    }
    
    // Process each dua in this surah
    for (final dua in duasInSurah) {
      if (_hasEmptyFields(dua)) {
        // Try to fill from verse data
        if (verseMap != null && verseMap.containsKey(dua.verse)) {
          final verse = verseMap[dua.verse]!;
          filledDuas.add(DuaModel(
            surah: dua.surah,
            verse: dua.verse,
            arabic: (dua.arabic.isEmpty || dua.arabic.trim().isEmpty) ? verse.arabicText : dua.arabic,
            transliteration: (dua.transliteration.isEmpty || dua.transliteration.trim().isEmpty) 
                ? (verse.transliteration ?? '') 
                : dua.transliteration,
            tajik: (dua.tajik.isEmpty || dua.tajik.trim().isEmpty) ? verse.tajikText : dua.tajik,
            reference: dua.reference,
            category: dua.category,
            description: dua.description,
            isFavorite: dua.isFavorite,
            prophet: dua.prophet,
            prophetArabic: dua.prophetArabic,
          ));
        } else {
          // If verse not found or verseMap is null, still add the dua with empty fields
          // This way all duas are shown, even if we couldn't fill them
          filledDuas.add(dua);
        }
      } else {
        // Keep the original dua if it has all fields
        filledDuas.add(dua);
      }
    }
  }
  
  return filledDuas;
});

// Provider for prophets duas - simplified to only use pre-populated JSON data
final prophetsDuasProvider = FutureProvider<List<DuaModel>>((ref) async {
  // Load directly from pre-populated JSON file (all data is already there)
  try {
    final List<dynamic> jsonList = await CompressedJsonLoader.loadJsonAsList('assets/data/prophets_duas.json');
    if (jsonList.isEmpty) {
      throw Exception('Prophets duas JSON file is empty or has no data');
    }
    
    final allDuas = jsonList.map((json) {
      try {
        return DuaModel.fromJson(json);
      } catch (e) {
        return null;
      }
    }).whereType<DuaModel>().toList();
    
    if (allDuas.isEmpty) {
      throw Exception('No valid duas found in prophets JSON file after parsing');
    }
    
    return allDuas;
  } catch (e) {
    if (e.toString().contains('does not exist') || e.toString().contains('empty')) {
      throw Exception('Prophets duas JSON file does not exist or has empty data. Please ensure assets/data/prophets_duas.json exists.');
    }
    throw Exception('Failed to load prophets duas JSON file: $e');
  }
});

// Removed duaImagesProvider - using permission-aware cachedImagesProvider instead

// Cached image list state - persists across tab switches
final cachedImagesProvider = StateNotifierProvider<CachedImagesNotifier, CachedImagesState>((ref) => CachedImagesNotifier());

class CachedImagesState {
  final List<ImageData> imageData;
  final bool isLoading;
  final String? error;
  final bool hasPermission;
  final bool permissionAsked;
  final bool isNetworkError;
  final bool hasAttemptedLoad;

  CachedImagesState({
    this.imageData = const [],
    this.isLoading = false,
    this.error,
    this.hasPermission = false,
    this.permissionAsked = false,
    this.isNetworkError = false,
    this.hasAttemptedLoad = false,
  });

  // Backward compatibility: get URLs from imageData
  List<String> get imageUrls => imageData.map((data) => data.url).toList();

  CachedImagesState copyWith({
    List<ImageData>? imageData,
    bool? isLoading,
    String? error,
    bool? hasPermission,
    bool? permissionAsked,
    bool? isNetworkError,
    bool? hasAttemptedLoad,
  }) {
    return CachedImagesState(
      imageData: imageData ?? this.imageData,
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
    if (state.imageData.isNotEmpty) return;

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
      final imageDataList = await imageApiService.fetchImageData();
      
      // Download images to device storage in the background
      _downloadImagesToDevice(imageDataList);
      
      state = state.copyWith(
        imageData: imageDataList,
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

  /// Downloads images to device storage for offline use
  Future<void> _downloadImagesToDevice(List<ImageData> imageDataList) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/dua_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      for (final imageData in imageDataList) {
        try {
          // Extract filename from URL
          final uri = Uri.parse(imageData.url);
          final fileName = uri.pathSegments.last;
          final filePath = '${imagesDir.path}/$fileName';
          final file = File(filePath);

          // Skip if already downloaded
          if (await file.exists()) {
            continue;
          }

          // Download the image
          final response = await http.get(Uri.parse(imageData.url));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          }
        } catch (e) {
          // Continue with other images if one fails
          print('Failed to download image ${imageData.url}: $e');
        }
      }
    } catch (e) {
      // Don't fail the whole operation if directory creation fails
      print('Failed to create images directory: $e');
    }
  }

  /// Gets the local file path for an image if it exists
  Future<String?> getLocalImagePath(String imageUrl) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/dua_images');
      
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      final filePath = '${imagesDir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
    } catch (e) {
      // Return null if file doesn't exist or error occurs
    }
    return null;
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
  final List<ImageData> filteredImages;
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
    List<ImageData>? filteredImages,
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

  void initializeImages(List<ImageData> allImages) {
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

  void searchImages(String query, List<ImageData> allImages) {
    if (query.isEmpty) {
      state = state.copyWith(
        query: query,
        filteredImages: allImages,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    final filtered = allImages.where((imageData) {
      final lowerQuery = query.toLowerCase();
      return imageData.name.toLowerCase().contains(lowerQuery) ||
          imageData.url.toLowerCase().contains(lowerQuery);
    }).toList();

    state = state.copyWith(
      query: query,
      filteredImages: filtered,
      isSearching: false,
    );
  }

  void clearSearch(List<DuaModel> allDuas, List<ImageData> allImages) {
    state = state.copyWith(
      query: '',
      filteredDuas: allDuas,
      filteredImages: allImages,
      isSearching: false,
    );
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
  late TabController _surahTabController;
  bool _isSearchExpanded = false;
  List<int> _surahNumbers = [];
  Map<int, List<DuaModel>> _duasBySurah = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _tabController.addListener(_onTabChangedForSearch);
    // Initialize surah tab controller with placeholder length, will be updated when data loads
    _surahTabController = TabController(length: 1, vsync: this);
  }

  void _onTabChanged() {
    // Show permission dialog when switching to Дигар tab (index 2)
    if (_tabController.index == 2) {
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
    _surahTabController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    final quranicDuasAsync = ref.read(quranicDuasProvider);
    final prophetsDuasAsync = ref.read(prophetsDuasProvider);
    final cachedImagesState = ref.read(cachedImagesProvider);
    
    if (_tabController.index == 0) {
      // Search in Quranic duas
      quranicDuasAsync.whenData((quranicDuas) {
        ref.read(duasSearchProvider.notifier).searchQuranicDuas(value, quranicDuas);
      });
    } else if (_tabController.index == 1) {
      // Search in Prophets duas
      prophetsDuasAsync.whenData((prophetsDuas) {
        ref.read(duasSearchProvider.notifier).searchQuranicDuas(value, prophetsDuas);
      });
    } else {
      // Search in images
      if (cachedImagesState.imageData.isNotEmpty) {
        ref.read(duasSearchProvider.notifier).searchImages(value, cachedImagesState.imageData);
      }
    }
  }

  void _clearSearch() {
    final quranicDuasAsync = ref.read(quranicDuasProvider);
    final prophetsDuasAsync = ref.read(prophetsDuasProvider);
    final cachedImagesState = ref.read(cachedImagesProvider);
    
    if (_tabController.index == 0) {
      quranicDuasAsync.whenData((quranicDuas) {
        ref.read(duasSearchProvider.notifier).clearSearch(quranicDuas, cachedImagesState.imageData);
      });
    } else if (_tabController.index == 1) {
      prophetsDuasAsync.whenData((prophetsDuas) {
        ref.read(duasSearchProvider.notifier).clearSearch(prophetsDuas, cachedImagesState.imageData);
      });
    } else {
      quranicDuasAsync.whenData((quranicDuas) {
        ref.read(duasSearchProvider.notifier).clearSearch(quranicDuas, cachedImagesState.imageData);
      });
    }
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
              // When expanded, search should span from after back button to the edge
              // The availableWidth already excludes the back button, so we can use most of it
              final searchWidth = _isSearchExpanded 
                  ? availableWidth - 8  // Small padding for edge
                  : 40.0;
              
              return Row(
                children: [
                  if (!_isSearchExpanded)
                    const Text('Дуоҳо'),
                  if (!_isSearchExpanded)
                    const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: searchWidth,
                    child: _isSearchExpanded
                        ? TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: _tabController.index == 0 
                                  ? 'Ҷустуҷӯи дуоҳои Раббано...' 
                                  : _tabController.index == 1
                                      ? 'Ҷустуҷӯи дуоҳои Пайғамбарон...'
                                      : 'Ҷустуҷӯи дуо...',
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/');
              }
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Раббано'),
              Tab(text: 'Пайғамбарон'),
              Tab(text: 'Дигар'),
            ],
          ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Qur'anic Duas Tab
          _buildQuranicTab(quranicDuasAsync, searchState),
          // Prophets Duas Tab
          _buildProphetsTab(ref.watch(prophetsDuasProvider), searchState),
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

        // Group duas by surah and update surah tab controller
        _updateSurahTabs(quranicDuas);

        // Build the tab structure with surah tabs
        return _buildRabbanoTabWithSurahTabs(quranicDuas, searchState);
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

  Widget _buildProphetsTab(AsyncValue<List<DuaModel>> prophetsDuasAsync, DuasSearchState searchState) {
    return prophetsDuasAsync.when(
      data: (prophetsDuas) {
        // Initialize search only once
        if (!searchState.isQuranicInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(duasSearchProvider.notifier).initializeQuranicDuas(prophetsDuas);
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
          onRetry: () => ref.refresh(prophetsDuasProvider),
        ),
      ),
    );
  }

  void _updateSurahTabs(List<DuaModel> duas) {
    // Group duas by surah
    final duasBySurah = <int, List<DuaModel>>{};
    for (final dua in duas) {
      if (!duasBySurah.containsKey(dua.surah)) {
        duasBySurah[dua.surah] = [];
      }
      duasBySurah[dua.surah]!.add(dua);
    }
    
    // Get sorted surah numbers
    final surahNumbers = duasBySurah.keys.toList()..sort();
    
    // Update state and tab controller if changed
    if (surahNumbers != _surahNumbers) {
      final newLength = surahNumbers.length + 1; // +1 for "All" tab
      
      // Update tab controller length if needed
      if (_surahTabController.length != newLength) {
        final oldIndex = _surahTabController.index;
        _surahTabController.dispose();
        _surahTabController = TabController(length: newLength, vsync: this);
        // Restore previous index if still valid
        if (oldIndex < newLength) {
          _surahTabController.index = oldIndex;
        }
      }
      
      setState(() {
        _surahNumbers = surahNumbers;
        _duasBySurah = duasBySurah;
      });
    }
  }

  String _getSurahName(int surahNumber) {
    final surahNames = {
      1: 'Ал-Фотиҳа', 2: 'Ал-Бақара', 3: 'Оли Имрон', 4: 'Ан-Нисо', 5: 'Ал-Маида',
      6: 'Ал-Анъом', 7: 'Ал-Аъроф', 8: 'Ал-Анфол', 9: 'Ат-Тавба', 10: 'Юнус',
      11: 'Ҳуд', 12: 'Юсуф', 13: 'Ар-Раъд', 14: 'Иброҳим', 15: 'Ал-Ҳиҷр',
      16: 'Ан-Наҳл', 17: 'Ал-Исро', 18: 'Ал-Каҳф', 19: 'Марям', 20: 'Тоҳо',
      21: 'Ал-Анбиё', 22: 'Ал-Ҳаҷҷ', 23: 'Ал-Муъминун', 24: 'Ан-Нур', 25: 'Ал-Фурқон',
      26: 'Аш-Шуъаро', 27: 'Ан-Намл', 28: 'Ал-Қасас', 29: 'Ал-Анкабут', 30: 'Ар-Рум',
      31: 'Луқмон', 32: 'Ас-Саҷда', 33: 'Ал-Аҳзоб', 34: 'Сабаъ', 35: 'Фотир',
      36: 'Ясин', 37: 'Ас-Соффот', 38: 'Сод', 39: 'Аз-Зумар', 40: 'Ғофир',
      41: 'Фуссилат', 42: 'Аш-Шуро', 43: 'Аз-Зухруф', 44: 'Ад-Духон', 45: 'Ал-Ҷосия',
      46: 'Ал-Аҳқоф', 47: 'Муҳаммад', 48: 'Ал-Фатҳ', 49: 'Ал-Ҳуҷурот', 50: 'Қоф',
      51: 'Аз-Зориёт', 52: 'Ат-Тур', 53: 'Ан-Наҷм', 54: 'Ал-Қамар', 55: 'Ар-Раҳмон',
      56: 'Ал-Воқиа', 57: 'Ал-Ҳадид', 58: 'Ал-Муҷодала', 59: 'Ал-Ҳашр', 60: 'Ал-Мумтаҳана',
      61: 'Ас-Сафф', 62: 'Ал-Ҷумъа', 63: 'Ал-Мунофиқун', 64: 'Ат-Тағобун', 65: 'Ат-Талақ',
      66: 'Ат-Таҳрим', 67: 'Ал-Мулк', 68: 'Ал-Қалам', 69: 'Ал-Ҳоққа', 70: 'Ал-Маъориҷ',
      71: 'Нуҳ', 72: 'Ал-Ҷинн', 73: 'Ал-Муззаммил', 74: 'Ал-Муддассир', 75: 'Ал-Қиёма',
      76: 'Ал-Инсон', 77: 'Ал-Мурсалот', 78: 'Ан-Набоъ', 79: 'Ан-Назиъот', 80: 'Абаса',
      81: 'Ат-Таквир', 82: 'Ал-Инфитор', 83: 'Ал-Мутоффифин', 84: 'Ал-Иншиқоқ', 85: 'Ал-Буруҷ',
      86: 'Ат-Ториқ', 87: 'Ал-Аъло', 88: 'Ал-Ғошия', 89: 'Ал-Фаҷр', 90: 'Ал-Балад',
      91: 'Аш-Шамс', 92: 'Ал-Лайл', 93: 'Аз-Зуҳо', 94: 'Ал-Иншироҳ', 95: 'Ат-Тин',
      96: 'Ал-Алақ', 97: 'Ал-Қадр', 98: 'Ал-Байина', 99: 'Аз-Залзала', 100: 'Ал-Одиёт',
      101: 'Ал-Қориа', 102: 'Ат-Такосур', 103: 'Ал-Аср', 104: 'Ал-Ҳумаза', 105: 'Ал-Фил',
      106: 'Қурайш', 107: 'Ал-Маъун', 108: 'Ал-Кавсар', 109: 'Ал-Кофирун', 110: 'Ан-Наср',
      111: 'Ал-Масад', 112: 'Ал-Ихлос', 113: 'Ал-Фалақ', 114: 'Ан-Нас',
    };
    return surahNames[surahNumber] ?? 'Сураи $surahNumber';
  }

  Widget _buildRabbanoTabWithSurahTabs(List<DuaModel> allDuas, DuasSearchState searchState) {
    if (_surahNumbers.isEmpty) {
      return const Center(child: LoadingCircularWidget());
    }

    return Column(
      children: [
        // TabBarView for surah content (at top)
        Expanded(
          child: TabBarView(
            controller: _surahTabController,
            children: [
              // "All" tab
              _buildDuasListForSurah(null, allDuas, searchState),
              // Individual surah tabs
              ..._surahNumbers.map((surahNum) {
                final duas = _duasBySurah[surahNum] ?? [];
                return _buildDuasListForSurah(surahNum, duas, searchState);
              }),
            ],
          ),
        ),
        // TabBar for surahs (at bottom)
        TabBar(
          controller: _surahTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: [
            const Tab(text: 'Ҳама'),
            ..._surahNumbers.map((surahNum) => Tab(text: _getSurahName(surahNum))),
          ],
        ),
      ],
    );
  }

  Widget _buildDuasListForSurah(int? surahNumber, List<DuaModel> duas, DuasSearchState searchState) {
    // Apply search filter if active
    List<DuaModel> displayDuas = duas;
    if (searchState.query.isNotEmpty && searchState.isQuranicInitialized) {
      displayDuas = duas.where((dua) {
        final lowerQuery = searchState.query.toLowerCase();
        return dua.arabic.toLowerCase().contains(lowerQuery) ||
            dua.transliteration.toLowerCase().contains(lowerQuery) ||
            dua.tajik.toLowerCase().contains(lowerQuery) ||
            '${dua.surah}:${dua.verse}'.contains(lowerQuery);
      }).toList();
    }

    if (displayDuas.isEmpty) {
      return _buildEmptyState(true);
    }

    return _buildQuranicDuasList(displayDuas);
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
    if (cachedImagesState.imageData.isNotEmpty && !searchState.isImagesInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(duasSearchProvider.notifier).initializeImages(cachedImagesState.imageData);
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

  Widget _buildImageGallery(List<ImageData> imageDataList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: imageDataList.length,
      itemBuilder: (context, index) {
        final imageData = imageDataList[index];
        return _buildImageCard(imageData);
      },
    );
  }

  Widget _buildImageCard(ImageData imageData) {
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
              imageUrl: imageData.url,
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
                imageData.name,
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
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    dua.arabic,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
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