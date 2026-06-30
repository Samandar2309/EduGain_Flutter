// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get save => 'Saqlash';

  @override
  String get cancel => 'Bekor';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get continueAction => 'Davom etish';

  @override
  String get languageTitle => 'Til';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUzbek => 'O‘zbekcha';

  @override
  String get welcomeTitle => 'Xush kelibsiz 👋';

  @override
  String get phoneSubtitle => 'Davom etish uchun telefon raqamingizni kiriting';

  @override
  String get phoneLabel => 'Telefon raqam';

  @override
  String get sendCode => 'Kod yuborish';

  @override
  String get dividerOr => 'yoki';

  @override
  String get googleSignIn => 'Google bilan kirish';

  @override
  String get termsNotice =>
      'Davom etish orqali siz Foydalanish shartlari va Maxfiylik siyosatiga rozilik bildirasiz';

  @override
  String get phoneInvalid =>
      'Telefon raqamini to‘g‘ri kiriting (+998XXXXXXXXX)';

  @override
  String get otpTitle => 'Tasdiqlash kodi';

  @override
  String otpSentTo(String phone) {
    return 'Kod yuborildi: $phone';
  }

  @override
  String get verify => 'Tasdiqlash';

  @override
  String resendCountdown(String time) {
    return 'Qayta yuborish — $time';
  }

  @override
  String get resendCode => 'Kodni qayta yuborish';

  @override
  String get otpEnter6 => '6 xonali kodni kiriting';

  @override
  String get otpResent => 'Yangi kod yuborildi';

  @override
  String get nameTitle => 'Tanishib olaylik';

  @override
  String get nameSubtitle => 'Sizga qanday murojaat qilaylik?';

  @override
  String get nameLabel => 'Ismingiz';

  @override
  String get nameHint => 'Masalan, Aziz';

  @override
  String get nameEmpty => 'Iltimos, ismingizni kiriting';

  @override
  String greeting(String name) {
    return 'Salom, $name 👋';
  }

  @override
  String levelLabel(String level) {
    return 'Daraja: $level';
  }

  @override
  String get letsLearnToday => 'Keling, bugun ham o‘rganamiz!';

  @override
  String get modules => 'Modullar';

  @override
  String get statXp => 'XP';

  @override
  String get statLevel => 'Daraja';

  @override
  String get statDay => 'Kun';

  @override
  String get reviewTime => 'Takrorlash vaqti';

  @override
  String wordsWaiting(int count) {
    return '$count ta so‘z sizni kutmoqda';
  }

  @override
  String get featuredBadge => 'TAVSIYA';

  @override
  String get featuredTitle => 'AI bilan suhbatni boshlang';

  @override
  String get featuredSubtitle => 'Haqiqiy suhbatda mashq qiling';

  @override
  String get placementTitle => 'Darajangizni aniqlang';

  @override
  String get placementSubtitle => 'Qisqa test — tajriba sizga moslashadi';

  @override
  String get moduleSpeakingSubtitle => 'AI bilan jonli suhbat';

  @override
  String get moduleVocabSubtitle => 'So‘z boyligini oshiring';

  @override
  String get moduleGrammarSubtitle => 'Grammatikani mashq qiling';

  @override
  String get navHome => 'Asosiy';

  @override
  String get navLessons => 'Darslar';

  @override
  String get navProfile => 'Profil';

  @override
  String get lessonsTitle => 'Darslar';

  @override
  String get lessonSpeakingSubtitle =>
      'AI bilan jonli suhbat orqali gapirishni mashq qiling';

  @override
  String get lessonVocabSubtitle =>
      'Fleshkartalar bilan so‘z boyligini oshiring';

  @override
  String get lessonGrammarSubtitle =>
      'Qoidalar va mashqlar bilan grammatikani mustahkamlang';

  @override
  String get lessonPlacementTitle => 'Daraja testi';

  @override
  String get lessonPlacementSubtitle => 'CEFR darajangizni aniqlang';

  @override
  String get profileTitle => 'Profil';

  @override
  String get logout => 'Chiqish';

  @override
  String get subscription => 'Obuna';

  @override
  String get xpHistory => 'XP tarixi';

  @override
  String get xpHistoryError => 'Tarixni yuklab bo‘lmadi';

  @override
  String get noXpYet => 'Hali XP yo‘q — mashqni boshlang!';

  @override
  String get editNameTitle => 'Ismni o‘zgartirish';

  @override
  String get dailyGoalTitle => 'Kunlik maqsad (XP)';

  @override
  String get dailyGoalHint => 'Masalan: 50';

  @override
  String get dailyGoalLabel => 'Kunlik maqsad';

  @override
  String get close => 'Yopish';

  @override
  String get yes => 'Ha';

  @override
  String get no => 'Yo‘q';

  @override
  String get loadFailed => 'Yuklab bo‘lmadi';

  @override
  String get check => 'Tekshirish';

  @override
  String get yourAnswer => 'Javobingiz';

  @override
  String get premiumContent => 'Premium kontent';

  @override
  String get paywallCtaDefault => 'Premium bilan davom eting';

  @override
  String get premiumButton => 'Premium';

  @override
  String get freeTopic => 'Erkin mavzu';

  @override
  String get freeTopicHint => 'Masalan: sayohat';

  @override
  String get freeTopicCardSubtitle => 'Istalgan mavzuda suhbat quring';

  @override
  String get scenarios => 'Ssenariylar';

  @override
  String get scenariosLoadError =>
      'Ssenariylarni yuklab bo‘lmadi. Internetni tekshiring.';

  @override
  String get limitReachedTitle => 'Limit tugadi';

  @override
  String get startConversation => 'Boshlash';

  @override
  String get feedbackTitle => 'Natija';

  @override
  String get strengths => 'Kuchli tomonlar';

  @override
  String get mistakes => 'Xatolar';

  @override
  String get feedbackLocked =>
      'To‘liq tahlil (barcha xatolar, maslahatlar) Premium bilan ochiladi.';

  @override
  String get micPermission =>
      'Mikrofon ruxsati kerak — telefon sozlamalaridan yoqing.';

  @override
  String get recordStartError => 'Yozib olishni boshlab bo‘lmadi.';

  @override
  String get audioCaptureError => 'Audio olinmadi.';

  @override
  String get aiUnavailable => 'AI vaqtincha mavjud emas';

  @override
  String get turnLimitReached => 'Suhbat limiti tugadi. Natijani oling.';

  @override
  String get speechNotRecognized =>
      'Ovoz aniqlanmadi — qaytadan urinib ko‘ring.';

  @override
  String chatTurnCounter(int turn, int max) {
    return 'Suhbat · $turn/$max navbat';
  }

  @override
  String get finishSession => 'Yakunlash';

  @override
  String get selectVoice => 'Ovozni tanlash';

  @override
  String get turnLimitBanner =>
      'Suhbat limiti tugadi — “Yakunlash” bilan natijani oling.';

  @override
  String get listening => 'tinglanmoqda…';

  @override
  String get tapToSpeak => 'Gapirish uchun bosing';

  @override
  String get composerHint => 'Xabar yozing yoki gapiring…';

  @override
  String get recordingLabel => 'Yozilmoqda';

  @override
  String get tapToSend => 'Yuborish uchun bosing';

  @override
  String get chooseVoice => 'Ovozni tanlang';

  @override
  String get voicesLoadError => 'Ovozlar ro‘yxatini yuklab bo‘lmadi.';

  @override
  String get noVoices => 'Hozircha ovozlar mavjud emas.';

  @override
  String get voicePreview => 'Eshitish';

  @override
  String get voicePreviewError => 'Ovozni eshittirib bo‘lmadi.';

  @override
  String get genderFemale => 'Ayol';

  @override
  String get genderMale => 'Erkak';

  @override
  String get noSets => 'Hozircha to‘plamlar yo‘q';

  @override
  String get noWords => 'So‘zlar yo‘q';

  @override
  String get tapCardToFlip => 'Ko‘rish uchun kartani bosing';

  @override
  String get dontKnow => 'Bilmadim';

  @override
  String get know => 'Bildim';

  @override
  String get congrats => 'Tabriklaymiz! 🎉';

  @override
  String vocabResult(int learned, int total) {
    return '$total ta so‘zdan $learned tasini bildingiz.';
  }

  @override
  String get reviewTitle => 'Takrorlash';

  @override
  String get allReviewed => 'Hammasi takrorlangan! 🎉';

  @override
  String get noReviewWords =>
      'Hozircha takrorlash uchun so‘z yo‘q.\nYangi so‘zlarni o‘rganishda davom eting.';

  @override
  String get wordSets => 'So‘z to‘plamlari';

  @override
  String get greatJob => 'Ajoyib ish! 🎉';

  @override
  String reviewResult(int correct, int reviewed) {
    return '$reviewed ta so‘zdan $correct tasini esladingiz.';
  }

  @override
  String get tapToSeeMeaning => 'Ma’nosini ko‘rish uchun kartani bosing';

  @override
  String get couldntRecall => 'Eslay olmadim';

  @override
  String get recalled => 'Esladim';

  @override
  String get noTopics => 'Hozircha mavzular yo‘q';

  @override
  String get atLeastOneAnswer => 'Kamida bitta javob bering';

  @override
  String grammarScore(int score, int total) {
    return 'Natija: $score / $total';
  }

  @override
  String get placementTestTitle => 'Daraja testi';

  @override
  String get noQuestions => 'Savollar topilmadi';

  @override
  String get resultReady => 'Natija tayyor 🎯';

  @override
  String get yourEnglishLevel => 'Sizning ingliz tili darajangiz';

  @override
  String get startAction => 'Boshlash';

  @override
  String get finishAction => 'Yakunlash';

  @override
  String get nextAction => 'Keyingi';

  @override
  String get choosePayment => 'To‘lov usulini tanlang';

  @override
  String get paymentPageError => 'To‘lov sahifasini ochib bo‘lmadi';

  @override
  String get finishPaymentTitle => 'To‘lovni yakunlang';

  @override
  String get finishPaymentBody =>
      'To‘lovni brauzerda yakunlang. So‘ng holatni tekshiring.';

  @override
  String get cancelSubscriptionTitle => 'Obunani bekor qilish';

  @override
  String get cancelSubscriptionBody =>
      'Imtiyozlar muddat oxirigacha saqlanadi. Davom etasizmi?';

  @override
  String get currentPlan => 'Joriy tarif';

  @override
  String validUntil(String date) {
    return 'Amal qiladi: $date';
  }

  @override
  String get cancelAction => 'Bekor qilish';

  @override
  String pricePerMonth(String price) {
    return '$price / oy';
  }

  @override
  String get choosePlan => 'Tanlash';

  @override
  String get appTagline => 'Sun’iy intellekt bilan ingliz tili';

  @override
  String get xpSourceDailyGoal => 'Kunlik maqsad';

  @override
  String get xpSourceStreak => 'Streak bonus';

  @override
  String get coachCorrection => 'To‘g‘rilash';

  @override
  String get coachNatural => 'Tabiiy variant';

  @override
  String get coachGrammar => 'Grammatika';

  @override
  String get coachVocabulary => 'Lug‘at';

  @override
  String get coachPronunciation => 'Talaffuz';

  @override
  String get statusSpeaking => 'Gapiryapti…';

  @override
  String get statusListening => 'Tinglayapti…';

  @override
  String get statusThinking => 'O‘ylayapti…';

  @override
  String get scoreOverall => 'Umumiy';

  @override
  String get scoreGrammar => 'Grammatika';

  @override
  String get scoreVocabulary => 'Lug‘at';

  @override
  String get scoreFluency => 'Ravonlik';

  @override
  String get scorePronunciation => 'Talaffuz';

  @override
  String get scoresEstimatedNote =>
      'Ravonlik va talaffuz matningiz asosida taxminiy.';

  @override
  String get voiceUnavailable => 'Ovoz vaqtincha mavjud emas.';

  @override
  String get listenModeOn => 'Tinglash rejimi — matn yashirilgan';

  @override
  String get listenModeOff => 'Matnni ko‘rsatish';

  @override
  String get tapToReveal => 'Ko‘rsatish uchun bosing';

  @override
  String get actionTranslate => 'Tarjima';

  @override
  String get actionHint => 'Maslahat';

  @override
  String get hintTitle => 'Qanday javob berish';

  @override
  String get hintTip =>
      'To‘liq gap bilan javob bering va suhbatni davom ettirish uchun qarshi savol bering.';
}
