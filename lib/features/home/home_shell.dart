import 'package:flutter/material.dart';
import 'gallery_page.dart';
import '../../core/widgets/custom_bottom_nav.dart';
import '../backup/backup_page.dart';
import '../settings/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final pages = const [GalleryPage(), BackupPage(), SettingsPage()];

  void _onTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: AdaptiveNavBar(index: _index, onTap: _onTab),
    );
  }
}