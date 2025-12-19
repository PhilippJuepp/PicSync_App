import 'package:flutter/material.dart';
import 'connection_status_icon.dart';

PreferredSizeWidget buildAppBar({
  required String title,
  required VoidCallback onReload,
}) {
  return AppBar(
    automaticallyImplyLeading: false,
    title: Text(title),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.blueAccent),
        onPressed: onReload,
      ),
      const SizedBox(width: 8),
      const ConnectionStatusIcon(),
      const SizedBox(width: 12),
    ],
  );
}