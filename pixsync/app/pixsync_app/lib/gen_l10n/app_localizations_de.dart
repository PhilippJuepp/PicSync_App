// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get welcomeTitle => 'Willkommen!';

  @override
  String get welcomeSubtitle =>
      'Gib deine Zugangsdaten zu deinem PixSync-Konto ein';

  @override
  String get signUp => 'Registrieren';

  @override
  String get signIn => 'Anmelden';
}
