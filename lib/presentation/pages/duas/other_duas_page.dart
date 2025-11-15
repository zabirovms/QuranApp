import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../data/models/image_data.dart';
import 'duas_page.dart'; // For shared providers

class OtherDuasPage extends ConsumerStatefulWidget {
  const OtherDuasPage({super.key});

  @override
  ConsumerState<OtherDuasPage> createState() => _OtherDuasPageState();
}

class _OtherDuasPageState extends ConsumerState<OtherDuasPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    // Show permission dialog when entering this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cachedImagesState = ref.read(cachedImagesProvider);
      if (!cachedImagesState.permissionAsked) {
        _showPermissionDialog();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    final cachedImagesState = ref.read(cachedImagesProvider);
    if (cachedImagesState.imageData.isNotEmpty) {
      ref.read(duasSearchProvider.notifier).searchImages(value, cachedImagesState.imageData);
    }
  }

  void _clearSearch() {
    final cachedImagesState = ref.read(cachedImagesProvider);
    ref.read(duasSearchProvider.notifier).clearSearch([], cachedImagesState.imageData);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Иҷозаи зеркашӣ'),
        content: const Text(
          'Барои дидани тасвирҳои дуоҳо, иҷозаи зеркашӣ додан лозим аст. Оё иҷоза медиҳед?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cachedImagesProvider.notifier).denyPermission();
              Navigator.of(context).pop();
            },
            child: const Text('Не'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cachedImagesProvider.notifier).grantPermission();
              Navigator.of(context).pop();
            },
            child: const Text('Бале'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cachedImagesState = ref.watch(cachedImagesProvider);
    final searchState = ref.watch(duasSearchProvider);

    // Load images if permission granted and not already loaded
    // This will automatically trigger when permission is granted via grantPermission()
    if (cachedImagesState.hasPermission && 
        cachedImagesState.imageUrls.isEmpty && 
        !cachedImagesState.isLoading &&
        !cachedImagesState.hasAttemptedLoad) {
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

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final searchWidth = _isSearchExpanded 
                ? availableWidth - 8
                : 40.0;
            
            return Row(
              children: [
                if (!_isSearchExpanded)
                  const Text('Дигар'),
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
                            hintText: 'Ҷустуҷӯи дуо...',
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
      ),
      body: _buildContent(cachedImagesState, searchState),
    );
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
      return _buildNetworkErrorState(cachedImagesState.error!, cachedImagesState.isNetworkError);
    }

    // If searching
    if (searchState.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no images found
    if (searchState.filteredImages.isEmpty) {
      return _buildEmptyState();
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
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkErrorState(String error, bool isNetworkError) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Тасвирҳо ёфт нашуд',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<ImageData> imageDataList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: imageDataList.length,
      itemBuilder: (context, index) {
        final imageData = imageDataList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildImageCard(imageData),
        );
      },
    );
  }

  Widget _buildImageCard(ImageData imageData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with original aspect ratio - let it decide its own size
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CachedNetworkImage(
                  imageUrl: imageData.url,
                  fit: BoxFit.contain, // Show original size
                  width: constraints.maxWidth, // Take full available width
                  // Don't set height - let image determine its own height based on aspect ratio
                  placeholder: (context, url) => Container(
                    width: constraints.maxWidth,
                    height: 200, // Fixed height only for loading state
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: constraints.maxWidth,
                    height: 200, // Fixed height only for error state
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image),
                    ),
                  ),
                );
              },
            ),
          ),
          // Image name and share button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    imageData.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () => _shareImage(imageData),
                  tooltip: 'Баҳамдиҳӣ',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage(ImageData imageData) async {
    try {
      // Try to get local file first
      final cachedImagesNotifier = ref.read(cachedImagesProvider.notifier);
      final localPath = await cachedImagesNotifier.getLocalImagePath(imageData.url);
      
      if (localPath != null && await File(localPath).exists()) {
        // Share local file
        await Share.shareXFiles(
          [XFile(localPath)],
          text: imageData.name,
        );
      } else {
        // Share URL if local file doesn't exist
        await Share.share(
          imageData.url,
          subject: imageData.name,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Хатогии баҳамдиҳӣ: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

