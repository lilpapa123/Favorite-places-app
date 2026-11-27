// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Viaggio';

  @override
  String get close => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String get undo => 'تراجع';

  @override
  String get pleaseWait => 'يرجى الانتظار...';

  @override
  String get optional => 'اختياري';

  @override
  String get noConnection => 'لا يوجد اتصال. تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  String get locationServicesOff => 'خدمات الموقع متوقفة. فعّلها من الإعدادات.';

  @override
  String couldNotGetLocation(String error) {
    return 'تعذّر تحديد موقعك: $error';
  }

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSubtitle => 'اجعل التطبيق يناسبك.';

  @override
  String get settingsRowSubtitle => 'المظهر واللغة';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'مثل الهاتف';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'مثل الهاتف';

  @override
  String get categoryCafe => 'مقهى';

  @override
  String get categoryCafePlural => 'مقاهٍ';

  @override
  String get categoryViewpoint => 'إطلالة';

  @override
  String get categoryViewpointPlural => 'إطلالات';

  @override
  String get categoryWalk => 'نزهة';

  @override
  String get categoryWalkPlural => 'نزهات';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get categoryOtherPlural => 'أخرى';

  @override
  String get tabMyPlaces => 'أماكني';

  @override
  String get tabMap => 'الخريطة';

  @override
  String get tabAccount => 'الحساب';

  @override
  String get takePhotoOfPlace => 'التقط صورة لمكان';

  @override
  String get noCameraChoosePhoto =>
      'لا توجد كاميرا على هذا الجهاز - اختر صورة بدلاً من ذلك.';

  @override
  String get savedToMyPlaces => 'حُفظ في أماكني';

  @override
  String get tapMapToDropPin => 'اضغط على الخريطة لوضع دبوس';

  @override
  String get useThisSpot => 'استخدم هذا المكان';

  @override
  String get sortNewest => 'الأحدث أولاً';

  @override
  String get sortOldest => 'الأقدم أولاً';

  @override
  String get sortName => 'الاسم، أ إلى ي';

  @override
  String get sortPlaces => 'ترتيب الأماكن';

  @override
  String favoritePlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان مفضل',
      many: '$count مكانًا مفضلاً',
      few: '$count أماكن مفضلة',
      two: 'مكانان مفضلان',
      one: 'مكان مفضل واحد',
      zero: 'لا أماكن مفضلة',
    );
    return '$_temp0';
  }

  @override
  String get findFavoritePlace => 'ابحث عن مكان مفضل';

  @override
  String allCount(int count) {
    return 'الكل · $count';
  }

  @override
  String get noPlacesMatch => 'لا توجد أماكن مطابقة';

  @override
  String get tryAnotherWord => 'جرّب كلمة أو نوعًا آخر.';

  @override
  String get showAllPlaces => 'عرض كل الأماكن';

  @override
  String get typeOfPlace => 'نوع المكان';

  @override
  String get noFavoritesYet => 'لا توجد أماكن مفضلة بعد';

  @override
  String get noFavoritesBody => 'أضف مكانًا مع صورة وسيظهر هنا.';

  @override
  String get addAPlace => 'أضف مكانًا';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get onMap => 'على الخريطة';

  @override
  String get osmCredit => '© مساهمو OpenStreetMap';

  @override
  String get changesSaved => 'تم حفظ التغييرات';

  @override
  String get editPlace => 'تعديل المكان';

  @override
  String get addPlace => 'إضافة مكان';

  @override
  String get editPlaceSubtitle => 'غيّر ما تريد.';

  @override
  String get addPlaceSubtitle => 'احتفظ بقطعة صغيرة من مكانٍ ما.';

  @override
  String get placeName => 'اسم المكان';

  @override
  String get placeNameHint => 'استراحة صغيرة عند النهر';

  @override
  String get littleNote => 'ملاحظة صغيرة';

  @override
  String get littleNoteHint => 'لماذا تحبه، في سطر أو سطرين';

  @override
  String get onlyYouCanSee => 'سيرى متابعوك هذا المكان.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get savePlace => 'حفظ المكان';

  @override
  String get removedFromMyPlaces => 'أُزيل من أماكني';

  @override
  String get removeFromMyPlaces => 'إزالة من أماكني';

  @override
  String get couldNotOpenMaps => 'تعذّر فتح الخرائط';

  @override
  String get savedPlace => 'مكان محفوظ';

  @override
  String get morePlaceActions => 'إجراءات أخرى للمكان';

  @override
  String savedOn(String date) {
    return 'حُفظ في $date';
  }

  @override
  String get myLittleNote => 'ملاحظتي الصغيرة';

  @override
  String get noLocationYet => 'لا يوجد موقع بعد — أضفه من تعديل المكان.';

  @override
  String get openInMaps => 'فتح في الخرائط';

  @override
  String couldNotFindQuery(String query) {
    return 'تعذّر العثور على \"$query\". جرّب مدينة أو عنوانًا كاملاً.';
  }

  @override
  String get allowLocationToSee => 'اسمح بالوصول إلى الموقع لرؤية مكانك.';

  @override
  String cityCount(String city, int count) {
    return '$city · $count';
  }

  @override
  String pinnedCount(int count) {
    return '$count مثبتة';
  }

  @override
  String get searchPlacesOrCities => 'ابحث عن أماكن أو مدن';

  @override
  String get closeSearch => 'إغلاق البحث';

  @override
  String get mapSubtitle => 'أماكن مفضلة من الجميع.';

  @override
  String get noPinsYet => 'لا توجد دبابيس بعد';

  @override
  String get noPinsBody => 'أضف مكانًا مع موقع\nوسيظهر هنا.';

  @override
  String get centerOnMyLocation => 'التوسيط على موقعي';

  @override
  String get viewPlace => 'عرض المكان';

  @override
  String get choosePhoto => 'اختر صورة';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get chooseFromLibrary => 'اختر من المكتبة';

  @override
  String get addPhoto => 'أضف صورة';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get addPhotoHint => 'التقط صورة أو اختر من المكتبة';

  @override
  String get addPhotoNote => 'اختياري، لكنه مليء بالذكريات.';

  @override
  String get errNoCamera =>
      'هذا الجهاز لا يحتوي على كاميرا. المحاكيات بلا كاميرا - اختر صورة من المكتبة أو استخدم هاتفًا حقيقيًا.';

  @override
  String get errCameraDenied =>
      'تم رفض الوصول إلى الكاميرا. اسمح به من الإعدادات > Viaggio.';

  @override
  String get errPhotosDenied =>
      'تم رفض الوصول إلى مكتبة الصور. اسمح به من الإعدادات > Viaggio.';

  @override
  String get errCameraRestricted =>
      'الوصول إلى الكاميرا مقيّد على هذا الجهاز (مدة استخدام الجهاز أو ملف تعريف إدارة يمنعه).';

  @override
  String get errPickerOpen =>
      'أداة الاختيار مفتوحة بالفعل. أغلقها وحاول مرة أخرى.';

  @override
  String errCouldNotGetPhoto(String details) {
    return 'تعذّر الحصول على صورة: $details';
  }

  @override
  String get whereIsIt => 'أين يقع؟';

  @override
  String get useMyLocation => 'استخدم موقعي';

  @override
  String get pickOnMap => 'اختر على الخريطة';

  @override
  String get removeLocation => 'إزالة الموقع';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get locationBlocked =>
      'الوصول إلى الموقع محظور. اسمح به من الإعدادات > Viaggio، أو اختر المكان على الخريطة.';

  @override
  String get findingSpot => 'جارٍ تحديد المكان…';

  @override
  String get takesASecond => 'يستغرق ذلك ثانية';

  @override
  String get addLocation => 'أضف موقعًا';

  @override
  String get addLocationHint => 'استخدم مكانك الحالي أو اختر على الخريطة';

  @override
  String get location => 'الموقع';

  @override
  String locationSemantic(String title) {
    return 'الموقع: $title';
  }

  @override
  String signInUnavailable(String error) {
    return 'تسجيل الدخول غير متاح الآن.\n$error';
  }

  @override
  String get enterEmailPassword => 'أدخل بريدك الإلكتروني وكلمة المرور';

  @override
  String get typeEmailFirst =>
      'اكتب بريدك الإلكتروني أولاً ثم اضغط \"نسيت كلمة المرور\"';

  @override
  String resetLinkSent(String email) {
    return 'أُرسل رابط إعادة التعيين إلى $email';
  }

  @override
  String get errInvalidEmail => 'عنوان البريد الإلكتروني غير صالح.';

  @override
  String get errUserDisabled => 'تم تعطيل هذا الحساب.';

  @override
  String get errWrongCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errEmailInUse =>
      'يوجد حساب بهذا البريد الإلكتروني بالفعل. سجّل الدخول بدلاً من ذلك.';

  @override
  String get errWeakPassword =>
      'كلمة المرور ضعيفة جدًا. استخدم 6 أحرف على الأقل.';

  @override
  String get errTooManyAttempts =>
      'محاولات كثيرة جدًا. انتظر قليلاً وحاول مرة أخرى.';

  @override
  String get errEmailNotEnabled =>
      'تسجيل الدخول بالبريد الإلكتروني غير مفعّل في لوحة Firebase (Authentication > Sign-in method).';

  @override
  String errSignInFailed(String code) {
    return 'فشل تسجيل الدخول ($code).';
  }

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get signUpSubtitle => 'سجّل لتبقى أماكنك معك';

  @override
  String get signInSubtitle => 'سجّل الدخول إلى حسابك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get atLeast6Chars => '6 أحرف على الأقل';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get newHere => 'جديد هنا؟';

  @override
  String get createAnAccount => 'أنشئ حسابًا';

  @override
  String get placesStayOnPhone => 'سجّل الدخول لمشاركة أماكنك ومتابعة أصدقائك.';

  @override
  String get you => 'أنت';

  @override
  String get profilePhoto => 'صورة الملف الشخصي';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get accountSubtitle => 'مجموعة صغيرة، كلها لك.';

  @override
  String get changeProfilePhoto => 'تغيير صورة الملف الشخصي';

  @override
  String statPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مكان',
      few: 'أماكن',
      two: 'مكانان',
      one: 'مكان',
    );
    return '$_temp0';
  }

  @override
  String get yourSpace => 'مساحتك';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get verifyWithSms => 'تحقق منه برمز SMS';

  @override
  String get verifiedTapToChange => 'موثّق · اضغط للتغيير';

  @override
  String get profilePreferences => 'الملف الشخصي والتفضيلات';

  @override
  String get makeYourselfAtHome => 'خذ راحتك';

  @override
  String get privateByDefault => 'من يرى أماكنك';

  @override
  String get placesJustForYou => 'يمكن لأي مستخدم مسجّل رؤيتها';

  @override
  String get privateBody =>
      'تُحفظ أماكنك في حسابك. يمكن لأي مستخدم مسجّل رؤيتها في ملفك الشخصي، ويراها متابعوك في صفحتهم. تبقى الصور على هذا الهاتف.';

  @override
  String get backupSync => 'النسخ الاحتياطي والمزامنة';

  @override
  String get memoriesKeptSafe => 'ذكرياتك في أمان';

  @override
  String get backupBody =>
      'أثناء تسجيل الدخول تُحفظ أماكنك في حسابك وتنتقل معك إلى هاتف جديد. تبقى الصور على هذا الجهاز حاليًا.';

  @override
  String get aLittleHelpQ => 'تحتاج مساعدة؟';

  @override
  String get aLittleHelp => 'مساعدة صغيرة';

  @override
  String get helpBody =>
      'اضغط على الكاميرا في منتصف الشريط لالتقاط مكان وحفظه. أعطه اسمًا ونوعًا وملاحظة، وأضف موقعًا لتراه على الخريطة. افتح مكانًا لتعديله أو العثور عليه في الخرائط.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get yourName => 'اسمك';

  @override
  String get yourNameHint => 'بماذا نناديك؟';

  @override
  String get enterNumberWithCode =>
      'أدخل رقمك مع رمز الدولة، مثل +90 555 123 45 67';

  @override
  String codeSentTo(String number) {
    return 'أُرسل الرمز إلى $number';
  }

  @override
  String get enter6DigitCode => 'أدخل الرمز المكوّن من 6 أرقام من الرسالة';

  @override
  String get signInFirstForPhone => 'سجّل الدخول أولاً لإضافة رقم هاتف.';

  @override
  String get phoneVerified => 'تم التحقق من رقم الهاتف';

  @override
  String get errInvalidPhone => 'رقم الهاتف لا يبدو صحيحًا. أضف رمز الدولة.';

  @override
  String get errInvalidCode =>
      'الرمز غير صحيح. تحقق من الرسالة وحاول مرة أخرى.';

  @override
  String get errCodeExpired => 'انتهت صلاحية الرمز. اضغط \"إرسال رمز جديد\".';

  @override
  String get errNumberInUse => 'هذا الرقم مستخدم بالفعل في حساب آخر.';

  @override
  String get errAlreadyHasPhone => 'هذا الحساب لديه رقم هاتف بالفعل.';

  @override
  String get errTooManyAttemptsLong =>
      'محاولات كثيرة جدًا. انتظر فترة وحاول مرة أخرى.';

  @override
  String get errSmsQuota => 'تم بلوغ حد الرسائل لهذا اليوم. حاول لاحقًا.';

  @override
  String get errPhoneNotEnabled =>
      'تسجيل الدخول بالهاتف غير مفعّل في لوحة Firebase (Authentication > Sign-in method > Phone).';

  @override
  String errVerificationFailed(String code) {
    return 'فشل التحقق ($code).';
  }

  @override
  String get enterCodeWeSent => 'أدخل الرمز الذي أرسلناه برسالة SMS.';

  @override
  String get wellTextYouCode => 'سنرسل إليك رمزًا للتحقق منه.';

  @override
  String get sixDigitCode => 'رمز من 6 أرقام';

  @override
  String sendNewCodeIn(int seconds) {
    return 'إرسال رمز جديد بعد $seconds ث';
  }

  @override
  String get sendNewCode => 'إرسال رمز جديد';

  @override
  String get verify => 'تحقق';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get smsRatesNote =>
      'قد تُطبّق رسوم الرسائل القياسية. يُستخدم رقمك فقط لتأمين حسابك.';

  @override
  String get tabFeed => 'الخلاصة';

  @override
  String get feedSubtitle => 'أماكن من الأشخاص الذين تتابعهم.';

  @override
  String get feedEmptyTitle => 'صفحتك فارغة';

  @override
  String get feedEmptyBody => 'تابع أشخاصًا لترى الأماكن التي يحفظونها.';

  @override
  String get signInForFeed => 'سجّل الدخول لمتابعة الأشخاص ورؤية أماكنهم.';

  @override
  String get findPeople => 'ابحث عن أشخاص';

  @override
  String get searchPeopleHint => 'ابحث باسم المستخدم @ أو الاسم';

  @override
  String get noPeopleFound => 'لم يُعثر على أحد';

  @override
  String get follow => 'متابعة';

  @override
  String get followingButton => 'تتابعه';

  @override
  String statFollowers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متابِع',
      few: 'متابِعون',
      two: 'متابِعان',
      one: 'متابِع',
    );
    return '$_temp0';
  }

  @override
  String get statFollowing => 'يتابع';

  @override
  String get followersTitle => 'المتابِعون';

  @override
  String get followingTitle => 'يتابع';

  @override
  String get noFollowersYet => 'لا متابِعين بعد';

  @override
  String get notFollowingAnyone => 'لا يتابع أحدًا بعد';

  @override
  String get noPlacesYet => 'لا أماكن بعد';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameHint => 'مثل khalid.travels';

  @override
  String get usernameInvalid =>
      'استخدم من 3 إلى 20 حرفًا أو رقمًا أو نقطة أو شرطة سفلية.';

  @override
  String get usernameTaken => 'اسم المستخدم هذا مأخوذ.';

  @override
  String get somethingWentWrong => 'حدث خطأ. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get categoryHike => 'تسلّق';

  @override
  String get categoryHikePlural => 'تسلّق';

  @override
  String get categoryNature => 'طبيعة';

  @override
  String get categoryNaturePlural => 'طبيعة';

  @override
  String get categoryBeach => 'شاطئ';

  @override
  String get categoryBeachPlural => 'شواطئ';

  @override
  String get categoryCamping => 'تخييم';

  @override
  String get categoryCampingPlural => 'تخييم';

  @override
  String get categoryNight => 'ليلي';

  @override
  String get categoryNightPlural => 'ليلي';

  @override
  String get badgesTitle => 'الشارات';

  @override
  String badgesProgress(int earned, int total) {
    return 'حصلت على $earned من $total';
  }

  @override
  String get noBadgesYet => 'احفظ أماكن لتحصل على شارات';

  @override
  String get badgeEarned => 'مكتسبة';

  @override
  String get badgeFirstSteps => 'الخطوات الأولى';

  @override
  String get badgeFirstStepsHow => 'احفظ أول مكان لك.';

  @override
  String get badgeCityHopper => 'متنقّل بين المدن';

  @override
  String get badgeCityHopperHow => 'احفظ أماكن في 5 مدن.';

  @override
  String get badgeGlobetrotter => 'رحّالة العالم';

  @override
  String get badgeGlobetrotterHow => 'احفظ أماكن في 5 دول.';

  @override
  String get badgeFrequentFlyer => 'مسافر دائم';

  @override
  String get badgeFrequentFlyerHow => 'احفظ أماكن في 3 قارات.';

  @override
  String get badgeRoadTripper => 'عاشق الطرق';

  @override
  String get badgeRoadTripperHow => 'احفظ مكانين تفصل بينهما 500 كم على الأقل.';

  @override
  String get badgeBackpacker => 'حامل الحقيبة';

  @override
  String get badgeBackpackerHow => 'احفظ 25 مكانًا.';

  @override
  String get badgeShutterbug => 'عاشق التصوير';

  @override
  String get badgeShutterbugHow => 'أضف صورًا إلى 10 أماكن.';

  @override
  String get badgeSummitSeeker => 'باحث القمم';

  @override
  String get badgeSummitSeekerHow => 'احفظ 3 أماكن من نوع تسلّق.';

  @override
  String get badgeJungleExplorer => 'مستكشف الأدغال';

  @override
  String get badgeJungleExplorerHow => 'احفظ 3 أماكن من نوع طبيعة.';

  @override
  String get badgeBeachBum => 'عاشق الشاطئ';

  @override
  String get badgeBeachBumHow => 'احفظ 3 أماكن من نوع شاطئ.';

  @override
  String get badgeHappyCamper => 'المخيّم السعيد';

  @override
  String get badgeHappyCamperHow => 'احفظ 3 أماكن من نوع تخييم.';

  @override
  String get badgeStargazer => 'راصد النجوم';

  @override
  String get badgeStargazerHow => 'احفظ 3 أماكن من نوع ليلي.';

  @override
  String get bio => 'نبذة';

  @override
  String get bioHint => 'بضع كلمات عنك';

  @override
  String get photoOnThisPhone => 'تظهر صورتك على هذا الهاتف فقط حاليًا.';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get profileSaveFailed => 'تعذّر حفظ ملفك الشخصي. حاول مرة أخرى.';

  @override
  String get usernameRequired => 'أدخل اسم مستخدم.';

  @override
  String get chooseUsername => 'اختر اسم مستخدم';

  @override
  String get chooseUsernameBody => 'ليجدك أصدقاؤك ويتابعوك.';

  @override
  String get tabDiscover => 'اكتشف';

  @override
  String get discoverSubtitle => 'أماكن مفضلة يوصي بها الناس.';

  @override
  String get signInForDiscover =>
      'سجّل الدخول لترى الأماكن التي يشاركها الناس.';

  @override
  String get discoverEmptyTitle => 'لا شيء مُشارك بعد';

  @override
  String get discoverEmptyBody => 'ستظهر هنا الأماكن التي يحفظها الآخرون.';

  @override
  String get yourPlaces => 'أماكنك';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get noPlacesYetHint => 'لا أماكن بعد. اضغط على الكاميرا لإضافة مكان.';

  @override
  String get addMorePhotos => 'إضافة المزيد من الصور';

  @override
  String agoMinutes(int count) {
    return 'قبل $count د';
  }

  @override
  String agoHours(int count) {
    return 'قبل $count س';
  }

  @override
  String agoDays(int count) {
    return 'قبل $count ي';
  }

  @override
  String get menu => 'القائمة';

  @override
  String get comments => 'التعليقات';

  @override
  String get addComment => 'أضف تعليقًا';

  @override
  String get noCommentsYet => 'لا توجد تعليقات بعد. كن أول من يعلق.';

  @override
  String get signInToComment => 'سجّل الدخول لتعلّق.';

  @override
  String get sendComment => 'إرسال';

  @override
  String get share => 'مشاركة';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get linkCopied => 'تم نسخ الرابط';

  @override
  String get shareToApps => 'مشاركة عبر تطبيقات أخرى';

  @override
  String get message => 'مراسلة';

  @override
  String get messagesTitle => 'الرسائل';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get writeMessage => 'اكتب رسالة…';

  @override
  String get newMessage => 'رسالة جديدة';

  @override
  String get newGroup => 'مجموعة جديدة';

  @override
  String get groupNameHint => 'اسم المجموعة (اختياري)';

  @override
  String get createGroup => 'إنشاء مجموعة';

  @override
  String groupCount(int count, int max) {
    return '$count/$max';
  }

  @override
  String get peopleYouFollow => 'أشخاص تتابعهم';

  @override
  String groupLimit(int max) {
    return 'حتى $max أشخاص، وأنت منهم.';
  }

  @override
  String get signInToMessage => 'سجّل الدخول لمراسلة الآخرين.';

  @override
  String get groupPhoto => 'صورة المجموعة';

  @override
  String get editGroupName => 'تعديل اسم المجموعة';

  @override
  String groupMembers(int count) {
    return '$count أعضاء';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get groupAdmin => 'المشرف';

  @override
  String get removeFromGroup => 'إزالة';

  @override
  String removeMemberConfirm(String name) {
    return 'إزالة $name من المجموعة؟';
  }

  @override
  String get sendTo => 'إرسال إلى';

  @override
  String get send => 'إرسال';

  @override
  String get postSent => 'تم الإرسال';

  @override
  String get filterPlaces => 'تصفية';

  @override
  String get splashTagline => 'احفظ الأماكن التي تحبها';

  @override
  String get factSaved => 'حُفظ';

  @override
  String get factPhotos => 'الصور';

  @override
  String get factVisibleTo => 'يراه';

  @override
  String get visibleToEveryone => 'الجميع';

  @override
  String get directions => 'الاتجاهات';

  @override
  String get pickSomeoneToSend => 'اختر من ترسل إليه';

  @override
  String sendToName(String name) {
    return 'أرسل إلى $name';
  }

  @override
  String sendToCount(int count) {
    return 'أرسل إلى $count أشخاص';
  }

  @override
  String byOwner(String name) {
    return 'بواسطة $name';
  }

  @override
  String get settingsFooter => 'صُنع لمن يحبّون التجوال.';

  @override
  String get languageAutoCode => 'تلقائي';

  @override
  String placesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أماكن محفوظة',
      one: 'مكان محفوظ واحد',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get secureStep => 'خطوة آمنة';

  @override
  String get checkYourMessages => 'تحقّق من رسائلك';

  @override
  String weSentCodeTo(String number) {
    return 'أرسلنا رمزًا من 6 أرقام إلى $number.';
  }

  @override
  String get change => 'تغيير';

  @override
  String get enterAll6Digits => 'أدخل الأرقام الستة';

  @override
  String get deleteDigit => 'حذف رقم';

  @override
  String get messagesSubtitle => 'محادثات مع من تتابعهم.';

  @override
  String get chats => 'المحادثات';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get phoneLanguage => 'الهاتف';

  @override
  String get europeMap => 'خريطة أوروبا';

  @override
  String get europeTitle => 'أوروبا';

  @override
  String get europeSubtitleMine => 'أماكنك في أنحاء القارة';

  @override
  String europeSubtitleOf(String name) {
    return 'أماكن $name في أنحاء القارة';
  }

  @override
  String regionsOf(int total) {
    return 'من $total منطقة';
  }

  @override
  String countriesAndPlaces(int countries, int places) {
    return '$countries دول · $places أماكن';
  }

  @override
  String get europeEmpty => 'الأماكن المحفوظة في أوروبا تضيء منطقتها هنا.';

  @override
  String newRegion(String country) {
    return 'منطقة جديدة في $country! أصبحت خضراء على خريطتك.';
  }

  @override
  String get legendSaved => 'حفظت مكانًا';

  @override
  String get legendBeen => 'زرتها';
}
