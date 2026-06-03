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
  String get nav_home => 'Home';

  @override
  String get nav_charts => 'Charts';

  @override
  String get nav_add => 'Add';

  @override
  String get nav_rent => 'Rent';

  @override
  String get nav_more => 'More';

  @override
  String get nav_maintenance => 'Maintenance';

  @override
  String get nav_receipts => 'Receipts';

  @override
  String shell_placeholder_coming_soon(String tab) {
    return '$tab — coming soon';
  }

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

  @override
  String get role_hero => 'Tell us who you are';

  @override
  String get role_title => 'Who are you?';

  @override
  String get role_subtitle => 'Pick your role to get the right features';

  @override
  String get role_most_common => '⭐ Most common';

  @override
  String get role_change_later => 'Change later in More';

  @override
  String get role_landlord_bn => 'Landlord';

  @override
  String get role_landlord_en => 'Landlord';

  @override
  String get role_landlord_desc => 'Manage my own buildings & tenants';

  @override
  String get role_landlord_perk1 => 'DMP form';

  @override
  String get role_landlord_perk2 => 'Rent collection';

  @override
  String get role_landlord_perk3 => 'Expense tracking';

  @override
  String get role_manager_bn => 'Building Manager';

  @override
  String get role_manager_en => 'Building Manager';

  @override
  String get role_manager_desc => "Manage multiple owners' properties";

  @override
  String get role_manager_perk1 => 'Multi-owner';

  @override
  String get role_manager_perk2 => 'Team access';

  @override
  String get role_manager_perk3 => 'Unified reports';

  @override
  String get role_tenant_bn => 'Tenant';

  @override
  String get role_tenant_en => 'Tenant';

  @override
  String get role_tenant_desc => 'I rent a flat';

  @override
  String get role_tenant_perk1 => 'Pay rent';

  @override
  String get role_tenant_perk2 => 'Receipts';

  @override
  String get role_tenant_perk3 => 'Repairs';

  @override
  String get more_title => 'More';

  @override
  String get more_profile => 'Profile';

  @override
  String get more_profile_en => 'Profile';

  @override
  String get more_plan => 'Plan & billing';

  @override
  String get more_plan_en => 'Plan & billing';

  @override
  String get more_lease => 'AI lease';

  @override
  String get more_lease_en => 'AI lease';

  @override
  String get more_warnings => 'Warnings & complaints';

  @override
  String get more_warnings_en => 'Warnings';

  @override
  String get more_language => 'Language · বাংলা/EN';

  @override
  String get more_language_en => 'Language';

  @override
  String get more_switch_role => 'Switch role';

  @override
  String get more_switch_role_en => 'Switch role';

  @override
  String get more_about => 'About Khatir';

  @override
  String get more_about_en => 'About Khatir';

  @override
  String get more_logout => 'Log out';

  @override
  String get more_name_fallback => 'User';

  @override
  String get more_plan_chip => 'Free 1/2';

  @override
  String get home_greeting => 'Assalamu alaikum,';

  @override
  String get home_name_fallback => 'Landlord';

  @override
  String home_summary_line(String buildings, String units) {
    return '$buildings buildings · $units units';
  }

  @override
  String get home_dmp_cta_badge => '⭐ Recommended · FLAGSHIP';

  @override
  String get home_dmp_cta => 'Police form, in just 2 minutes!';

  @override
  String get home_dmp_cta_sub =>
      'Police form in 2 minutes — snap the NID, we do the rest ✨';

  @override
  String get home_dmp_cta_action => 'Start · শুরু করি';

  @override
  String get home_stat_buildings => 'Bldg · বিল্ডিং';

  @override
  String get home_stat_units => 'Units · ইউনিট';

  @override
  String get home_stat_monthly => '/mo · মাসিক';

  @override
  String get home_collected => 'Collected this month · এ মাসে আদায়';

  @override
  String get home_collected_todo => 'Collection detail & charts coming soon';

  @override
  String get home_add_building => 'Add building · বিল্ডিং যোগ করুন';

  @override
  String get home_empty_title => 'Add your first building';

  @override
  String get home_empty_body => 'No buildings yet. Add a building to get started.';

  @override
  String home_currency_amount(String amount) {
    return '৳$amount';
  }

  @override
  String get portfolio_title => 'পোর্টফোলিও · Portfolio';

  @override
  String get portfolio_stat_buildings => 'Buildings · বিল্ডিং';

  @override
  String get portfolio_stat_occupied => 'Occupied · ভাড়া হয়েছে';

  @override
  String portfolio_occupancy(String occupied, String total) {
    return '$occupied/$total';
  }

  @override
  String get portfolio_units => 'Units';

  @override
  String get portfolio_occupied => 'Occupied';

  @override
  String get portfolio_monthly => 'Monthly';

  @override
  String get portfolio_add_building => 'নতুন বিল্ডিং · Add building';

  @override
  String get portfolio_empty =>
      'এখনো কোনো বিল্ডিং নেই। শুরু করতে একটি বিল্ডিং যোগ করুন।';

  @override
  String get portfolio_empty_title => 'আপনার প্রথম বিল্ডিং যোগ করুন';

  @override
  String get area_uttara => 'Uttara';

  @override
  String get area_mirpur => 'Mirpur';

  @override
  String get area_mohammadpur => 'Mohammadpur';

  @override
  String get area_dhanmondi => 'Dhanmondi';

  @override
  String get area_banasree => 'Banasree';

  @override
  String get area_gulshan => 'Gulshan';

  @override
  String get area_banani => 'Banani';

  @override
  String get area_bashundhara => 'Bashundhara';

  @override
  String get area_old_dhaka => 'Old Dhaka';

  @override
  String get area_other => 'Other';
}
