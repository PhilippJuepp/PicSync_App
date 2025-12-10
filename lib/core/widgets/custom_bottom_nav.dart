import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../gen_l10n/app_localizations.dart';
import '../theme/light_theme.dart';
import '../theme/dark_theme.dart';

class AdaptiveNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const AdaptiveNavBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS(context) : _buildAndroid(context);
  }

  Widget _buildIOS(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final items = [
      _NavInfo(label: loc.library, icon: CupertinoIcons.photo_on_rectangle),
      _NavInfo(label: loc.backup, icon: CupertinoIcons.cloud_upload),
      _NavInfo(label: loc.settings, icon: CupertinoIcons.settings),
    ];

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(top: 6, bottom: 6 + bottomPadding),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withValues(alpha: 0.75),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(items.length, (i) {
              final active = i == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon,
                          size: active ? 28 : 24,
                          color: active
                              ? AppColorsLight.primary
                              : AppColorsLight.iconInactive),
                      const SizedBox(height: 2),
                      Text(items[i].label,
                          style: TextStyle(
                            fontSize: active ? 13 : 12,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            color: active
                                ? AppColorsLight.primary
                                : AppColorsLight.iconInactive,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColorsDark.navbar : AppColorsLight.navbar;

    final items = [
      NavigationDestination(
        icon: Icon(Icons.photo_library_outlined, color: isDark ? AppColorsDark.iconInactive : AppColorsLight.iconInactive),
        selectedIcon: Icon(Icons.photo_library_rounded, color: isDark ? Colors.white70 : AppColorsLight.primary),
        label: loc.library,
      ),
      NavigationDestination(
        icon: Icon(Icons.cloud_upload_outlined, color: isDark ? AppColorsDark.iconInactive : AppColorsLight.iconInactive),
        selectedIcon: Icon(Icons.cloud_upload_rounded, color: isDark ? Colors.white70 : AppColorsLight.primary),
        label: loc.backup,
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined, color: isDark ? AppColorsDark.iconInactive : AppColorsLight.iconInactive),
        selectedIcon: Icon(Icons.settings_rounded, color: isDark ? Colors.white70 : AppColorsLight.primary),
        label: loc.settings,
      ),
    ];

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPadding + 2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 56,
            backgroundColor: surfaceColor.withValues(alpha: 0.95),
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            selectedIndex: index,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: items,
            onDestinationSelected: onTap,
          ),
        ),
      ),
    );
  }
}

class _NavInfo {
  final String label;
  final IconData icon;
  const _NavInfo({required this.label, required this.icon});
}