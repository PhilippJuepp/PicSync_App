// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get welcomeSubtitle =>
      'Enter personal details to your PicSync-account';

  @override
  String get signUp => 'Sign up';

  @override
  String get signIn => 'Sign in';

  @override
  String get getStarted => 'Get Started';

  @override
  String get fullName => 'Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get agreePersonalData => 'I agree to the processing of personal data';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get back => 'Back';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationSuccess => 'Registration successful!';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get loginSuccess => 'Login successful!';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get invalidCredentials => 'Invalid login details';

  @override
  String get emailOrUserExists => 'Email adress or username already exists';

  @override
  String get invalidInput => 'Invalid input';

  @override
  String get connectServer => 'Connect to Server';

  @override
  String get serverConnectionHint => 'Enter server address (IP, domain or URL)';

  @override
  String get connect => 'Connect';

  @override
  String get connectionFailed => 'Could not connect to server';

  @override
  String get invalidUrl => 'Invalid URL';
}
