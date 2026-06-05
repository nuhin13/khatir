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
  String home_collected_pending(String amount) {
    return 'Pending · বাকি $amount';
  }

  @override
  String get home_view_dashboard => 'View charts · চার্ট দেখুন';

  @override
  String home_late_payers(String count) {
    return '$count rent overdue · $count টি ভাড়া বাকি';
  }

  @override
  String get home_late_payers_one => 'Rent overdue · ভাড়া বাকি';

  @override
  String get home_all_paid =>
      'All rent collected — nicely done · সব ভাড়া আদায় হয়েছে';

  @override
  String get home_quick_request => 'Ask · চান';

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
  String get unit_maintenance => 'মেরামত · Maintenance';

  @override
  String get unit_expenses => 'খরচ · Expenses';

  @override
  String get unit_view_all => 'সব দেখুন · View all';

  @override
  String unit_maint_open_count(String count) {
    return '$count টি খোলা · open';
  }

  @override
  String get unit_maint_empty => 'কোনো অনুরোধ নেই · No requests';

  @override
  String get unit_maint_status_open => 'খোলা · Open';

  @override
  String unit_expenses_total(String amount) {
    return '৳$amount';
  }

  @override
  String unit_expenses_count(String count) {
    return '$count টি খরচ · expenses';
  }

  @override
  String get unit_expenses_empty => 'কোনো খরচ নেই · No expenses';

  @override
  String get unit_section_error => 'লোড করা যায়নি · Could not load';

  @override
  String get unit_lease_active => 'চলমান লিজ';

  @override
  String unit_lease_term(Object end, Object start) {
    return '$start – $end';
  }

  @override
  String get unit_lease_no_dates => 'মেয়াদ নির্ধারিত নয়';

  @override
  String get unit_next_due => 'পরবর্তী কিস্তি';

  @override
  String unit_next_due_value(Object amount, Object period) {
    return '$period · ৳$amount';
  }

  @override
  String get unit_next_due_none => 'কোনো বকেয়া কিস্তি নেই';

  @override
  String get unit_create_lease => 'লিজ তৈরি করুন';

  @override
  String get unit_lease_verified => 'NID যাচাইকৃত';

  @override
  String get unit_lease_unverified => 'যাচাই হয়নি';

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

  @override
  String get add_tenant_title => 'ভাড়াটিয়া যোগ · Add tenant';

  @override
  String get add_tenant_hero_title => 'Let\'s add a tenant';

  @override
  String get add_tenant_hero_sub =>
      'কীভাবে শুরু করবেন? · How would you like to start?';

  @override
  String get add_tenant_ocr => 'NID-এর ছবি তুলুন · Snap the NID';

  @override
  String get add_tenant_ocr_sub => 'Snap the NID — AI fills everything';

  @override
  String get add_tenant_voice => 'ভয়েস দিয়ে বলুন · Say it with voice';

  @override
  String get add_tenant_voice_sub => 'Just say it in Bangla';

  @override
  String get add_tenant_manual => 'হাতে লিখুন · Fill it in yourself';

  @override
  String get add_tenant_manual_sub => 'Type the details yourself';

  @override
  String get add_tenant_tip =>
      'Tip: the NID photo method is fastest — done in 2 minutes';

  @override
  String get ocr_capture_title => 'NID স্ক্যান · OCR';

  @override
  String get ocr_capture_heading => 'Snap your NID';

  @override
  String get ocr_frame_hint =>
      'NID কার্ড ফ্রেমে রাখুন · Place the NID in the frame';

  @override
  String get ocr_privacy_note =>
      'ভালো আলোতে ধরুন। ছবি কোথাও পাঠানো হবে না · Hold it in good light. The photo never leaves your phone.';

  @override
  String get ocr_take_photo => 'ছবি তুলুন · Take photo';

  @override
  String get ocr_from_gallery => 'গ্যালারি থেকে · From gallery';

  @override
  String get ocr_processing => 'AI পড়ছে… · Reading the NID…';

  @override
  String get ocr_error => 'ছবি পড়া যায়নি · Couldn\'t read the photo';

  @override
  String get ocr_retry => 'আবার চেষ্টা · Try again';

  @override
  String get ocr_review_title => 'যাচাই করুন · Review';

  @override
  String get ocr_review_banner =>
      'AI বুঝে নিয়েছে — যাচাই করুন · AI extracted, please confirm';

  @override
  String get ocr_low_confidence =>
      'এটি ভালোভাবে পড়া যায়নি — যাচাই করুন · Read with low confidence — please check';

  @override
  String get tenant_name => 'নাম · Name';

  @override
  String get tenant_nid => 'NID নম্বর · NID number';

  @override
  String get tenant_dob => 'জন্ম তারিখ · Date of birth';

  @override
  String get tenant_address => 'ঠিকানা · Address';

  @override
  String get ocr_err_name => 'নাম দিন · Name is required';

  @override
  String get ocr_err_nid => 'NID নম্বর দিন · NID number is required';

  @override
  String get ocr_family_section => 'পরিবার সদস্য · Family members';

  @override
  String get ocr_family_add => '+ সদস্য যোগ · Add member';

  @override
  String get ocr_family_name => 'নাম · Name';

  @override
  String get ocr_family_relation => 'সম্পর্ক · Relation';

  @override
  String get ocr_family_remove => 'সরান · Remove';

  @override
  String get family_add => '+ সদস্য যোগ · Add member';

  @override
  String get family_name => 'নাম · Name';

  @override
  String get family_relation => 'সম্পর্ক · Relation';

  @override
  String get family_remove => 'সরান · Remove';

  @override
  String get ocr_confirm => 'পরবর্তী — ফর্ম তৈরি · Build form 🚀';

  @override
  String get voice_title => 'ভয়েস ফর্ম · Voice';

  @override
  String get voice_heading => 'Talk to me!';

  @override
  String get voice_tap_to_record => 'মাইক চাপুন · Tap the mic';

  @override
  String get voice_recording => 'শুনছি… ছেড়ে দিন · Listening… release to stop';

  @override
  String get voice_processing => 'AI বুঝছে… · Understanding…';

  @override
  String get voice_error =>
      'শোনা যায়নি — আবার চেষ্টা করুন · Couldn\'t catch that — please try again';

  @override
  String get voice_example_label => 'উদাহরণ · Example';

  @override
  String get voice_example =>
      '\"নতুন ভাড়াটিয়া, নাম রহিম উদ্দিন, ফ্ল্যাট ৪বি, ভাড়া ছাব্বিশ হাজার, মার্চ থেকে…\"';

  @override
  String get voice_unavailable =>
      'ভয়েস ফর্ম এখন বন্ধ আছে · Voice entry is currently unavailable.';

  @override
  String get manual_title => 'হাতে DMP ফর্ম · Manual form';

  @override
  String get manual_intro =>
      'সরকারি ভাড়াটিয়া তথ্য ফরমের সব ঘর হাতে পূরণ করুন · Fill every official field by hand.';

  @override
  String get manual_section_landlord => '১. বাড়িওয়ালা · Landlord';

  @override
  String get manual_section_tenant => '২. ভাড়াটিয়া · Tenant';

  @override
  String get manual_section_unit => '৩. বর্তমান বাসা · Current unit';

  @override
  String get manual_section_family => '৪. পরিবার ও কর্মচারী · Family & staff';

  @override
  String get manual_full_name => 'পূর্ণ নাম · Full name';

  @override
  String get manual_occupation => 'পেশা · Occupation';

  @override
  String get manual_permanent_address => 'স্থায়ী ঠিকানা · Permanent address';

  @override
  String get manual_building => 'বিল্ডিং · Building';

  @override
  String get manual_unit => 'ইউনিট · Unit';

  @override
  String get manual_rent => 'ভাড়া · Rent';

  @override
  String get manual_move_in => 'ওঠার তারিখ · Move-in';

  @override
  String get tenant_mobile => 'মোবাইল · Mobile';

  @override
  String get manual_proceed => 'ফর্ম তৈরি ও PDF দেখুন · Generate PDF 🚀';

  @override
  String get tenant_save_error =>
      'Couldn\'t save the tenant. Please try again.';

  @override
  String tenant_free_tier_status(int used, int limit) {
    return 'Free plan: $used/$limit tenants used';
  }

  @override
  String get dmp_placeholder_title => 'DMP form';

  @override
  String get dmp_placeholder_heading => 'Tenant saved!';

  @override
  String get dmp_placeholder_body =>
      'The DMP (police) form will be generated here soon.';

  @override
  String get dmp_title => 'DMP form · ডিএমপি ফর্ম';

  @override
  String get dmp_ready => 'Ready';

  @override
  String get dmp_hero_title => 'All done!';

  @override
  String get dmp_hero_sub => 'Your form is ready to generate';

  @override
  String get dmp_org => 'Dhaka Metropolitan Police';

  @override
  String get dmp_org_sub => 'DMP · CIMS · TENANT INFORMATION';

  @override
  String get dmp_org_badge => 'Tenant information form';

  @override
  String get dmp_field_tenant => 'Tenant · ভাড়াটিয়া';

  @override
  String get dmp_field_nid => 'NID';

  @override
  String get dmp_field_landlord => 'Landlord · বাড়িওয়ালা';

  @override
  String get dmp_field_address => 'Address · ঠিকানা';

  @override
  String get dmp_field_present => 'Present address';

  @override
  String get dmp_field_permanent => 'Permanent address';

  @override
  String get dmp_field_dob => 'Date of birth';

  @override
  String get dmp_field_phone => 'Phone · মোবাইল';

  @override
  String get dmp_field_family => 'Family · পরিবার';

  @override
  String get dmp_generate => 'Generate PDF · PDF তৈরি করুন';

  @override
  String get dmp_edit => 'Edit · সম্পাদনা';

  @override
  String get dmp_error => 'Could not load the form. Please try again.';

  @override
  String get dmp_retry => 'Retry';

  @override
  String get dmp_pdf_title => 'DMP PDF · ডিএমপি পিডিএফ';

  @override
  String get dmp_generating => 'Generating your form…';

  @override
  String get dmp_pdf_download => 'Download · নামান';

  @override
  String get dmp_pdf_share => 'Share · শেয়ার';

  @override
  String get dmp_pdf_whatsapp => 'Share on WhatsApp · WhatsApp-এ পাঠান';

  @override
  String get dmp_pdf_error => 'Could not generate the PDF. Please try again.';

  @override
  String get dmp_pdf_action_failed =>
      'Could not complete that. Please try again.';

  @override
  String get lease_new_title => 'নতুন ভাড়া চুক্তি · New lease';

  @override
  String get lease_edit_title => 'চুক্তি সম্পাদনা · Edit lease';

  @override
  String get lease_section_tenant => 'ভাড়াটে · Tenant';

  @override
  String get lease_section_terms => 'শর্তাবলি · Terms';

  @override
  String get lease_tenant => 'ভাড়াটে · Tenant';

  @override
  String get lease_tenant_hint => 'একজন ভাড়াটে বাছাই করুন · Select a tenant';

  @override
  String get lease_tenant_empty =>
      'এই ইউনিটে কোনো ভাড়াটে যোগ করা হয়নি · Add a tenant to this unit first.';

  @override
  String get lease_rent => 'মাসিক ভাড়া · Monthly rent';

  @override
  String get lease_advance => 'অগ্রিম · Advance';

  @override
  String get lease_start => 'শুরুর তারিখ · Start date';

  @override
  String get lease_end => 'শেষের তারিখ · End date';

  @override
  String get lease_due_day => 'পরিশোধের দিন · Due day';

  @override
  String lease_due_day_value(int day) {
    return 'প্রতি মাসের $day তারিখ · $day of each month';
  }

  @override
  String get lease_due_day_note =>
      'ভাড়ার সময়সূচি তৈরিতে এই দিনটি ব্যবহৃত হয় · Used to generate the rent schedule.';

  @override
  String get lease_save => 'খসড়া সংরক্ষণ · Save draft';

  @override
  String get lease_activate => 'সংরক্ষণ ও সক্রিয় · Save & activate';

  @override
  String get lease_err_tenant =>
      'চুক্তি তৈরি করতে একজন ভাড়াটে বাছাই করুন · Select a tenant to create the lease';

  @override
  String get lease_err_rent =>
      'একটি বৈধ ভাড়ার পরিমাণ দিন · Enter a valid rent amount';

  @override
  String get lease_err_dates =>
      'শেষের তারিখ শুরুর তারিখের পরে হতে হবে · End date must be after the start date';

  @override
  String get lease_saved =>
      'চুক্তি খসড়া হিসেবে সংরক্ষিত · Lease saved as a draft';

  @override
  String get lease_activated =>
      'চুক্তি সক্রিয় — সময়সূচি তৈরি হয়েছে · Lease activated — schedule generated';

  @override
  String get lease_save_error =>
      'চুক্তি সংরক্ষণ করা যায়নি · Could not save the lease. Please try again.';

  @override
  String get lease_active_exists =>
      'এই ইউনিটে ইতিমধ্যে একটি সক্রিয় চুক্তি আছে · This unit already has an active lease.';

  @override
  String get leases_title => 'ভাড়া চুক্তি · Leases';

  @override
  String get leases_empty_title => 'এখনো কোনো চুক্তি নেই · No leases yet';

  @override
  String get leases_empty =>
      'একটি ইউনিট থেকে ভাড়া চুক্তি তৈরি করুন · Create a lease from a unit to see it here.';

  @override
  String get lease_detail_title => 'চুক্তির বিবরণ · Lease detail';

  @override
  String get lease_status_draft => 'খসড়া · Draft';

  @override
  String get lease_status_active => 'সক্রিয় · Active';

  @override
  String get lease_status_ended => 'সমাপ্ত · Ended';

  @override
  String get lease_status_terminated => 'বাতিল · Terminated';

  @override
  String get lease_section_schedule => 'ভাড়ার সময়সূচি · Rent schedule';

  @override
  String get lease_schedule_empty =>
      'কোনো সময়সূচি নেই — চুক্তি সক্রিয় করুন · No schedule yet — activate the lease.';

  @override
  String lease_schedule_summary(String count) {
    return '$count টি কিস্তি · $count periods';
  }

  @override
  String lease_term_range(String start, String end) {
    return '$start – $end';
  }

  @override
  String get lease_rent_amount => 'মাসিক ভাড়া · Monthly rent';

  @override
  String get lease_sched_status_pending => 'বাকি · Pending';

  @override
  String get lease_sched_status_requested => 'অনুরোধ করা হয়েছে · Requested';

  @override
  String get lease_sched_status_paid => 'পরিশোধিত · Paid';

  @override
  String get lease_sched_status_overdue => 'মেয়াদোত্তীর্ণ · Overdue';

  @override
  String get lease_terminate => 'চুক্তি বাতিল করুন · Terminate lease';

  @override
  String get lease_terminate_confirm_title =>
      'চুক্তি বাতিল করবেন? · Terminate this lease?';

  @override
  String get lease_terminate_confirm_body =>
      'চুক্তিটি বন্ধ হয়ে যাবে এবং আর সক্রিয় থাকবে না · The lease will be closed and no longer active.';

  @override
  String get lease_terminate_cancel => 'বাতিল · Cancel';

  @override
  String get lease_terminated_ok => 'চুক্তি বাতিল হয়েছে · Lease terminated';

  @override
  String get lease_terminate_error =>
      'চুক্তি বাতিল করা যায়নি · Could not terminate the lease. Please try again.';

  @override
  String get rent_request_title => 'ভাড়ার অনুরোধ · Rent';

  @override
  String get rent_request_heading => 'ভাড়া চান · Ask for rent';

  @override
  String get rent_request_subtitle =>
      'অ্যাপ না থাকলেও সমস্যা নেই — WhatsApp-এ লিংক পাবেন · No app needed — they get a WhatsApp link';

  @override
  String get rent_request_amount => 'ভাড়ার পরিমাণ · Rent amount';

  @override
  String get rent_request_period => 'সময়কাল · Period';

  @override
  String get rent_request_period_hint => 'YYYY-MM (e.g. 2026-06)';

  @override
  String get rent_send_whatsapp => 'WhatsApp লিংক পাঠান · Send WhatsApp link';

  @override
  String get rent_mark_received => 'টাকা পেয়েছি (নগদ) · Mark received (cash)';

  @override
  String get rent_request_err_amount =>
      'সঠিক পরিমাণ লিখুন · Enter a valid amount';

  @override
  String get rent_request_err_period =>
      'YYYY-MM ফরম্যাটে সময়কাল লিখুন · Enter the period as YYYY-MM';

  @override
  String get rent_request_sent => 'লিংক পাঠানো হয়েছে · Link sent';

  @override
  String get rent_request_received =>
      'টাকা পেয়েছি বলে রেকর্ড হয়েছে · Marked as received';

  @override
  String get rent_request_error =>
      'অনুরোধ পাঠানো যায়নি · Couldn\'t send the request. Please try again.';

  @override
  String get verify_title => 'পেমেন্ট যাচাই · Verify';

  @override
  String verify_claim(String name) {
    return '$name বলছেন ভাড়া দিয়েছেন · $name says they paid';
  }

  @override
  String verify_amount_period(String amount, String period) {
    return '৳$amount · $period';
  }

  @override
  String get verify_proof => 'জমা প্রমাণ · Submitted proof';

  @override
  String get verify_proof_none =>
      'এখনো কোনো প্রমাণ জমা পড়েনি · No proof submitted yet';

  @override
  String get verify_proof_image_failed =>
      'ছবি লোড করা যায়নি · Couldn\'t load the image';

  @override
  String get verify_proof_txn => 'Txn ID';

  @override
  String get verify_proof_amount => 'Amount';

  @override
  String get verify_confirm => 'টাকা পেয়েছি · Received';

  @override
  String get verify_reject => 'এখনো পাইনি · Not yet received';

  @override
  String get verify_reason => 'কারণ লিখুন · Reason for rejecting';

  @override
  String get verify_reason_hint =>
      'কেন গ্রহণ করছেন না? · Why are you rejecting this?';

  @override
  String get verify_reason_required =>
      'একটি কারণ লিখুন · Please enter a reason';

  @override
  String get verify_reason_cancel => 'বাতিল · Cancel';

  @override
  String get verify_reason_submit => 'প্রত্যাখ্যান · Reject';

  @override
  String get verify_verified => 'যাচাই সম্পন্ন · Verified';

  @override
  String get verify_rejected =>
      'অনুরোধ প্রত্যাখ্যান করা হয়েছে · Request rejected';

  @override
  String get verify_error =>
      'কাজটি সম্পন্ন হয়নি · Couldn\'t complete that. Please try again.';

  @override
  String get verify_load_error =>
      'অনুরোধ লোড করা যায়নি · Couldn\'t load the request';

  @override
  String get verify_retry => 'আবার চেষ্টা · Retry';

  @override
  String get receipt_title => 'রসিদ · Receipt';

  @override
  String get receipt_ready => 'রসিদ তৈরি হয়েছে · Receipt ready';

  @override
  String get receipt_ready_sub =>
      'ভাড়াটিয়াকে পাঠিয়ে দিন · Share it with your tenant';

  @override
  String get receipt_heading => 'ভাড়ার রসিদ · Rent Receipt';

  @override
  String receipt_amount(String amount) {
    return '৳$amount';
  }

  @override
  String get receipt_tenant => 'ভাড়াটিয়া · Tenant';

  @override
  String get receipt_unit => 'ইউনিট · Unit';

  @override
  String get receipt_period => 'সময়কাল · Period';

  @override
  String get receipt_method => 'পদ্ধতি · Method';

  @override
  String get receipt_status => 'স্ট্যাটাস · Status';

  @override
  String get receipt_status_paid => '✓ পরিশোধিত · Paid';

  @override
  String get receipt_no => 'রসিদ নং · Receipt no';

  @override
  String get receipt_share => 'ভাড়াটিয়াকে পাঠান · Send to tenant';

  @override
  String get receipt_done => 'PDF · Done';

  @override
  String get receipt_dash => '—';

  @override
  String receipt_share_text(String amount, String period) {
    return 'ভাড়ার রসিদ · Rent Receipt\n৳$amount · $period';
  }

  @override
  String get receipt_action_failed =>
      'কাজটি সম্পন্ন হয়নি · Couldn\'t complete that. Please try again.';

  @override
  String get receipt_load_error =>
      'রসিদ লোড করা যায়নি · Couldn\'t load the receipt';

  @override
  String get receipt_retry => 'আবার চেষ্টা · Retry';

  @override
  String get expenses_title => 'মেরামত ও খরচ · Maintenance';

  @override
  String get expenses_this_month => 'এ মাসে · This month';

  @override
  String get expenses_total => 'মোট খরচ · Total expenses';

  @override
  String expenses_total_amount(String amount) {
    return '৳$amount';
  }

  @override
  String expenses_count(String count) {
    return '$count টি খরচ · expenses';
  }

  @override
  String get expenses_filter_all => 'সব · All';

  @override
  String get expenses_section_recent => 'সাম্প্রতিক খরচ · Recent expenses';

  @override
  String get expenses_source_manual => 'ম্যানুয়াল · Manual';

  @override
  String get expenses_source_request => 'মেরামত · Maintenance';

  @override
  String expenses_amount(String amount) {
    return '৳$amount';
  }

  @override
  String get expenses_add => 'খরচ যোগ · Add expense';

  @override
  String get expenses_export => 'CSV রপ্তানি · Export CSV';

  @override
  String get expenses_export_failed =>
      'রপ্তানি সম্পন্ন হয়নি · Couldn\'t export. Please try again.';

  @override
  String get expenses_empty => 'এখনও কোনো খরচ নেই · No expenses yet';

  @override
  String get expenses_category_plumbing => 'প্লাম্বিং · Plumbing';

  @override
  String get expenses_category_paint => 'পেইন্ট · Paint';

  @override
  String get expenses_category_electrical => 'বিদ্যুৎ · Electrical';

  @override
  String get expenses_category_structural => 'স্ট্রাকচার · Structural';

  @override
  String get expenses_category_appliance => 'অ্যাপ্লায়েন্স · Appliance';

  @override
  String get expenses_category_utility => 'ইউটিলিটি · Utility';

  @override
  String get expenses_category_other => 'অন্যান্য · Other';

  @override
  String get add_expense_title => 'খরচ যোগ · Add expense';

  @override
  String get expense_amount => 'পরিমাণ · Amount';

  @override
  String get expense_amount_hint => '৳ ০';

  @override
  String get expense_category => 'খাত · Category';

  @override
  String get expense_unit => 'ইউনিট · Unit';

  @override
  String get expense_building => 'ভবন · Building';

  @override
  String get expense_unit_hint => 'একটি ইউনিট বাছুন · Choose a unit';

  @override
  String get expense_building_hint => 'একটি ভবন বাছুন · Choose a building';

  @override
  String get expense_date => 'তারিখ · Date';

  @override
  String get expense_note => 'নোট · Note (optional)';

  @override
  String get expense_receipt => 'রসিদ · Receipt (optional)';

  @override
  String get expense_receipt_add => 'রসিদ যোগ করুন · Attach receipt';

  @override
  String get expense_receipt_attached => 'রসিদ যুক্ত হয়েছে · Receipt attached';

  @override
  String get expense_receipt_remove => 'সরান · Remove';

  @override
  String get expense_save => 'খরচ সেভ করুন · Save expense';

  @override
  String get expense_err_amount => 'একটি বৈধ পরিমাণ দিন · Enter a valid amount';

  @override
  String get expense_err_unit => 'ইউনিট বাছাই করুন · Please choose a unit';

  @override
  String get expense_saved => 'খরচ সেভ হয়েছে · Expense saved';

  @override
  String get expense_save_failed =>
      'সেভ হয়নি · Couldn\'t save. Please try again.';

  @override
  String get maintenance_title => 'মেরামতের অনুরোধ · Maintenance';

  @override
  String get maintenance_section_open => 'নতুন অনুরোধ · New requests';

  @override
  String maintenance_open_count(String count) {
    return '$count টি অপেক্ষায় · open';
  }

  @override
  String maintenance_unit(String unit) {
    return 'ইউনিট $unit';
  }

  @override
  String get maintenance_resolve => 'সমাধান + খরচ · Resolve';

  @override
  String get maintenance_resolved_badge => 'সমাধান হয়েছে · Resolved';

  @override
  String get maintenance_cost => 'খরচ · Cost';

  @override
  String get maintenance_cost_hint => '৳ ০';

  @override
  String get maintenance_resolution_note => 'নোট · Note (optional)';

  @override
  String get maintenance_resolve_title => 'সমাধান + খরচ · Resolve with cost';

  @override
  String get maintenance_resolve_hint =>
      'এই খরচ একটি খরচ এন্ট্রি তৈরি করবে · This records an expense on the unit.';

  @override
  String get maintenance_resolve_confirm => 'সমাধান করুন · Resolve';

  @override
  String get maintenance_resolve_cancel => 'বাতিল · Cancel';

  @override
  String get maintenance_err_cost => 'একটি বৈধ খরচ দিন · Enter a valid cost';

  @override
  String get maintenance_resolved => 'অনুরোধ সমাধান হয়েছে · Request resolved';

  @override
  String get maintenance_resolve_failed =>
      'সমাধান হয়নি · Couldn\'t resolve. Please try again.';

  @override
  String get maintenance_empty => 'কোনো খোলা অনুরোধ নেই · No open requests';

  @override
  String get maintenance_category_plumbing => 'পানি · Plumbing';

  @override
  String get maintenance_category_electrical => 'বিদ্যুৎ · Electrical';

  @override
  String get maintenance_category_paint => 'পেইন্ট · Paint';

  @override
  String get maintenance_category_structural => 'স্ট্রাকচার · Structural';

  @override
  String get maintenance_category_appliance => 'অ্যাপ্লায়েন্স · Appliance';

  @override
  String get maintenance_category_utility => 'ইউটিলিটি · Utility';

  @override
  String get maintenance_category_other => 'অন্যান্য · Other';

  @override
  String get dashboard_title => 'ড্যাশবোর্ড · Dashboard';

  @override
  String get dashboard_income => 'এ মাসের মোট আয় · Income this month';

  @override
  String dashboard_amount(String value) {
    return '৳$value';
  }

  @override
  String get dashboard_collection => 'আদায় হার · Collection rate (6 mo)';

  @override
  String get dashboard_occupancy => 'অকুপেন্সি · Occupancy';

  @override
  String dashboard_occupancy_units(String occupied, String total) {
    return '$occupied/$total';
  }

  @override
  String get dashboard_occupied => 'ভাড়া হয়েছে · Occupied';

  @override
  String get dashboard_vacant => 'খালি · Vacant';

  @override
  String get dashboard_income_expense => 'আয় ও খরচ · Income vs expense';

  @override
  String get dashboard_income_legend => 'আয় · Income';

  @override
  String get dashboard_expense_legend => 'খরচ · Expense';

  @override
  String get dashboard_income_series => 'আয় · Income';

  @override
  String get dashboard_expense_series => 'খরচ · Expense';

  @override
  String get dashboard_expenses => 'প্রধান খরচ · Top expenses 💸';

  @override
  String get dashboard_late => 'দেরিতে ভাড়া · Late payers';

  @override
  String get dashboard_late_none => 'কেউ দেরিতে নেই · No late payers';

  @override
  String dashboard_late_count(String count) {
    return '$count জন দেরিতে · $count late payer(s)';
  }

  @override
  String get dashboard_late_request =>
      'ভাড়ার অনুরোধ পাঠান · Send rent request';

  @override
  String get dashboard_chart_empty => 'কোনো তথ্য নেই · No data yet';

  @override
  String get dashboard_empty =>
      'এখনো কোনো তথ্য নেই · Nothing to show yet — add tenants & log rent to see your charts.';

  @override
  String get plan_title => 'Plan & billing';

  @override
  String get plan_current => 'Now';

  @override
  String plan_current_banner(String tier) {
    return 'You\'re on $tier';
  }

  @override
  String plan_usage(String used, String limit) {
    return '$used/$limit tenants used';
  }

  @override
  String plan_usage_unlimited(String used) {
    return '$used tenants · unlimited';
  }

  @override
  String get plan_free => 'Free';

  @override
  String get plan_upgrade => 'Upgrade with bKash / Nagad';

  @override
  String get plan_choose => 'Choose this plan';

  @override
  String get plan_best_value => '⭐ BEST VALUE';

  @override
  String get plan_per_month => '/mo';

  @override
  String get plan_per_tenant_month => '/tenant/mo';

  @override
  String plan_band(String min, String max) {
    return '$min–$max tenants';
  }

  @override
  String plan_band_min(String min) {
    return '$min+ tenants';
  }

  @override
  String get plan_band_unlimited => 'Unlimited tenants';

  @override
  String get plan_includes_verification => '+ NID verify';

  @override
  String get plan_billing_note => 'Prices admin-configurable · illustrative';

  @override
  String get plan_billing_confirm_pending =>
      'We\'ll confirm once payment clears';

  @override
  String get plan_billing_error => 'Couldn\'t upgrade · please try again';

  @override
  String get plan_empty => 'No plans available';

  @override
  String get upgrade_title => 'You\'ve reached your free limit';

  @override
  String get upgrade_body =>
      'Free plans cover your first 2 tenants. Upgrade to add more and unlock NID verification.';

  @override
  String get upgrade_cta => 'Upgrade plan';

  @override
  String get upgrade_later => 'Not now';
}
