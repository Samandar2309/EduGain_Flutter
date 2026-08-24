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
  String get peerQuotaTitle => 'Bugungi jonli suhbat vaqtingiz tugadi';

  @override
  String get peerQuotaBody =>
      'Obuna bilan boshqa o‘quvchilar bilan cheksiz gaplashing.';

  @override
  String get resumeTitle => 'Tugallanmagan suhbat';

  @override
  String resumeSubtitle(int turns) {
    return '$turns ta navbat o‘tdi — to‘xtagan joyingizdan davom eting';
  }

  @override
  String get resumeAction => 'Davom ettirish';

  @override
  String get networkError =>
      'Internetga ulanishda xatolik. Qaytadan urinib ko‘ring.';

  @override
  String get feedbackNotReadyTitle => 'Hisobot tayyor emas';

  @override
  String get feedbackNotReadyBody =>
      'Suhbatingiz saqlandi. Baholash xizmati hozir javob bermadi — hisobotni qaytadan yig‘ishingiz mumkin.';

  @override
  String get continueAction => 'Davom etish';

  @override
  String minutesShort(int count) {
    return '$count daq';
  }

  @override
  String groupRoomHoldsUpTo(int count) {
    return 'Xonaga $count kishigacha qo‘shiladi';
  }

  @override
  String get cannotHearYou =>
      'Sizni eshitmayapmiz — balandroq gapiring yoki yozib yuboring';

  @override
  String get micBlockedTapToAllow =>
      'Mikrofon yopiq — ruxsat berish uchun bosing';

  @override
  String minutesLeft(int count) {
    return '$count daqiqa qoldi';
  }

  @override
  String get actionEnd => 'Tugatish';

  @override
  String get questionsTitle => 'Savollar';

  @override
  String get workedTitle => 'Qanday javob berish kerak';

  @override
  String get workedWeak => 'Ko‘pchilik shunday javob beradi';

  @override
  String get workedStrong => 'Shunday bo‘lsa yaxshiroq';

  @override
  String get workedMoves => 'Nima o‘zgardi';

  @override
  String get workedLocked => 'Javob tahlili Premium’da';

  @override
  String get workedLockedWhy =>
      'Savollar hamma uchun ochiq. Tahlil — kuchsiz va kuchli javob yonma-yon, farqi belgilangan holda — Premium’da.';

  @override
  String get workedOpen => 'Tahlilni ochish';

  @override
  String questionsFollows(String title) {
    return '$title kartochkasidan keyin';
  }

  @override
  String get questionsPart3Hint =>
      'Bu savollar shaxsiy emas — jamiyat haqida. Fikringizni ayting va sabab keltiring, bir-ikki jumla bilan chegaralanmang.';

  @override
  String get cueCardLabel => 'Kartochka topshirig‘i';

  @override
  String get cueCardYouShouldSay => 'Quyidagilarni aytishingiz kerak:';

  @override
  String get cueCardHint =>
      '1 daqiqa tayyorlaning, keyin to‘xtamasdan 2 daqiqa gapiring. Juftlikda mashq qilsangiz: biri kartani o‘qiydi va vaqtni oladi, keyin almashasiz.';

  @override
  String cueCardPrep(int count) {
    return '$count daqiqa tayyorgarlik';
  }

  @override
  String cueCardTalk(int count) {
    return '$count daqiqa gapirish';
  }

  @override
  String get questionsModeSubtitle => 'Suhbat uchun tayyor savollar to‘plami';

  @override
  String get questionsIntro =>
      'Jonli suhbatda bir-biringizga bering yoki oldindan tayyorlaning.';

  @override
  String get questionsUseHint =>
      'Bittasini tanlang va sherigingizga bering — keyin siz javob bering.';

  @override
  String get questionsSaved => 'Saqlanganlar';

  @override
  String get questionsNoneSaved =>
      'Hali savol saqlamadingiz.\nYoqqanini xatcho‘pga qo‘shing.';

  @override
  String get questionsNew => 'YANGI';

  @override
  String get questionsError => 'Savollarni yuklab bo‘lmadi.';

  @override
  String get speakingSectionPrepare => 'Tayyorgarlik';

  @override
  String questionsCount(int count) {
    return '$count ta savol';
  }

  @override
  String questionsTopicCount(int count) {
    return '$count ta mavzu';
  }

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
  String get learnLangComingSoon => 'Tez kunda';

  @override
  String get learnLangNotifyMe => 'Xabar beramiz';

  @override
  String learnLangInterestSaved(String language) {
    return 'Qayd etildi. $language ochilganda birinchi bo‘lib sizga aytamiz.';
  }

  @override
  String get feedbackSendTitle => 'Fikr bildirish';

  @override
  String get feedbackSendSubtitle =>
      'Nima ishlamadi, nima yetishmayapti — yozing. Har birini o‘qiymiz.';

  @override
  String get feedbackHint => 'Muammoni yoki taklifingizni yozing…';

  @override
  String get feedbackSend => 'Yuborish';

  @override
  String get feedbackEmpty => 'Iltimos, avval fikringizni yozing';

  @override
  String get feedbackThanks => 'Rahmat! Xabaringiz bizga yetib bordi.';

  @override
  String get feedbackTooMany =>
      'Bugunga yetarli xabar yubordingiz. Ertaga davom etamiz.';

  @override
  String get rateSessionQuestion => 'Bu suhbat qanday bo‘ldi?';

  @override
  String get rateSessionCommentHint => 'Izoh qoldirasizmi? (ixtiyoriy)';

  @override
  String get rateSessionCommentSent => 'Izohingiz yuborildi. Rahmat!';

  @override
  String get rateSessionThanks => 'Rahmat — bu bizga yordam beradi.';

  @override
  String get channelTitle => 'Kanalimizga qo‘shiling';

  @override
  String get channelSubtitle =>
      'Yangi darslar, foydali maslahatlar va yangiliklar shu yerda e’lon qilinadi. Bir marta obuna bo‘lasiz — keyin davom etamiz.';

  @override
  String get channelOpenAction => 'Kanalga o‘tish';

  @override
  String get channelJoinedAction => 'Obuna bo‘ldim';

  @override
  String get channelNotYet =>
      'Obunangiz hali ko‘rinmadi. Kanalga qo‘shilib, qaytadan urinib ko‘ring.';

  @override
  String greeting(String name) {
    return 'Salom, $name 👋';
  }

  @override
  String levelLabel(String level) {
    return 'Ingliz tili: $level';
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
  String get details => 'Tafsilotlar';

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
  String get voiceAddMore => 'Yana ovoz qoʻshish';

  @override
  String get voiceAddMoreIntro =>
      'Ilova faqat qurilmangizda mavjud ovozlardan foydalana oladi. Qurilma sozlamalaridan yangisini oʻrnating, soʻng qaytib roʻyxatni yangilang.';

  @override
  String get voiceStepsAndroid =>
      'Sozlamalar → Tizim → Til va kiritish → Matndan nutqqa → Google Text-to-Speech → Ovoz maʼlumotlarini oʻrnatish → English. “Enhanced” ovozlarni tanlang — ular ancha tabiiy eshitiladi.';

  @override
  String get voiceStepsIos =>
      'Sozlamalar → Maxsus imkoniyatlar → Nutq → Ovozlar → English. “Premium” yoki “Enhanced” ovozni yuklang, masalan Evan yoki Nathan.';

  @override
  String get voiceStepsWindows =>
      'Sozlamalar → Vaqt va til → Nutq → Ovozlarni boshqarish → Ovoz qoʻshish → English (United States).';

  @override
  String get voiceStepsMac =>
      'Tizim sozlamalari → Maxsus imkoniyatlar → Nutq → Tizim ovozi → Ovozlarni boshqarish → English.';

  @override
  String get voiceStepsGeneric =>
      'Qurilma sozlamalarini oching, matndan nutqqa yoki nutq boʻlimini toping va inglizcha ovoz oʻrnating.';

  @override
  String get voiceRefresh => 'Roʻyxatni yangilash';

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
  String get gamesTitle => 'O‘yinlar';

  @override
  String get gamesVocabTitle => 'So‘z o‘yinlari';

  @override
  String get gamesVocabSubtitle =>
      'Yolg‘iz, Gainsy bilan yoki jonli raqib bilan';

  @override
  String get gamesGrammarTitle => 'Grammatika';

  @override
  String get gamesGrammarSubtitle => 'Qoidani o‘rganing va mashq qiling';

  @override
  String get gamesBrowseTitle => 'So‘zlarni ko‘rish';

  @override
  String get gamesBrowseSubtitle => 'Tarjimasi va misoli bilan';

  @override
  String get gamesReviewSubtitle => 'Unutish arafasidagi so‘zlar';

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
  String get placementResultBody =>
      'Endi ustoz shu darajada gapiradi — siz oʻsgan sari daraja ham oʻzgaradi.';

  @override
  String get placementLastResultTitle => 'Oxirgi natijangiz';

  @override
  String get placementTakenToday => 'Bugun topshirilgan';

  @override
  String get placementTakenYesterday => 'Kecha topshirilgan';

  @override
  String placementTakenDaysAgo(int days) {
    return '$days kun oldin topshirilgan';
  }

  @override
  String get placementRetakeQuestion => 'Testni qaytadan yechmoqchimisiz?';

  @override
  String get placementRetakeReplaces =>
      'Yangi natija hozirgi darajangiz oʻrnini egallaydi.';

  @override
  String get placementRetakeAction => 'Ha, qaytadan boshlayman';

  @override
  String get placementKeepAction => 'Yoʻq, darajam qolsin';

  @override
  String get levelInviteTitle => 'Avval darajangizni aniqlaymiz';

  @override
  String get levelInviteBody =>
      'Bir necha qisqa savol. Shundan keyin ustoz taxmin qilib emas, siz tushunadigan darajada gapiradi.';

  @override
  String get levelInviteMeta => '18 ta savol · taxminan 2 daqiqa';

  @override
  String get levelInviteStart => 'Darajamni aniqlash';

  @override
  String get levelInviteSkip => 'Hozir emas';

  @override
  String get leaderboardTitle => 'Reyting';

  @override
  String get navLeaderboard => 'Reyting';

  @override
  String get leaderboardThisWeek => 'Bu hafta';

  @override
  String get leaderboardLastWeek => 'Oʻtgan hafta';

  @override
  String get leaderboardEmpty => 'Bu hafta hali hech kim XP yigʻmagan.';

  @override
  String get leaderboardEmptyLastWeek => 'Oʻtgan hafta hech kim XP yigʻmagan.';

  @override
  String get leaderboardFirstPlaceOpen => 'Birinchi suhbat — birinchi oʻrin.';

  @override
  String get leaderboardNotRankedYet =>
      'Reytingga kirish uchun bitta darsni tugating.';

  @override
  String get leaderboardYou => 'Siz';

  @override
  String get leaderboardYouAreFirst => 'Siz birinchisiz — oʻrningizni saqlang.';

  @override
  String get leaderboardPlaceSuffix => '-oʻringacha';

  @override
  String leaderboardStreakDays(int days) {
    return '$days kun';
  }

  @override
  String get leaderboardResetsMonday =>
      'Reyting har dushanba yangidan boshlanadi.';

  @override
  String get tierFree => 'Bepul';

  @override
  String get homeLevelUnknown => 'Daraja: aniqlanmagan';

  @override
  String get statStreak => 'Kunlik seriya';

  @override
  String get statGoal => 'Maqsad';

  @override
  String get homeAiKicker => 'Tavsiya';

  @override
  String get homeAiTitle => 'AI bilan suhbatni boshlang';

  @override
  String get homeAiSubtitle => 'Speaking koʻnikmangizni oshiring';

  @override
  String get homeAiLocked => 'Daraja aniqlangach ochiladi';

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
  String get quotaTitle => 'Kunlik so‘zlashuv vaqti';

  @override
  String quotaMinutesLeft(int minutes) {
    return '$minutes daqiqa qoldi';
  }

  @override
  String quotaUsedOf(int used, int total) {
    return '$total daqiqadan $used tasi ishlatildi';
  }

  @override
  String get quotaExhausted => 'Bugungi daqiqalar tugadi';

  @override
  String get quotaUpgrade => 'Limitni oshirish';

  @override
  String get commProfileTitle => 'Muloqot profili';

  @override
  String get commProfileEmpty =>
      'AI ustoz bilan bir necha suhbat qiling — profilingiz haqiqiy nutqingizdan o‘zi shakllanadi.';

  @override
  String get focusTagsTitle => 'Hozir ustida ishlayapmiz';

  @override
  String get paceLabel => 'Nutq tezligi';

  @override
  String paceValue(int wpm) {
    return '$wpm so‘z/daq';
  }

  @override
  String paceTarget(int target) {
    return 'maqsad $target';
  }

  @override
  String get minutesSpoken => 'Gapirilgan daqiqalar';

  @override
  String get wordsSpoken => 'Aytilgan so‘zlar';

  @override
  String basedOnSessions(int count) {
    return '$count ta suhbat asosida';
  }

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get paywallReportTitle => 'To‘liq hisobotni oching';

  @override
  String get paywallReportBody =>
      'Har bir xato, tuzatish va shaxsiy maslahat — Premium bilan.';

  @override
  String get paywallSeePlans => 'Tariflarni ko‘rish';

  @override
  String get premiumBadge => 'Premium';

  @override
  String get planPopular => 'Eng ommabop';

  @override
  String get premiumHeroTitle => 'EduGain Premium';

  @override
  String get premiumHeroBody =>
      'Har kuni ko‘proq gapiring, barcha yo‘nalishlarni oching va nutqingizning to‘liq tahlilini oling.';

  @override
  String get appTagline => 'Sun’iy intellekt bilan ingliz tili';

  @override
  String get welcomeChooseLanguage => 'Tilni tanlang';

  @override
  String get welcomeSkip => 'O‘tkazib yuborish';

  @override
  String get welcomeStart => 'Boshlash';

  @override
  String get welcomeSpeakTitle => 'AI ustoz bilan gaplashing';

  @override
  String get welcomeSpeakBody =>
      'Kun-u tun istalgan payt jonli suhbat. Xato qilishdan qo‘rqmasdan — shunchaki mashq qiling.';

  @override
  String get welcomeCoachTitle => 'Suhbat ichida jonli yordam';

  @override
  String get welcomeCoachBody =>
      'Har jumladan keyin yumshoq tuzatishlar hamda grammatika, so‘z boyligi va ravonlik bo‘yicha aniq hisobot.';

  @override
  String get welcomeGoalTitle => 'Maqsadingiz sari yo‘l';

  @override
  String get welcomeGoalBody =>
      'IELTS, karyera, sayohat yoki kundalik suhbat — trek zaif tomonlaringizga moslashadi.';

  @override
  String get xpSourceDailyGoal => 'Kunlik maqsad';

  @override
  String get xpSourceStreak => 'Seriya bonusi';

  @override
  String get coachWhy => 'Nega';

  @override
  String get coachMore => 'Nega, va tabiiy variant';

  @override
  String get coachLess => 'Izohni yashirish';

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

  @override
  String get groupChatTitle => 'Guruh suhbati';

  @override
  String get groupCreateRoom => 'Xona yaratish';

  @override
  String get groupNewRoom => 'Yangi guruh suhbati';

  @override
  String get groupTopicLabel => 'Mavzu';

  @override
  String get groupVisibilityLabel => 'Ko‘rinish';

  @override
  String get groupPublicOption => 'Ochiq';

  @override
  String get groupPrivateOption => 'Yopiq';

  @override
  String get groupPublicHint => 'Har kim lobbydan qo‘shila oladi';

  @override
  String get groupPrivateHint => 'Faqat kod/havola orqali qo‘shiladi';

  @override
  String groupParticipantsCount(int count) {
    return 'Ishtirokchilar: $count';
  }

  @override
  String get groupCreateAndStart => 'Yaratish va boshlash';

  @override
  String get groupCreateFailed => 'Xona yaratib bo‘lmadi';

  @override
  String get groupEmptyTitle => 'Hozircha ochiq suhbat yo‘q';

  @override
  String get groupEmptySubtitle => 'Birinchi bo‘lib xona yarating!';

  @override
  String get groupJoinByCode => 'Kod bilan qo‘shilish';

  @override
  String get groupCodeHint => 'masalan: ABC123';

  @override
  String get groupInviteFriends => 'Do‘stlaringizni taklif qiling';

  @override
  String get groupShareTelegram => 'Telegram’da ulashish';

  @override
  String get groupCopyCode => 'Kodni nusxalash';

  @override
  String get groupCodeCopied => 'Kod nusxalandi';

  @override
  String get inviteCopied => 'Taklif nusxalandi — do‘stingizga yuboring';

  @override
  String get groupInvite => 'Taklif qilish';

  @override
  String groupInviteShareText(String code) {
    return 'EduGain\'da guruh suhbatiga qo\'shiling! 🎙\n\nXona kodi: $code\n\n@edugain_bot ni oching → Speaking → Guruh suhbati → «Kod bilan qo\'shilish»';
  }

  @override
  String get groupConnected => 'Ulangan';

  @override
  String get groupConnectingStatus => 'Ulanmoqda…';

  @override
  String get groupYou => 'Siz';

  @override
  String get groupMicOff => 'Mikrofon o‘chiq';

  @override
  String get groupRemove => 'Chiqarish';

  @override
  String get groupRoomNotFound => 'Xona topilmadi';

  @override
  String get groupFull => 'To‘lgan';

  @override
  String get groupJoin => 'Qo‘shilish';

  @override
  String get groupKickedMsg => 'Siz xonadan chiqarildingiz';

  @override
  String get groupConnectErrorMsg => 'Ulanishda xatolik';

  @override
  String get groupChatEmpty => 'Hozircha xabar yo‘q — birinchi bo‘lib yozing';

  @override
  String get groupModeratorNote => 'AI moderator mavzuni boshqarib boradi';

  @override
  String get groupRule4b => 'AI moderator ko‘rsatmalariga amal qiling';

  @override
  String get groupCallTime => 'Suhbat vaqti';

  @override
  String get groupLeaveRoom => 'Suhbatdan chiqish';

  @override
  String get groupOthers => 'Boshqalar';

  @override
  String get groupWriteMessage => 'Xabar yozing…';

  @override
  String get groupParticipants => 'Ishtirokchilar';

  @override
  String get groupSeeAll => 'Barchasini ko‘rish';

  @override
  String get groupRulesTitle => 'Xona qoidalari';

  @override
  String get groupRule1 => 'Bir-biringizni tinglang';

  @override
  String get groupRule2 => 'Hurmatli bo‘ling';

  @override
  String get groupRule3 => 'Ingliz tilida gaplashing';

  @override
  String get groupRule4 => 'Spam yo‘q';

  @override
  String get groupSettingsTitle => 'Suhbat sozlamalari';

  @override
  String get groupSettingMic => 'Mikrofon';

  @override
  String get groupSettingNotify => 'Eslatma';

  @override
  String get groupSettingRules => 'Qoidalar';

  @override
  String get groupSpeakNow => 'Gapirish';

  @override
  String get groupMuteMic => 'Mikrofonni o‘chirish';

  @override
  String get groupSpeakingNow => 'HOZIR GAPIRYAPTI';

  @override
  String get groupNobodySpeaking => 'Hech kim gapirmayapti';

  @override
  String get groupInRoom => 'XONADA';

  @override
  String get groupMuteMember => 'Ovozsiz qilish';

  @override
  String get groupMakeHost => 'Hostlikni topshirish';

  @override
  String get groupMuteEveryone => 'Hammani ovozsiz qilish';

  @override
  String get groupMutedByHost => 'Xona egasi sizni ovozsiz qildi';

  @override
  String get groupMicBlocked => 'Mikrofonga ruxsat berilmadi';

  @override
  String get groupHostBadge => 'Host';

  @override
  String get groupMore => 'yana';

  @override
  String get grammarTitle => 'Grammatika';

  @override
  String get grammarChooseLevel => 'Darajangizni tanlang';

  @override
  String get grammarLevelsSubtitle =>
      'A1 dan C2 gacha — bosqichma-bosqich grammatika';

  @override
  String grammarTopicCount(int count) {
    return '$count ta mavzu';
  }

  @override
  String get comingSoon => 'Tez kunda';

  @override
  String get grammarLevelA1 => 'Boshlang‘ich';

  @override
  String get grammarLevelA2 => 'Elementar';

  @override
  String get grammarLevelB1 => 'O‘rta';

  @override
  String get grammarLevelB2 => 'O‘rta-yuqori';

  @override
  String get grammarLevelC1 => 'Ilg‘or';

  @override
  String get grammarLevelC2 => 'Professional';

  @override
  String get grammarRulePlusPractice => 'Qoida + mashq';

  @override
  String get grammarLearnRule => 'Qoidani o‘rganish';

  @override
  String get grammarRuleExamplesPattern => 'Qoida, misollar va naqsh';

  @override
  String get grammarPractice => 'Mashq qilish';

  @override
  String get grammarPracticeSubtitle =>
      'Bo‘shliqni to‘ldirish + gap tuzish o‘yinlari';

  @override
  String get grammarStartPractice => 'Mashq qilishni boshlash';

  @override
  String get grammarRuleLabel => 'Qoida';

  @override
  String get grammarRuleReadySpeaking =>
      'Bu qoidani endi Speaking mashg‘ulotida qo‘llab ko‘ring 🎯';

  @override
  String get grammarNotEnoughExercises =>
      'Bu mavzuda mashq uchun yetarli topshiriq yo‘q.';

  @override
  String get grammarChooseForm => 'TO‘G‘RI SHAKLNI TANLANG';

  @override
  String get grammarBuildSentence => 'GAPNI TUZING';

  @override
  String get answerCorrectExcl => 'To‘g‘ri!';

  @override
  String get answerWrongLabel => 'Xato';

  @override
  String correctAnswerLabel(String answer) {
    return 'To‘g‘ri javob: $answer';
  }

  @override
  String get vocabWhatToDo => 'Nima qilamiz?';

  @override
  String get vocabLearnTitle => 'So‘zlarni o‘rganish';

  @override
  String get vocabLearnSubtitle =>
      'Yangi so‘zlarni tarjimasi va misoli bilan ko‘ring';

  @override
  String get vocabTestKnowledge => 'Bilimni sinash';

  @override
  String get vocabTestSubtitle => 'O‘yinlar orqali yodlaganingizni tekshiring';

  @override
  String get vocabDailyReview => 'Kunlik takrorlash';

  @override
  String vocabDueReady(int count) {
    return '$count ta so‘z takrorlashga tayyor — mustahkamlab oling.';
  }

  @override
  String get vocabStartReview => 'Takrorlashni boshlash';

  @override
  String get vocabNotEnoughReview => 'Takrorlash uchun so‘z yetarli emas';

  @override
  String vocabWordCount(int count) {
    return '$count so‘z';
  }

  @override
  String get vocabWordSet => 'So‘z to‘plami';

  @override
  String get vocabHowToPlay => 'Qanday o‘ynaymiz?';

  @override
  String get vocabSoloTitle => 'Solo o‘ynash';

  @override
  String get vocabSoloSubtitle => 'O‘z tezligingizda so‘z yodlang';

  @override
  String get vocabSpellTitle => 'Harflardan yig‘ish';

  @override
  String get vocabSpellSubtitle => 'So‘zni xotiradan harflab tuzing';

  @override
  String get vocabDuelBotTitle => 'Gainsy bilan bellashuv';

  @override
  String get vocabDuelBotSubtitle => 'Botga qarshi tezlik poygasi';

  @override
  String get vocabDuelOnlineTitle => 'Odam bilan o‘ynash';

  @override
  String get vocabDuelOnlineSubtitle => 'Jonli raqib bilan tezlik poygasi';

  @override
  String get vocabNotEnoughWords =>
      'Bu to‘plamda o‘yin uchun so‘z yetarli emas';

  @override
  String get loadRetryError => 'Yuklashda xatolik. Qayta urinib ko‘ring.';

  @override
  String get vocabGainsyAnswering => 'Gainsy javob beryapti…';

  @override
  String get vocabFindingOpponent => 'Raqib qidirilmoqda…';

  @override
  String get vocabDuelWaitHint =>
      'Boshqa o‘quvchi shu o‘yinni tanlashi bilan avtomatik ulanasiz';

  @override
  String get vocabNoOpponent => 'Hozircha onlayn raqib topilmadi.';

  @override
  String get vocabPlayWithGainsy => 'Gainsy bilan o‘ynash';

  @override
  String vocabPartnerAnswering(String name) {
    return '$name javob beryapti…';
  }

  @override
  String get vocabConnLostPlayBot =>
      'Ulanishda muammo. Gainsy bilan o‘ynab turasizmi?';

  @override
  String get backAction => 'Orqaga';

  @override
  String get vocabSpellInstruction => 'SO‘ZNI HARFLARDAN YIG‘ING';

  @override
  String get vocabNoSpellWords =>
      'Bu to‘plamda harflardan yig‘ish uchun mos so‘z yo‘q.';

  @override
  String get gameChooseTranslation => 'Tarjimasini tanlang';

  @override
  String get gameChooseWord => 'So‘zni tanlang';

  @override
  String get gameWordsReadySpeaking =>
      'Bu so‘zlar endi Speaking mashg‘ulotida tayyor 🎯';

  @override
  String get gameYouWon => 'Siz yutdingiz!';

  @override
  String gameOpponentAhead(String name) {
    return '$name bu safar oldinda';
  }

  @override
  String get gameNiceWork => 'Ajoyib ish!';

  @override
  String get youLabel => 'Siz';

  @override
  String get gameCorrectAnswers => 'To‘g‘ri javob';

  @override
  String get gameCombo => 'Kombo';

  @override
  String get gameAccuracy => 'Aniqlik';

  @override
  String get gamePlayAgain => 'Yana o‘ynash';

  @override
  String get vocabTitle => 'Lug‘at';

  @override
  String get speakingSectionAi => 'AI ustoz bilan · doim mavjud';

  @override
  String get speakingSectionLive => 'Odamlar bilan · jonli';

  @override
  String get speakingFreeTitle => 'Erkin suhbat';

  @override
  String get speakingFreeSubtitle => 'AI bilan istalgan mavzuda';

  @override
  String get speakingTopicsTitle => 'Tayyor darslar';

  @override
  String get speakingTopicsSubtitle => 'AI bilan darajangiz bo‘yicha';

  @override
  String get speakingGroupSubtitle =>
      'Ochiq xonaga qo‘shiling yoki o‘zingiz yarating';

  @override
  String get speakingOneToOneTitle => '1:1 jonli suhbat';

  @override
  String get speakingOneToOneSubtitle => 'Bitta odam bilan yuzma-yuz mashq';

  @override
  String get peerLiveChat => 'Jonli suhbat';

  @override
  String get micPrimerTitle => 'Mikrofonni yoqing';

  @override
  String get micPrimerBody =>
      'Suhbatdoshingiz sizni eshitishi kerak. Hozir brauzer ruxsat so‘raydi — «Allow» tugmasini bosing.';

  @override
  String get micPrimerAllowWord => 'Allow';

  @override
  String get micPrimerBlockWord => 'Block';

  @override
  String get micPrimerContinue => 'Davom etish';

  @override
  String get micBlockedTelegramBody =>
      'Mikrofonga ruxsat berilmadi. Telegram’ni butunlay yoping, EduGain’ni qaytadan oching va bu safar «Allow» tugmasini bosing.';

  @override
  String get micBlockedBrowserBody =>
      'Bu sayt uchun mikrofon bloklangan. Manzil yonidagi qulf belgisini bosing → Mikrofon → Ruxsat berish, so‘ng sahifani yangilang.';

  @override
  String get peerPartnerMicOff =>
      'Suhbatdoshingizning mikrofoni o‘chiq — u sizni eshitadi, siz uni eshitmaysiz.';

  @override
  String get peerNoMicRejoin =>
      'Mikrofon yoqilmagan. Suhbatni tugatib, qaytadan boshlang — ruxsat darhol so‘raladi.';

  @override
  String get micPreparing => 'Mikrofon tayyorlanmoqda…';

  @override
  String get micNeededTitle => 'Mikrofon kerak';

  @override
  String get micDeniedBody =>
      'Suhbatdosh bilan gaplashish uchun mikrofonga ruxsat kerak.';

  @override
  String get micBlockedBody =>
      'Mikrofonga ruxsat bloklangan. Brauzer yoki Telegram sozlamalarida ruxsat bering va qaytadan urinib ko‘ring.';

  @override
  String get micNotFoundBody => 'Bu qurilmada mikrofon topilmadi.';

  @override
  String get micBusyBody =>
      'Mikrofonni boshqa ilova ishlatyapti. Uni yoping va qaytadan urinib ko‘ring.';

  @override
  String get micInsecureBody =>
      'Mikrofon faqat xavfsiz ulanishda ishlaydi. Ilovani botdan qaytadan oching.';

  @override
  String get micConstraintsBody =>
      'Mikrofoningiz qo‘ng‘iroq uchun kerakli sozlamalarni qo‘llab-quvvatlamaydi.';

  @override
  String get micUnknownBody =>
      'Mikrofonni yoqib bo‘lmadi. Qaytadan urinib ko‘ring.';

  @override
  String get micRetry => 'Qaytadan urinish';

  @override
  String get peerFriendRoom => 'Do‘st bilan xona';

  @override
  String get peerJoinByCode => 'Kod bilan kirish';

  @override
  String get peerHistory => 'Suhbatlar tarixi';

  @override
  String peerConvCount(int count) {
    return '$count ta suhbat';
  }

  @override
  String get peerRoomCode => 'Xona kodi';

  @override
  String get peerEnter => 'Kirish';

  @override
  String peerOnlineCount(int count) {
    return '$count kishi onlayn';
  }

  @override
  String get peerFindPartner => 'Partner topish';

  @override
  String get peerFindPartnerSubtitle =>
      'Onlayn o‘quvchi bilan tasodifiy ulanib,\ninglizcha jonli suhbat quring';

  @override
  String get peerNoHistoryTitle => 'Hali suhbatlaringiz yo‘q';

  @override
  String get peerNoHistorySubtitle =>
      'Birinchi partneringizni toping — har bir suhbat\nshu yerda saqlanadi.';

  @override
  String get peerToday => 'Bugun';

  @override
  String get peerYesterday => 'Kecha';

  @override
  String peerDurMinSec(int m, int s) {
    return '$m min $s s';
  }

  @override
  String peerDurSec(int s) {
    return '$s s';
  }

  @override
  String get peerStatusConnecting => 'Ulanmoqda…';

  @override
  String get peerStatusSearching => 'Partner qidirilmoqda…';

  @override
  String get peerStatusWaitingFriend => 'Do‘stingiz kutilmoqda';

  @override
  String get peerStatusConnectingVoice => 'Ovoz ulanmoqda…';

  @override
  String peerStatusLiveChat(String time) {
    return 'Jonli suhbat · $time';
  }

  @override
  String get peerStatusEnded => 'Suhbat tugadi';

  @override
  String get peerSearchingTitle => 'Sizga mos partner qidirilmoqda…';

  @override
  String get peerSearchingSubtitle =>
      'Boshqa o‘quvchi qidiruvni boshlashi bilan\navtomatik ulanasiz';

  @override
  String get peerYourPartner => 'Suhbat partneringiz';

  @override
  String get peerInviteTelegram => 'Telegram orqali taklif qilish';

  @override
  String peerInviteShareText(String code) {
    return 'EduGain’da men bilan jonli ingliz tili suhbatiga qo‘shiling! Ilovadagi “Jonli suhbat” bo‘limida shu kodni kiriting: $code';
  }

  @override
  String get peerYourRole => 'Sizning rolingiz';

  @override
  String get peerPartnerRole => 'Partner roli';

  @override
  String get peerStopSearching => 'Qidiruvni to‘xtatish';

  @override
  String get peerEndedPartnerLeft => 'Partner suhbatni tark etdi.';

  @override
  String get peerEndedYouEnded => 'Suhbat yakunlandi. Yaxshi mashq! 👏';

  @override
  String get peerEndedFailed =>
      'Ulanishda muammo yuz berdi. Qayta urinib ko‘ring.';

  @override
  String get peerEndedDefault => 'Suhbat tugadi.';

  @override
  String get speakingDailyMission => 'Kunlik topshiriq';

  @override
  String get speakingRecommended => 'Sizga tavsiya';

  @override
  String get seeAll => 'Barchasi';

  @override
  String get tracksSectionTitle => 'Yoʻnalishlar';

  @override
  String lessonsOf(int done, int total) {
    return '$total darsdan $done tasi';
  }

  @override
  String get speakingExploreByGoal => 'Maqsad bo‘yicha';

  @override
  String get speakingLessonPremium => 'Bu dars Premium tarkibida.';

  @override
  String speakingReachToUnlock(String level) {
    return 'Bu darsni ochish uchun $level darajaga yeting.';
  }

  @override
  String get speakingStartFirstLesson => 'Birinchi darsni boshlang';

  @override
  String get speakingPickGoal =>
      'Maqsadni tanlang va bir zumda gapirishni boshlang.';

  @override
  String get speakingStartNow => 'Hozir boshlash';

  @override
  String get speakingContinueLearning => 'O‘rganishni davom ettirish';

  @override
  String get speakingPracticeAgain => 'Yana mashq qilish';

  @override
  String get speakingTodaysMission => 'Bugungi Speaking topshirig‘i';

  @override
  String get speakingLoadError => 'Speaking yuklanmadi.';

  @override
  String get speakingLastToday => 'Bugun ochilgan';

  @override
  String get speakingLastYesterday => 'Kecha ochilgan';

  @override
  String speakingLastDaysAgo(int days) {
    return '$days kun oldin ochilgan';
  }

  @override
  String speakingMinutesShort(int minutes) {
    return '$minutes daq';
  }

  @override
  String speakingLessonsShort(int done, int total) {
    return '$done/$total dars';
  }

  @override
  String speakingLessonsCompleted(int done, int total) {
    return '$done/$total dars tugatildi';
  }

  @override
  String get turnFailedRetry => 'Javobingiz yuborilmadi';

  @override
  String get assistTooFast => 'Bir soniya — qaytadan urinib ko‘ring.';

  @override
  String get sayAgain => 'Yana ayt';

  @override
  String get saySlower => 'Sekinroq';

  @override
  String get youSaidLabel => 'Siz aytdingiz';

  @override
  String get sttMisheardHint =>
      'Siz aytgandek emasmi? Mikrofonni bosib qayta urinib ko‘ring.';

  @override
  String get switchToTyping => 'Yozib javob berish';

  @override
  String get switchToSpeaking => 'Gapirib javob berish';

  @override
  String get sendAction => 'Yuborish';

  @override
  String get sendingLabel => 'Yuborilmoqda';

  @override
  String get speakingHistoryTitle => 'O‘tgan suhbatlar';

  @override
  String get speakingHistoryEmpty => 'Hali suhbatlar yo‘q';

  @override
  String get speakingHistoryEmptyBody =>
      'Suhbatni yakunlang — u hisoboti bilan shu yerda saqlanadi.';

  @override
  String speakingTurnsCount(int count) {
    return '$count ta javob';
  }

  @override
  String get speakingUnfinished => 'Tugallanmagan';

  @override
  String get speakingNoReport => 'Bu suhbat uchun hisobot yo‘q';

  @override
  String get speakingFreeTopicLabel => 'Erkin mavzu';

  @override
  String get a11yMicReady => 'Mikrofon. Gapirish uchun bosing';

  @override
  String get a11yMicRecording => 'Yozilmoqda. Javobni yuborish uchun bosing';

  @override
  String get a11yMicBusy => 'Kuting — o‘qituvchi javob bermoqda';

  @override
  String get speakingUnclearAudio =>
      'Yaxshi eshitilmadi — biroz aniqroq aytib ko‘ring';

  @override
  String get tapToHide => 'Matnni yashirish uchun bosing';

  @override
  String get groupReply => 'Javob berish';

  @override
  String get questionsDraw => 'Tasodifiy savol';

  @override
  String get questionsDrawHint =>
      'Gap tugab qoldimi? «Tasodifiy savol» ni bosing — hali javob bermagan savolingiz chiqadi.';

  @override
  String get questionsAllSeen => 'Hammasi berildi, yangidan boshlandi';

  @override
  String get courseUnitLocked =>
      'Bu bo‘lim hali ochilmagan — avvalgisini tugating';

  @override
  String courseUnitsDone(int done, int total) {
    return '$done / $total bo‘lim tugatildi';
  }

  @override
  String get courseStart => 'Boshlash';

  @override
  String get courseLessons => 'Darslar';

  @override
  String get courseRule => 'Qoida';

  @override
  String get courseYouWillLearn => 'BU BO‘LIMDA O‘RGANASIZ';

  @override
  String get courseStartLesson => 'Boshlash';

  @override
  String courseContinueLesson(int n) {
    return '$n-darsni davom ettirish';
  }

  @override
  String courseNextUnit(String title) {
    return 'Keyingi mavzu: $title';
  }

  @override
  String courseLessonN(int n) {
    return '$n-dars';
  }

  @override
  String courseItemCount(int n) {
    return '$n ta mashq';
  }

  @override
  String courseMastery(int level, int max) {
    return 'Mahorat $level / $max';
  }

  @override
  String get drillPickMeaning => 'So\'zning ma\'nosini tanlang';

  @override
  String get drillPickWord => 'Mos inglizcha so\'zni tanlang';

  @override
  String get drillMatchPairs =>
      'Chapdagini bosing, so\'ng juftini o\'ngdan tanlang';

  @override
  String get drillPickAnswer => 'To\'g\'ri javobni tanlang';

  @override
  String get drillOrderWords => 'So\'zlarni bosib, gapni tuzing';

  @override
  String get drillTypeMissing => 'Tushib qolgan so\'zni yozing';

  @override
  String get drillRewrite => 'Gapni qayta yozing';

  @override
  String get courseCheck => 'Tekshirish';

  @override
  String get courseContinue => 'Davom etish';

  @override
  String get courseCorrect => 'To\'g\'ri!';

  @override
  String get courseNotQuite => 'Bu safar emas';

  @override
  String courseTheAnswerWas(String answer) {
    return 'To\'g\'ri javob: $answer';
  }

  @override
  String get courseLessonDone => 'Dars tugadi!';

  @override
  String get courseUnitDone => 'Bo\'lim tugadi!';

  @override
  String get courseCorrectCount => 'To\'g\'ri javob';

  @override
  String get courseBackToPath => 'Yo‘lga qaytish';

  @override
  String get courseQuitTitle => 'Darsni tark etasizmi?';

  @override
  String get courseQuitBody => 'Hozirgi javoblaringiz saqlanmaydi.';

  @override
  String get courseQuitStay => 'Davom etaman';

  @override
  String get courseQuitLeave => 'Chiqish';

  @override
  String get lessonCourseTitle => 'Words & Rules';

  @override
  String get lessonCourseSubtitle => 'Qoidalarni o‘rganing, so‘zlarni yodlang';

  @override
  String get lessonPracticeTitle => 'Mashq';

  @override
  String get lessonPracticeSubtitle => 'Xato qilganlaringiz';

  @override
  String get courseWillReturn => 'Bu savol dars oxirida qayta chiqadi';

  @override
  String get courseTestFinish => 'Tugatish';

  @override
  String courseTestPassed(int n) {
    return '$n ta bo‘lim ochildi!';
  }

  @override
  String get courseTestFailed => 'Hali erta — darslardan boshlang';

  @override
  String get courseTestNoXp =>
      'Sakrab o‘tish XP bermaydi. Darslarni qilsangiz, XP olasiz.';

  @override
  String get courseJumpTitle => 'Bu darajani bilasizmi?';

  @override
  String courseJumpBody(int n, int pass) {
    return 'Oldingi bo‘limlardan $n ta savolga javob bering. To‘g‘ri javoblaringiz $pass% dan yuqori bo‘lsa, ular ochiladi — lekin XP berilmaydi.';
  }

  @override
  String get courseJumpStart => 'Sinovni boshlash';

  @override
  String get courseJumpCancel => 'Yo‘q, tartib bilan boraman';

  @override
  String get courseReview => 'TAKRORLASH';

  @override
  String get courseQuitBodyKept =>
      'Javob berganlaringiz saqlanadi, lekin dars tugallanmagan bo\'lib qoladi.';

  @override
  String get homeSpeakLive => 'Jonli suhbat';

  @override
  String get homeGroupTitle => 'Guruh suhbati';

  @override
  String get homeGroupSubtitle => '50 kishigacha ochiq xonada gapiring';

  @override
  String get homePeerTitle => 'Sherik bilan suhbat';

  @override
  String get homePeerSubtitle => 'Bir kishi bilan yuzma-yuz mashq';

  @override
  String get peerFindTap => 'Partner qidirish';

  @override
  String get profilePhotoTitle => 'Profil rasmi';

  @override
  String get profilePhotoPick => 'Galereyadan tanlash';

  @override
  String get profilePhotoCamera => 'Suratga olish';

  @override
  String get profilePhotoReset => 'Telegram rasmiga qaytish';

  @override
  String get profilePhotoSaved => 'Rasm yangilandi';

  @override
  String get profilePhotoTooLarge =>
      'Rasm juda katta — 2 MB gacha bo‘lishi kerak';

  @override
  String get commProfileIntro =>
      'So‘nggi suhbatlaringiz asosida. Har bir baho — 100 ballik shkalada.';

  @override
  String get bandStrong => 'Kuchli';

  @override
  String get bandGood => 'Yaxshi';

  @override
  String get bandMiddle => 'O‘rtacha';

  @override
  String get bandStarting => 'Boshlanmoqda';

  @override
  String get trendUp => 'o‘smoqda';

  @override
  String get trendDown => 'pasaymoqda';

  @override
  String get trendSteady => 'barqaror';

  @override
  String get paceExplain =>
      'Ravon suhbat odatda 120–160 so‘z/daqiqa. Tezlik o‘z-o‘zidan maqsad emas — aniq gapirish muhimroq.';

  @override
  String get focusTagsHint =>
      'Ustoz keyingi suhbatlarda shularga e’tibor beradi.';

  @override
  String get tagVerbTense => 'Fe’l zamonlari';

  @override
  String get tagWordChoice => 'So‘z tanlash';

  @override
  String get tagWordOrder => 'So‘z tartibi';

  @override
  String get tagArticles => 'Artikllar (a / the)';

  @override
  String get tagPreposition => 'Predloglar';

  @override
  String get tagPlural => 'Ko‘plik shakli';

  @override
  String get tagAgreement => 'Ega-kesim moslashuvi';

  @override
  String get tagPronoun => 'Olmoshlar';

  @override
  String get tagComparative => 'Qiyosiy daraja';

  @override
  String get tagConditional => 'Shart gaplar';

  @override
  String get tagQuestionForm => 'So‘roq gap tuzilishi';

  @override
  String get tagCollocation => 'So‘z birikmalari';

  @override
  String get accountTitle => 'Hisob';

  @override
  String get xpSourceCourse => 'Kurs darsi';

  @override
  String get developerTitle => 'Yordam';

  @override
  String get developerCopied => 'Telegram manzili nusxalandi';

  @override
  String get speakingTopicsTag => 'CEFR · IELTS';

  @override
  String get peerWhoTitle => 'Kim bilan suhbatlashmoqchisiz?';

  @override
  String get peerWhoFemale => 'Ayol';

  @override
  String get peerWhoMale => 'Erkak';

  @override
  String get peerWhoAny => 'Farqi yo‘q';

  @override
  String get peerWhoFemaleSub => 'Faqat ayollar bilan bog‘lanasiz';

  @override
  String get peerWhoMaleSub => 'Faqat erkaklar bilan bog‘lanasiz';

  @override
  String get peerWhoAnySub => 'Eng tez juftlanadi';

  @override
  String get peerWhoStart => 'Suhbatdosh qidirish';

  @override
  String get peerWhoNarrowHint =>
      'Tanlov qo‘ysangiz kutish uzoqroq bo‘lishi mumkin.';

  @override
  String peerWhoOnline(int count) {
    return '$count kishi onlayn';
  }

  @override
  String get accountName => 'Ism';

  @override
  String get accountUsername => 'Telegram';

  @override
  String get accountPhone => 'Telefon';

  @override
  String get accountGender => 'Jins';

  @override
  String get accountGenderUnset => 'Ko‘rsatilmagan';

  @override
  String get accountGenderFemale => 'Ayol';

  @override
  String get accountGenderMale => 'Erkak';

  @override
  String get accountGenderWhy =>
      'Jonli suhbatda mos suhbatdosh tanlash uchun ishlatiladi.';

  @override
  String get accountNoUsername => 'Yo‘q';

  @override
  String get accountSaved => 'Saqlandi';

  @override
  String get quizTitle => 'Jonli viktorina';

  @override
  String get quizHubTitle => 'Jonli viktorina';

  @override
  String get quizHubSubtitle =>
      'Istalgan vaqtda qo\'shiling — har 3 daqiqada yangi o\'yin';

  @override
  String quizPlaying(int count) {
    return '$count kishi o\'ynayapti';
  }

  @override
  String get quizAlone => 'Birinchi bo\'lib kiring';

  @override
  String quizQuestionOf(int index, int total) {
    return '$index / $total';
  }

  @override
  String get quizPickMeaning => 'Ma\'nosini tanlang';

  @override
  String get quizPickWord => 'So\'zni tanlang';

  @override
  String get quizFillGap => 'Bo\'shliqni to\'ldiring';

  @override
  String get quizGrammar => 'Grammatika';

  @override
  String get quizCorrect => 'To\'g\'ri';

  @override
  String get quizWrong => 'Bu safar emas';

  @override
  String get quizTimeUp => 'Vaqt tugadi';

  @override
  String quizPoints(int points) {
    return '+$points';
  }

  @override
  String get quizMatchBoard => 'Shu o\'yin';

  @override
  String quizNextMatch(int seconds) {
    return 'Yangi o\'yin $seconds soniyada';
  }

  @override
  String get quizMatchOver => 'O\'yin tugadi';

  @override
  String get quizYouPlaceholder => 'Siz';

  @override
  String get quizNoScoreYet => 'Jadvalga tushish uchun javob bering';

  @override
  String get quizEmpty =>
      'Viktorina tayyorlanmoqda. Bir ozdan keyin urinib ko\'ring.';

  @override
  String get quizJoinedMidMatch =>
      'O\'yin o\'rtasida qo\'shildingiz — tez orada yangisi boshlanadi';

  @override
  String get quizStart => 'Viktorinani boshlash';

  @override
  String get quizStartHint =>
      'Hozir hech kim o\'ynamayapti — o\'yin oching, hammaga xabar boradi';

  @override
  String get quizLobbyTitle => 'Boshlanishini kutamiz';

  @override
  String quizWaitingFor(int count) {
    return 'Yana $count kishi kerak';
  }

  @override
  String get quizStartingNow => 'Boshlanmoqda…';

  @override
  String get quizImReady => 'Tayyorman';

  @override
  String get quizYouAreReady => 'Siz o\'yindasiz';

  @override
  String get quizInLobby => 'Lobbida';

  @override
  String quizHostedBy(String name) {
    return '$name o\'yinni ochdi';
  }

  @override
  String get quizLeave => 'Chiqish';

  @override
  String get peerNoMicBody => 'Mikrofon yoqilmadi — qayta bosing';

  @override
  String get peerListening => 'Gapirish uchun mikrofonni bosing';

  @override
  String get homeLiveOpen => 'Hozir ochiq';

  @override
  String get homeLiveQuiet => 'Hozircha bo\'sh';

  @override
  String homeOnlineN(int count) {
    return '$count online';
  }

  @override
  String get homeJoinChat => 'Suhbatga qo\'shilish';

  @override
  String get homeSeeAll => 'Barchasini ko\'rish';

  @override
  String homeLessonsN(int count) {
    return '$count dars';
  }

  @override
  String homeGamesN(int count) {
    return '$count o\'yin';
  }

  @override
  String get homeWordsTitle => 'So\'zlar va grammatika';

  @override
  String get homeWordsSub => 'Yangi so\'zlar, qoidalar va mashqlar';

  @override
  String get homeGamesSub => 'O\'ynang va ingliz tilini yaxshilang';

  @override
  String homeLessonsAt(int done, int total) {
    return '$done / $total dars';
  }

  @override
  String get referralTitle => 'Do‘stni taklif qiling';

  @override
  String referralBody(int minutes) {
    return 'Har bir qo‘shilgan do‘st uchun $minutes daqiqa suhbat. Bu daqiqalar tugamaydi.';
  }

  @override
  String get referralCta => 'Do‘stni taklif qilish';

  @override
  String referralFriends(int count) {
    return '$count do‘st qo‘shildi';
  }

  @override
  String referralShareText(String link) {
    return 'EduGain’da ingliz tilida gapirishni mashq qiling — AI bilan suhbatlashing va boshqa o‘rganuvchilar bilan jonli suhbat qiling.\n\n$link';
  }

  @override
  String referralEarned(int minutes) {
    return 'Jami $minutes daqiqa';
  }

  @override
  String referralLeft(int minutes) {
    return '$minutes daqiqa qoldi';
  }
}
