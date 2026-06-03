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
  String get common_logout => 'Log out';

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
  String get role_manager_desc => 'Manage multiple owners\' properties';

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
  String get map_picker_tap_hint => 'Tap to drop pin';

  @override
  String get map_picker_attribution => '© OpenStreetMap contributors';

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
  String get home_empty_body =>
      'No buildings yet. Add a building to get started.';

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

  @override
  String unit_title(String label) {
    return 'ইউনিট · Unit $label';
  }

  @override
  String get unit_rent => 'ভাড়া · Rent';

  @override
  String unit_rent_per_month(String amount) {
    return '৳$amount';
  }

  @override
  String get unit_per_month_suffix => '/মাস · /mo';

  @override
  String get unit_status => 'অবস্থা · Status';

  @override
  String get unit_type => 'ধরন · Type';

  @override
  String get unit_amenities => 'সুবিধা · Amenities';

  @override
  String get unit_amenities_none => 'কোনো সুবিধা যোগ করা হয়নি · None yet';

  @override
  String get unit_add_tenant => 'ভাড়াটিয়া যোগ করুন · Add tenant';

  @override
  String get unit_no_tenant => 'এখনো কোনো ভাড়াটিয়া নেই · No tenant yet';

  @override
  String get unit_no_tenant_body => 'এই ইউনিটে একজন ভাড়াটিয়া যোগ করুন।';

  @override
  String get unit_tenant_section => 'ভাড়াটিয়া ও লিজ · Tenant & lease';

  @override
  String get unit_edit => 'সম্পাদনা · Edit';

  @override
  String get unit_edit_rent_label => 'মাসিক ভাড়া · Monthly rent (৳)';

  @override
  String get unit_save => 'সংরক্ষণ · Save';

  @override
  String get unit_status_occupied => 'ভাড়া হয়েছে · Occupied';

  @override
  String get unit_status_vacant => 'খালি · Vacant';

  @override
  String get unit_status_maintenance => 'রক্ষণাবেক্ষণ · Maintenance';

  @override
  String get unit_type_apartment => 'অ্যাপার্টমেন্ট · Apartment';

  @override
  String get unit_type_room => 'রুম · Room';

  @override
  String get unit_type_commercial => 'বাণিজ্যিক · Commercial';

  @override
  String get unit_type_garage => 'গ্যারেজ · Garage';

  @override
  String get unit_type_other => 'অন্যান্য · Other';

  @override
  String wizard_step_x_of_4(String step) {
    return 'ধাপ $step/৪ · Step $step of 4';
  }

  @override
  String get wizard_title_name => 'নতুন বিল্ডিং · New building';

  @override
  String get wizard_title_address => 'ঠিকানা · Address';

  @override
  String get wizard_step1_hero_title => 'Name your building';

  @override
  String get wizard_step1_hero_sub => 'বিল্ডিংয়ের নাম দিন';

  @override
  String get wizard_step2_hero_title => 'Where is it?';

  @override
  String get wizard_step2_hero_sub => 'ঠিকানা — ম্যাপ থেকে নিন';

  @override
  String get building_name => 'বিল্ডিংয়ের নাম · Building name';

  @override
  String get building_name_hint => 'যেমন: করিম মঞ্জিল, House 12';

  @override
  String get building_area => 'এলাকা · Area';

  @override
  String get building_address => 'সম্পূর্ণ ঠিকানা · Full address';

  @override
  String get building_address_hint => 'ম্যাপ থেকে নিন অথবা হাতে লিখুন';

  @override
  String get building_address_auto => '(auto)';

  @override
  String get wizard_pick_on_map => 'ম্যাপ থেকে বেছে নিন · Pick on map';

  @override
  String get wizard_map_filled =>
      'ম্যাপ থেকে ঠিকানা নেওয়া হয়েছে · Address filled from map';

  @override
  String get wizard_reset_pin => 'রিসেট · Reset';

  @override
  String get wizard_next => 'পরবর্তী · Next';

  @override
  String get wizard_next_units => 'পরবর্তী — ইউনিট · Units';

  @override
  String get wizard_err_name => 'বিল্ডিংয়ের নাম দিন · Enter a building name';

  @override
  String get wizard_err_area => 'একটি এলাকা বেছে নিন · Pick an area';

  @override
  String get wizard_err_address => 'ঠিকানা দিন · Enter an address';

  @override
  String get wizard_title_units => 'ফ্ল্যাট/ইউনিট · Units';

  @override
  String get wizard_title_review => 'সংক্ষিপ্ত · Review';

  @override
  String get wizard_step3_hero_title => 'How many flats?';

  @override
  String get wizard_step3_hero_sub => 'কয়টি ফ্ল্যাট, কোন ফ্লোরে';

  @override
  String get wizard_step4_hero_title => 'Looks good?';

  @override
  String get wizard_step4_hero_sub => 'সব ঠিক আছে?';

  @override
  String get wizard_floors => 'মোট ফ্লোর · Floors';

  @override
  String get wizard_floors_sub => 'কয়টি তলা';

  @override
  String get wizard_per_floor => 'প্রতি ফ্লোরে ফ্ল্যাট · Flats / floor';

  @override
  String get wizard_per_floor_sub => 'প্রতি তলায় কয়টি';

  @override
  String get wizard_scheme => 'নম্বরিং ধরন · Numbering scheme';

  @override
  String get wizard_scheme_letter => 'ফ্লোর + অক্ষর';

  @override
  String get wizard_scheme_number => 'ফ্লোর × ১০০';

  @override
  String wizard_units_count(int count) {
    return 'ইউনিট তালিকা · $count units';
  }

  @override
  String get wizard_units_empty =>
      'ফ্লোর ও ফ্ল্যাট বাড়ান, অথবা কাস্টম যোগ করুন · Add floors/flats or a custom unit';

  @override
  String get wizard_units_footnote =>
      'প্রতিটি ইউনিটে পরে ভাড়া ও ভাড়াটিয়া যোগ করবেন · Add rent & tenant per unit later';

  @override
  String get wizard_add_custom => '+ কাস্টম · Custom';

  @override
  String get wizard_add_custom_title => 'কাস্টম ইউনিট · Custom unit';

  @override
  String get wizard_add_custom_hint => 'যেমন 8B, 2001';

  @override
  String get wizard_cancel => 'বাতিল · Cancel';

  @override
  String get wizard_add => 'যোগ · Add';

  @override
  String get wizard_next_review => 'পরবর্তী — দেখুন · Review';

  @override
  String get wizard_review_building => 'বিল্ডিং · Building';

  @override
  String get wizard_review_area => 'এলাকা · Area';

  @override
  String get wizard_review_address => 'ঠিকানা · Address';

  @override
  String get wizard_review_pin => 'ম্যাপ পিন · Pin';

  @override
  String get wizard_review_pin_saved => 'সংরক্ষিত · Saved';

  @override
  String get wizard_review_units => 'মোট ইউনিট · Units';

  @override
  String wizard_review_units_value(int count, int floors, int perFloor) {
    return '$count টি ($floors ফ্লোর × $perFloor)';
  }

  @override
  String get wizard_save => 'বিল্ডিং সেভ করুন · Save building';

  @override
  String get wizard_saving => 'সেভ হচ্ছে · Saving…';

  @override
  String get wizard_saved => 'বিল্ডিং সেভ হয়েছে · Building saved';
}
