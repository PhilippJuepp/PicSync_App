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
      'Gib deine Zugangsdaten zu deinem PicSync-Konto ein';

  @override
  String get signUp => 'Registrieren';

  @override
  String get signIn => 'Anmelden';

  @override
  String get getStarted => 'Registrieren';

  @override
  String get fullName => 'Name';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get agreePersonalData =>
      'Ich stimme der Verarbeitung meiner persönlichen Daten zu';

  @override
  String get alreadyHaveAccount => 'Du hast bereits ein Konto?';

  @override
  String get fieldRequired => 'Dieses Feld wird benötigt';

  @override
  String get back => 'Zurück';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get registrationSuccess => 'Registrierung erfolgreich!';

  @override
  String get registrationFailed => 'Registrierung fehlgeschlagen';

  @override
  String get emailOrUsername => 'E-Mail oder Benutzername';

  @override
  String get rememberMe => 'Angemeldet bleiben';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get noAccount => 'Du hast noch kein Konto?';

  @override
  String get loginSuccess => 'Login erfolgreich!';

  @override
  String get loginFailed => 'Login fehlgeschlagen';

  @override
  String get invalidCredentials => 'Ungültige Zugangsdaten';

  @override
  String get emailOrUserExists => 'E-Mail oder Benutzername bereits vergeben';

  @override
  String get invalidInput => 'Ungültige Eingabe';

  @override
  String get connectServer => 'Mit Server verbinden';

  @override
  String get serverConnectionHint =>
      'Server-Adresse eingeben (IP, Domain oder URL)';

  @override
  String get connect => 'Verbinden';

  @override
  String get connectionFailed => 'Verbindung zum Server fehlgeschlagen';

  @override
  String get invalidUrl => 'Ungültige URL';
}
