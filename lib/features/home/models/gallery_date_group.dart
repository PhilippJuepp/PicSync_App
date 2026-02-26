import 'package:photo_manager/photo_manager.dart';

/// Model for grouping assets by date
class GalleryDateGroup {
  final DateTime date;
  final List<AssetEntity> assets;

  GalleryDateGroup({
    required this.date,
    required this.assets,
  });

  String get dateKey => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryDateGroup &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey;

  @override
  int get hashCode => dateKey.hashCode;
}
