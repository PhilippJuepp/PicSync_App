import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../features/home/gallery_page.dart' show AssetDto;

class AssetTile extends StatelessWidget {
  final AssetDto asset;
  final VoidCallback onTap;
  const AssetTile({super.key, required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: asset.url,
              fit: BoxFit.cover,
              imageErrorBuilder: (c, e, st) => Container(
                color: theme.cardColor,
                child: const Center(child: Icon(Icons.broken_image, size: 36)),
              ),
            ),
            // subtle overlay for readability of year label
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.black45 : Colors.white24),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black87.withOpacity(0.6) : Colors.white70,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${asset.takenAt.year}',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}