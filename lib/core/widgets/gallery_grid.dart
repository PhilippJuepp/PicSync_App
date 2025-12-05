import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../features/home/gallery_page.dart' show AssetDto;
import 'asset_tile.dart';

class ZoomableGrid extends StatefulWidget {
  final List<AssetDto> assets;
  const ZoomableGrid({super.key, required this.assets});

  @override
  State<ZoomableGrid> createState() => _ZoomableGridState();
}

class _ZoomableGridState extends State<ZoomableGrid> {
  double _scale = 1.0;
  int columns = 3;

  @override
  void initState() {
    super.initState();
    columns = 3;
  }

  void _onScale(double scaleDelta) {
    setState(() {
      _scale *= scaleDelta;
      _scale = _scale.clamp(0.7, 2.0);
      // map 0.7..2.0 to column counts 2..6 (smooth)
      final mapped = (6 - ((_scale - 0.7) / (2.0 - 0.7) * 4)).round();
      columns = mapped.clamp(2, 6);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          _onScale(details.scale);
        }
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        // responsive: adjust baseline columns by width (tablet gets more)
        final isTablet = width > 900;
        final base = isTablet ? 4 : 3;
        final crossAxisCount = (base + (columns - 3)).clamp(2, 6);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GridView.builder(
            key: ValueKey(crossAxisCount), // rebuild when columns change
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.assets.length,
            itemBuilder: (context, i) {
              final asset = widget.assets[i];
              return Hero(
                tag: asset.id,
                child: AssetTile(asset: asset, onTap: () => _openViewer(asset)),
              );
            },
          ),
        );
      }),
    );
  }

  void _openViewer(AssetDto asset) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: PhotoView(
            imageProvider: NetworkImage(asset.url),
            heroAttributes: PhotoViewHeroAttributes(tag: asset.id),
            loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }));
  }
}