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
}
