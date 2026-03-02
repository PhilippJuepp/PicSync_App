import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'widgets/gallery_tile.dart';
import 'widgets/photo_video_viewer.dart';
import '../../core/widgets/connection_status_icon.dart';
import '../../gen_l10n/app_localizations.dart';

class ModernGalleryPage extends StatefulWidget {
  const ModernGalleryPage({Key? key}) : super(key: key);

  @override
  State<ModernGalleryPage> createState() => _ModernGalleryPageState();
}

class _ModernGalleryPageState extends State<ModernGalleryPage>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 200;
  static const int _crossAxisCount = 4;
  static const double _spacing = 2.0;

  List<AssetPathEntity> _albums = [];
  Map<String, List<AssetEntity>> _groupedAssets = {};
  List<String> _dateKeys = [];
  final List<AssetEntity> _allAssets = [];
  final Map<String, int> _assetIndexById = {};

  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitializing = true;

  bool _isSelectionMode = false;
  final Set<String> _selectedAssets = {};

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

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
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    setState(() {
      _albums = albums;
      _groupedAssets.clear();
      _dateKeys.clear();
      _allAssets.clear();
      _assetIndexById.clear();
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

      for (final asset in assets) {
        final date = asset.createDateTime;
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        if (!_groupedAssets.containsKey(dateKey)) {
          _groupedAssets[dateKey] = [];
          _dateKeys.add(dateKey);
        }
        _groupedAssets[dateKey]!.add(asset);

        if (!_assetIndexById.containsKey(asset.id)) {
          _assetIndexById[asset.id] = _allAssets.length;
          _allAssets.add(asset);
        }
      }

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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.permissionRequired),
        content: Text(l10n.permissionSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PhotoManager.openSetting();
            },
            child: Text(l10n.openSettings),
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

  void _openViewer(AssetEntity asset) {
    final initialIndex = _assetIndexById[asset.id] ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PhotoVideoViewer(assets: _allAssets, initialIndex: initialIndex),
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
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      title: Text(
        _isSelectionMode
            ? '${_selectedAssets.length} ${l10n.selected}'
            : l10n.gallery,
        style: TextStyle(
          fontSize: _isSelectionMode ? 16 : 28,
          fontWeight: _isSelectionMode ? FontWeight.w600 : FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              splashRadius: 20,
            )
          : null,
      actions: const [ConnectionStatusIcon(), SizedBox(width: 8)],
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPhotos,
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _initGallery,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_groupedAssets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return RefreshIndicator(
      onRefresh: _initGallery,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          ..._buildDateGroups(),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[500]!,
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
        SliverToBoxAdapter(child: _buildDateHeader(date, assets.length)),
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
            delegate: SliverChildBuilderDelegate((context, index) {
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
                    _openViewer(asset);
                  }
                },
                onLongPress: () {},
              );
            }, childCount: assets.length),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildDateHeader(DateTime date, int count) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    String headerText;
    if (dateToCheck == today) {
      headerText = l10n.today;
    } else if (dateToCheck == yesterday) {
      headerText = l10n.yesterday;
    } else {
      headerText = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Text(
            headerText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
