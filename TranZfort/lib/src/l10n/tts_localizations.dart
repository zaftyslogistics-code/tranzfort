import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'tts_localizations_en.dart';
import 'tts_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of TtsLocalizations
/// returned by `TtsLocalizations.of(context)`.
///
/// Applications need to include `TtsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/tts_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: TtsLocalizations.localizationsDelegates,
///   supportedLocales: TtsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the TtsLocalizations.supportedLocales
/// property.
abstract class TtsLocalizations {
  TtsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static TtsLocalizations of(BuildContext context) {
    return Localizations.of<TtsLocalizations>(context, TtsLocalizations)!;
  }

  static const LocalizationsDelegate<TtsLocalizations> delegate =
      _TtsLocalizationsDelegate();

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
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @ttsListenToLoadHint.
  ///
  /// In en, this message translates to:
  /// **'Listen to load details'**
  String get ttsListenToLoadHint;

  /// No description provided for @ttsLoadCardRoute.
  ///
  /// In en, this message translates to:
  /// **'Load from {origin} to {destination}.'**
  String ttsLoadCardRoute(Object origin, Object destination);

  /// No description provided for @ttsLoadCardMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material {material}.'**
  String ttsLoadCardMaterial(Object material);

  /// No description provided for @ttsLoadCardTruckTyres.
  ///
  /// In en, this message translates to:
  /// **'Truck from {minTyres} to {maxTyres} wheels required.'**
  String ttsLoadCardTruckTyres(Object minTyres, Object maxTyres);

  /// No description provided for @ttsLoadCardTruckCapacityTonnes.
  ///
  /// In en, this message translates to:
  /// **'Truck capacity from {minTonnes} to {maxTonnes} tonnes.'**
  String ttsLoadCardTruckCapacityTonnes(Object minTonnes, Object maxTonnes);

  /// No description provided for @ttsLoadCardBodyType.
  ///
  /// In en, this message translates to:
  /// **'Body type {bodyType}.'**
  String ttsLoadCardBodyType(Object bodyType);

  /// No description provided for @ttsLoadCardRatePerTon.
  ///
  /// In en, this message translates to:
  /// **'Rate {amount} rupees per ton.'**
  String ttsLoadCardRatePerTon(Object amount);

  /// No description provided for @ttsLoadCardRateFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed rate {amount} rupees for the load.'**
  String ttsLoadCardRateFixed(Object amount);

  /// No description provided for @ttsLoadCardPickupToday.
  ///
  /// In en, this message translates to:
  /// **'Pickup today.'**
  String get ttsLoadCardPickupToday;

  /// No description provided for @ttsLoadCardPickupTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Pickup tomorrow.'**
  String get ttsLoadCardPickupTomorrow;

  /// No description provided for @ttsLoadCardPickupOnDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup on {dateLabel}.'**
  String ttsLoadCardPickupOnDate(Object dateLabel);

  /// No description provided for @ttsLoadCardAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance {percent} percent.'**
  String ttsLoadCardAdvance(Object percent);

  /// No description provided for @ttsSupplierLoadListSummary.
  ///
  /// In en, this message translates to:
  /// **'Load {origin} to {destination}. Material {material}. {weightTonnes} tonnes. Rate {amount} rupees. Status {status}.'**
  String ttsSupplierLoadListSummary(
    Object origin,
    Object destination,
    Object material,
    Object weightTonnes,
    Object amount,
    Object status,
  );

  /// No description provided for @ttsTripCardSummary.
  ///
  /// In en, this message translates to:
  /// **'Trip {route}. Material {material}. Stage {stage}. Truck {truckNumber}.'**
  String ttsTripCardSummary(
    Object route,
    Object material,
    Object stage,
    Object truckNumber,
  );

  /// No description provided for @ttsBookingRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking was rejected. Look for another load.'**
  String get ttsBookingRejected;

  /// No description provided for @ttsBookingApproved.
  ///
  /// In en, this message translates to:
  /// **'Booking approved. Head to pickup.'**
  String get ttsBookingApproved;
}

class _TtsLocalizationsDelegate
    extends LocalizationsDelegate<TtsLocalizations> {
  const _TtsLocalizationsDelegate();

  @override
  Future<TtsLocalizations> load(Locale locale) {
    return SynchronousFuture<TtsLocalizations>(lookupTtsLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_TtsLocalizationsDelegate old) => false;
}

TtsLocalizations lookupTtsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return TtsLocalizationsEn();
    case 'hi':
      return TtsLocalizationsHi();
  }

  throw FlutterError(
    'TtsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
