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
  String get common_logout => 'Log out';

  @override
  String get splash_loading => 'Loading…';

  @override
  String get home_placeholder_welcome => 'You\'re signed in';

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

  @override
  String get auth_phone_hero => 'Hello!';

  @override
  String get auth_phone_title => 'Welcome — sign in with your mobile number';

  @override
  String get auth_phone_label => 'Mobile number · মোবাইল নম্বর';

  @override
  String get auth_phone_hint => '01XXXXXXXXX';

  @override
  String get auth_phone_invalid =>
      'Enter a valid 11-digit number (01XXXXXXXXX)';

  @override
  String get auth_phone_submit => 'Send code · OTP পাঠান';

  @override
  String get auth_phone_whatsapp => 'Code via WhatsApp · WhatsApp-এ কোড পাবেন';

  @override
  String get auth_rate_limited => 'Too many attempts. Please try again later.';

  @override
  String get common_network_error => 'Connection problem. Please try again.';

  @override
  String get common_retry => 'Try again';

  @override
  String get auth_otp_appbar => 'Verify code · কোড যাচাই';

  @override
  String get auth_otp_title => 'Enter code · কোড লিখুন';

  @override
  String auth_otp_sent_to(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get auth_otp_verify => 'Verify · যাচাই করুন';

  @override
  String get auth_otp_no_code => 'Didn\'t get the code?';

  @override
  String get auth_otp_resend => 'Resend';

  @override
  String auth_otp_resend_in(String time) {
    return 'Resend ($time)';
  }

  @override
  String get auth_otp_invalid => 'Wrong code. Please try again.';

  @override
  String get auth_otp_expired => 'Code expired. Request a new one.';
}
