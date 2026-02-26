import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'widgets/gallery_tile.dart';
import 'widgets/photo_video_viewer.dart';

/// Modern Gallery Page - Google Photos Style
/// Features:
/// - Date grouping with sticky headers
/// - Photos + Videos support
/// - High performance with optimized thumbnails
/// - Multi-select mode
/// - Smooth scrolling with pagination
class ModernGalleryPage extends StatefulWidget {
  const ModernGalleryPage({Key? key}) : super(key: key);

  @override
  State<ModernGalleryPage> createState() => _ModernGalleryPageState();
}

class _ModernGalleryPageState extends State<ModernGalleryPage> {
  static const int _pageSize = 200; // Increased for better performance
  static const int _crossAxisCount = 4; // Standard grid count
  static const double _spacing = 2.0;

  List<AssetPathEntity> _albums = [];
  Map<String, List<AssetEntity>> _groupedAssets = {};
  List<String> _dateKeys = []; // Sorted date keys
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitializing = true;

  // Multi-select mode
  bool _isSelectionMode = false;
  final Set<String> _selectedAssets = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initGallery();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initGallery() async {
    setState(() => _isInitializing = true);
    
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      if (mounted) {
        _showPermissionDialog();
      }
      setState(() => _isInitializing = false);
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common, // Both images and videos
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false)
        ],
      ),
    );

    setState(() {
      _albums = albums;
      _groupedAssets.clear();
      _dateKeys.clear();
      _currentPage = 0;
      _hasMore = true;
      _isInitializing = false;
    });

    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading || _albums.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final assets = await _albums.first.getAssetListPaged(
        page: _currentPage,
        size: _pageSize,
      );

      if (assets.isEmpty || assets.length < _pageSize) {
        setState(() => _hasMore = false);
      }

      // Group assets by date
      for (final asset in assets) {
        final date = asset.createDateTime;
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        if (!_groupedAssets.containsKey(dateKey)) {
          _groupedAssets[dateKey] = [];
          _dateKeys.add(dateKey);
        }
        _groupedAssets[dateKey]!.add(asset);
      }

      // Sort date keys (newest first)
      _dateKeys.sort((a, b) => b.compareTo(a));

      setState(() {
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading assets: $e');
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 1000 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berechtigung erforderlich'),
        content: const Text(
          'PicSync benötigt Zugriff auf deine Fotos und Videos, um sie anzuzeigen und zu sichern.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PhotoManager.openSetting();
            },
            child: const Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedAssets.clear();
      }
    });
  }

  void _toggleAssetSelection(String assetId) {
    setState(() {
      if (_selectedAssets.contains(assetId)) {
        _selectedAssets.remove(assetId);
      } else {
        _selectedAssets.add(assetId);
      }

      // Exit selection mode if no items selected
      if (_selectedAssets.isEmpty && _isSelectionMode) {
        _isSelectionMode = false;
      }
    });
  }

  void _openViewer(List<AssetEntity> assets, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoVideoViewer(
          assets: assets,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!_isSelectionMode) ...[
            const Text(
              'Fotos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Implement menu
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            ),
            Text(
              '${_selectedAssets.length} ausgewählt',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO: Implement share
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                // TODO: Implement delete
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Keine Fotos gefunden',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _initGallery,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_groupedAssets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _initGallery,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ..._buildDateGroups(),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDateGroups() {
    final List<Widget> slivers = [];

    for (final dateKey in _dateKeys) {
      final assets = _groupedAssets[dateKey]!;
      final date = DateTime.parse(dateKey);

      // Date header
      slivers.add(
        SliverToBoxAdapter(
          child: _buildDateHeader(date, assets.length),
        ),
      );

      // Grid of assets
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _spacing),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount,
              crossAxisSpacing: _spacing,
              mainAxisSpacing: _spacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final asset = assets[index];
                final isSelected = _selectedAssets.contains(asset.id);

                return GalleryTile(
                  asset: asset,
                  isSelectionMode: _isSelectionMode,
                  isSelected: isSelected,
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleAssetSelection(asset.id);
                    } else {
                      _openViewer(assets, index);
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      setState(() => _isSelectionMode = true);
                    }
                    _toggleAssetSelection(asset.id);
                  },
                );
              },
              childCount: assets.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildDateHeader(DateTime date, int count) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    String headerText;
    if (dateToCheck == today) {
      headerText = 'Heute';
    } else if (dateToCheck == yesterday) {
      headerText = 'Gestern';
    } else {
      headerText = DateFormat('d. MMMM yyyy', 'de_DE').format(date);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            headerText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}