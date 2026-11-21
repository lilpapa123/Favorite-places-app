import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite Places'**
  String get appTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get noConnection;

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Turn them on in Settings.'**
  String get locationServicesOff;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location: {error}'**
  String couldNotGetLocation(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make the app feel like yours.'**
  String get settingsSubtitle;

  /// No description provided for @settingsRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance and language'**
  String get settingsRowSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get languageSystem;

  /// No description provided for @categoryCafe.
  ///
  /// In en, this message translates to:
  /// **'Café'**
  String get categoryCafe;

  /// No description provided for @categoryCafePlural.
  ///
  /// In en, this message translates to:
  /// **'Cafés'**
  String get categoryCafePlural;

  /// No description provided for @categoryViewpoint.
  ///
  /// In en, this message translates to:
  /// **'Viewpoint'**
  String get categoryViewpoint;

  /// No description provided for @categoryViewpointPlural.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get categoryViewpointPlural;

  /// No description provided for @categoryWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get categoryWalk;

  /// No description provided for @categoryWalkPlural.
  ///
  /// In en, this message translates to:
  /// **'Walks'**
  String get categoryWalkPlural;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @categoryOtherPlural.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOtherPlural;

  /// No description provided for @tabMyPlaces.
  ///
  /// In en, this message translates to:
  /// **'My places'**
  String get tabMyPlaces;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @takePhotoOfPlace.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of a place'**
  String get takePhotoOfPlace;

  /// No description provided for @noCameraChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'No camera on this device - choose a photo instead.'**
  String get noCameraChoosePhoto;

  /// No description provided for @savedToMyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved to My places'**
  String get savedToMyPlaces;

  /// No description provided for @tapMapToDropPin.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to drop a pin'**
  String get tapMapToDropPin;

  /// No description provided for @useThisSpot.
  ///
  /// In en, this message translates to:
  /// **'Use this spot'**
  String get useThisSpot;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name, A to Z'**
  String get sortName;

  /// No description provided for @sortPlaces.
  ///
  /// In en, this message translates to:
  /// **'Sort places'**
  String get sortPlaces;

  /// No description provided for @favoritePlacesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 favorite place} other{{count} favorite places}}'**
  String favoritePlacesCount(int count);

  /// No description provided for @findFavoritePlace.
  ///
  /// In en, this message translates to:
  /// **'Find a favorite place'**
  String get findFavoritePlace;

  /// No description provided for @allCount.
  ///
  /// In en, this message translates to:
  /// **'All · {count}'**
  String allCount(int count);

  /// No description provided for @noPlacesMatch.
  ///
  /// In en, this message translates to:
  /// **'No places match'**
  String get noPlacesMatch;

  /// No description provided for @tryAnotherWord.
  ///
  /// In en, this message translates to:
  /// **'Try another word or type.'**
  String get tryAnotherWord;

  /// No description provided for @showAllPlaces.
  ///
  /// In en, this message translates to:
  /// **'Show all places'**
  String get showAllPlaces;

  /// No description provided for @typeOfPlace.
  ///
  /// In en, this message translates to:
  /// **'Type of place'**
  String get typeOfPlace;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite places yet'**
  String get noFavoritesYet;

  /// No description provided for @noFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'Add a place with a photo, and it will show up here.'**
  String get noFavoritesBody;

  /// No description provided for @addAPlace.
  ///
  /// In en, this message translates to:
  /// **'Add a place'**
  String get addAPlace;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @onMap.
  ///
  /// In en, this message translates to:
  /// **'On map'**
  String get onMap;

  /// No description provided for @osmCredit.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get osmCredit;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get changesSaved;

  /// No description provided for @editPlace.
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get editPlace;

  /// No description provided for @addPlace.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get addPlace;

  /// No description provided for @editPlaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change anything you like.'**
  String get editPlaceSubtitle;

  /// No description provided for @addPlaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a little piece of somewhere.'**
  String get addPlaceSubtitle;

  /// No description provided for @placeName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get placeName;

  /// No description provided for @placeNameHint.
  ///
  /// In en, this message translates to:
  /// **'A little pause by the river'**
  String get placeNameHint;

  /// No description provided for @littleNote.
  ///
  /// In en, this message translates to:
  /// **'A little note'**
  String get littleNote;

  /// No description provided for @littleNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Why you love it, in a line or two'**
  String get littleNoteHint;

  /// No description provided for @onlyYouCanSee.
  ///
  /// In en, this message translates to:
  /// **'People who follow you will see this place.'**
  String get onlyYouCanSee;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @savePlace.
  ///
  /// In en, this message translates to:
  /// **'Save place'**
  String get savePlace;

  /// No description provided for @removedFromMyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Removed from My places'**
  String get removedFromMyPlaces;

  /// No description provided for @removeFromMyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Remove from my places'**
  String get removeFromMyPlaces;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Maps'**
  String get couldNotOpenMaps;

  /// No description provided for @savedPlace.
  ///
  /// In en, this message translates to:
  /// **'Saved place'**
  String get savedPlace;

  /// No description provided for @morePlaceActions.
  ///
  /// In en, this message translates to:
  /// **'More place actions'**
  String get morePlaceActions;

  /// No description provided for @savedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved on {date}'**
  String savedOn(String date);

  /// No description provided for @myLittleNote.
  ///
  /// In en, this message translates to:
  /// **'MY LITTLE NOTE'**
  String get myLittleNote;

  /// No description provided for @noLocationYet.
  ///
  /// In en, this message translates to:
  /// **'No location yet — add one with Edit place.'**
  String get noLocationYet;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @couldNotFindQuery.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find \"{query}\". Try a city or full address.'**
  String couldNotFindQuery(String query);

  /// No description provided for @allowLocationToSee.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to see where you are.'**
  String get allowLocationToSee;

  /// No description provided for @cityCount.
  ///
  /// In en, this message translates to:
  /// **'{city} · {count}'**
  String cityCount(String city, int count);

  /// No description provided for @pinnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pinned'**
  String pinnedCount(int count);

  /// No description provided for @searchPlacesOrCities.
  ///
  /// In en, this message translates to:
  /// **'Search places or cities'**
  String get searchPlacesOrCities;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @mapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your favorites, a little closer.'**
  String get mapSubtitle;

  /// No description provided for @noPinsYet.
  ///
  /// In en, this message translates to:
  /// **'No pins yet'**
  String get noPinsYet;

  /// No description provided for @noPinsBody.
  ///
  /// In en, this message translates to:
  /// **'Add a place with a location\nand it shows up here.'**
  String get noPinsBody;

  /// No description provided for @centerOnMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get centerOnMyLocation;

  /// No description provided for @viewPlace.
  ///
  /// In en, this message translates to:
  /// **'View place'**
  String get viewPlace;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get choosePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get chooseFromLibrary;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @addPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Take one or choose from library'**
  String get addPhotoHint;

  /// No description provided for @addPhotoNote.
  ///
  /// In en, this message translates to:
  /// **'Optional, but full of memories.'**
  String get addPhotoNote;

  /// No description provided for @errNoCamera.
  ///
  /// In en, this message translates to:
  /// **'This device has no camera. Simulators have no camera - choose a photo from the library, or use a real phone.'**
  String get errNoCamera;

  /// No description provided for @errCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Allow it in Settings > Favorite Places.'**
  String get errCameraDenied;

  /// No description provided for @errPhotosDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo library access was denied. Allow it in Settings > Favorite Places.'**
  String get errPhotosDenied;

  /// No description provided for @errCameraRestricted.
  ///
  /// In en, this message translates to:
  /// **'Camera access is restricted on this device (Screen Time or an MDM profile is blocking it).'**
  String get errCameraRestricted;

  /// No description provided for @errPickerOpen.
  ///
  /// In en, this message translates to:
  /// **'The picker is already open. Close it and try again.'**
  String get errPickerOpen;

  /// No description provided for @errCouldNotGetPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not get a photo: {details}'**
  String errCouldNotGetPhoto(String details);

  /// No description provided for @whereIsIt.
  ///
  /// In en, this message translates to:
  /// **'Where is it?'**
  String get whereIsIt;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on the map'**
  String get pickOnMap;

  /// No description provided for @removeLocation.
  ///
  /// In en, this message translates to:
  /// **'Remove location'**
  String get removeLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Allow it in Settings > Favorite Places, or pick the spot on the map instead.'**
  String get locationBlocked;

  /// No description provided for @findingSpot.
  ///
  /// In en, this message translates to:
  /// **'Finding the spot…'**
  String get findingSpot;

  /// No description provided for @takesASecond.
  ///
  /// In en, this message translates to:
  /// **'This takes a second'**
  String get takesASecond;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add a location'**
  String get addLocation;

  /// No description provided for @addLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Use where you are, or pick on the map'**
  String get addLocationHint;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationSemantic.
  ///
  /// In en, this message translates to:
  /// **'Location: {title}'**
  String locationSemantic(String title);

  /// No description provided for @signInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is unavailable right now.\n{error}'**
  String signInUnavailable(String error);

  /// No description provided for @enterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password'**
  String get enterEmailPassword;

  /// No description provided for @typeEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Type your email first, then tap \"Forgot password\"'**
  String get typeEmailFirst;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}'**
  String resetLinkSent(String email);

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address is not valid.'**
  String get errInvalidEmail;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errUserDisabled;

  /// No description provided for @errWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errWrongCredentials;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for that email. Sign in instead.'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get errWeakPassword;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get errTooManyAttempts;

  /// No description provided for @errEmailNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is not enabled in the Firebase console (Authentication > Sign-in method).'**
  String get errEmailNotEnabled;

  /// No description provided for @errSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed ({code}).'**
  String errSignInFailed(String code);

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to keep your places with you'**
  String get signUpSubtitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Chars;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @placesStayOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share your places and follow friends.'**
  String get placesStayOnPhone;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get nameUpdated;

  /// No description provided for @couldNotUpdateName.
  ///
  /// In en, this message translates to:
  /// **'Could not update your name'**
  String get couldNotUpdateName;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @accountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A small collection, all yours.'**
  String get accountSubtitle;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @statPlaces.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Place} other{Places}}'**
  String statPlaces(int count);

  /// No description provided for @yourSpace.
  ///
  /// In en, this message translates to:
  /// **'YOUR SPACE'**
  String get yourSpace;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @verifyWithSms.
  ///
  /// In en, this message translates to:
  /// **'Verify it with an SMS code'**
  String get verifyWithSms;

  /// No description provided for @verifiedTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Verified · tap to change'**
  String get verifiedTapToChange;

  /// No description provided for @profilePreferences.
  ///
  /// In en, this message translates to:
  /// **'Profile & preferences'**
  String get profilePreferences;

  /// No description provided for @makeYourselfAtHome.
  ///
  /// In en, this message translates to:
  /// **'Make yourself at home'**
  String get makeYourselfAtHome;

  /// No description provided for @privateByDefault.
  ///
  /// In en, this message translates to:
  /// **'Who sees your places'**
  String get privateByDefault;

  /// No description provided for @placesJustForYou.
  ///
  /// In en, this message translates to:
  /// **'Anyone signed in can see them'**
  String get placesJustForYou;

  /// No description provided for @privateBody.
  ///
  /// In en, this message translates to:
  /// **'Your places are saved to your account. Anyone signed in can see them on your profile, and people who follow you see them in their feed. Photos stay on this phone.'**
  String get privateBody;

  /// No description provided for @backupSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & sync'**
  String get backupSync;

  /// No description provided for @memoriesKeptSafe.
  ///
  /// In en, this message translates to:
  /// **'Your memories, kept safe'**
  String get memoriesKeptSafe;

  /// No description provided for @backupBody.
  ///
  /// In en, this message translates to:
  /// **'While you are signed in, your places are saved to your account and follow you to a new phone. Photos stay on this device for now.'**
  String get backupBody;

  /// No description provided for @aLittleHelpQ.
  ///
  /// In en, this message translates to:
  /// **'A little help?'**
  String get aLittleHelpQ;

  /// No description provided for @aLittleHelp.
  ///
  /// In en, this message translates to:
  /// **'A little help'**
  String get aLittleHelp;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the camera in the middle of the bar to snap a place and save it. Give it a name, a type and a note, and add a location to see it on the map. Open a place to edit it or find it in Maps.'**
  String get helpBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get yourNameHint;

  /// No description provided for @enterNumberWithCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your number with the country code, e.g. +90 555 123 45 67'**
  String get enterNumberWithCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {number}'**
  String codeSentTo(String number);

  /// No description provided for @enter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from the SMS'**
  String get enter6DigitCode;

  /// No description provided for @signInFirstForPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in first to add a phone number.'**
  String get signInFirstForPhone;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified'**
  String get phoneVerified;

  /// No description provided for @errInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'That phone number doesn\'t look right. Include the country code.'**
  String get errInvalidPhone;

  /// No description provided for @errInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right. Check the SMS and try again.'**
  String get errInvalidCode;

  /// No description provided for @errCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'The code expired. Tap \"Send a new code\".'**
  String get errCodeExpired;

  /// No description provided for @errNumberInUse.
  ///
  /// In en, this message translates to:
  /// **'This number is already used by another account.'**
  String get errNumberInUse;

  /// No description provided for @errAlreadyHasPhone.
  ///
  /// In en, this message translates to:
  /// **'This account already has a phone number.'**
  String get errAlreadyHasPhone;

  /// No description provided for @errTooManyAttemptsLong.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a while and try again.'**
  String get errTooManyAttemptsLong;

  /// No description provided for @errSmsQuota.
  ///
  /// In en, this message translates to:
  /// **'SMS limit reached for today. Try again later.'**
  String get errSmsQuota;

  /// No description provided for @errPhoneNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Phone sign-in is not enabled in the Firebase console (Authentication > Sign-in method > Phone).'**
  String get errPhoneNotEnabled;

  /// No description provided for @errVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed ({code}).'**
  String errVerificationFailed(String code);

  /// No description provided for @enterCodeWeSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent by SMS.'**
  String get enterCodeWeSent;

  /// No description provided for @wellTextYouCode.
  ///
  /// In en, this message translates to:
  /// **'We\'ll text you a code to verify it.'**
  String get wellTextYouCode;

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCode;

  /// No description provided for @sendNewCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Send a new code in {seconds}s'**
  String sendNewCodeIn(int seconds);

  /// No description provided for @sendNewCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get sendNewCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @smsRatesNote.
  ///
  /// In en, this message translates to:
  /// **'Standard SMS rates may apply. Your number is only used to secure your account.'**
  String get smsRatesNote;

  /// No description provided for @tabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get tabFeed;

  /// No description provided for @feedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Places from people you follow.'**
  String get feedSubtitle;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your feed is empty'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Follow people to see the places they save.'**
  String get feedEmptyBody;

  /// No description provided for @signInForFeed.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow people and see their places.'**
  String get signInForFeed;

  /// No description provided for @findPeople.
  ///
  /// In en, this message translates to:
  /// **'Find people'**
  String get findPeople;

  /// No description provided for @searchPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Search by @username or name'**
  String get searchPeopleHint;

  /// No description provided for @noPeopleFound.
  ///
  /// In en, this message translates to:
  /// **'No one found'**
  String get noPeopleFound;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @followingButton.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingButton;

  /// No description provided for @statFollowers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Follower} other{Followers}}'**
  String statFollowers(int count);

  /// No description provided for @statFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get statFollowing;

  /// No description provided for @followersTitle.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followersTitle;

  /// No description provided for @followingTitle.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingTitle;

  /// No description provided for @noFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get noFollowersYet;

  /// No description provided for @notFollowingAnyone.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone yet'**
  String get notFollowingAnyone;

  /// No description provided for @noPlacesYet.
  ///
  /// In en, this message translates to:
  /// **'No places yet'**
  String get noPlacesYet;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @chooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseUsername;

  /// No description provided for @chooseUsernameBody.
  ///
  /// In en, this message translates to:
  /// **'So friends can find and follow you.'**
  String get chooseUsernameBody;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. khalid.travels'**
  String get usernameHint;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 3–20 letters, numbers, dots or underscores.'**
  String get usernameInvalid;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is taken.'**
  String get usernameTaken;

  /// No description provided for @usernameSaved.
  ///
  /// In en, this message translates to:
  /// **'Username saved'**
  String get usernameSaved;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get somethingWentWrong;

  /// No description provided for @categoryHike.
  ///
  /// In en, this message translates to:
  /// **'Hike'**
  String get categoryHike;

  /// No description provided for @categoryHikePlural.
  ///
  /// In en, this message translates to:
  /// **'Hikes'**
  String get categoryHikePlural;

  /// No description provided for @categoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get categoryNature;

  /// No description provided for @categoryNaturePlural.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get categoryNaturePlural;

  /// No description provided for @categoryBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get categoryBeach;

  /// No description provided for @categoryBeachPlural.
  ///
  /// In en, this message translates to:
  /// **'Beaches'**
  String get categoryBeachPlural;

  /// No description provided for @categoryCamping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get categoryCamping;

  /// No description provided for @categoryCampingPlural.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get categoryCampingPlural;

  /// No description provided for @categoryNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get categoryNight;

  /// No description provided for @categoryNightPlural.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get categoryNightPlural;

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesTitle;

  /// No description provided for @badgesProgress.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} earned'**
  String badgesProgress(int earned, int total);

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'Save places to earn badges'**
  String get noBadgesYet;

  /// No description provided for @badgeEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get badgeEarned;

  /// No description provided for @badgeFirstSteps.
  ///
  /// In en, this message translates to:
  /// **'First Steps'**
  String get badgeFirstSteps;

  /// No description provided for @badgeFirstStepsHow.
  ///
  /// In en, this message translates to:
  /// **'Save your first place.'**
  String get badgeFirstStepsHow;

  /// No description provided for @badgeCityHopper.
  ///
  /// In en, this message translates to:
  /// **'City Hopper'**
  String get badgeCityHopper;

  /// No description provided for @badgeCityHopperHow.
  ///
  /// In en, this message translates to:
  /// **'Save places in 5 cities.'**
  String get badgeCityHopperHow;

  /// No description provided for @badgeGlobetrotter.
  ///
  /// In en, this message translates to:
  /// **'Globetrotter'**
  String get badgeGlobetrotter;

  /// No description provided for @badgeGlobetrotterHow.
  ///
  /// In en, this message translates to:
  /// **'Save places in 5 countries.'**
  String get badgeGlobetrotterHow;

  /// No description provided for @badgeFrequentFlyer.
  ///
  /// In en, this message translates to:
  /// **'Frequent Flyer'**
  String get badgeFrequentFlyer;

  /// No description provided for @badgeFrequentFlyerHow.
  ///
  /// In en, this message translates to:
  /// **'Save places on 3 continents.'**
  String get badgeFrequentFlyerHow;

  /// No description provided for @badgeRoadTripper.
  ///
  /// In en, this message translates to:
  /// **'Road Tripper'**
  String get badgeRoadTripper;

  /// No description provided for @badgeRoadTripperHow.
  ///
  /// In en, this message translates to:
  /// **'Save two places at least 500 km apart.'**
  String get badgeRoadTripperHow;

  /// No description provided for @badgeBackpacker.
  ///
  /// In en, this message translates to:
  /// **'Backpacker'**
  String get badgeBackpacker;

  /// No description provided for @badgeBackpackerHow.
  ///
  /// In en, this message translates to:
  /// **'Save 25 places.'**
  String get badgeBackpackerHow;

  /// No description provided for @badgeShutterbug.
  ///
  /// In en, this message translates to:
  /// **'Shutterbug'**
  String get badgeShutterbug;

  /// No description provided for @badgeShutterbugHow.
  ///
  /// In en, this message translates to:
  /// **'Add photos to 10 places.'**
  String get badgeShutterbugHow;

  /// No description provided for @badgeSummitSeeker.
  ///
  /// In en, this message translates to:
  /// **'Summit Seeker'**
  String get badgeSummitSeeker;

  /// No description provided for @badgeSummitSeekerHow.
  ///
  /// In en, this message translates to:
  /// **'Save 3 Hike places.'**
  String get badgeSummitSeekerHow;

  /// No description provided for @badgeJungleExplorer.
  ///
  /// In en, this message translates to:
  /// **'Jungle Explorer'**
  String get badgeJungleExplorer;

  /// No description provided for @badgeJungleExplorerHow.
  ///
  /// In en, this message translates to:
  /// **'Save 3 Nature places.'**
  String get badgeJungleExplorerHow;

  /// No description provided for @badgeBeachBum.
  ///
  /// In en, this message translates to:
  /// **'Beach Bum'**
  String get badgeBeachBum;

  /// No description provided for @badgeBeachBumHow.
  ///
  /// In en, this message translates to:
  /// **'Save 3 Beach places.'**
  String get badgeBeachBumHow;

  /// No description provided for @badgeHappyCamper.
  ///
  /// In en, this message translates to:
  /// **'Happy Camper'**
  String get badgeHappyCamper;

  /// No description provided for @badgeHappyCamperHow.
  ///
  /// In en, this message translates to:
  /// **'Save 3 Camping places.'**
  String get badgeHappyCamperHow;

  /// No description provided for @badgeStargazer.
  ///
  /// In en, this message translates to:
  /// **'Stargazer'**
  String get badgeStargazer;

  /// No description provided for @badgeStargazerHow.
  ///
  /// In en, this message translates to:
  /// **'Save 3 Night places.'**
  String get badgeStargazerHow;
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
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
