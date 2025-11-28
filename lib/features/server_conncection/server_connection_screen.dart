import 'package:flutter/material.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/widgets/auth_background_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/welcome_screen.dart';
import '../../core/services/api_client.dart';

class ServerConnectionScreen extends StatefulWidget {
  const ServerConnectionScreen({super.key});

  @override
  State<ServerConnectionScreen> createState() => _ServerConnectionScreenState();
}

class _ServerConnectionScreenState extends State<ServerConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

String _normalize(String input) {
  String out = input.trim();

  if (!out.startsWith('http://') && !out.startsWith('https://')) {
    out = 'http://$out';
  }

  final uri = Uri.parse(out);

  final cleanedPath = uri.path.replaceAll(RegExp(r'/{2,}'), '/');

  out = Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.port,
    path: cleanedPath,
  ).toString();

  if (out.endsWith('/')) {
    out = out.substring(0, out.length - 1);
  }

  return out;
}

  Future<void> _testAndSaveServer() async {
    if (!_formKey.currentState!.validate()) return;

    final serverInput = _serverController.text.trim();
    if (serverInput.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final url = _normalize(serverInput);
      
      //Healthcheck
      final testUrl = Uri.parse('$url/health');

      final response = await ApiClient.testConnection(testUrl);
      if (response) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('serverUrl', url);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const WelcomeScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.connectionFailed)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.connectionFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

@override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final bool isTablet = size.width > 600;

  return Scaffold(
    body: GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AuthBackgroundWrapper(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context)!.connectServer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: _buildModernTextField(
                      controller: _serverController,
                      hint: AppLocalizations.of(context)!.serverConnectionHint,
                      icon: Icons.cloud_outlined,
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.fieldRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isLoading ? null : _testAndSaveServer,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            AppLocalizations.of(context)!.connect,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.fromRGBO(255, 255, 255, hasFocus ? 0.9 : 0.25),
                width: hasFocus ? 1.8 : 1.2,
              ),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.white70),
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              validator: validator,
            ),
          );
        },
      ),
    );
  }
}