class AssetDto {
  final String id;
  final String url;
  final DateTime takenAt;

  AssetDto({
    required this.id,
    required this.url,
    required this.takenAt,
  });

  factory AssetDto.fromMap(Map<String, dynamic> m) {
    return AssetDto(
      id: (m['id'] ?? m['asset_id'] ?? '').toString(),
      url: (m['url'] ?? m['storage_key'] ?? m['path'] ?? '') as String,
      takenAt: DateTime.tryParse(
            (m['taken_at'] ?? m['created_at'] ?? '')
                ?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }
}