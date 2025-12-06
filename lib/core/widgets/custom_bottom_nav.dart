import 'dart:ui';
import 'package:flutter/material.dart';
import '../../gen_l10n/app_localizations.dart';
import '..//theme/light_theme.dart';
import '..//theme/dark_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const CustomBottomNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final items = [
      _NavItem(icon: Icons.photo_library_rounded, label: loc.library),
      _NavItem(icon: Icons.cloud_upload_rounded, label: loc.backup),
      _NavItem(icon: Icons.settings_rounded, label: loc.settings),
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.colorScheme.surface.withAlpha((isDark ? 0.85 : 0.96 * 255).round());
    final shadowColor = isDark 
        ? Colors.black.withAlpha((0.6 * 255).round()) 
        : Colors.black.withAlpha((0.08 * 255).round());
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: bgColor,
              elevation: 6,
              shadowColor: shadowColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (i) {
                  final it = items[i];
                  final active = i == index;
                  final iconColor = active
                      ? theme.colorScheme.primary
                      : (isDark ? AppColorsDark.iconInactive : AppColorsLight.iconInactive);
                  final textColor = active
                    ? theme.colorScheme.primary
                    : (isDark ? AppColorsDark.iconInactive : AppColorsLight.iconInactive);

                  return Expanded(
                    child: _NavButton(
                      label: it.label,
                      icon: it.icon,
                      active: active,
                      iconColor: iconColor,
                      textColor: textColor,
                      onTap: () => onTap(i),
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
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;
  const _NavButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      containedInkWell: true,
      borderRadius: BorderRadius.circular(15),
      splashFactory: InkRipple.splashFactory,
      splashColor: Theme.of(context).colorScheme.primary.withAlpha((0.25 * 255).round()),
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: active ? iconColor.withAlpha((0.08 * 255).round()) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: active ? 26 : 22, color: iconColor),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: active ? 13 : 12,
                color: textColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}