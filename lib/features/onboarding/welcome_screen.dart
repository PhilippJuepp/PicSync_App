import 'package:flutter/material.dart';
import '../../gen_l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../core/widgets/auth_background_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

void _navigateAdaptive(BuildContext context, Widget page) {
  Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (_, _, _) => page,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  ));
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;

    return Scaffold(
      body: AuthBackgroundWrapper(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 50),

                Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.welcomeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.welcomeSubtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 400 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('seenWelcome', true); 
                            if (!context.mounted) return;
                            _navigateAdaptive(context, const RegisterScreen());
                          },
                          child: Text(AppLocalizations.of(context)!.signUp),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            side: const BorderSide(
                              color: Colors.white70,
                              width: 1,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('seenWelcome', true);
                            if (!context.mounted) return;
                            _navigateAdaptive(context, const LoginScreen());
                          },
                          child: Text(AppLocalizations.of(context)!.signIn),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}