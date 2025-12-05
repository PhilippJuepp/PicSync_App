import 'package:flutter/material.dart';
import '../../core/services/assets_service.dart';
import '../../core/widgets/gallery_grid.dart';
import '../../gen_l10n/app_localizations.dart';

class AssetDto {
  final String id;
  final String url;
  final DateTime takenAt;
  AssetDto({required this.id, required this.url, required this.takenAt});

  factory AssetDto.fromMap(Map<String, dynamic> m) {
    return AssetDto(
      id: (m['id'] ?? m['asset_id'] ?? '').toString(),
      url: (m['url'] ?? m['storage_key'] ?? m['path'] ?? '') as String,
      takenAt: DateTime.tryParse((m['taken_at'] ?? m['created_at'] ?? '')?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<AssetDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AssetDto>> _load() async {
    try {
      final raw = await AssetsService.fetchAssets(limit: 300);
      return raw.map((m) => AssetDto.fromMap(m)).where((a) => a.url.isNotEmpty).toList();
    } catch (e) {
      // bubble up error to FutureBuilder
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Text(loc.library, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _future = _load()),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: loc.refresh,
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AssetDto>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('${loc.connectionFailed}: ${snap.error}'));
              }
              final assets = snap.data ?? [];
              if (assets.isEmpty) {
                return Center(child: Text(loc.no_media_found));
              }
              return ZoomableGrid(assets: assets);
            },
          ),
        ),
      ],
    );
  }
}