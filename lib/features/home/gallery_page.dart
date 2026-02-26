import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ModernGalleryPage extends StatefulWidget {
  const ModernGalleryPage({Key? key}) : super(key: key);

  @override
  State<ModernGalleryPage> createState() => _ModernGalleryPageState();
}

class _ModernGalleryPageState extends State<ModernGalleryPage> {
  static const int _pageSize = 120;

  List<AssetPathEntity> _albums = [];
  List<AssetEntity> _photos = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initGallery();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initGallery() async {
    final Permissions = await PhotoManager.requestPermissionExtend();
    if (!Permissions.isAuth) {
      PhotoManager.openSetting();
      return;
    }
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(),
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)]
      ),
    );
    setState(() {
      _albums = albums;
      _photos.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading || _albums.isEmpty) return;
    setState(() => _isLoading = true);
    final pageAssets = await _albums.first.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );
    setState(() {
      _photos.addAll(pageAssets);
      _isLoading = false;
      _currentPage++;
      if (pageAssets.length < _pageSize) _hasMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 800 &&
        !_isLoading) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fotos"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _initGallery,
            tooltip: "Aktualisieren",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initGallery,
        child: _buildGalleryView(context),
      ),
    );
  }

  Widget _buildGalleryView(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = (constraints.maxWidth / 110).floor().clamp(2, 8);

      return MasonryGridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(left: 2, right: 2, bottom: 24),
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        ),
        itemCount: _photos.length + (_hasMore ? 1 : 0),
        cacheExtent: 1000,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          if (index >= _photos.length) {
            // Loader für Paging
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _PhotoTile(asset: _photos[index], onTap: () => _openPreview(context, index));
        },
      );
    });
  }

  void _openPreview(BuildContext context, int index) async {
    // Einfache Fullscreen-Preview (google-like)
    final asset = _photos[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(asset: asset),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;
  const _PhotoTile({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Hero(
          tag: asset.id,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(300),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final AssetEntity asset;
  const _PhotoViewer({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Hero(
          tag: asset.id,
          child: AssetEntityImage(
            asset,
            isOriginal: true,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}