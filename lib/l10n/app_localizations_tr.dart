// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Favori Yerler';

  @override
  String get close => 'Kapat';

  @override
  String get back => 'Geri';

  @override
  String get undo => 'Geri al';

  @override
  String get pleaseWait => 'Lütfen bekleyin...';

  @override
  String get optional => 'İsteğe bağlı';

  @override
  String get noConnection =>
      'Bağlantı yok. İnternetinizi kontrol edip tekrar deneyin.';

  @override
  String get locationServicesOff =>
      'Konum servisleri kapalı. Ayarlar\'dan açın.';

  @override
  String couldNotGetLocation(String error) {
    return 'Konumunuz alınamadı: $error';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsSubtitle => 'Uygulamayı kendinize göre ayarlayın.';

  @override
  String get settingsRowSubtitle => 'Görünüm ve dil';

  @override
  String get appearance => 'GÖRÜNÜM';

  @override
  String get themeSystem => 'Telefonla aynı';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get language => 'DİL';

  @override
  String get languageSystem => 'Telefonla aynı';

  @override
  String get categoryCafe => 'Kafe';

  @override
  String get categoryCafePlural => 'Kafeler';

  @override
  String get categoryViewpoint => 'Manzara';

  @override
  String get categoryViewpointPlural => 'Manzaralar';

  @override
  String get categoryWalk => 'Yürüyüş';

  @override
  String get categoryWalkPlural => 'Yürüyüşler';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get categoryOtherPlural => 'Diğer';

  @override
  String get tabMyPlaces => 'Yerlerim';

  @override
  String get tabMap => 'Harita';

  @override
  String get tabAccount => 'Hesap';

  @override
  String get takePhotoOfPlace => 'Bir yerin fotoğrafını çek';

  @override
  String get noCameraChoosePhoto =>
      'Bu cihazda kamera yok - bunun yerine bir fotoğraf seçin.';

  @override
  String get savedToMyPlaces => 'Yerlerim\'e kaydedildi';

  @override
  String get tapMapToDropPin => 'İğne bırakmak için haritaya dokunun';

  @override
  String get useThisSpot => 'Bu noktayı kullan';

  @override
  String get sortNewest => 'Önce en yeni';

  @override
  String get sortOldest => 'Önce en eski';

  @override
  String get sortName => 'İsim, A\'dan Z\'ye';

  @override
  String get sortPlaces => 'Yerleri sırala';

  @override
  String favoritePlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count favori yer',
    );
    return '$_temp0';
  }

  @override
  String get findFavoritePlace => 'Favori bir yer bul';

  @override
  String allCount(int count) {
    return 'Tümü · $count';
  }

  @override
  String get noPlacesMatch => 'Eşleşen yer yok';

  @override
  String get tryAnotherWord => 'Başka bir kelime veya tür deneyin.';

  @override
  String get showAllPlaces => 'Tüm yerleri göster';

  @override
  String get typeOfPlace => 'Yer türü';

  @override
  String get noFavoritesYet => 'Henüz favori yer yok';

  @override
  String get noFavoritesBody => 'Fotoğraflı bir yer ekleyin, burada görünecek.';

  @override
  String get addAPlace => 'Yer ekle';

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String get onMap => 'Haritada';

  @override
  String get osmCredit => '© OpenStreetMap katkıcıları';

  @override
  String get changesSaved => 'Değişiklikler kaydedildi';

  @override
  String get editPlace => 'Yeri düzenle';

  @override
  String get addPlace => 'Yer ekle';

  @override
  String get editPlaceSubtitle => 'İstediğinizi değiştirin.';

  @override
  String get addPlaceSubtitle => 'Bir yerden küçük bir parça saklayın.';

  @override
  String get placeName => 'Yer adı';

  @override
  String get placeNameHint => 'Nehir kenarında küçük bir mola';

  @override
  String get littleNote => 'Küçük bir not';

  @override
  String get littleNoteHint => 'Neden sevdiğinizi bir iki satırda yazın';

  @override
  String get onlyYouCanSee => 'Sizi takip edenler bu yeri görecek.';

  @override
  String get saveChanges => 'Değişiklikleri kaydet';

  @override
  String get savePlace => 'Yeri kaydet';

  @override
  String get removedFromMyPlaces => 'Yerlerim\'den kaldırıldı';

  @override
  String get removeFromMyPlaces => 'Yerlerimden kaldır';

  @override
  String get couldNotOpenMaps => 'Haritalar açılamadı';

  @override
  String get savedPlace => 'Kayıtlı yer';

  @override
  String get morePlaceActions => 'Diğer yer işlemleri';

  @override
  String savedOn(String date) {
    return '$date tarihinde kaydedildi';
  }

  @override
  String get myLittleNote => 'KÜÇÜK NOTUM';

  @override
  String get noLocationYet => 'Henüz konum yok — Yeri düzenle ile ekleyin.';

  @override
  String get openInMaps => 'Haritalar\'da aç';

  @override
  String couldNotFindQuery(String query) {
    return '\"$query\" bulunamadı. Bir şehir veya tam adres deneyin.';
  }

  @override
  String get allowLocationToSee =>
      'Nerede olduğunuzu görmek için konum erişimine izin verin.';

  @override
  String cityCount(String city, int count) {
    return '$city · $count';
  }

  @override
  String pinnedCount(int count) {
    return '$count işaretli';
  }

  @override
  String get searchPlacesOrCities => 'Yer veya şehir ara';

  @override
  String get closeSearch => 'Aramayı kapat';

  @override
  String get mapSubtitle => 'Favorileriniz, biraz daha yakın.';

  @override
  String get noPinsYet => 'Henüz iğne yok';

  @override
  String get noPinsBody => 'Konumlu bir yer ekleyin,\nburada görünsün.';

  @override
  String get centerOnMyLocation => 'Konumuma ortala';

  @override
  String get viewPlace => 'Yeri gör';

  @override
  String get choosePhoto => 'Bir fotoğraf seç';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get chooseFromLibrary => 'Galeriden seç';

  @override
  String get addPhoto => 'Fotoğraf ekle';

  @override
  String get changePhoto => 'Fotoğrafı değiştir';

  @override
  String get addPhotoHint => 'Çekin veya galeriden seçin';

  @override
  String get addPhotoNote => 'İsteğe bağlı, ama anılarla dolu.';

  @override
  String get errNoCamera =>
      'Bu cihazda kamera yok. Simülatörlerde kamera bulunmaz - galeriden bir fotoğraf seçin veya gerçek bir telefon kullanın.';

  @override
  String get errCameraDenied =>
      'Kamera erişimi reddedildi. Ayarlar > Favori Yerler\'den izin verin.';

  @override
  String get errPhotosDenied =>
      'Fotoğraf arşivi erişimi reddedildi. Ayarlar > Favori Yerler\'den izin verin.';

  @override
  String get errCameraRestricted =>
      'Bu cihazda kamera erişimi kısıtlı (Ekran Süresi veya bir MDM profili engelliyor).';

  @override
  String get errPickerOpen => 'Seçici zaten açık. Kapatıp tekrar deneyin.';

  @override
  String errCouldNotGetPhoto(String details) {
    return 'Fotoğraf alınamadı: $details';
  }

  @override
  String get whereIsIt => 'Nerede?';

  @override
  String get useMyLocation => 'Konumumu kullan';

  @override
  String get pickOnMap => 'Haritada seç';

  @override
  String get removeLocation => 'Konumu kaldır';

  @override
  String get locationPermissionDenied => 'Konum izni reddedildi.';

  @override
  String get locationBlocked =>
      'Konum erişimi engelli. Ayarlar > Favori Yerler\'den izin verin veya noktayı haritada seçin.';

  @override
  String get findingSpot => 'Nokta bulunuyor…';

  @override
  String get takesASecond => 'Bir saniye sürer';

  @override
  String get addLocation => 'Konum ekle';

  @override
  String get addLocationHint =>
      'Bulunduğunuz yeri kullanın veya haritada seçin';

  @override
  String get location => 'Konum';

  @override
  String locationSemantic(String title) {
    return 'Konum: $title';
  }

  @override
  String signInUnavailable(String error) {
    return 'Giriş şu anda kullanılamıyor.\n$error';
  }

  @override
  String get enterEmailPassword => 'E-posta ve şifrenizi girin';

  @override
  String get typeEmailFirst =>
      'Önce e-postanızı yazın, sonra \"Şifremi unuttum\"a dokunun';

  @override
  String resetLinkSent(String email) {
    return 'Sıfırlama bağlantısı $email adresine gönderildi';
  }

  @override
  String get errInvalidEmail => 'Bu e-posta adresi geçerli değil.';

  @override
  String get errUserDisabled => 'Bu hesap devre dışı bırakıldı.';

  @override
  String get errWrongCredentials => 'E-posta veya şifre yanlış.';

  @override
  String get errEmailInUse =>
      'Bu e-posta için zaten bir hesap var. Bunun yerine giriş yapın.';

  @override
  String get errWeakPassword => 'Şifre çok zayıf. En az 6 karakter kullanın.';

  @override
  String get errTooManyAttempts =>
      'Çok fazla deneme. Biraz bekleyip tekrar deneyin.';

  @override
  String get errEmailNotEnabled =>
      'E-posta ile giriş Firebase konsolunda etkin değil (Authentication > Sign-in method).';

  @override
  String errSignInFailed(String code) {
    return 'Giriş başarısız ($code).';
  }

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get welcomeBack => 'Tekrar hoş geldiniz';

  @override
  String get signUpSubtitle => 'Yerlerinizi yanınızda tutmak için kaydolun';

  @override
  String get signInSubtitle => 'Hesabınıza giriş yapın';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get atLeast6Chars => 'En az 6 karakter';

  @override
  String get forgotPassword => 'Şifremi unuttum?';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı?';

  @override
  String get newHere => 'Yeni misiniz?';

  @override
  String get createAnAccount => 'Hesap oluşturun';

  @override
  String get placesStayOnPhone =>
      'Yerlerinizi paylaşmak ve arkadaşlarınızı takip etmek için giriş yapın.';

  @override
  String get you => 'Siz';

  @override
  String get profilePhoto => 'Profil fotoğrafı';

  @override
  String get removePhoto => 'Fotoğrafı kaldır';

  @override
  String get accountSubtitle => 'Küçük bir koleksiyon, tamamen sizin.';

  @override
  String get changeProfilePhoto => 'Profil fotoğrafını değiştir';

  @override
  String statPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Yer',
    );
    return '$_temp0';
  }

  @override
  String get yourSpace => 'ALANINIZ';

  @override
  String get phoneNumber => 'Telefon numarası';

  @override
  String get verifyWithSms => 'SMS koduyla doğrulayın';

  @override
  String get verifiedTapToChange => 'Doğrulandı · değiştirmek için dokunun';

  @override
  String get profilePreferences => 'Profil ve tercihler';

  @override
  String get makeYourselfAtHome => 'Kendinizi evinizde hissedin';

  @override
  String get privateByDefault => 'Yerlerinizi kim görür';

  @override
  String get placesJustForYou => 'Giriş yapan herkes görebilir';

  @override
  String get privateBody =>
      'Yerleriniz hesabınıza kaydedilir. Giriş yapan herkes profilinizde görebilir, sizi takip edenler akışlarında görür. Fotoğraflar bu telefonda kalır.';

  @override
  String get backupSync => 'Yedekleme ve eşitleme';

  @override
  String get memoriesKeptSafe => 'Anılarınız güvende';

  @override
  String get backupBody =>
      'Giriş yaptığınızda yerleriniz hesabınıza kaydedilir ve yeni telefonunuza gelir. Fotoğraflar şimdilik bu cihazda kalır.';

  @override
  String get aLittleHelpQ => 'Biraz yardım?';

  @override
  String get aLittleHelp => 'Biraz yardım';

  @override
  String get helpBody =>
      'Bir yeri çekip kaydetmek için çubuğun ortasındaki kameraya dokunun. Ona bir ad, tür ve not verin; haritada görmek için konum ekleyin. Düzenlemek veya Haritalar\'da bulmak için bir yeri açın.';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get yourName => 'Adınız';

  @override
  String get yourNameHint => 'Size nasıl hitap edelim?';

  @override
  String get enterNumberWithCode =>
      'Numaranızı ülke koduyla girin, ör. +90 555 123 45 67';

  @override
  String codeSentTo(String number) {
    return 'Kod $number numarasına gönderildi';
  }

  @override
  String get enter6DigitCode => 'SMS\'teki 6 haneli kodu girin';

  @override
  String get signInFirstForPhone =>
      'Telefon numarası eklemek için önce giriş yapın.';

  @override
  String get phoneVerified => 'Telefon numarası doğrulandı';

  @override
  String get errInvalidPhone =>
      'Bu telefon numarası doğru görünmüyor. Ülke kodunu ekleyin.';

  @override
  String get errInvalidCode =>
      'Kod yanlış. SMS\'i kontrol edip tekrar deneyin.';

  @override
  String get errCodeExpired =>
      'Kodun süresi doldu. \"Yeni kod gönder\"e dokunun.';

  @override
  String get errNumberInUse =>
      'Bu numara zaten başka bir hesapta kullanılıyor.';

  @override
  String get errAlreadyHasPhone => 'Bu hesabın zaten bir telefon numarası var.';

  @override
  String get errTooManyAttemptsLong =>
      'Çok fazla deneme. Bir süre bekleyip tekrar deneyin.';

  @override
  String get errSmsQuota =>
      'Bugünkü SMS sınırına ulaşıldı. Daha sonra tekrar deneyin.';

  @override
  String get errPhoneNotEnabled =>
      'Telefonla giriş Firebase konsolunda etkin değil (Authentication > Sign-in method > Phone).';

  @override
  String errVerificationFailed(String code) {
    return 'Doğrulama başarısız ($code).';
  }

  @override
  String get enterCodeWeSent => 'SMS ile gönderdiğimiz kodu girin.';

  @override
  String get wellTextYouCode => 'Doğrulamak için size bir kod göndereceğiz.';

  @override
  String get sixDigitCode => '6 haneli kod';

  @override
  String sendNewCodeIn(int seconds) {
    return '$seconds sn sonra yeni kod gönder';
  }

  @override
  String get sendNewCode => 'Yeni kod gönder';

  @override
  String get verify => 'Doğrula';

  @override
  String get sendCode => 'Kod gönder';

  @override
  String get smsRatesNote =>
      'Standart SMS ücretleri uygulanabilir. Numaranız yalnızca hesabınızı korumak için kullanılır.';

  @override
  String get tabFeed => 'Akış';

  @override
  String get feedSubtitle => 'Takip ettiğiniz kişilerin yerleri.';

  @override
  String get feedEmptyTitle => 'Akışınız boş';

  @override
  String get feedEmptyBody =>
      'Kaydettikleri yerleri görmek için birilerini takip edin.';

  @override
  String get signInForFeed =>
      'Kişileri takip etmek ve yerlerini görmek için giriş yapın.';

  @override
  String get findPeople => 'Kişi bul';

  @override
  String get searchPeopleHint => '@kullanıcı adı veya isimle ara';

  @override
  String get noPeopleFound => 'Kimse bulunamadı';

  @override
  String get follow => 'Takip et';

  @override
  String get followingButton => 'Takip ediliyor';

  @override
  String statFollowers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Takipçi',
    );
    return '$_temp0';
  }

  @override
  String get statFollowing => 'Takip';

  @override
  String get followersTitle => 'Takipçiler';

  @override
  String get followingTitle => 'Takip edilenler';

  @override
  String get noFollowersYet => 'Henüz takipçi yok';

  @override
  String get notFollowingAnyone => 'Henüz kimseyi takip etmiyor';

  @override
  String get noPlacesYet => 'Henüz yer yok';

  @override
  String get username => 'Kullanıcı adı';

  @override
  String get usernameHint => 'ör. khalid.travels';

  @override
  String get usernameInvalid =>
      '3–20 harf, rakam, nokta veya alt çizgi kullanın.';

  @override
  String get usernameTaken => 'Bu kullanıcı adı alınmış.';

  @override
  String get somethingWentWrong =>
      'Bir şeyler ters gitti. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get categoryHike => 'Doğa yürüyüşü';

  @override
  String get categoryHikePlural => 'Doğa yürüyüşleri';

  @override
  String get categoryNature => 'Doğa';

  @override
  String get categoryNaturePlural => 'Doğa';

  @override
  String get categoryBeach => 'Plaj';

  @override
  String get categoryBeachPlural => 'Plajlar';

  @override
  String get categoryCamping => 'Kamp';

  @override
  String get categoryCampingPlural => 'Kamp';

  @override
  String get categoryNight => 'Gece';

  @override
  String get categoryNightPlural => 'Gece';

  @override
  String get badgesTitle => 'Rozetler';

  @override
  String badgesProgress(int earned, int total) {
    return '$total rozetten $earned tanesi kazanıldı';
  }

  @override
  String get noBadgesYet => 'Rozet kazanmak için yer kaydedin';

  @override
  String get badgeEarned => 'Kazanıldı';

  @override
  String get badgeFirstSteps => 'İlk Adımlar';

  @override
  String get badgeFirstStepsHow => 'İlk yerinizi kaydedin.';

  @override
  String get badgeCityHopper => 'Şehir Gezgini';

  @override
  String get badgeCityHopperHow => '5 şehirde yer kaydedin.';

  @override
  String get badgeGlobetrotter => 'Dünya Gezgini';

  @override
  String get badgeGlobetrotterHow => '5 ülkede yer kaydedin.';

  @override
  String get badgeFrequentFlyer => 'Sık Uçan';

  @override
  String get badgeFrequentFlyerHow => '3 kıtada yer kaydedin.';

  @override
  String get badgeRoadTripper => 'Yol Tutkunu';

  @override
  String get badgeRoadTripperHow =>
      'Aralarında en az 500 km olan iki yer kaydedin.';

  @override
  String get badgeBackpacker => 'Sırt Çantalı';

  @override
  String get badgeBackpackerHow => '25 yer kaydedin.';

  @override
  String get badgeShutterbug => 'Fotoğraf Tutkunu';

  @override
  String get badgeShutterbugHow => '10 yere fotoğraf ekleyin.';

  @override
  String get badgeSummitSeeker => 'Zirve Avcısı';

  @override
  String get badgeSummitSeekerHow => '3 Doğa yürüyüşü yeri kaydedin.';

  @override
  String get badgeJungleExplorer => 'Orman Kaşifi';

  @override
  String get badgeJungleExplorerHow => '3 Doğa yeri kaydedin.';

  @override
  String get badgeBeachBum => 'Plaj Sever';

  @override
  String get badgeBeachBumHow => '3 Plaj yeri kaydedin.';

  @override
  String get badgeHappyCamper => 'Mutlu Kampçı';

  @override
  String get badgeHappyCamperHow => '3 Kamp yeri kaydedin.';

  @override
  String get badgeStargazer => 'Yıldız Gözlemcisi';

  @override
  String get badgeStargazerHow => '3 Gece yeri kaydedin.';

  @override
  String get bio => 'Biyografi';

  @override
  String get bioHint => 'Kendinizden birkaç kelimeyle bahsedin';

  @override
  String get photoOnThisPhone =>
      'Fotoğrafınız şimdilik yalnızca bu telefonda görünür.';

  @override
  String get profileSaved => 'Profil kaydedildi';

  @override
  String get profileSaveFailed =>
      'Profiliniz kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get usernameRequired => 'Bir kullanıcı adı girin.';

  @override
  String get chooseUsername => 'Bir kullanıcı adı seçin';

  @override
  String get chooseUsernameBody => 'Arkadaşlarınız sizi bulup takip edebilsin.';
}
