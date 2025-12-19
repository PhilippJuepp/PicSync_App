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
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      _NavInfo(label: loc.library, icon: CupertinoIcons.photo_on_rectangle),
      _NavInfo(label: loc.backup, icon: CupertinoIcons.cloud_upload),
      _NavInfo(label: loc.settings, icon: CupertinoIcons.settings),
    ];

    return SafeArea(
      bottom: true,
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
            child: Container(
              height: 64.0,
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.systemGrey6.darkColor.withValues(alpha: 0.75)
                    : CupertinoColors.systemGrey6.withValues(alpha: 0.75),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (i) {
                  final active = i == index;
                  final color = active
                      ? AppColorsLight.primary
                      : AppColorsLight.iconInactive;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            items[i].icon,
                            size: active ? 28.0 : 24.0,
                            color: color,
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              fontSize: active ? 13.0 : 12.0,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
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

    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    final horizontalPadding =
        isTablet ? ((size.width - 560) / 2.0) : 14.0;

    final items = [
      NavigationDestination(
        icon: Icon(Icons.photo_library_outlined,
            color: isDark ? AppColorsDark.iconInactive : AppColorsLight.iconInactive),
        selectedIcon: Icon(Icons.photo_library_rounded,
            color: isDark
                ? Color(0xFF4285F4)
                : Color(0xFF1A73E8)),
        label: loc.library,
      ),
      NavigationDestination(
        icon: Icon(Icons.cloud_upload_outlined,
            color: isDark ? AppColorsDark.iconInactive : AppColorsLight.iconInactive),
        selectedIcon: Icon(Icons.cloud_upload_rounded,
            color: isDark
                ? Color(0xFF4285F4)
                : Color(0xFF1A73E8)),
        label: loc.backup,
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined,
            color: isDark ? AppColorsDark.iconInactive : AppColorsLight.iconInactive),
        selectedIcon: Icon(Icons.settings_rounded,
            color: isDark
                ? Color(0xFF4285F4)
                : Color(0xFF1A73E8)),
        label: loc.settings,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0.0, horizontalPadding, 8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.0),
            child: NavigationBar(
              height: 64.0,
              backgroundColor: surfaceColor.withValues(alpha: 0.95),
              indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              selectedIndex: index,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: items,
              onDestinationSelected: onTap,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
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