import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const AuthBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            isDark
                ? 'assets/images/welcome_background_dark.svg'
                : 'assets/images/welcome_background_light.svg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Color.fromRGBO(0, 0, 0, 0.25),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}