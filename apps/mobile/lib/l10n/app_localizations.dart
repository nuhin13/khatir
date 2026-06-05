import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// App name shown in the title bar / headers.
  ///
  /// In bn, this message translates to:
  /// **'খাতির'**
  String get common_app_name;

  /// Label on the language toggle button. Shows the language it will switch TO.
  ///
  /// In bn, this message translates to:
  /// **'English'**
  String get common_toggle_language;

  /// Bottom-nav label: home tab.
  ///
  /// In bn, this message translates to:
  /// **'হোম'**
  String get nav_home;

  /// Bottom-nav label: charts/dashboard tab.
  ///
  /// In bn, this message translates to:
  /// **'চার্ট'**
  String get nav_charts;

  /// Bottom-nav label: center add action.
  ///
  /// In bn, this message translates to:
  /// **'যোগ'**
  String get nav_add;

  /// Bottom-nav label: rent tab.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া'**
  String get nav_rent;

  /// Bottom-nav label: more/settings tab.
  ///
  /// In bn, this message translates to:
  /// **'আরও'**
  String get nav_more;

  /// Bottom-nav label: tenant maintenance tab.
  ///
  /// In bn, this message translates to:
  /// **'রক্ষণাবেক্ষণ'**
  String get nav_maintenance;

  /// Bottom-nav label: tenant receipts tab.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ'**
  String get nav_receipts;

  /// Placeholder body shown in a role-shell tab until its feature epic fills it in.
  ///
  /// In bn, this message translates to:
  /// **'{tab} — শীঘ্রই আসছে'**
  String shell_placeholder_coming_soon(String tab);

  /// Logout action label.
  ///
  /// In bn, this message translates to:
  /// **'লগ আউট'**
  String get common_logout;

  /// Role chooser handwritten English hero line.
  ///
  /// In bn, this message translates to:
  /// **'Tell us who you are'**
  String get role_hero;

  /// Role chooser Bangla title.
  ///
  /// In bn, this message translates to:
  /// **'আপনি কে?'**
  String get role_title;

  /// Role chooser subtitle prompting the user to pick a role.
  ///
  /// In bn, this message translates to:
  /// **'যথাযথ ফিচার পেতে ভূমিকা নির্বাচন করুন · Pick your role'**
  String get role_subtitle;

  /// Badge on the recommended (landlord) role card.
  ///
  /// In bn, this message translates to:
  /// **'⭐ সাধারণত এটিই · Most common'**
  String get role_most_common;

  /// Footnote: the role can be changed later from the More menu.
  ///
  /// In bn, this message translates to:
  /// **'পরে More মেনু থেকে পরিবর্তন করা যাবে · Change later in More'**
  String get role_change_later;

  /// Landlord role name (Bangla).
  ///
  /// In bn, this message translates to:
  /// **'বাড়িওয়ালা'**
  String get role_landlord_bn;

  /// Landlord role name (English accent line).
  ///
  /// In bn, this message translates to:
  /// **'Landlord'**
  String get role_landlord_en;

  /// Landlord role one-line description.
  ///
  /// In bn, this message translates to:
  /// **'নিজের বিল্ডিং ও ভাড়াটিয়া পরিচালনা · Manage my own buildings'**
  String get role_landlord_desc;

  /// Landlord perk: DMP form.
  ///
  /// In bn, this message translates to:
  /// **'DMP ফর্ম'**
  String get role_landlord_perk1;

  /// Landlord perk: rent collection.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া আদায়'**
  String get role_landlord_perk2;

  /// Landlord perk: expense tracking.
  ///
  /// In bn, this message translates to:
  /// **'খরচের হিসাব'**
  String get role_landlord_perk3;

  /// Building manager role name (Bangla).
  ///
  /// In bn, this message translates to:
  /// **'ভবন ম্যানেজার'**
  String get role_manager_bn;

  /// Building manager role name (English accent line).
  ///
  /// In bn, this message translates to:
  /// **'Building Manager'**
  String get role_manager_en;

  /// Building manager role one-line description.
  ///
  /// In bn, this message translates to:
  /// **'একাধিক মালিকের সম্পত্তি · Manage multiple owners'**
  String get role_manager_desc;

  /// Manager perk: multi-owner.
  ///
  /// In bn, this message translates to:
  /// **'মাল্টি-ওনার'**
  String get role_manager_perk1;

  /// Manager perk: team access.
  ///
  /// In bn, this message translates to:
  /// **'টিম এক্সেস'**
  String get role_manager_perk2;

  /// Manager perk: unified reports.
  ///
  /// In bn, this message translates to:
  /// **'একীভূত রিপোর্ট'**
  String get role_manager_perk3;

  /// Tenant role name (Bangla).
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়া'**
  String get role_tenant_bn;

  /// Tenant role name (English accent line).
  ///
  /// In bn, this message translates to:
  /// **'Tenant'**
  String get role_tenant_en;

  /// Tenant role one-line description.
  ///
  /// In bn, this message translates to:
  /// **'একটি ফ্ল্যাটে ভাড়া থাকি · I rent a flat'**
  String get role_tenant_desc;

  /// Tenant perk: pay rent.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া পরিশোধ'**
  String get role_tenant_perk1;

  /// Tenant perk: receipts.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ'**
  String get role_tenant_perk2;

  /// Tenant perk: repairs.
  ///
  /// In bn, this message translates to:
  /// **'মেরামত'**
  String get role_tenant_perk3;

  /// More menu app-bar title.
  ///
  /// In bn, this message translates to:
  /// **'আরও · More'**
  String get more_title;

  /// More row: profile (Bangla primary).
  ///
  /// In bn, this message translates to:
  /// **'প্রোফাইল'**
  String get more_profile;

  /// More row: profile (English caption).
  ///
  /// In bn, this message translates to:
  /// **'Profile'**
  String get more_profile_en;

  /// More row: plan & billing (Bangla primary).
  ///
  /// In bn, this message translates to:
  /// **'প্ল্যান ও বিলিং'**
  String get more_plan;

  /// More row: plan & billing (English caption).
  ///
  /// In bn, this message translates to:
  /// **'Plan & billing'**
  String get more_plan_en;

  /// More row: AI lease (Bangla primary, landlord/manager only).
  ///
  /// In bn, this message translates to:
  /// **'AI লিজ তৈরি'**
  String get more_lease;

  /// More row: AI lease (English caption).
  ///
  /// In bn, this message translates to:
  /// **'AI lease'**
  String get more_lease_en;

  /// More row: warnings & complaints (Bangla primary, landlord/manager only).
  ///
  /// In bn, this message translates to:
  /// **'সতর্কতা ও অভিযোগ'**
  String get more_warnings;

  /// More row: warnings (English caption).
  ///
  /// In bn, this message translates to:
  /// **'Warnings'**
  String get more_warnings_en;

  /// More row: language toggle (Bangla primary).
  ///
  /// In bn, this message translates to:
  /// **'ভাষা · বাংলা/EN'**
  String get more_language;

  /// More row: language (English caption).
  ///
  /// In bn, this message translates to:
  /// **'Language'**
  String get more_language_en;

  /// More row: switch role (Bangla primary).
  ///
  /// In bn, this message translates to:
  /// **'ভূমিকা পরিবর্তন'**
  String get more_switch_role;

  /// More row: switch role (English caption).
  ///
  /// In bn, this message translates to:
  /// **'Switch role'**
  String get more_switch_role_en;

  /// More row: about Khatir (Bangla primary).
  ///
  /// In bn, this message translates to:
  /// **'Khatir সম্পর্কে'**
  String get more_about;

  /// More row: about Khatir (English caption).
  ///
  /// In bn, this message translates to:
  /// **'About Khatir'**
  String get more_about_en;

  /// More menu logout button label.
  ///
  /// In bn, this message translates to:
  /// **'লগআউট · Log out'**
  String get more_logout;

  /// Fallback name shown in the profile header when the user has no name.
  ///
  /// In bn, this message translates to:
  /// **'ব্যবহারকারী'**
  String get more_name_fallback;

  /// Placeholder plan chip in the profile header (real value lands in EPIC-10).
  ///
  /// In bn, this message translates to:
  /// **'Free 1/2'**
  String get more_plan_chip;

  /// Loading copy shown on the splash while the session bootstraps.
  ///
  /// In bn, this message translates to:
  /// **'লোড হচ্ছে…'**
  String get splash_loading;

  /// Welcome message on the temporary authenticated home placeholder.
  ///
  /// In bn, this message translates to:
  /// **'আপনি সাইন ইন করেছেন'**
  String get home_placeholder_welcome;

  /// Welcome message on the placeholder screen.
  ///
  /// In bn, this message translates to:
  /// **'খাতিরে স্বাগতম'**
  String get placeholder_welcome;

  /// Onboarding slide 1 chip / kicker.
  ///
  /// In bn, this message translates to:
  /// **'স্বাগতম'**
  String get onboarding_slide1_kicker;

  /// Onboarding slide 1 title (Bangla).
  ///
  /// In bn, this message translates to:
  /// **'বাড়িওয়ালার ডিজিটাল খাতা'**
  String get onboarding_slide1_title;

  /// Onboarding slide 1 handwritten English accent line.
  ///
  /// In bn, this message translates to:
  /// **'The landlord\'s digital ledger'**
  String get onboarding_slide1_accent;

  /// Onboarding slide 1 body copy.
  ///
  /// In bn, this message translates to:
  /// **'কাগজের ঝামেলা শেষ। ভাড়াটিয়ার তথ্য, ভাড়ার হিসাব, খরচ — সব এক জায়গায়।'**
  String get onboarding_slide1_body;

  /// Onboarding slide 2 chip / kicker.
  ///
  /// In bn, this message translates to:
  /// **'প্রধান সুবিধা'**
  String get onboarding_slide2_kicker;

  /// Onboarding slide 2 title (Bangla).
  ///
  /// In bn, this message translates to:
  /// **'পুলিশ ফর্ম, ২ মিনিটে!'**
  String get onboarding_slide2_title;

  /// Onboarding slide 2 handwritten English accent line.
  ///
  /// In bn, this message translates to:
  /// **'Police form, in 2 minutes'**
  String get onboarding_slide2_accent;

  /// Onboarding slide 2 body copy.
  ///
  /// In bn, this message translates to:
  /// **'থানায় দৌড়ানো বন্ধ। NID-এর ছবি তুলুন, ফর্ম নিজে থেকেই পূরণ হবে।'**
  String get onboarding_slide2_body;

  /// Onboarding slide 3 chip / kicker.
  ///
  /// In bn, this message translates to:
  /// **'একদম ফ্রি!'**
  String get onboarding_slide3_kicker;

  /// Onboarding slide 3 title (Bangla).
  ///
  /// In bn, this message translates to:
  /// **'প্রথম ২ ভাড়াটিয়া ফ্রি'**
  String get onboarding_slide3_title;

  /// Onboarding slide 3 handwritten English accent line.
  ///
  /// In bn, this message translates to:
  /// **'First 2 tenants free'**
  String get onboarding_slide3_accent;

  /// Onboarding slide 3 body copy.
  ///
  /// In bn, this message translates to:
  /// **'কোনো খরচ ছাড়াই পুরো ব্যবস্থা ব্যবহার করুন। NID যাচাই ছাড়া সব ফিচার।'**
  String get onboarding_slide3_body;

  /// Skip button on the onboarding slides.
  ///
  /// In bn, this message translates to:
  /// **'এড়িয়ে যান'**
  String get onboarding_skip;

  /// Next button on the onboarding slides.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী'**
  String get onboarding_next;

  /// Get-started button on the final onboarding slide.
  ///
  /// In bn, this message translates to:
  /// **'শুরু করি!'**
  String get onboarding_start;

  /// Phone-entry hero greeting (Bangla).
  ///
  /// In bn, this message translates to:
  /// **'স্বাগতম, বাড়িওয়ালা'**
  String get auth_phone_hero;

  /// Phone-entry subtitle / sign-in prompt.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল নম্বর দিয়ে শুরু করুন'**
  String get auth_phone_title;

  /// Label above the phone number field.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল নম্বর · Mobile number'**
  String get auth_phone_label;

  /// Placeholder/hint for the phone number input.
  ///
  /// In bn, this message translates to:
  /// **'01XXXXXXXXX'**
  String get auth_phone_hint;

  /// Inline error when the entered phone number is invalid.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক ১১-সংখ্যার নম্বর দিন (01XXXXXXXXX)'**
  String get auth_phone_invalid;

  /// Submit button: request the OTP.
  ///
  /// In bn, this message translates to:
  /// **'OTP পাঠান · Send code'**
  String get auth_phone_submit;

  /// Helper note that the code arrives via WhatsApp.
  ///
  /// In bn, this message translates to:
  /// **'WhatsApp-এ কোড পাবেন · Code via WhatsApp'**
  String get auth_phone_whatsapp;

  /// Friendly message shown on HTTP 429 (rate limited).
  ///
  /// In bn, this message translates to:
  /// **'অনেকবার চেষ্টা হয়েছে। একটু পরে আবার চেষ্টা করুন।'**
  String get auth_rate_limited;

  /// Generic network/connection error message with retry.
  ///
  /// In bn, this message translates to:
  /// **'সংযোগে সমস্যা। আবার চেষ্টা করুন।'**
  String get common_network_error;

  /// Retry action label.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা করুন'**
  String get common_retry;

  /// OTP screen app-bar title.
  ///
  /// In bn, this message translates to:
  /// **'কোড যাচাই'**
  String get auth_otp_appbar;

  /// OTP screen hero heading.
  ///
  /// In bn, this message translates to:
  /// **'কোড লিখুন · Enter code'**
  String get auth_otp_title;

  /// Subtitle telling the user where the code was sent.
  ///
  /// In bn, this message translates to:
  /// **'{phone} নম্বরে পাঠানো কোড লিখুন'**
  String auth_otp_sent_to(String phone);

  /// Verify button label.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই করুন · Verify'**
  String get auth_otp_verify;

  /// Lead-in before the resend action / countdown.
  ///
  /// In bn, this message translates to:
  /// **'কোড আসেনি?'**
  String get auth_otp_no_code;

  /// Resend action label (when the cooldown has elapsed).
  ///
  /// In bn, this message translates to:
  /// **'আবার পাঠান'**
  String get auth_otp_resend;

  /// Resend label with the remaining cooldown countdown.
  ///
  /// In bn, this message translates to:
  /// **'আবার পাঠান ({time})'**
  String auth_otp_resend_in(String time);

  /// Inline error for a wrong OTP code.
  ///
  /// In bn, this message translates to:
  /// **'ভুল কোড। আবার চেষ্টা করুন।'**
  String get auth_otp_invalid;

  /// Inline error for an expired OTP code.
  ///
  /// In bn, this message translates to:
  /// **'কোডের মেয়াদ শেষ। নতুন কোড নিন।'**
  String get auth_otp_expired;

  /// Overlay prompt on the map-pin picker, shown before a pin has been dropped.
  ///
  /// In bn, this message translates to:
  /// **'ট্যাপ করে পিন দিন'**
  String get map_picker_tap_hint;

  /// Required OpenStreetMap tile attribution shown on the map-pin picker.
  ///
  /// In bn, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get map_picker_attribution;

  /// Landlord home handwritten greeting line above the user's name.
  ///
  /// In bn, this message translates to:
  /// **'আসসালামু আলাইকুম,'**
  String get home_greeting;

  /// Fallback name in the home greeting when the user has no name.
  ///
  /// In bn, this message translates to:
  /// **'বাড়িওয়ালা'**
  String get home_name_fallback;

  /// Portfolio one-liner under the greeting: building + unit counts.
  ///
  /// In bn, this message translates to:
  /// **'{buildings} বিল্ডিং · {units} ইউনিট'**
  String home_summary_line(String buildings, String units);

  /// Badge chip on the DMP hero CTA card.
  ///
  /// In bn, this message translates to:
  /// **'⭐ সুপারিশ · FLAGSHIP'**
  String get home_dmp_cta_badge;

  /// Hero DMP CTA title (Bangla).
  ///
  /// In bn, this message translates to:
  /// **'পুলিশ ফর্ম, মাত্র ২ মিনিটে!'**
  String get home_dmp_cta;

  /// Hero DMP CTA subtitle/explainer.
  ///
  /// In bn, this message translates to:
  /// **'Police form in 2 minutes — NID-এর ছবি তুলুন, বাকিটা আমরা করব ✨'**
  String get home_dmp_cta_sub;

  /// Hero DMP CTA action pill label.
  ///
  /// In bn, this message translates to:
  /// **'শুরু করি · Start'**
  String get home_dmp_cta_action;

  /// Quick-stat tile label: building count.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিং · Bldg'**
  String get home_stat_buildings;

  /// Quick-stat tile label: unit count.
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট · Units'**
  String get home_stat_units;

  /// Quick-stat tile label: monthly rent total.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক · /mo'**
  String get home_stat_monthly;

  /// Collection summary card heading.
  ///
  /// In bn, this message translates to:
  /// **'এ মাসে আদায় · Collected this month'**
  String get home_collected;

  /// Placeholder note in the collection card for the charts region (EPIC-09).
  ///
  /// In bn, this message translates to:
  /// **'বিস্তারিত আদায় ও চার্ট শীঘ্রই · Collection detail coming soon'**
  String get home_collected_todo;

  /// Sub-label under the collected amount showing the still-pending total.
  ///
  /// In bn, this message translates to:
  /// **'বাকি {amount} · Pending'**
  String home_collected_pending(String amount);

  /// Tap hint on the home collection card that opens the dashboard tab.
  ///
  /// In bn, this message translates to:
  /// **'চার্ট দেখুন · View charts'**
  String get home_view_dashboard;

  /// Home late-payers heading with the overdue count.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি ভাড়া বাকি · {count} rent overdue'**
  String home_late_payers(String count);

  /// Per-row label on a single overdue rent request.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া বাকি · Rent overdue'**
  String get home_late_payers_one;

  /// Home empty/all-paid reassurance when nothing is overdue.
  ///
  /// In bn, this message translates to:
  /// **'সব ভাড়া আদায় হয়েছে · All rent collected'**
  String get home_all_paid;

  /// Compact quick-request action on a late-payer row.
  ///
  /// In bn, this message translates to:
  /// **'চান · Ask'**
  String get home_quick_request;

  /// Empty-state primary action: add the first building.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিং যোগ করুন · Add building'**
  String get home_add_building;

  /// Empty-state title shown when the landlord has no buildings yet.
  ///
  /// In bn, this message translates to:
  /// **'আপনার প্রথম বিল্ডিং যোগ করুন'**
  String get home_empty_title;

  /// Empty-state body shown when the landlord has no buildings yet.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো বিল্ডিং নেই। শুরু করতে একটি বিল্ডিং যোগ করুন।'**
  String get home_empty_body;

  /// Taka-prefixed amount used for rent totals on the home screen.
  ///
  /// In bn, this message translates to:
  /// **'৳{amount}'**
  String home_currency_amount(String amount);

  /// Portfolio screen top-bar title.
  ///
  /// In bn, this message translates to:
  /// **'পোর্টফোলিও · Portfolio'**
  String get portfolio_title;

  /// Portfolio summary stat label: number of buildings.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিং · Buildings'**
  String get portfolio_stat_buildings;

  /// Portfolio summary stat label: occupied / total units.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া হয়েছে · Occupied'**
  String get portfolio_stat_occupied;

  /// Occupied-over-total units, e.g. ১১/১৪.
  ///
  /// In bn, this message translates to:
  /// **'{occupied}/{total}'**
  String portfolio_occupancy(String occupied, String total);

  /// Per-building footer caption: total units.
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট'**
  String get portfolio_units;

  /// Per-building footer caption: occupied units.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া হয়েছে'**
  String get portfolio_occupied;

  /// Per-building footer caption: monthly rent total.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক'**
  String get portfolio_monthly;

  /// Portfolio CTA: add a new building.
  ///
  /// In bn, this message translates to:
  /// **'নতুন বিল্ডিং · Add building'**
  String get portfolio_add_building;

  /// Empty-state body shown when the landlord has no buildings.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো বিল্ডিং নেই। শুরু করতে একটি বিল্ডিং যোগ করুন।'**
  String get portfolio_empty;

  /// Empty-state title shown when the landlord has no buildings.
  ///
  /// In bn, this message translates to:
  /// **'আপনার প্রথম বিল্ডিং যোগ করুন'**
  String get portfolio_empty_title;

  /// No description provided for @area_uttara.
  ///
  /// In bn, this message translates to:
  /// **'উত্তরা'**
  String get area_uttara;

  /// No description provided for @area_mirpur.
  ///
  /// In bn, this message translates to:
  /// **'মিরপুর'**
  String get area_mirpur;

  /// No description provided for @area_mohammadpur.
  ///
  /// In bn, this message translates to:
  /// **'মোহাম্মদপুর'**
  String get area_mohammadpur;

  /// No description provided for @area_dhanmondi.
  ///
  /// In bn, this message translates to:
  /// **'ধানমন্ডি'**
  String get area_dhanmondi;

  /// No description provided for @area_banasree.
  ///
  /// In bn, this message translates to:
  /// **'বনশ্রী'**
  String get area_banasree;

  /// No description provided for @area_gulshan.
  ///
  /// In bn, this message translates to:
  /// **'গুলশান'**
  String get area_gulshan;

  /// No description provided for @area_banani.
  ///
  /// In bn, this message translates to:
  /// **'বনানী'**
  String get area_banani;

  /// No description provided for @area_bashundhara.
  ///
  /// In bn, this message translates to:
  /// **'বসুন্ধরা'**
  String get area_bashundhara;

  /// No description provided for @area_old_dhaka.
  ///
  /// In bn, this message translates to:
  /// **'পুরান ঢাকা'**
  String get area_old_dhaka;

  /// No description provided for @area_other.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get area_other;

  /// Unit detail top-bar title (unit label appended).
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট {label}'**
  String unit_title(String label);

  /// No description provided for @unit_rent.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া'**
  String get unit_rent;

  /// Monthly rent amount on the unit hero (currency prefixed).
  ///
  /// In bn, this message translates to:
  /// **'৳{amount}'**
  String unit_rent_per_month(String amount);

  /// No description provided for @unit_per_month_suffix.
  ///
  /// In bn, this message translates to:
  /// **'/মাস'**
  String get unit_per_month_suffix;

  /// No description provided for @unit_status.
  ///
  /// In bn, this message translates to:
  /// **'অবস্থা'**
  String get unit_status;

  /// No description provided for @unit_type.
  ///
  /// In bn, this message translates to:
  /// **'ধরন'**
  String get unit_type;

  /// No description provided for @unit_amenities.
  ///
  /// In bn, this message translates to:
  /// **'সুবিধা'**
  String get unit_amenities;

  /// No description provided for @unit_amenities_none.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সুবিধা যোগ করা হয়নি'**
  String get unit_amenities_none;

  /// No description provided for @unit_add_tenant.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়া যোগ করুন'**
  String get unit_add_tenant;

  /// No description provided for @unit_no_tenant.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো ভাড়াটিয়া নেই'**
  String get unit_no_tenant;

  /// No description provided for @unit_no_tenant_body.
  ///
  /// In bn, this message translates to:
  /// **'এই ইউনিটে একজন ভাড়াটিয়া যোগ করুন।'**
  String get unit_no_tenant_body;

  /// No description provided for @unit_tenant_section.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়া ও লিজ'**
  String get unit_tenant_section;

  /// No description provided for @unit_maintenance.
  ///
  /// In bn, this message translates to:
  /// **'মেরামত'**
  String get unit_maintenance;

  /// No description provided for @unit_expenses.
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get unit_expenses;

  /// No description provided for @unit_view_all.
  ///
  /// In bn, this message translates to:
  /// **'সব দেখুন'**
  String get unit_view_all;

  /// No description provided for @unit_maint_open_count.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি খোলা'**
  String unit_maint_open_count(String count);

  /// No description provided for @unit_maint_empty.
  ///
  /// In bn, this message translates to:
  /// **'কোনো অনুরোধ নেই'**
  String get unit_maint_empty;

  /// No description provided for @unit_maint_status_open.
  ///
  /// In bn, this message translates to:
  /// **'খোলা'**
  String get unit_maint_status_open;

  /// No description provided for @unit_expenses_total.
  ///
  /// In bn, this message translates to:
  /// **'৳{amount}'**
  String unit_expenses_total(String amount);

  /// No description provided for @unit_expenses_count.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি খরচ'**
  String unit_expenses_count(String count);

  /// No description provided for @unit_expenses_empty.
  ///
  /// In bn, this message translates to:
  /// **'কোনো খরচ নেই'**
  String get unit_expenses_empty;

  /// No description provided for @unit_section_error.
  ///
  /// In bn, this message translates to:
  /// **'লোড করা যায়নি'**
  String get unit_section_error;

  /// No description provided for @unit_lease_active.
  ///
  /// In bn, this message translates to:
  /// **'চলমান লিজ'**
  String get unit_lease_active;

  /// No description provided for @unit_lease_term.
  ///
  /// In bn, this message translates to:
  /// **'{start} – {end}'**
  String unit_lease_term(Object end, Object start);

  /// No description provided for @unit_lease_no_dates.
  ///
  /// In bn, this message translates to:
  /// **'মেয়াদ নির্ধারিত নয়'**
  String get unit_lease_no_dates;

  /// No description provided for @unit_next_due.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী কিস্তি'**
  String get unit_next_due;

  /// No description provided for @unit_next_due_value.
  ///
  /// In bn, this message translates to:
  /// **'{period} · ৳{amount}'**
  String unit_next_due_value(Object amount, Object period);

  /// No description provided for @unit_next_due_none.
  ///
  /// In bn, this message translates to:
  /// **'কোনো বকেয়া কিস্তি নেই'**
  String get unit_next_due_none;

  /// No description provided for @unit_create_lease.
  ///
  /// In bn, this message translates to:
  /// **'লিজ তৈরি করুন'**
  String get unit_create_lease;

  /// No description provided for @unit_lease_verified.
  ///
  /// In bn, this message translates to:
  /// **'NID যাচাইকৃত'**
  String get unit_lease_verified;

  /// No description provided for @unit_lease_unverified.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই হয়নি'**
  String get unit_lease_unverified;

  /// No description provided for @unit_edit.
  ///
  /// In bn, this message translates to:
  /// **'সম্পাদনা'**
  String get unit_edit;

  /// No description provided for @unit_edit_rent_label.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক ভাড়া (৳)'**
  String get unit_edit_rent_label;

  /// No description provided for @unit_save.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ'**
  String get unit_save;

  /// No description provided for @unit_status_occupied.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া হয়েছে'**
  String get unit_status_occupied;

  /// No description provided for @unit_status_vacant.
  ///
  /// In bn, this message translates to:
  /// **'খালি'**
  String get unit_status_vacant;

  /// No description provided for @unit_status_maintenance.
  ///
  /// In bn, this message translates to:
  /// **'রক্ষণাবেক্ষণ'**
  String get unit_status_maintenance;

  /// No description provided for @unit_type_apartment.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপার্টমেন্ট'**
  String get unit_type_apartment;

  /// No description provided for @unit_type_room.
  ///
  /// In bn, this message translates to:
  /// **'রুম'**
  String get unit_type_room;

  /// No description provided for @unit_type_commercial.
  ///
  /// In bn, this message translates to:
  /// **'বাণিজ্যিক'**
  String get unit_type_commercial;

  /// No description provided for @unit_type_garage.
  ///
  /// In bn, this message translates to:
  /// **'গ্যারেজ'**
  String get unit_type_garage;

  /// No description provided for @unit_type_other.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get unit_type_other;

  /// Add-building wizard progress caption (step N of 4).
  ///
  /// In bn, this message translates to:
  /// **'ধাপ {step}/৪'**
  String wizard_step_x_of_4(String step);

  /// No description provided for @wizard_title_name.
  ///
  /// In bn, this message translates to:
  /// **'নতুন বিল্ডিং'**
  String get wizard_title_name;

  /// No description provided for @wizard_title_address.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get wizard_title_address;

  /// No description provided for @wizard_step1_hero_title.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিংয়ের নাম দিন'**
  String get wizard_step1_hero_title;

  /// No description provided for @wizard_step1_hero_sub.
  ///
  /// In bn, this message translates to:
  /// **'নতুন বিল্ডিং যোগ করুন'**
  String get wizard_step1_hero_sub;

  /// No description provided for @wizard_step2_hero_title.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা কোথায়?'**
  String get wizard_step2_hero_title;

  /// No description provided for @wizard_step2_hero_sub.
  ///
  /// In bn, this message translates to:
  /// **'ম্যাপ থেকে ঠিকানা নিন'**
  String get wizard_step2_hero_sub;

  /// No description provided for @building_name.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিংয়ের নাম'**
  String get building_name;

  /// No description provided for @building_name_hint.
  ///
  /// In bn, this message translates to:
  /// **'যেমন: করিম মঞ্জিল'**
  String get building_name_hint;

  /// No description provided for @building_area.
  ///
  /// In bn, this message translates to:
  /// **'এলাকা'**
  String get building_area;

  /// No description provided for @building_address.
  ///
  /// In bn, this message translates to:
  /// **'সম্পূর্ণ ঠিকানা'**
  String get building_address;

  /// No description provided for @building_address_hint.
  ///
  /// In bn, this message translates to:
  /// **'ম্যাপ থেকে নিন অথবা হাতে লিখুন'**
  String get building_address_hint;

  /// No description provided for @building_address_auto.
  ///
  /// In bn, this message translates to:
  /// **'(স্বয়ংক্রিয়)'**
  String get building_address_auto;

  /// No description provided for @wizard_pick_on_map.
  ///
  /// In bn, this message translates to:
  /// **'ম্যাপ থেকে বেছে নিন'**
  String get wizard_pick_on_map;

  /// No description provided for @wizard_map_filled.
  ///
  /// In bn, this message translates to:
  /// **'ম্যাপ থেকে ঠিকানা নেওয়া হয়েছে'**
  String get wizard_map_filled;

  /// No description provided for @wizard_reset_pin.
  ///
  /// In bn, this message translates to:
  /// **'রিসেট'**
  String get wizard_reset_pin;

  /// No description provided for @wizard_next.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী'**
  String get wizard_next;

  /// No description provided for @wizard_next_units.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী — ইউনিট'**
  String get wizard_next_units;

  /// No description provided for @wizard_err_name.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিংয়ের নাম দিন'**
  String get wizard_err_name;

  /// No description provided for @wizard_err_area.
  ///
  /// In bn, this message translates to:
  /// **'একটি এলাকা বেছে নিন'**
  String get wizard_err_area;

  /// No description provided for @wizard_err_address.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা দিন'**
  String get wizard_err_address;

  /// No description provided for @wizard_title_units.
  ///
  /// In bn, this message translates to:
  /// **'ফ্ল্যাট/ইউনিট'**
  String get wizard_title_units;

  /// No description provided for @wizard_title_review.
  ///
  /// In bn, this message translates to:
  /// **'সংক্ষিপ্ত'**
  String get wizard_title_review;

  /// No description provided for @wizard_step3_hero_title.
  ///
  /// In bn, this message translates to:
  /// **'কয়টি ফ্ল্যাট?'**
  String get wizard_step3_hero_title;

  /// No description provided for @wizard_step3_hero_sub.
  ///
  /// In bn, this message translates to:
  /// **'কয়টি ফ্ল্যাট, কোন ফ্লোরে'**
  String get wizard_step3_hero_sub;

  /// No description provided for @wizard_step4_hero_title.
  ///
  /// In bn, this message translates to:
  /// **'সব ঠিক?'**
  String get wizard_step4_hero_title;

  /// No description provided for @wizard_step4_hero_sub.
  ///
  /// In bn, this message translates to:
  /// **'সব ঠিক আছে?'**
  String get wizard_step4_hero_sub;

  /// No description provided for @wizard_floors.
  ///
  /// In bn, this message translates to:
  /// **'মোট ফ্লোর'**
  String get wizard_floors;

  /// No description provided for @wizard_floors_sub.
  ///
  /// In bn, this message translates to:
  /// **'কয়টি তলা'**
  String get wizard_floors_sub;

  /// No description provided for @wizard_per_floor.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি ফ্লোরে ফ্ল্যাট'**
  String get wizard_per_floor;

  /// No description provided for @wizard_per_floor_sub.
  ///
  /// In bn, this message translates to:
  /// **'প্রতি তলায় কয়টি'**
  String get wizard_per_floor_sub;

  /// No description provided for @wizard_scheme.
  ///
  /// In bn, this message translates to:
  /// **'নম্বরিং ধরন'**
  String get wizard_scheme;

  /// No description provided for @wizard_scheme_letter.
  ///
  /// In bn, this message translates to:
  /// **'ফ্লোর + অক্ষর'**
  String get wizard_scheme_letter;

  /// No description provided for @wizard_scheme_number.
  ///
  /// In bn, this message translates to:
  /// **'ফ্লোর × ১০০'**
  String get wizard_scheme_number;

  /// Header for the generated unit list with a count.
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট তালিকা · {count} টি'**
  String wizard_units_count(int count);

  /// No description provided for @wizard_units_empty.
  ///
  /// In bn, this message translates to:
  /// **'ফ্লোর ও ফ্ল্যাট বাড়ান, অথবা কাস্টম যোগ করুন'**
  String get wizard_units_empty;

  /// No description provided for @wizard_units_footnote.
  ///
  /// In bn, this message translates to:
  /// **'প্রতিটি ইউনিটে পরে ভাড়া ও ভাড়াটিয়া যোগ করবেন'**
  String get wizard_units_footnote;

  /// No description provided for @wizard_add_custom.
  ///
  /// In bn, this message translates to:
  /// **'+ কাস্টম'**
  String get wizard_add_custom;

  /// No description provided for @wizard_add_custom_title.
  ///
  /// In bn, this message translates to:
  /// **'কাস্টম ইউনিট'**
  String get wizard_add_custom_title;

  /// No description provided for @wizard_add_custom_hint.
  ///
  /// In bn, this message translates to:
  /// **'যেমন 8B, 2001'**
  String get wizard_add_custom_hint;

  /// No description provided for @wizard_cancel.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get wizard_cancel;

  /// No description provided for @wizard_add.
  ///
  /// In bn, this message translates to:
  /// **'যোগ'**
  String get wizard_add;

  /// No description provided for @wizard_next_review.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী — দেখুন'**
  String get wizard_next_review;

  /// No description provided for @wizard_review_building.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিং'**
  String get wizard_review_building;

  /// No description provided for @wizard_review_area.
  ///
  /// In bn, this message translates to:
  /// **'এলাকা'**
  String get wizard_review_area;

  /// No description provided for @wizard_review_address.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get wizard_review_address;

  /// No description provided for @wizard_review_pin.
  ///
  /// In bn, this message translates to:
  /// **'ম্যাপ পিন'**
  String get wizard_review_pin;

  /// No description provided for @wizard_review_pin_saved.
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষিত'**
  String get wizard_review_pin_saved;

  /// No description provided for @wizard_review_units.
  ///
  /// In bn, this message translates to:
  /// **'মোট ইউনিট'**
  String get wizard_review_units;

  /// Review row value summarising the unit count and grid.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি ({floors} ফ্লোর × {perFloor})'**
  String wizard_review_units_value(int count, int floors, int perFloor);

  /// No description provided for @wizard_save.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিং সেভ করুন'**
  String get wizard_save;

  /// No description provided for @wizard_saving.
  ///
  /// In bn, this message translates to:
  /// **'সেভ হচ্ছে…'**
  String get wizard_saving;

  /// No description provided for @wizard_saved.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিং সেভ হয়েছে'**
  String get wizard_saved;

  /// Add-tenant method chooser top-bar title (bilingual).
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়া যোগ · Add tenant'**
  String get add_tenant_title;

  /// Add-tenant chooser hero headline.
  ///
  /// In bn, this message translates to:
  /// **'চলুন একজন ভাড়াটিয়া যোগ করি'**
  String get add_tenant_hero_title;

  /// Add-tenant chooser hero sub-prompt (handwritten accent).
  ///
  /// In bn, this message translates to:
  /// **'কীভাবে শুরু করবেন?'**
  String get add_tenant_hero_sub;

  /// OCR method card title.
  ///
  /// In bn, this message translates to:
  /// **'NID-এর ছবি তুলুন'**
  String get add_tenant_ocr;

  /// OCR method card subtitle.
  ///
  /// In bn, this message translates to:
  /// **'ছবি তুলুন — AI সব পূরণ করবে'**
  String get add_tenant_ocr_sub;

  /// Voice method card title.
  ///
  /// In bn, this message translates to:
  /// **'ভয়েস দিয়ে বলুন'**
  String get add_tenant_voice;

  /// Voice method card subtitle.
  ///
  /// In bn, this message translates to:
  /// **'বাংলায় বলুন'**
  String get add_tenant_voice_sub;

  /// Manual method card title.
  ///
  /// In bn, this message translates to:
  /// **'হাতে লিখুন'**
  String get add_tenant_manual;

  /// Manual method card subtitle.
  ///
  /// In bn, this message translates to:
  /// **'নিজে পূরণ করুন'**
  String get add_tenant_manual_sub;

  /// Tip card under the method list.
  ///
  /// In bn, this message translates to:
  /// **'টিপ: NID ছবি পদ্ধতি সবচেয়ে দ্রুত — ২ মিনিটে শেষ'**
  String get add_tenant_tip;

  /// Top-bar title for the NID OCR capture screen.
  ///
  /// In bn, this message translates to:
  /// **'NID স্ক্যান'**
  String get ocr_capture_title;

  /// Handwritten-style heading above the camera frame.
  ///
  /// In bn, this message translates to:
  /// **'NID-এর ছবি তুলুন'**
  String get ocr_capture_heading;

  /// Hint inside the camera viewfinder frame.
  ///
  /// In bn, this message translates to:
  /// **'NID কার্ড ফ্রেমে রাখুন'**
  String get ocr_frame_hint;

  /// Privacy reassurance card under the camera frame.
  ///
  /// In bn, this message translates to:
  /// **'ভালো আলোতে ধরুন। ছবি কোথাও পাঠানো হবে না।'**
  String get ocr_privacy_note;

  /// Camera capture button.
  ///
  /// In bn, this message translates to:
  /// **'ছবি তুলুন'**
  String get ocr_take_photo;

  /// Gallery fallback button.
  ///
  /// In bn, this message translates to:
  /// **'গ্যালারি থেকে'**
  String get ocr_from_gallery;

  /// Loading label shown while the upload + OCR runs.
  ///
  /// In bn, this message translates to:
  /// **'AI পড়ছে…'**
  String get ocr_processing;

  /// Error heading shown when OCR fails.
  ///
  /// In bn, this message translates to:
  /// **'ছবি পড়া যায়নি'**
  String get ocr_error;

  /// Retry button shown on the OCR error state.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা'**
  String get ocr_retry;

  /// Top-bar title for the OCR review/edit screen.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই করুন'**
  String get ocr_review_title;

  /// Banner reminding the landlord to verify the extracted fields.
  ///
  /// In bn, this message translates to:
  /// **'AI বুঝে নিয়েছে — যাচাই করুন'**
  String get ocr_review_banner;

  /// Hint shown under a field the OCR extracted with low confidence.
  ///
  /// In bn, this message translates to:
  /// **'এটি ভালোভাবে পড়া যায়নি — যাচাই করুন'**
  String get ocr_low_confidence;

  /// Label for the tenant name field.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get tenant_name;

  /// Label for the tenant NID number field.
  ///
  /// In bn, this message translates to:
  /// **'NID নম্বর'**
  String get tenant_nid;

  /// Label for the tenant date-of-birth field.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get tenant_dob;

  /// Label for the tenant address field.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা'**
  String get tenant_address;

  /// Validation error when the name field is empty.
  ///
  /// In bn, this message translates to:
  /// **'নাম দিন'**
  String get ocr_err_name;

  /// Validation error when the NID field is empty.
  ///
  /// In bn, this message translates to:
  /// **'NID নম্বর দিন'**
  String get ocr_err_nid;

  /// Section heading for the family-members sub-form.
  ///
  /// In bn, this message translates to:
  /// **'পরিবার সদস্য'**
  String get ocr_family_section;

  /// Button to add a family-member row.
  ///
  /// In bn, this message translates to:
  /// **'+ সদস্য যোগ'**
  String get ocr_family_add;

  /// Label for a family-member name field.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get ocr_family_name;

  /// Label for a family-member relation field.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get ocr_family_relation;

  /// Tooltip/label to remove a family-member row.
  ///
  /// In bn, this message translates to:
  /// **'সরান'**
  String get ocr_family_remove;

  /// Shared family sub-form: add a family-member row.
  ///
  /// In bn, this message translates to:
  /// **'+ সদস্য যোগ'**
  String get family_add;

  /// Shared family sub-form: label for a family-member name field.
  ///
  /// In bn, this message translates to:
  /// **'নাম'**
  String get family_name;

  /// Shared family sub-form: label for a family-member relation field.
  ///
  /// In bn, this message translates to:
  /// **'সম্পর্ক'**
  String get family_relation;

  /// Shared family sub-form: tooltip to remove a family-member row.
  ///
  /// In bn, this message translates to:
  /// **'সরান'**
  String get family_remove;

  /// Proceed button that saves the reviewed tenant and continues to the DMP form.
  ///
  /// In bn, this message translates to:
  /// **'পরবর্তী — ফর্ম তৈরি 🚀'**
  String get ocr_confirm;

  /// App-bar title for the voice tenant-entry screen.
  ///
  /// In bn, this message translates to:
  /// **'ভয়েস ফর্ম'**
  String get voice_title;

  /// Handwritten hero greeting above the mic on the voice screen.
  ///
  /// In bn, this message translates to:
  /// **'আমাকে বলুন!'**
  String get voice_heading;

  /// Prompt/label inviting the user to press the mic to start recording.
  ///
  /// In bn, this message translates to:
  /// **'মাইক চাপুন'**
  String get voice_tap_to_record;

  /// Label shown under the mic while recording is in progress.
  ///
  /// In bn, this message translates to:
  /// **'শুনছি… ছেড়ে দিন'**
  String get voice_recording;

  /// Loading label while the clip uploads and ASR extracts fields.
  ///
  /// In bn, this message translates to:
  /// **'AI বুঝছে…'**
  String get voice_processing;

  /// Error message when recording, mic permission, or upload fails.
  ///
  /// In bn, this message translates to:
  /// **'শোনা যায়নি — আবার চেষ্টা করুন'**
  String get voice_error;

  /// Label above the example phrasing card on the voice screen.
  ///
  /// In bn, this message translates to:
  /// **'উদাহরণ'**
  String get voice_example_label;

  /// Example Bangla phrasing the landlord can speak.
  ///
  /// In bn, this message translates to:
  /// **'\"নতুন ভাড়াটিয়া, নাম রহিম উদ্দিন, ফ্ল্যাট ৪বি, ভাড়া ছাব্বিশ হাজার, মার্চ থেকে…\"'**
  String get voice_example;

  /// Shown when the voice_tenant_entry feature flag is off.
  ///
  /// In bn, this message translates to:
  /// **'ভয়েস ফর্ম এখন বন্ধ আছে।'**
  String get voice_unavailable;

  /// App-bar title of the manual tenant-entry form.
  ///
  /// In bn, this message translates to:
  /// **'হাতে DMP ফর্ম'**
  String get manual_title;

  /// Intro banner explaining the manual form fills the DMP fields by hand.
  ///
  /// In bn, this message translates to:
  /// **'সরকারি ভাড়াটিয়া তথ্য ফরমের সব ঘর হাতে পূরণ করুন।'**
  String get manual_intro;

  /// Section heading for the landlord block of the manual form.
  ///
  /// In bn, this message translates to:
  /// **'১. বাড়িওয়ালা'**
  String get manual_section_landlord;

  /// Section heading for the tenant block of the manual form.
  ///
  /// In bn, this message translates to:
  /// **'২. ভাড়াটিয়া'**
  String get manual_section_tenant;

  /// Section heading for the current-unit block of the manual form.
  ///
  /// In bn, this message translates to:
  /// **'৩. বর্তমান বাসা'**
  String get manual_section_unit;

  /// Section heading for the family & staff block of the manual form.
  ///
  /// In bn, this message translates to:
  /// **'৪. পরিবার ও কর্মচারী'**
  String get manual_section_family;

  /// Tenant full-name field label (required).
  ///
  /// In bn, this message translates to:
  /// **'পূর্ণ নাম'**
  String get manual_full_name;

  /// Tenant occupation field label.
  ///
  /// In bn, this message translates to:
  /// **'পেশা'**
  String get manual_occupation;

  /// Tenant permanent-address field label.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ী ঠিকানা'**
  String get manual_permanent_address;

  /// Current-unit building field label.
  ///
  /// In bn, this message translates to:
  /// **'বিল্ডিং'**
  String get manual_building;

  /// Current-unit unit field label.
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট'**
  String get manual_unit;

  /// Current-unit monthly rent field label.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া'**
  String get manual_rent;

  /// Current-unit move-in date field label.
  ///
  /// In bn, this message translates to:
  /// **'ওঠার তারিখ'**
  String get manual_move_in;

  /// Shared mobile-number field label for tenant forms.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল'**
  String get tenant_mobile;

  /// Proceed button on the manual form — builds the DMP form.
  ///
  /// In bn, this message translates to:
  /// **'ফর্ম তৈরি ও PDF দেখুন 🚀'**
  String get manual_proceed;

  /// Snackbar shown when saving a tenant fails (network/server error).
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটে সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'**
  String get tenant_save_error;

  /// Free-tier usage toast after saving a tenant (e.g. 1/2 used).
  ///
  /// In bn, this message translates to:
  /// **'ফ্রি প্ল্যান: {used}/{limit} ভাড়াটে ব্যবহৃত'**
  String tenant_free_tier_status(int used, int limit);

  /// App-bar title of the DMP form placeholder screen (until EPIC-05).
  ///
  /// In bn, this message translates to:
  /// **'DMP ফর্ম'**
  String get dmp_placeholder_title;

  /// Heading on the DMP placeholder confirming the tenant was saved.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটে সংরক্ষিত হয়েছে!'**
  String get dmp_placeholder_heading;

  /// Body on the DMP placeholder explaining the real form lands in EPIC-05.
  ///
  /// In bn, this message translates to:
  /// **'DMP (পুলিশ) ফর্ম শীঘ্রই এখানে তৈরি হবে।'**
  String get dmp_placeholder_body;

  /// App-bar title of the DMP form preview screen.
  ///
  /// In bn, this message translates to:
  /// **'ডিএমপি ফর্ম · DMP form'**
  String get dmp_title;

  /// Top-bar chip indicating the DMP form is assembled and ready.
  ///
  /// In bn, this message translates to:
  /// **'প্রস্তুত'**
  String get dmp_ready;

  /// Celebratory heading on the DMP preview — the form is assembled.
  ///
  /// In bn, this message translates to:
  /// **'সব হয়ে গেছে!'**
  String get dmp_hero_title;

  /// Subheading under the DMP preview hero.
  ///
  /// In bn, this message translates to:
  /// **'ফর্ম তৈরি হয়েছে'**
  String get dmp_hero_sub;

  /// Organisation name printed at the top of the DMP form card.
  ///
  /// In bn, this message translates to:
  /// **'ঢাকা মেট্রোপলিটন পুলিশ'**
  String get dmp_org;

  /// Sub-label under the DMP org name on the form card.
  ///
  /// In bn, this message translates to:
  /// **'DMP · CIMS · TENANT INFORMATION'**
  String get dmp_org_sub;

  /// Pill badge describing the DMP form type.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়া তথ্য ফরম'**
  String get dmp_org_badge;

  /// Field label: tenant name.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়া · Tenant'**
  String get dmp_field_tenant;

  /// Field label: national ID (masked).
  ///
  /// In bn, this message translates to:
  /// **'NID'**
  String get dmp_field_nid;

  /// Field label: landlord name.
  ///
  /// In bn, this message translates to:
  /// **'বাড়িওয়ালা · Landlord'**
  String get dmp_field_landlord;

  /// Field label: building/rented address.
  ///
  /// In bn, this message translates to:
  /// **'ঠিকানা · Address'**
  String get dmp_field_address;

  /// Field label: tenant present address.
  ///
  /// In bn, this message translates to:
  /// **'বর্তমান ঠিকানা'**
  String get dmp_field_present;

  /// Field label: tenant permanent address.
  ///
  /// In bn, this message translates to:
  /// **'স্থায়ী ঠিকানা'**
  String get dmp_field_permanent;

  /// Field label: date of birth.
  ///
  /// In bn, this message translates to:
  /// **'জন্ম তারিখ'**
  String get dmp_field_dob;

  /// Field label: landlord phone.
  ///
  /// In bn, this message translates to:
  /// **'মোবাইল · Phone'**
  String get dmp_field_phone;

  /// Section label for the household members table.
  ///
  /// In bn, this message translates to:
  /// **'পরিবার · Family'**
  String get dmp_field_family;

  /// Primary action: generate the DMP PDF.
  ///
  /// In bn, this message translates to:
  /// **'PDF তৈরি করুন · Generate PDF'**
  String get dmp_generate;

  /// Secondary action: go back to edit the tenant.
  ///
  /// In bn, this message translates to:
  /// **'সম্পাদনা · Edit'**
  String get dmp_edit;

  /// Error state message on the DMP preview.
  ///
  /// In bn, this message translates to:
  /// **'ফর্ম লোড করা যায়নি। আবার চেষ্টা করুন।'**
  String get dmp_error;

  /// Retry button on the DMP preview error state.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা'**
  String get dmp_retry;

  /// Title of the DMP PDF preview + share screen.
  ///
  /// In bn, this message translates to:
  /// **'DMP PDF · ডিএমপি পিডিএফ'**
  String get dmp_pdf_title;

  /// Loading message while the DMP PDF is generated + downloaded.
  ///
  /// In bn, this message translates to:
  /// **'আপনার ফর্ম তৈরি হচ্ছে…'**
  String get dmp_generating;

  /// Primary action: download/save the generated DMP PDF.
  ///
  /// In bn, this message translates to:
  /// **'নামান · Download'**
  String get dmp_pdf_download;

  /// Secondary action: share the DMP PDF via the OS sheet (WhatsApp/system).
  ///
  /// In bn, this message translates to:
  /// **'শেয়ার · Share'**
  String get dmp_pdf_share;

  /// WhatsApp-specific share label for the DMP PDF.
  ///
  /// In bn, this message translates to:
  /// **'WhatsApp-এ পাঠান · Share on WhatsApp'**
  String get dmp_pdf_whatsapp;

  /// Error state message when DMP PDF generation fails.
  ///
  /// In bn, this message translates to:
  /// **'পিডিএফ তৈরি করা যায়নি। আবার চেষ্টা করুন।'**
  String get dmp_pdf_error;

  /// Snackbar shown when a share/download action fails.
  ///
  /// In bn, this message translates to:
  /// **'কাজটি সম্পন্ন হয়নি। আবার চেষ্টা করুন।'**
  String get dmp_pdf_action_failed;

  /// App-bar title of the lease create form.
  ///
  /// In bn, this message translates to:
  /// **'নতুন ভাড়া চুক্তি'**
  String get lease_new_title;

  /// App-bar title of the lease edit form.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি সম্পাদনা'**
  String get lease_edit_title;

  /// Section heading above the tenant picker on the lease form.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটে'**
  String get lease_section_tenant;

  /// Section heading above the rent/advance/dates terms on the lease form.
  ///
  /// In bn, this message translates to:
  /// **'শর্তাবলি'**
  String get lease_section_terms;

  /// Label of the tenant picker field on the lease form.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটে'**
  String get lease_tenant;

  /// Placeholder of the tenant picker when no tenant is selected.
  ///
  /// In bn, this message translates to:
  /// **'একজন ভাড়াটে বাছাই করুন'**
  String get lease_tenant_hint;

  /// Helper shown when the unit has no tenants to lease to.
  ///
  /// In bn, this message translates to:
  /// **'এই ইউনিটে কোনো ভাড়াটে যোগ করা হয়নি। আগে একজন ভাড়াটে যোগ করুন।'**
  String get lease_tenant_empty;

  /// Monthly rent amount field label on the lease form.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক ভাড়া'**
  String get lease_rent;

  /// Advance (deposit) amount field label on the lease form.
  ///
  /// In bn, this message translates to:
  /// **'অগ্রিম'**
  String get lease_advance;

  /// Lease start-date field label.
  ///
  /// In bn, this message translates to:
  /// **'শুরুর তারিখ'**
  String get lease_start;

  /// Lease end-date field label.
  ///
  /// In bn, this message translates to:
  /// **'শেষের তারিখ'**
  String get lease_end;

  /// Monthly rent due-day field label (defaults from config).
  ///
  /// In bn, this message translates to:
  /// **'প্রতি মাসের পরিশোধের দিন'**
  String get lease_due_day;

  /// Formatted due-day value (e.g. the 5th of each month).
  ///
  /// In bn, this message translates to:
  /// **'প্রতি মাসের {day} তারিখ'**
  String lease_due_day_value(int day);

  /// Helper explaining the due-day drives the generated rent schedule.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়ার সময়সূচি তৈরিতে এই দিনটি ব্যবহৃত হয়।'**
  String get lease_due_day_note;

  /// Primary button — saves the lease as a draft.
  ///
  /// In bn, this message translates to:
  /// **'খসড়া সংরক্ষণ'**
  String get lease_save;

  /// Button that creates the lease draft and activates it (generates the schedule).
  ///
  /// In bn, this message translates to:
  /// **'সংরক্ষণ ও সক্রিয় করুন'**
  String get lease_activate;

  /// Validation error when no tenant is selected.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি তৈরি করতে একজন ভাড়াটে বাছাই করুন'**
  String get lease_err_tenant;

  /// Validation error for a missing/invalid rent amount.
  ///
  /// In bn, this message translates to:
  /// **'একটি বৈধ ভাড়ার পরিমাণ দিন'**
  String get lease_err_rent;

  /// Validation error when the end date is not after the start date.
  ///
  /// In bn, this message translates to:
  /// **'শেষের তারিখ অবশ্যই শুরুর তারিখের পরে হতে হবে'**
  String get lease_err_dates;

  /// Snackbar shown after a lease draft is saved.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি খসড়া হিসেবে সংরক্ষিত হয়েছে'**
  String get lease_saved;

  /// Snackbar shown after a lease is activated and its schedule generated.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি সক্রিয় হয়েছে — ভাড়ার সময়সূচি তৈরি হয়েছে'**
  String get lease_activated;

  /// Snackbar shown when saving/activating a lease fails.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'**
  String get lease_save_error;

  /// Friendly message when the backend rejects activation because the unit already has an active lease.
  ///
  /// In bn, this message translates to:
  /// **'এই ইউনিটে ইতিমধ্যে একটি সক্রিয় চুক্তি রয়েছে।'**
  String get lease_active_exists;

  /// App-bar title of the lease list screen.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া চুক্তি'**
  String get leases_title;

  /// Empty-state title on the lease list when the landlord has no leases.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো চুক্তি নেই'**
  String get leases_empty_title;

  /// Empty-state body on the lease list.
  ///
  /// In bn, this message translates to:
  /// **'একটি ইউনিট থেকে ভাড়া চুক্তি তৈরি করুন, তাহলে এখানে দেখা যাবে।'**
  String get leases_empty;

  /// App-bar title of the lease detail screen.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তির বিবরণ'**
  String get lease_detail_title;

  /// Label for a draft lease status.
  ///
  /// In bn, this message translates to:
  /// **'খসড়া'**
  String get lease_status_draft;

  /// Label for an active lease status.
  ///
  /// In bn, this message translates to:
  /// **'সক্রিয়'**
  String get lease_status_active;

  /// Label for an ended (natural end-of-term) lease status.
  ///
  /// In bn, this message translates to:
  /// **'সমাপ্ত'**
  String get lease_status_ended;

  /// Label for a terminated (early-closed) lease status.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get lease_status_terminated;

  /// Section heading above the rent-schedule summary on lease detail.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়ার সময়সূচি'**
  String get lease_section_schedule;

  /// Shown on lease detail when the lease has no rent-schedule rows.
  ///
  /// In bn, this message translates to:
  /// **'কোনো সময়সূচি নেই — চুক্তি সক্রিয় করুন।'**
  String get lease_schedule_empty;

  /// Count summary of the rent-schedule periods.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি কিস্তি'**
  String lease_schedule_summary(String count);

  /// Lease term shown as start – end on the detail screen.
  ///
  /// In bn, this message translates to:
  /// **'{start} – {end}'**
  String lease_term_range(String start, String end);

  /// Label for the lease's monthly rent on the detail screen.
  ///
  /// In bn, this message translates to:
  /// **'মাসিক ভাড়া'**
  String get lease_rent_amount;

  /// Rent-schedule row status: pending.
  ///
  /// In bn, this message translates to:
  /// **'বাকি'**
  String get lease_sched_status_pending;

  /// Rent-schedule row status: requested.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ করা হয়েছে'**
  String get lease_sched_status_requested;

  /// Rent-schedule row status: paid.
  ///
  /// In bn, this message translates to:
  /// **'পরিশোধিত'**
  String get lease_sched_status_paid;

  /// Rent-schedule row status: overdue.
  ///
  /// In bn, this message translates to:
  /// **'মেয়াদোত্তীর্ণ'**
  String get lease_sched_status_overdue;

  /// Action button that terminates an active lease on the detail screen.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি বাতিল করুন'**
  String get lease_terminate;

  /// Title of the terminate confirmation dialog.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি বাতিল করবেন?'**
  String get lease_terminate_confirm_title;

  /// Body of the terminate confirmation dialog.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তিটি বন্ধ হয়ে যাবে এবং আর সক্রিয় থাকবে না।'**
  String get lease_terminate_confirm_body;

  /// Cancel button on the terminate confirmation dialog.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get lease_terminate_cancel;

  /// Snackbar shown after a lease is terminated.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি বাতিল হয়েছে'**
  String get lease_terminated_ok;

  /// Snackbar shown when terminating a lease fails.
  ///
  /// In bn, this message translates to:
  /// **'চুক্তি বাতিল করা যায়নি। আবার চেষ্টা করুন।'**
  String get lease_terminate_error;

  /// App-bar title of the rent-request screen.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়ার অনুরোধ'**
  String get rent_request_title;

  /// Hero heading on the rent-request screen.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া চান'**
  String get rent_request_heading;

  /// Hero subtitle explaining the tenant gets a WhatsApp link.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ না থাকলেও সমস্যা নেই — WhatsApp-এ লিংক পাবেন'**
  String get rent_request_subtitle;

  /// Label of the rent amount field on the rent-request screen.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়ার পরিমাণ'**
  String get rent_request_amount;

  /// Label of the billing period (YYYY-MM) field on the rent-request screen.
  ///
  /// In bn, this message translates to:
  /// **'সময়কাল'**
  String get rent_request_period;

  /// Helper text for the period field's expected YYYY-MM format.
  ///
  /// In bn, this message translates to:
  /// **'YYYY-MM (যেমন 2026-06)'**
  String get rent_request_period_hint;

  /// Primary action: create the request and send the tenant link.
  ///
  /// In bn, this message translates to:
  /// **'WhatsApp লিংক পাঠান'**
  String get rent_send_whatsapp;

  /// Secondary action: record an off-platform cash payment and settle.
  ///
  /// In bn, this message translates to:
  /// **'টাকা পেয়েছি (নগদ)'**
  String get rent_mark_received;

  /// Validation error when the rent amount is missing or not positive.
  ///
  /// In bn, this message translates to:
  /// **'সঠিক পরিমাণ লিখুন'**
  String get rent_request_err_amount;

  /// Validation error when the period is not in YYYY-MM format.
  ///
  /// In bn, this message translates to:
  /// **'YYYY-MM ফরম্যাটে সময়কাল লিখুন'**
  String get rent_request_err_period;

  /// Snackbar shown after the rent link is created and sent.
  ///
  /// In bn, this message translates to:
  /// **'লিংক পাঠানো হয়েছে'**
  String get rent_request_sent;

  /// Snackbar shown after a cash payment is marked received.
  ///
  /// In bn, this message translates to:
  /// **'টাকা পেয়েছি বলে রেকর্ড হয়েছে'**
  String get rent_request_received;

  /// Snackbar shown when creating/sending/marking the request fails.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ পাঠানো যায়নি। আবার চেষ্টা করুন।'**
  String get rent_request_error;

  /// App-bar title of the verify-payment screen.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট যাচাই'**
  String get verify_title;

  /// Header line: the tenant claims to have paid.
  ///
  /// In bn, this message translates to:
  /// **'{name} বলছেন ভাড়া দিয়েছেন'**
  String verify_claim(String name);

  /// Subline under the claim: the requested amount and billing period.
  ///
  /// In bn, this message translates to:
  /// **'৳{amount} · {period}'**
  String verify_amount_period(String amount, String period);

  /// Section title above the tenant's submitted payment proof.
  ///
  /// In bn, this message translates to:
  /// **'জমা প্রমাণ'**
  String get verify_proof;

  /// Shown in the proof viewer when the tenant has not submitted any proof.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো প্রমাণ জমা পড়েনি'**
  String get verify_proof_none;

  /// Shown in the proof viewer when the signed-URL screenshot fails to load.
  ///
  /// In bn, this message translates to:
  /// **'ছবি লোড করা যায়নি'**
  String get verify_proof_image_failed;

  /// Label for the transaction-id line in the proof details.
  ///
  /// In bn, this message translates to:
  /// **'লেনদেন আইডি'**
  String get verify_proof_txn;

  /// Label for the amount line in the proof details.
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get verify_proof_amount;

  /// Primary action: verify the proof and generate a receipt.
  ///
  /// In bn, this message translates to:
  /// **'টাকা পেয়েছি'**
  String get verify_confirm;

  /// Secondary action: reject the request with a reason.
  ///
  /// In bn, this message translates to:
  /// **'এখনো পাইনি'**
  String get verify_reject;

  /// Label/title of the reject-reason input dialog.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাখ্যানের কারণ লিখুন'**
  String get verify_reason;

  /// Hint text inside the reject-reason input.
  ///
  /// In bn, this message translates to:
  /// **'কেন গ্রহণ করছেন না?'**
  String get verify_reason_hint;

  /// Validation error when a reject reason is left empty.
  ///
  /// In bn, this message translates to:
  /// **'একটি কারণ লিখুন'**
  String get verify_reason_required;

  /// Cancel button in the reject-reason dialog.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get verify_reason_cancel;

  /// Confirm button in the reject-reason dialog.
  ///
  /// In bn, this message translates to:
  /// **'প্রত্যাখ্যান'**
  String get verify_reason_submit;

  /// Snackbar shown after the payment proof is verified.
  ///
  /// In bn, this message translates to:
  /// **'যাচাই সম্পন্ন'**
  String get verify_verified;

  /// Snackbar shown after the request is rejected.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ প্রত্যাখ্যান করা হয়েছে'**
  String get verify_rejected;

  /// Snackbar shown when verify/reject fails.
  ///
  /// In bn, this message translates to:
  /// **'কাজটি সম্পন্ন হয়নি। আবার চেষ্টা করুন।'**
  String get verify_error;

  /// Shown when the rent request cannot be loaded.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ লোড করা যায়নি'**
  String get verify_load_error;

  /// Retry button shown in the load-error state.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা'**
  String get verify_retry;

  /// App-bar title of the rent receipt screen.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ'**
  String get receipt_title;

  /// Hero headline shown after a payment is verified and the receipt is generated.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ তৈরি হয়েছে'**
  String get receipt_ready;

  /// Hero subline under the receipt-ready headline.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়াকে পাঠিয়ে দিন'**
  String get receipt_ready_sub;

  /// Title printed at the top of the receipt card.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়ার রসিদ'**
  String get receipt_heading;

  /// The large paid amount shown on the receipt card.
  ///
  /// In bn, this message translates to:
  /// **'৳{amount}'**
  String receipt_amount(String amount);

  /// Label for the tenant row on the receipt.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়া'**
  String get receipt_tenant;

  /// Label for the unit row on the receipt.
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট'**
  String get receipt_unit;

  /// Label for the billing-period row on the receipt.
  ///
  /// In bn, this message translates to:
  /// **'সময়কাল'**
  String get receipt_period;

  /// Label for the payment-method row on the receipt.
  ///
  /// In bn, this message translates to:
  /// **'পদ্ধতি'**
  String get receipt_method;

  /// Label for the status row on the receipt.
  ///
  /// In bn, this message translates to:
  /// **'স্ট্যাটাস'**
  String get receipt_status;

  /// Value shown for a verified/paid receipt status.
  ///
  /// In bn, this message translates to:
  /// **'✓ পরিশোধিত'**
  String get receipt_status_paid;

  /// Label for the receipt-number footnote.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ নং'**
  String get receipt_no;

  /// Primary action: share the receipt with the tenant (WhatsApp/system).
  ///
  /// In bn, this message translates to:
  /// **'ভাড়াটিয়াকে পাঠান'**
  String get receipt_share;

  /// Secondary action: download/save the receipt PDF or finish.
  ///
  /// In bn, this message translates to:
  /// **'PDF · সম্পন্ন'**
  String get receipt_done;

  /// Placeholder dash shown when a receipt field value is unknown.
  ///
  /// In bn, this message translates to:
  /// **'—'**
  String get receipt_dash;

  /// Fallback share text used when no receipt PDF is available.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়ার রসিদ\n৳{amount} · {period}'**
  String receipt_share_text(String amount, String period);

  /// Snackbar shown when share/download of the receipt fails.
  ///
  /// In bn, this message translates to:
  /// **'কাজটি সম্পন্ন হয়নি। আবার চেষ্টা করুন।'**
  String get receipt_action_failed;

  /// Shown when the rent request behind the receipt cannot be loaded.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ লোড করা যায়নি'**
  String get receipt_load_error;

  /// Retry button shown in the receipt load-error state.
  ///
  /// In bn, this message translates to:
  /// **'আবার চেষ্টা'**
  String get receipt_retry;

  /// App-bar title for the maintenance & expenses list screen.
  ///
  /// In bn, this message translates to:
  /// **'মেরামত ও খরচ'**
  String get expenses_title;

  /// Chip on the totals hero card scoping the total to the current month.
  ///
  /// In bn, this message translates to:
  /// **'এ মাসে'**
  String get expenses_this_month;

  /// Label above the big total-expenses figure on the hero card.
  ///
  /// In bn, this message translates to:
  /// **'মোট খরচ'**
  String get expenses_total;

  /// The total-expenses amount, prefixed with the Taka sign.
  ///
  /// In bn, this message translates to:
  /// **'৳{amount}'**
  String expenses_total_amount(String amount);

  /// Sub-line under the total showing how many expenses are in view.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি খরচ'**
  String expenses_count(String count);

  /// Filter chip that clears the building filter (shows every expense).
  ///
  /// In bn, this message translates to:
  /// **'সব'**
  String get expenses_filter_all;

  /// Section heading above the list of expense rows.
  ///
  /// In bn, this message translates to:
  /// **'সাম্প্রতিক খরচ'**
  String get expenses_section_recent;

  /// Source chip for an expense logged manually by the landlord.
  ///
  /// In bn, this message translates to:
  /// **'ম্যানুয়াল'**
  String get expenses_source_manual;

  /// Source chip for an expense auto-created from resolving a maintenance request.
  ///
  /// In bn, this message translates to:
  /// **'মেরামত'**
  String get expenses_source_request;

  /// An expense row's amount, prefixed with the Taka sign.
  ///
  /// In bn, this message translates to:
  /// **'৳{amount}'**
  String expenses_amount(String amount);

  /// App-bar action / CTA to log a new manual expense.
  ///
  /// In bn, this message translates to:
  /// **'খরচ যোগ'**
  String get expenses_add;

  /// Action to export the (filtered) expenses as a shareable CSV file.
  ///
  /// In bn, this message translates to:
  /// **'CSV রপ্তানি'**
  String get expenses_export;

  /// Snackbar shown when the CSV export/share fails.
  ///
  /// In bn, this message translates to:
  /// **'রপ্তানি সম্পন্ন হয়নি। আবার চেষ্টা করুন।'**
  String get expenses_export_failed;

  /// Empty-state message when the landlord has logged no expenses.
  ///
  /// In bn, this message translates to:
  /// **'এখনও কোনো খরচ নেই'**
  String get expenses_empty;

  /// Expense category label: plumbing.
  ///
  /// In bn, this message translates to:
  /// **'প্লাম্বিং'**
  String get expenses_category_plumbing;

  /// Expense category label: paint.
  ///
  /// In bn, this message translates to:
  /// **'পেইন্ট'**
  String get expenses_category_paint;

  /// Expense category label: electrical.
  ///
  /// In bn, this message translates to:
  /// **'বিদ্যুৎ'**
  String get expenses_category_electrical;

  /// Expense category label: structural.
  ///
  /// In bn, this message translates to:
  /// **'স্ট্রাকচার'**
  String get expenses_category_structural;

  /// Expense category label: appliance.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ্লায়েন্স'**
  String get expenses_category_appliance;

  /// Expense category label: utility.
  ///
  /// In bn, this message translates to:
  /// **'ইউটিলিটি'**
  String get expenses_category_utility;

  /// Expense category label: other.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get expenses_category_other;

  /// Add-expense screen app-bar title.
  ///
  /// In bn, this message translates to:
  /// **'খরচ যোগ'**
  String get add_expense_title;

  /// Add-expense form: amount field label (required).
  ///
  /// In bn, this message translates to:
  /// **'পরিমাণ'**
  String get expense_amount;

  /// Add-expense form: amount field placeholder.
  ///
  /// In bn, this message translates to:
  /// **'৳ ০'**
  String get expense_amount_hint;

  /// Add-expense form: category section label.
  ///
  /// In bn, this message translates to:
  /// **'খাত'**
  String get expense_category;

  /// Add-expense form: unit field label (required).
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট'**
  String get expense_unit;

  /// Add-expense form: building selector label.
  ///
  /// In bn, this message translates to:
  /// **'ভবন'**
  String get expense_building;

  /// Add-expense form: unit selector placeholder.
  ///
  /// In bn, this message translates to:
  /// **'একটি ইউনিট বাছুন'**
  String get expense_unit_hint;

  /// Add-expense form: building selector placeholder.
  ///
  /// In bn, this message translates to:
  /// **'একটি ভবন বাছুন'**
  String get expense_building_hint;

  /// Add-expense form: date field label.
  ///
  /// In bn, this message translates to:
  /// **'তারিখ'**
  String get expense_date;

  /// Add-expense form: note field label (optional).
  ///
  /// In bn, this message translates to:
  /// **'নোট (ঐচ্ছিক)'**
  String get expense_note;

  /// Add-expense form: receipt photo label (optional).
  ///
  /// In bn, this message translates to:
  /// **'রসিদ (ঐচ্ছিক)'**
  String get expense_receipt;

  /// Add-expense form: attach-receipt button.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ যোগ করুন'**
  String get expense_receipt_add;

  /// Add-expense form: receipt attached confirmation.
  ///
  /// In bn, this message translates to:
  /// **'রসিদ যুক্ত হয়েছে'**
  String get expense_receipt_attached;

  /// Add-expense form: remove attached receipt.
  ///
  /// In bn, this message translates to:
  /// **'সরান'**
  String get expense_receipt_remove;

  /// Add-expense form: save button.
  ///
  /// In bn, this message translates to:
  /// **'খরচ সেভ করুন'**
  String get expense_save;

  /// Add-expense form: amount validation error.
  ///
  /// In bn, this message translates to:
  /// **'একটি বৈধ পরিমাণ দিন'**
  String get expense_err_amount;

  /// Add-expense form: missing-unit validation error.
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট বাছাই করুন'**
  String get expense_err_unit;

  /// Add-expense: success snackbar.
  ///
  /// In bn, this message translates to:
  /// **'খরচ সেভ হয়েছে'**
  String get expense_saved;

  /// Add-expense: failure snackbar.
  ///
  /// In bn, this message translates to:
  /// **'সেভ হয়নি'**
  String get expense_save_failed;

  /// App-bar title for the landlord maintenance-queue screen.
  ///
  /// In bn, this message translates to:
  /// **'মেরামতের অনুরোধ'**
  String get maintenance_title;

  /// Section heading above the list of open maintenance requests.
  ///
  /// In bn, this message translates to:
  /// **'নতুন অনুরোধ'**
  String get maintenance_section_open;

  /// Sub-line showing how many open requests are in the queue.
  ///
  /// In bn, this message translates to:
  /// **'{count} টি অপেক্ষায়'**
  String maintenance_open_count(String count);

  /// Per-request unit label.
  ///
  /// In bn, this message translates to:
  /// **'ইউনিট {unit}'**
  String maintenance_unit(String unit);

  /// Primary action on a request: resolve it and record the cost (auto-creates an expense).
  ///
  /// In bn, this message translates to:
  /// **'সমাধান + খরচ'**
  String get maintenance_resolve;

  /// Badge shown on a request that has already been resolved.
  ///
  /// In bn, this message translates to:
  /// **'সমাধান হয়েছে'**
  String get maintenance_resolved_badge;

  /// Resolve dialog: the cost field label (becomes the auto-expense amount).
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get maintenance_cost;

  /// Resolve dialog: cost field placeholder.
  ///
  /// In bn, this message translates to:
  /// **'৳ ০'**
  String get maintenance_cost_hint;

  /// Resolve dialog: optional resolution note label.
  ///
  /// In bn, this message translates to:
  /// **'নোট (ঐচ্ছিক)'**
  String get maintenance_resolution_note;

  /// Title of the resolve-with-cost dialog.
  ///
  /// In bn, this message translates to:
  /// **'সমাধান + খরচ'**
  String get maintenance_resolve_title;

  /// Resolve dialog: explanation that resolving records an expense.
  ///
  /// In bn, this message translates to:
  /// **'এই খরচ একটি খরচ এন্ট্রি তৈরি করবে'**
  String get maintenance_resolve_hint;

  /// Resolve dialog: confirm button.
  ///
  /// In bn, this message translates to:
  /// **'সমাধান করুন'**
  String get maintenance_resolve_confirm;

  /// Resolve dialog: cancel button.
  ///
  /// In bn, this message translates to:
  /// **'বাতিল'**
  String get maintenance_resolve_cancel;

  /// Resolve dialog: cost validation error.
  ///
  /// In bn, this message translates to:
  /// **'একটি বৈধ খরচ দিন'**
  String get maintenance_err_cost;

  /// Snackbar shown after a request is resolved and an expense is created.
  ///
  /// In bn, this message translates to:
  /// **'অনুরোধ সমাধান হয়েছে'**
  String get maintenance_resolved;

  /// Snackbar shown when resolving a request fails.
  ///
  /// In bn, this message translates to:
  /// **'সমাধান হয়নি'**
  String get maintenance_resolve_failed;

  /// Empty-state message when there are no open maintenance requests.
  ///
  /// In bn, this message translates to:
  /// **'কোনো খোলা অনুরোধ নেই'**
  String get maintenance_empty;

  /// Maintenance category label: plumbing.
  ///
  /// In bn, this message translates to:
  /// **'পানি'**
  String get maintenance_category_plumbing;

  /// Maintenance category label: electrical.
  ///
  /// In bn, this message translates to:
  /// **'বিদ্যুৎ'**
  String get maintenance_category_electrical;

  /// Maintenance category label: paint.
  ///
  /// In bn, this message translates to:
  /// **'পেইন্ট'**
  String get maintenance_category_paint;

  /// Maintenance category label: structural.
  ///
  /// In bn, this message translates to:
  /// **'স্ট্রাকচার'**
  String get maintenance_category_structural;

  /// Maintenance category label: appliance.
  ///
  /// In bn, this message translates to:
  /// **'অ্যাপ্লায়েন্স'**
  String get maintenance_category_appliance;

  /// Maintenance category label: utility.
  ///
  /// In bn, this message translates to:
  /// **'ইউটিলিটি'**
  String get maintenance_category_utility;

  /// Maintenance category label: other.
  ///
  /// In bn, this message translates to:
  /// **'অন্যান্য'**
  String get maintenance_category_other;

  /// Dashboard / charts screen app-bar title.
  ///
  /// In bn, this message translates to:
  /// **'ড্যাশবোর্ড'**
  String get dashboard_title;

  /// Label on the income hero card.
  ///
  /// In bn, this message translates to:
  /// **'এ মাসের মোট আয়'**
  String get dashboard_income;

  /// A taka money amount rendered with localized numerals.
  ///
  /// In bn, this message translates to:
  /// **'৳{value}'**
  String dashboard_amount(String value);

  /// Heading above the 6-month collection bar chart.
  ///
  /// In bn, this message translates to:
  /// **'আদায় হার (৬ মাস)'**
  String get dashboard_collection;

  /// Heading above the occupancy donut.
  ///
  /// In bn, this message translates to:
  /// **'অকুপেন্সি'**
  String get dashboard_occupancy;

  /// Occupied-of-total units sublabel inside the occupancy donut.
  ///
  /// In bn, this message translates to:
  /// **'{occupied}/{total}'**
  String dashboard_occupancy_units(String occupied, String total);

  /// Occupancy legend: occupied units.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়া হয়েছে'**
  String get dashboard_occupied;

  /// Occupancy legend: vacant units.
  ///
  /// In bn, this message translates to:
  /// **'খালি'**
  String get dashboard_vacant;

  /// Heading above the income-vs-expense chart.
  ///
  /// In bn, this message translates to:
  /// **'আয় ও খরচ'**
  String get dashboard_income_expense;

  /// Income-vs-expense legend: income.
  ///
  /// In bn, this message translates to:
  /// **'আয়'**
  String get dashboard_income_legend;

  /// Income-vs-expense legend: expense.
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get dashboard_expense_legend;

  /// Income-vs-expense chart: the income series label (sage).
  ///
  /// In bn, this message translates to:
  /// **'আয়'**
  String get dashboard_income_series;

  /// Income-vs-expense chart: the expense series label (rose).
  ///
  /// In bn, this message translates to:
  /// **'খরচ'**
  String get dashboard_expense_series;

  /// Heading above the top expense categories list.
  ///
  /// In bn, this message translates to:
  /// **'প্রধান খরচ 💸'**
  String get dashboard_expenses;

  /// Heading on the late-payers card.
  ///
  /// In bn, this message translates to:
  /// **'দেরিতে ভাড়া'**
  String get dashboard_late;

  /// Late-payers card when nobody is overdue.
  ///
  /// In bn, this message translates to:
  /// **'কেউ দেরিতে নেই'**
  String get dashboard_late_none;

  /// Number of late payers; count is already localized to a numeral string.
  ///
  /// In bn, this message translates to:
  /// **'{count} জন দেরিতে'**
  String dashboard_late_count(String count);

  /// Quick-request CTA on the late-payers card.
  ///
  /// In bn, this message translates to:
  /// **'ভাড়ার অনুরোধ পাঠান'**
  String get dashboard_late_request;

  /// Empty-state label inside a chart with no data.
  ///
  /// In bn, this message translates to:
  /// **'কোনো তথ্য নেই'**
  String get dashboard_chart_empty;

  /// Whole-screen empty state for a brand-new landlord with no data.
  ///
  /// In bn, this message translates to:
  /// **'এখনো কোনো তথ্য নেই — ভাড়াটিয়া যোগ করুন ও ভাড়া লিপিবদ্ধ করুন।'**
  String get dashboard_empty;

  /// App-bar title on the plan & billing screen.
  ///
  /// In bn, this message translates to:
  /// **'প্ল্যান · Plan'**
  String get plan_title;

  /// Chip marking the caller's current tier.
  ///
  /// In bn, this message translates to:
  /// **'এখন'**
  String get plan_current;

  /// Top card: which tier the caller is currently on.
  ///
  /// In bn, this message translates to:
  /// **'এখন {tier}-এ আছেন'**
  String plan_current_banner(String tier);

  /// Usage line under the current-plan banner; numerals pre-localized.
  ///
  /// In bn, this message translates to:
  /// **'{used}/{limit} ভাড়াটিয়া ব্যবহৃত'**
  String plan_usage(String used, String limit);

  /// Usage line for an unlimited plan; used is pre-localized.
  ///
  /// In bn, this message translates to:
  /// **'{used} ভাড়াটিয়া · সীমাহীন'**
  String plan_usage_unlimited(String used);

  /// Price shown for the free tier (BDT 0).
  ///
  /// In bn, this message translates to:
  /// **'ফ্রি'**
  String get plan_free;

  /// Primary upgrade button on the plan screen.
  ///
  /// In bn, this message translates to:
  /// **'bKash / Nagad দিয়ে আপগ্রেড'**
  String get plan_upgrade;

  /// Subscribe action on a non-current tier card.
  ///
  /// In bn, this message translates to:
  /// **'এই প্ল্যান নিন'**
  String get plan_choose;

  /// Badge on the recommended (best-value) tier card.
  ///
  /// In bn, this message translates to:
  /// **'⭐ সেরা মূল্য'**
  String get plan_best_value;

  /// Suffix on a monthly tier price.
  ///
  /// In bn, this message translates to:
  /// **'/মাস'**
  String get plan_per_month;

  /// Suffix on a per-tenant tier price.
  ///
  /// In bn, this message translates to:
  /// **'/ভাড়াটিয়া/মাস'**
  String get plan_per_tenant_month;

  /// Tenant band a tier covers; numerals pre-localized.
  ///
  /// In bn, this message translates to:
  /// **'{min}–{max} ভাড়াটিয়া'**
  String plan_band(String min, String max);

  /// Tenant band with no upper bound (unlimited).
  ///
  /// In bn, this message translates to:
  /// **'{min}+ ভাড়াটিয়া'**
  String plan_band_min(String min);

  /// Tenant band label for the unlimited tier.
  ///
  /// In bn, this message translates to:
  /// **'সীমাহীন ভাড়াটিয়া'**
  String get plan_band_unlimited;

  /// Feature note shown when a tier bundles NID verification.
  ///
  /// In bn, this message translates to:
  /// **'+ NID যাচাই'**
  String get plan_includes_verification;

  /// Footer note: prices are admin-configurable and illustrative.
  ///
  /// In bn, this message translates to:
  /// **'দাম অ্যাডমিন-নিয়ন্ত্রিত · নমুনা'**
  String get plan_billing_note;

  /// Snackbar after a stubbed subscribe: confirmation pending.
  ///
  /// In bn, this message translates to:
  /// **'পেমেন্ট নিশ্চিত হলে আমরা জানাব'**
  String get plan_billing_confirm_pending;

  /// Snackbar when a subscribe request fails.
  ///
  /// In bn, this message translates to:
  /// **'আপগ্রেড করা যায়নি · আবার চেষ্টা করুন'**
  String get plan_billing_error;

  /// Empty state when no tiers are configured.
  ///
  /// In bn, this message translates to:
  /// **'কোনো প্ল্যান নেই'**
  String get plan_empty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
