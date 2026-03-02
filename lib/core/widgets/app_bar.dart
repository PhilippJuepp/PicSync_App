import 'package:flutter/material.dart';
import 'connection_status_icon.dart';

PreferredSizeWidget buildAppBar({
  required String title,
}) {
  return AppBar(
    automaticallyImplyLeading: false,
    title: Text(title),
    actions: const [
      ConnectionStatusIcon(),
      SizedBox(width: 12),
    ],
  );
}