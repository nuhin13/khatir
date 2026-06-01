// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_app_name => 'Khatir';

  @override
  String get common_toggle_language => 'বাংলা';

  @override
  String get placeholder_welcome => 'Welcome to Khatir';

  @override
  String get onboarding_slide1_kicker => 'Welcome';

  @override
  String get onboarding_slide1_title => 'The landlord\'s digital ledger';

  @override
  String get onboarding_slide1_accent => 'All in one place';

  @override
  String get onboarding_slide1_body =>
      'No more paperwork hassle. Tenant records, rent, expenses — all in one place.';

  @override
  String get onboarding_slide2_kicker => 'The wedge';

  @override
  String get onboarding_slide2_title => 'Police form, in 2 minutes';

  @override
  String get onboarding_slide2_accent => 'No more thana runs';

  @override
  String get onboarding_slide2_body =>
      'Stop running to the thana. Snap the NID, the form fills itself.';

  @override
  String get onboarding_slide3_kicker => 'Free hook';

  @override
  String get onboarding_slide3_title => 'First 2 tenants free';

  @override
  String get onboarding_slide3_accent => 'Zero cost to start';

  @override
  String get onboarding_slide3_body =>
      'Use the whole system at zero cost — every feature except NID verification.';

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_next => 'Next';

  @override
  String get onboarding_start => 'Get started';
}
