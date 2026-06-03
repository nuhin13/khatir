// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get common_app_name => 'খাতির';

  @override
  String get common_toggle_language => 'English';

  @override
  String get common_logout => 'লগ আউট';

  @override
  String get nav_home => 'হোম';

  @override
  String get nav_charts => 'চার্ট';

  @override
  String get nav_add => 'যোগ';

  @override
  String get nav_rent => 'ভাড়া';

  @override
  String get nav_more => 'আরও';

  @override
  String get nav_maintenance => 'রক্ষণাবেক্ষণ';

  @override
  String get nav_receipts => 'রসিদ';

  @override
  String shell_placeholder_coming_soon(String tab) {
    return '$tab — শীঘ্রই আসছে';
  }

  @override
  String get splash_loading => 'লোড হচ্ছে…';

  @override
  String get home_placeholder_welcome => 'আপনি সাইন ইন করেছেন';

  @override
  String get placeholder_welcome => 'খাতিরে স্বাগতম';

  @override
  String get onboarding_slide1_kicker => 'স্বাগতম';

  @override
  String get onboarding_slide1_title => 'বাড়িওয়ালার ডিজিটাল খাতা';

  @override
  String get onboarding_slide1_accent => 'The landlord\'s digital ledger';

  @override
  String get onboarding_slide1_body =>
      'কাগজের ঝামেলা শেষ। ভাড়াটিয়ার তথ্য, ভাড়ার হিসাব, খরচ — সব এক জায়গায়।';

  @override
  String get onboarding_slide2_kicker => 'প্রধান সুবিধা';

  @override
  String get onboarding_slide2_title => 'পুলিশ ফর্ম, ২ মিনিটে!';

  @override
  String get onboarding_slide2_accent => 'Police form, in 2 minutes';

  @override
  String get onboarding_slide2_body =>
      'থানায় দৌড়ানো বন্ধ। NID-এর ছবি তুলুন, ফর্ম নিজে থেকেই পূরণ হবে।';

  @override
  String get onboarding_slide3_kicker => 'একদম ফ্রি!';

  @override
  String get onboarding_slide3_title => 'প্রথম ২ ভাড়াটিয়া ফ্রি';

  @override
  String get onboarding_slide3_accent => 'First 2 tenants free';

  @override
  String get onboarding_slide3_body =>
      'কোনো খরচ ছাড়াই পুরো ব্যবস্থা ব্যবহার করুন। NID যাচাই ছাড়া সব ফিচার।';

  @override
  String get onboarding_skip => 'এড়িয়ে যান';

  @override
  String get onboarding_next => 'পরবর্তী';

  @override
  String get onboarding_start => 'শুরু করি!';

  @override
  String get auth_phone_hero => 'স্বাগতম, বাড়িওয়ালা';

  @override
  String get auth_phone_title => 'মোবাইল নম্বর দিয়ে শুরু করুন';

  @override
  String get auth_phone_label => 'মোবাইল নম্বর · Mobile number';

  @override
  String get auth_phone_hint => '01XXXXXXXXX';

  @override
  String get auth_phone_invalid => 'সঠিক ১১-সংখ্যার নম্বর দিন (01XXXXXXXXX)';

  @override
  String get auth_phone_submit => 'OTP পাঠান · Send code';

  @override
  String get auth_phone_whatsapp => 'WhatsApp-এ কোড পাবেন · Code via WhatsApp';

  @override
  String get auth_rate_limited =>
      'অনেকবার চেষ্টা হয়েছে। একটু পরে আবার চেষ্টা করুন।';

  @override
  String get common_network_error => 'সংযোগে সমস্যা। আবার চেষ্টা করুন।';

  @override
  String get common_retry => 'আবার চেষ্টা করুন';

  @override
  String get auth_otp_appbar => 'কোড যাচাই';

  @override
  String get auth_otp_title => 'কোড লিখুন · Enter code';

  @override
  String auth_otp_sent_to(String phone) {
    return '$phone নম্বরে পাঠানো কোড লিখুন';
  }

  @override
  String get auth_otp_verify => 'যাচাই করুন · Verify';

  @override
  String get auth_otp_no_code => 'কোড আসেনি?';

  @override
  String get auth_otp_resend => 'আবার পাঠান';

  @override
  String auth_otp_resend_in(String time) {
    return 'আবার পাঠান ($time)';
  }

  @override
  String get auth_otp_invalid => 'ভুল কোড। আবার চেষ্টা করুন।';

  @override
  String get auth_otp_expired => 'কোডের মেয়াদ শেষ। নতুন কোড নিন।';

  @override
  String get role_hero => 'Tell us who you are';

  @override
  String get role_title => 'আপনি কে?';

  @override
  String get role_subtitle =>
      'যথাযথ ফিচার পেতে ভূমিকা নির্বাচন করুন · Pick your role';

  @override
  String get role_most_common => '⭐ সাধারণত এটিই · Most common';

  @override
  String get role_change_later =>
      'পরে More মেনু থেকে পরিবর্তন করা যাবে · Change later in More';

  @override
  String get role_landlord_bn => 'বাড়িওয়ালা';

  @override
  String get role_landlord_en => 'Landlord';

  @override
  String get role_landlord_desc =>
      'নিজের বিল্ডিং ও ভাড়াটিয়া পরিচালনা · Manage my own buildings';

  @override
  String get role_landlord_perk1 => 'DMP ফর্ম';

  @override
  String get role_landlord_perk2 => 'ভাড়া আদায়';

  @override
  String get role_landlord_perk3 => 'খরচের হিসাব';

  @override
  String get role_manager_bn => 'ভবন ম্যানেজার';

  @override
  String get role_manager_en => 'Building Manager';

  @override
  String get role_manager_desc =>
      'একাধিক মালিকের সম্পত্তি · Manage multiple owners';

  @override
  String get role_manager_perk1 => 'মাল্টি-ওনার';

  @override
  String get role_manager_perk2 => 'টিম এক্সেস';

  @override
  String get role_manager_perk3 => 'একীভূত রিপোর্ট';

  @override
  String get role_tenant_bn => 'ভাড়াটিয়া';

  @override
  String get role_tenant_en => 'Tenant';

  @override
  String get role_tenant_desc => 'একটি ফ্ল্যাটে ভাড়া থাকি · I rent a flat';

  @override
  String get role_tenant_perk1 => 'ভাড়া পরিশোধ';

  @override
  String get role_tenant_perk2 => 'রসিদ';

  @override
  String get role_tenant_perk3 => 'মেরামত';

  @override
  String get more_title => 'আরও · More';

  @override
  String get more_profile => 'প্রোফাইল';

  @override
  String get more_profile_en => 'Profile';

  @override
  String get more_plan => 'প্ল্যান ও বিলিং';

  @override
  String get more_plan_en => 'Plan & billing';

  @override
  String get more_lease => 'AI লিজ তৈরি';

  @override
  String get more_lease_en => 'AI lease';

  @override
  String get more_warnings => 'সতর্কতা ও অভিযোগ';

  @override
  String get more_warnings_en => 'Warnings';

  @override
  String get more_language => 'ভাষা · বাংলা/EN';

  @override
  String get more_language_en => 'Language';

  @override
  String get more_switch_role => 'ভূমিকা পরিবর্তন';

  @override
  String get more_switch_role_en => 'Switch role';

  @override
  String get more_about => 'Khatir সম্পর্কে';

  @override
  String get more_about_en => 'About Khatir';

  @override
  String get more_logout => 'লগআউট · Log out';

  @override
  String get more_name_fallback => 'ব্যবহারকারী';

  @override
  String get more_plan_chip => 'Free 1/2';

  @override
  String get home_greeting => 'আসসালামু আলাইকুম,';

  @override
  String get home_name_fallback => 'বাড়িওয়ালা';

  @override
  String home_summary_line(String buildings, String units) {
    return '$buildings বিল্ডিং · $units ইউনিট';
  }

  @override
  String get home_dmp_cta_badge => '⭐ সুপারিশ · FLAGSHIP';

  @override
  String get home_dmp_cta => 'পুলিশ ফর্ম, মাত্র ২ মিনিটে!';

  @override
  String get home_dmp_cta_sub =>
      'Police form in 2 minutes — NID-এর ছবি তুলুন, বাকিটা আমরা করব ✨';

  @override
  String get home_dmp_cta_action => 'শুরু করি · Start';

  @override
  String get home_stat_buildings => 'বিল্ডিং · Bldg';

  @override
  String get home_stat_units => 'ইউনিট · Units';

  @override
  String get home_stat_monthly => 'মাসিক · /mo';

  @override
  String get home_collected => 'এ মাসে আদায় · Collected this month';

  @override
  String get home_collected_todo =>
      'বিস্তারিত আদায় ও চার্ট শীঘ্রই · Collection detail coming soon';

  @override
  String get home_add_building => 'বিল্ডিং যোগ করুন · Add building';

  @override
  String get home_empty_title => 'আপনার প্রথম বিল্ডিং যোগ করুন';

  @override
  String get home_empty_body =>
      'এখনো কোনো বিল্ডিং নেই। শুরু করতে একটি বিল্ডিং যোগ করুন।';

  @override
  String home_currency_amount(String amount) {
    return '৳$amount';
  }

  @override
  String get portfolio_title => 'পোর্টফোলিও · Portfolio';

  @override
  String get portfolio_stat_buildings => 'বিল্ডিং · Buildings';

  @override
  String get portfolio_stat_occupied => 'ভাড়া হয়েছে · Occupied';

  @override
  String portfolio_occupancy(String occupied, String total) {
    return '$occupied/$total';
  }

  @override
  String get portfolio_units => 'ইউনিট';

  @override
  String get portfolio_occupied => 'ভাড়া হয়েছে';

  @override
  String get portfolio_monthly => 'মাসিক';

  @override
  String get portfolio_add_building => 'নতুন বিল্ডিং · Add building';

  @override
  String get portfolio_empty =>
      'এখনো কোনো বিল্ডিং নেই। শুরু করতে একটি বিল্ডিং যোগ করুন।';

  @override
  String get portfolio_empty_title => 'আপনার প্রথম বিল্ডিং যোগ করুন';

  @override
  String get area_uttara => 'উত্তরা';

  @override
  String get area_mirpur => 'মিরপুর';

  @override
  String get area_mohammadpur => 'মোহাম্মদপুর';

  @override
  String get area_dhanmondi => 'ধানমন্ডি';

  @override
  String get area_banasree => 'বনশ্রী';

  @override
  String get area_gulshan => 'গুলশান';

  @override
  String get area_banani => 'বনানী';

  @override
  String get area_bashundhara => 'বসুন্ধরা';

  @override
  String get area_old_dhaka => 'পুরান ঢাকা';

  @override
  String get area_other => 'অন্যান্য';

  @override
  String unit_title(String label) {
    return 'ইউনিট $label';
  }

  @override
  String get unit_rent => 'ভাড়া';

  @override
  String unit_rent_per_month(String amount) {
    return '৳$amount';
  }

  @override
  String get unit_per_month_suffix => '/মাস';

  @override
  String get unit_status => 'অবস্থা';

  @override
  String get unit_type => 'ধরন';

  @override
  String get unit_amenities => 'সুবিধা';

  @override
  String get unit_amenities_none => 'কোনো সুবিধা যোগ করা হয়নি';

  @override
  String get unit_add_tenant => 'ভাড়াটিয়া যোগ করুন';

  @override
  String get unit_no_tenant => 'এখনো কোনো ভাড়াটিয়া নেই';

  @override
  String get unit_no_tenant_body => 'এই ইউনিটে একজন ভাড়াটিয়া যোগ করুন।';

  @override
  String get unit_tenant_section => 'ভাড়াটিয়া ও লিজ';

  @override
  String get unit_edit => 'সম্পাদনা';

  @override
  String get unit_edit_rent_label => 'মাসিক ভাড়া (৳)';

  @override
  String get unit_save => 'সংরক্ষণ';

  @override
  String get unit_status_occupied => 'ভাড়া হয়েছে';

  @override
  String get unit_status_vacant => 'খালি';

  @override
  String get unit_status_maintenance => 'রক্ষণাবেক্ষণ';

  @override
  String get unit_type_apartment => 'অ্যাপার্টমেন্ট';

  @override
  String get unit_type_room => 'রুম';

  @override
  String get unit_type_commercial => 'বাণিজ্যিক';

  @override
  String get unit_type_garage => 'গ্যারেজ';

  @override
  String get unit_type_other => 'অন্যান্য';
}
