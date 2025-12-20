import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';
import '../../gen_l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title: AppLocalizations.of(context)!.settings, onReload: () {}),
      body: const Center(child: Text("Settings Page", style: TextStyle(fontSize: 16))),
    );
  }
}