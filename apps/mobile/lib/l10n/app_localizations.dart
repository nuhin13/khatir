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

  /// Logout action label.
  ///
  /// In bn, this message translates to:
  /// **'লগ আউট'**
  String get common_logout;

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
