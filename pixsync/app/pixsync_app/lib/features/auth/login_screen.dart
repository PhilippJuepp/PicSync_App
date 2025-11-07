import 'package:flutter/material.dart';
import '../../gen_l10n/app_localizations.dart';
import 'register_screen.dart';
import '../../core/widgets/auth_background_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  final FocusScopeNode _focusScope = FocusScopeNode();

  @override
  void dispose() {
    _focusScope.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateFadeReplacement(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AuthBackgroundWrapper(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                child: FocusScope(
                  node: _focusScope,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.back,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.signIn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildModernTextField(
                              controller: _emailController,
                              hint: AppLocalizations.of(context)!.emailOrUsername,
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _passwordController,
                              hint: AppLocalizations.of(context)!.password,
                              icon: Icons.lock_outline,
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: Colors.white,
                                      checkColor: Colors.blueAccent,
                                      onChanged: (value) {
                                        setState(() => _rememberMe = value ?? false);
                                      },
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.rememberMe,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  splashColor: Colors.white24,
                                  onTap: () {
                                    // TODO: Forgot password action
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Text(
                                      AppLocalizations.of(context)!.forgotPassword,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                if (_formKey.currentState!.validate()) {
                                  // TODO: Login logic
                                }
                              },
                              child: Text(
                                AppLocalizations.of(context)!.signIn,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.noAccount,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  splashColor: Colors.white24,
                                  onTap: () {
                                      _navigateFadeReplacement(context, const RegisterScreen());
                                    },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      AppLocalizations.of(context)!.signUp,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
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
              color: Color.fromRGBO(255, 255, 255, 0.08),
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              validator: validator ??
                  (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.fieldRequired;
                    }
                    return null;
                  },
            ),
          );
        },
      ),
    );
  }
}