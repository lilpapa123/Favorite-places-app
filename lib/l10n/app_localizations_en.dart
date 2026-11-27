// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Viaggio';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get undo => 'Undo';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get optional => 'Optional';

  @override
  String get noConnection =>
      'No connection. Check your internet and try again.';

  @override
  String get locationServicesOff =>
      'Location services are off. Turn them on in Settings.';

  @override
  String couldNotGetLocation(String error) {
    return 'Could not get your location: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Make the app feel like yours.';

  @override
  String get settingsRowSubtitle => 'Appearance and language';

  @override
  String get appearance => 'APPEARANCE';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'LANGUAGE';

  @override
  String get languageSystem => 'Same as phone';

  @override
  String get categoryCafe => 'Café';

  @override
  String get categoryCafePlural => 'Cafés';

  @override
  String get categoryViewpoint => 'Viewpoint';

  @override
  String get categoryViewpointPlural => 'Views';

  @override
  String get categoryWalk => 'Walk';

  @override
  String get categoryWalkPlural => 'Walks';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryOtherPlural => 'Other';

  @override
  String get tabMyPlaces => 'My places';

  @override
  String get tabMap => 'Map';

  @override
  String get tabAccount => 'Account';

  @override
  String get takePhotoOfPlace => 'Take a photo of a place';

  @override
  String get noCameraChoosePhoto =>
      'No camera on this device - choose a photo instead.';

  @override
  String get savedToMyPlaces => 'Saved to My places';

  @override
  String get tapMapToDropPin => 'Tap the map to drop a pin';

  @override
  String get useThisSpot => 'Use this spot';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortName => 'Name, A to Z';

  @override
  String get sortPlaces => 'Sort places';

  @override
  String favoritePlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count favorite places',
      one: '1 favorite place',
    );
    return '$_temp0';
  }

  @override
  String get findFavoritePlace => 'Find a favorite place';

  @override
  String allCount(int count) {
    return 'All · $count';
  }

  @override
  String get noPlacesMatch => 'No places match';

  @override
  String get tryAnotherWord => 'Try another word or type.';

  @override
  String get showAllPlaces => 'Show all places';

  @override
  String get typeOfPlace => 'Type of place';

  @override
  String get noFavoritesYet => 'No favorite places yet';

  @override
  String get noFavoritesBody =>
      'Add a place with a photo, and it will show up here.';

  @override
  String get addAPlace => 'Add a place';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get onMap => 'On map';

  @override
  String get osmCredit => '© OpenStreetMap contributors';

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get editPlace => 'Edit place';

  @override
  String get addPlace => 'Add place';

  @override
  String get editPlaceSubtitle => 'Change anything you like.';

  @override
  String get addPlaceSubtitle => 'Keep a little piece of somewhere.';

  @override
  String get placeName => 'Place name';

  @override
  String get placeNameHint => 'A little pause by the river';

  @override
  String get littleNote => 'A little note';

  @override
  String get littleNoteHint => 'Why you love it, in a line or two';

  @override
  String get onlyYouCanSee => 'People who follow you will see this place.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get savePlace => 'Save place';

  @override
  String get removedFromMyPlaces => 'Removed from My places';

  @override
  String get removeFromMyPlaces => 'Remove from my places';

  @override
  String get couldNotOpenMaps => 'Could not open Maps';

  @override
  String get savedPlace => 'Saved place';

  @override
  String get morePlaceActions => 'More place actions';

  @override
  String savedOn(String date) {
    return 'Saved on $date';
  }

  @override
  String get myLittleNote => 'MY LITTLE NOTE';

  @override
  String get noLocationYet => 'No location yet — add one with Edit place.';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String couldNotFindQuery(String query) {
    return 'Couldn\'t find \"$query\". Try a city or full address.';
  }

  @override
  String get allowLocationToSee =>
      'Allow location access to see where you are.';

  @override
  String cityCount(String city, int count) {
    return '$city · $count';
  }

  @override
  String pinnedCount(int count) {
    return '$count pinned';
  }

  @override
  String get searchPlacesOrCities => 'Search places or cities';

  @override
  String get closeSearch => 'Close search';

  @override
  String get mapSubtitle => 'Favorite places from everyone.';

  @override
  String get noPinsYet => 'No pins yet';

  @override
  String get noPinsBody => 'Add a place with a location\nand it shows up here.';

  @override
  String get centerOnMyLocation => 'Center on my location';

  @override
  String get viewPlace => 'View place';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromLibrary => 'Choose from library';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get addPhotoHint => 'Take one or choose from library';

  @override
  String get addPhotoNote => 'Optional, but full of memories.';

  @override
  String get errNoCamera =>
      'This device has no camera. Simulators have no camera - choose a photo from the library, or use a real phone.';

  @override
  String get errCameraDenied =>
      'Camera access was denied. Allow it in Settings > Viaggio.';

  @override
  String get errPhotosDenied =>
      'Photo library access was denied. Allow it in Settings > Viaggio.';

  @override
  String get errCameraRestricted =>
      'Camera access is restricted on this device (Screen Time or an MDM profile is blocking it).';

  @override
  String get errPickerOpen =>
      'The picker is already open. Close it and try again.';

  @override
  String errCouldNotGetPhoto(String details) {
    return 'Could not get a photo: $details';
  }

  @override
  String get whereIsIt => 'Where is it?';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get pickOnMap => 'Pick on the map';

  @override
  String get removeLocation => 'Remove location';

  @override
  String get locationPermissionDenied => 'Location permission was denied.';

  @override
  String get locationBlocked =>
      'Location access is blocked. Allow it in Settings > Viaggio, or pick the spot on the map instead.';

  @override
  String get findingSpot => 'Finding the spot…';

  @override
  String get takesASecond => 'This takes a second';

  @override
  String get addLocation => 'Add a location';

  @override
  String get addLocationHint => 'Use where you are, or pick on the map';

  @override
  String get location => 'Location';

  @override
  String locationSemantic(String title) {
    return 'Location: $title';
  }

  @override
  String signInUnavailable(String error) {
    return 'Sign-in is unavailable right now.\n$error';
  }

  @override
  String get enterEmailPassword => 'Enter your email and password';

  @override
  String get typeEmailFirst =>
      'Type your email first, then tap \"Forgot password\"';

  @override
  String resetLinkSent(String email) {
    return 'Reset link sent to $email';
  }

  @override
  String get errInvalidEmail => 'That email address is not valid.';

  @override
  String get errUserDisabled => 'This account has been disabled.';

  @override
  String get errWrongCredentials => 'Wrong email or password.';

  @override
  String get errEmailInUse =>
      'An account already exists for that email. Sign in instead.';

  @override
  String get errWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get errTooManyAttempts =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get errEmailNotEnabled =>
      'Email sign-in is not enabled in the Firebase console (Authentication > Sign-in method).';

  @override
  String errSignInFailed(String code) {
    return 'Sign-in failed ($code).';
  }

  @override
  String get createAccount => 'Create account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signUpSubtitle => 'Sign up to keep your places with you';

  @override
  String get signInSubtitle => 'Sign in to your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get atLeast6Chars => 'At least 6 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get newHere => 'New here?';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get placesStayOnPhone =>
      'Sign in to share your places and follow friends.';

  @override
  String get you => 'You';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get accountSubtitle => 'A small collection, all yours.';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String statPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Places',
      one: 'Place',
    );
    return '$_temp0';
  }

  @override
  String get yourSpace => 'YOUR SPACE';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get verifyWithSms => 'Verify it with an SMS code';

  @override
  String get verifiedTapToChange => 'Verified · tap to change';

  @override
  String get profilePreferences => 'Profile & preferences';

  @override
  String get makeYourselfAtHome => 'Make yourself at home';

  @override
  String get privateByDefault => 'Who sees your places';

  @override
  String get placesJustForYou => 'Anyone signed in can see them';

  @override
  String get privateBody =>
      'Your places are saved to your account. Anyone signed in can see them on your profile, and people who follow you see them in their feed. Photos stay on this phone.';

  @override
  String get backupSync => 'Backup & sync';

  @override
  String get memoriesKeptSafe => 'Your memories, kept safe';

  @override
  String get backupBody =>
      'While you are signed in, your places are saved to your account and follow you to a new phone. Photos stay on this device for now.';

  @override
  String get aLittleHelpQ => 'A little help?';

  @override
  String get aLittleHelp => 'A little help';

  @override
  String get helpBody =>
      'Tap the camera in the middle of the bar to snap a place and save it. Give it a name, a type and a note, and add a location to see it on the map. Open a place to edit it or find it in Maps.';

  @override
  String get signOut => 'Sign out';

  @override
  String get yourName => 'Your name';

  @override
  String get yourNameHint => 'How should we call you?';

  @override
  String get enterNumberWithCode =>
      'Enter your number with the country code, e.g. +90 555 123 45 67';

  @override
  String codeSentTo(String number) {
    return 'Code sent to $number';
  }

  @override
  String get enter6DigitCode => 'Enter the 6-digit code from the SMS';

  @override
  String get signInFirstForPhone => 'Sign in first to add a phone number.';

  @override
  String get phoneVerified => 'Phone number verified';

  @override
  String get errInvalidPhone =>
      'That phone number doesn\'t look right. Include the country code.';

  @override
  String get errInvalidCode =>
      'That code isn\'t right. Check the SMS and try again.';

  @override
  String get errCodeExpired => 'The code expired. Tap \"Send a new code\".';

  @override
  String get errNumberInUse =>
      'This number is already used by another account.';

  @override
  String get errAlreadyHasPhone => 'This account already has a phone number.';

  @override
  String get errTooManyAttemptsLong =>
      'Too many attempts. Wait a while and try again.';

  @override
  String get errSmsQuota => 'SMS limit reached for today. Try again later.';

  @override
  String get errPhoneNotEnabled =>
      'Phone sign-in is not enabled in the Firebase console (Authentication > Sign-in method > Phone).';

  @override
  String errVerificationFailed(String code) {
    return 'Verification failed ($code).';
  }

  @override
  String get enterCodeWeSent => 'Enter the code we sent by SMS.';

  @override
  String get wellTextYouCode => 'We\'ll text you a code to verify it.';

  @override
  String get sixDigitCode => '6-digit code';

  @override
  String sendNewCodeIn(int seconds) {
    return 'Send a new code in ${seconds}s';
  }

  @override
  String get sendNewCode => 'Send a new code';

  @override
  String get verify => 'Verify';

  @override
  String get sendCode => 'Send code';

  @override
  String get smsRatesNote =>
      'Standard SMS rates may apply. Your number is only used to secure your account.';

  @override
  String get tabFeed => 'Feed';

  @override
  String get feedSubtitle => 'Places from people you follow.';

  @override
  String get feedEmptyTitle => 'Your feed is empty';

  @override
  String get feedEmptyBody => 'Follow people to see the places they save.';

  @override
  String get signInForFeed => 'Sign in to follow people and see their places.';

  @override
  String get findPeople => 'Find people';

  @override
  String get searchPeopleHint => 'Search by @username or name';

  @override
  String get noPeopleFound => 'No one found';

  @override
  String get follow => 'Follow';

  @override
  String get followingButton => 'Following';

  @override
  String statFollowers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Followers',
      one: 'Follower',
    );
    return '$_temp0';
  }

  @override
  String get statFollowing => 'Following';

  @override
  String get followersTitle => 'Followers';

  @override
  String get followingTitle => 'Following';

  @override
  String get noFollowersYet => 'No followers yet';

  @override
  String get notFollowingAnyone => 'Not following anyone yet';

  @override
  String get noPlacesYet => 'No places yet';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'e.g. khalid.travels';

  @override
  String get usernameInvalid =>
      'Use 3–20 letters, numbers, dots or underscores.';

  @override
  String get usernameTaken => 'That username is taken.';

  @override
  String get somethingWentWrong =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get categoryHike => 'Hike';

  @override
  String get categoryHikePlural => 'Hikes';

  @override
  String get categoryNature => 'Nature';

  @override
  String get categoryNaturePlural => 'Nature';

  @override
  String get categoryBeach => 'Beach';

  @override
  String get categoryBeachPlural => 'Beaches';

  @override
  String get categoryCamping => 'Camping';

  @override
  String get categoryCampingPlural => 'Camping';

  @override
  String get categoryNight => 'Night';

  @override
  String get categoryNightPlural => 'Night';

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgesProgress(int earned, int total) {
    return '$earned of $total earned';
  }

  @override
  String get noBadgesYet => 'Save places to earn badges';

  @override
  String get badgeEarned => 'Earned';

  @override
  String get badgeFirstSteps => 'First Steps';

  @override
  String get badgeFirstStepsHow => 'Save your first place.';

  @override
  String get badgeCityHopper => 'City Hopper';

  @override
  String get badgeCityHopperHow => 'Save places in 5 cities.';

  @override
  String get badgeGlobetrotter => 'Globetrotter';

  @override
  String get badgeGlobetrotterHow => 'Save places in 5 countries.';

  @override
  String get badgeFrequentFlyer => 'Frequent Flyer';

  @override
  String get badgeFrequentFlyerHow => 'Save places on 3 continents.';

  @override
  String get badgeRoadTripper => 'Road Tripper';

  @override
  String get badgeRoadTripperHow => 'Save two places at least 500 km apart.';

  @override
  String get badgeBackpacker => 'Backpacker';

  @override
  String get badgeBackpackerHow => 'Save 25 places.';

  @override
  String get badgeShutterbug => 'Shutterbug';

  @override
  String get badgeShutterbugHow => 'Add photos to 10 places.';

  @override
  String get badgeSummitSeeker => 'Summit Seeker';

  @override
  String get badgeSummitSeekerHow => 'Save 3 Hike places.';

  @override
  String get badgeJungleExplorer => 'Jungle Explorer';

  @override
  String get badgeJungleExplorerHow => 'Save 3 Nature places.';

  @override
  String get badgeBeachBum => 'Beach Bum';

  @override
  String get badgeBeachBumHow => 'Save 3 Beach places.';

  @override
  String get badgeHappyCamper => 'Happy Camper';

  @override
  String get badgeHappyCamperHow => 'Save 3 Camping places.';

  @override
  String get badgeStargazer => 'Stargazer';

  @override
  String get badgeStargazerHow => 'Save 3 Night places.';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'A few words about you';

  @override
  String get photoOnThisPhone =>
      'Your photo is only shown on this phone for now.';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileSaveFailed =>
      'Couldn\'t save your profile. Please try again.';

  @override
  String get usernameRequired => 'Enter a username.';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String get chooseUsernameBody => 'So friends can find and follow you.';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get discoverSubtitle => 'Favorite places people recommend.';

  @override
  String get signInForDiscover => 'Sign in to see the places people share.';

  @override
  String get discoverEmptyTitle => 'Nothing shared yet';

  @override
  String get discoverEmptyBody => 'Places other people save will show up here.';

  @override
  String get yourPlaces => 'YOUR PLACES';

  @override
  String get seeAll => 'See all';

  @override
  String get noPlacesYetHint => 'No places yet. Tap the camera to add one.';

  @override
  String get addMorePhotos => 'Add more photos';

  @override
  String agoMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String agoHours(int count) {
    return '${count}h ago';
  }

  @override
  String agoDays(int count) {
    return '${count}d ago';
  }

  @override
  String get menu => 'Menu';

  @override
  String get comments => 'Comments';

  @override
  String get addComment => 'Add a comment';

  @override
  String get noCommentsYet => 'No comments yet. Be the first.';

  @override
  String get signInToComment => 'Sign in to comment.';

  @override
  String get sendComment => 'Send';

  @override
  String get share => 'Share';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get shareToApps => 'Share to other apps';

  @override
  String get message => 'Message';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get writeMessage => 'Message…';

  @override
  String get newMessage => 'New message';

  @override
  String get newGroup => 'New group';

  @override
  String get groupNameHint => 'Group name (optional)';

  @override
  String get createGroup => 'Create group';

  @override
  String groupCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String get peopleYouFollow => 'People you follow';

  @override
  String groupLimit(int max) {
    return 'Up to $max people, you included.';
  }

  @override
  String get signInToMessage => 'Sign in to message people.';

  @override
  String get groupPhoto => 'Group photo';

  @override
  String get editGroupName => 'Edit group name';

  @override
  String groupMembers(int count) {
    return '$count members';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get groupAdmin => 'Admin';

  @override
  String get removeFromGroup => 'Remove';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from the group?';
  }

  @override
  String get sendTo => 'Send to';

  @override
  String get send => 'Send';

  @override
  String get postSent => 'Sent';

  @override
  String get filterPlaces => 'Filter';

  @override
  String get splashTagline => 'Save the places you love';

  @override
  String get factSaved => 'Saved';

  @override
  String get factPhotos => 'Photos';

  @override
  String get factVisibleTo => 'Visible to';

  @override
  String get visibleToEveryone => 'Everyone';

  @override
  String get directions => 'Directions';

  @override
  String get pickSomeoneToSend => 'Pick someone to send to';

  @override
  String sendToName(String name) {
    return 'Send to $name';
  }

  @override
  String sendToCount(int count) {
    return 'Send to $count people';
  }

  @override
  String byOwner(String name) {
    return 'by $name';
  }

  @override
  String get settingsFooter => 'Made for people who wander.';

  @override
  String get languageAutoCode => 'Auto';

  @override
  String placesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places saved',
      one: '1 place saved',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'Edit';

  @override
  String get secureStep => 'Secure step';

  @override
  String get checkYourMessages => 'Check your messages';

  @override
  String weSentCodeTo(String number) {
    return 'We sent a 6-digit code to $number.';
  }

  @override
  String get change => 'Change';

  @override
  String get enterAll6Digits => 'Enter all 6 digits';

  @override
  String get deleteDigit => 'Delete digit';

  @override
  String get messagesSubtitle => 'Chats with people you follow.';

  @override
  String get chats => 'Chats';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get phoneLanguage => 'Phone';
}
