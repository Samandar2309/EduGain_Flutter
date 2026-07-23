// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get retry => 'Повторить';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get languageTitle => 'Язык';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUzbek => 'O‘zbekcha';

  @override
  String get welcomeTitle => 'Добро пожаловать 👋';

  @override
  String get phoneSubtitle => 'Введите номер телефона, чтобы продолжить';

  @override
  String get phoneLabel => 'Номер телефона';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get dividerOr => 'или';

  @override
  String get googleSignIn => 'Войти через Google';

  @override
  String get termsNotice =>
      'Продолжая, вы соглашаетесь с Условиями использования и Политикой конфиденциальности';

  @override
  String get phoneInvalid =>
      'Введите корректный номер телефона (+998XXXXXXXXX)';

  @override
  String get otpTitle => 'Код подтверждения';

  @override
  String otpSentTo(String phone) {
    return 'Код отправлен на: $phone';
  }

  @override
  String get verify => 'Подтвердить';

  @override
  String resendCountdown(String time) {
    return 'Повторить через $time';
  }

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get otpEnter6 => 'Введите 6-значный код';

  @override
  String get otpResent => 'Новый код отправлен';

  @override
  String get nameTitle => 'Давайте познакомимся';

  @override
  String get nameSubtitle => 'Как к вам обращаться?';

  @override
  String get nameLabel => 'Ваше имя';

  @override
  String get nameHint => 'например, Азиз';

  @override
  String get nameEmpty => 'Пожалуйста, введите имя';

  @override
  String greeting(String name) {
    return 'Привет, $name 👋';
  }

  @override
  String levelLabel(String level) {
    return 'Уровень: $level';
  }

  @override
  String get letsLearnToday => 'Давайте поучимся сегодня!';

  @override
  String get modules => 'Модули';

  @override
  String get statXp => 'XP';

  @override
  String get statLevel => 'Уровень';

  @override
  String get statDay => 'Дней';

  @override
  String get reviewTime => 'Время повторения';

  @override
  String wordsWaiting(int count) {
    return '$count слов ждут вас';
  }

  @override
  String get featuredBadge => 'РЕКОМЕНДУЕМ';

  @override
  String get featuredTitle => 'Начните разговор с ИИ';

  @override
  String get featuredSubtitle => 'Практикуйтесь в настоящем диалоге';

  @override
  String get placementTitle => 'Определите свой уровень';

  @override
  String get placementSubtitle => 'Короткий тест — опыт подстроится под вас';

  @override
  String get moduleSpeakingSubtitle => 'Живой диалог с ИИ';

  @override
  String get moduleVocabSubtitle => 'Расширяйте словарный запас';

  @override
  String get moduleGrammarSubtitle => 'Тренируйте грамматику';

  @override
  String get navHome => 'Главная';

  @override
  String get navLessons => 'Уроки';

  @override
  String get navProfile => 'Профиль';

  @override
  String get lessonsTitle => 'Уроки';

  @override
  String get lessonSpeakingSubtitle => 'Практикуйте речь в живом диалоге с ИИ';

  @override
  String get lessonVocabSubtitle => 'Расширяйте словарный запас с карточками';

  @override
  String get lessonGrammarSubtitle =>
      'Закрепляйте грамматику правилами и упражнениями';

  @override
  String get lessonPlacementTitle => 'Тест на уровень';

  @override
  String get lessonPlacementSubtitle => 'Определите свой уровень CEFR';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get logout => 'Выйти';

  @override
  String get subscription => 'Подписка';

  @override
  String get xpHistory => 'История XP';

  @override
  String get xpHistoryError => 'Не удалось загрузить историю';

  @override
  String get noXpYet => 'Пока нет XP — начните практиковаться!';

  @override
  String get editNameTitle => 'Изменить имя';

  @override
  String get dailyGoalTitle => 'Дневная цель (XP)';

  @override
  String get dailyGoalHint => 'например, 50';

  @override
  String get dailyGoalLabel => 'Дневная цель';

  @override
  String get close => 'Закрыть';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get loadFailed => 'Не удалось загрузить';

  @override
  String get check => 'Проверить';

  @override
  String get yourAnswer => 'Ваш ответ';

  @override
  String get premiumContent => 'Премиум-контент';

  @override
  String get paywallCtaDefault => 'Продолжить с Premium';

  @override
  String get premiumButton => 'Premium';

  @override
  String get freeTopic => 'Свободная тема';

  @override
  String get freeTopicHint => 'например, путешествия';

  @override
  String get freeTopicCardSubtitle => 'Беседа на любую тему';

  @override
  String get scenarios => 'Сценарии';

  @override
  String get scenariosLoadError =>
      'Не удалось загрузить сценарии. Проверьте подключение.';

  @override
  String get limitReachedTitle => 'Лимит исчерпан';

  @override
  String get startConversation => 'Начать';

  @override
  String get feedbackTitle => 'Результат';

  @override
  String get strengths => 'Сильные стороны';

  @override
  String get mistakes => 'Ошибки';

  @override
  String get feedbackLocked =>
      'Полный разбор (все ошибки и советы) открывается с Premium.';

  @override
  String get micPermission =>
      'Нужен доступ к микрофону — включите его в настройках телефона.';

  @override
  String get recordStartError => 'Не удалось начать запись.';

  @override
  String get audioCaptureError => 'Аудио не записано.';

  @override
  String get aiUnavailable => 'ИИ временно недоступен';

  @override
  String get turnLimitReached => 'Лимит беседы исчерпан. Получите результат.';

  @override
  String get speechNotRecognized => 'Речь не распознана — попробуйте ещё раз.';

  @override
  String chatTurnCounter(int turn, int max) {
    return 'Беседа · $turn/$max реплик';
  }

  @override
  String get finishSession => 'Завершить';

  @override
  String get selectVoice => 'Выбрать голос';

  @override
  String get turnLimitBanner =>
      'Лимит беседы исчерпан — нажмите «Завершить» для результата.';

  @override
  String get listening => 'слушаю…';

  @override
  String get tapToSpeak => 'Нажмите, чтобы говорить';

  @override
  String get composerHint => 'Напишите сообщение или говорите…';

  @override
  String get recordingLabel => 'Идёт запись';

  @override
  String get tapToSend => 'Нажмите, чтобы отправить';

  @override
  String get chooseVoice => 'Выберите голос';

  @override
  String get voicesLoadError => 'Не удалось загрузить список голосов.';

  @override
  String get noVoices => 'Голосов пока нет.';

  @override
  String get voicePreview => 'Прослушать';

  @override
  String get voicePreviewError => 'Не удалось воспроизвести голос.';

  @override
  String get genderFemale => 'Женский';

  @override
  String get genderMale => 'Мужской';

  @override
  String get noSets => 'Пока нет наборов';

  @override
  String get noWords => 'Нет слов';

  @override
  String get tapCardToFlip => 'Нажмите на карточку, чтобы увидеть';

  @override
  String get dontKnow => 'Не знаю';

  @override
  String get know => 'Знаю';

  @override
  String get congrats => 'Поздравляем! 🎉';

  @override
  String vocabResult(int learned, int total) {
    return 'Вы знали $learned из $total слов.';
  }

  @override
  String get reviewTitle => 'Повторение';

  @override
  String get allReviewed => 'Всё повторено! 🎉';

  @override
  String get noReviewWords =>
      'Сейчас нет слов для повторения.\nПродолжайте учить новые слова.';

  @override
  String get wordSets => 'Наборы слов';

  @override
  String get greatJob => 'Отличная работа! 🎉';

  @override
  String reviewResult(int correct, int reviewed) {
    return 'Вы вспомнили $correct из $reviewed слов.';
  }

  @override
  String get tapToSeeMeaning => 'Нажмите на карточку, чтобы увидеть значение';

  @override
  String get couldntRecall => 'Не вспомнил';

  @override
  String get recalled => 'Вспомнил';

  @override
  String get noTopics => 'Пока нет тем';

  @override
  String get atLeastOneAnswer => 'Дайте хотя бы один ответ';

  @override
  String grammarScore(int score, int total) {
    return 'Результат: $score / $total';
  }

  @override
  String get placementTestTitle => 'Тест на уровень';

  @override
  String get noQuestions => 'Вопросы не найдены';

  @override
  String get resultReady => 'Результат готов 🎯';

  @override
  String get yourEnglishLevel => 'Ваш уровень английского';

  @override
  String get startAction => 'Начать';

  @override
  String get finishAction => 'Завершить';

  @override
  String get nextAction => 'Далее';

  @override
  String get choosePayment => 'Выберите способ оплаты';

  @override
  String get paymentPageError => 'Не удалось открыть страницу оплаты';

  @override
  String get finishPaymentTitle => 'Завершите оплату';

  @override
  String get finishPaymentBody =>
      'Завершите оплату в браузере, затем проверьте статус.';

  @override
  String get cancelSubscriptionTitle => 'Отменить подписку';

  @override
  String get cancelSubscriptionBody =>
      'Привилегии сохранятся до конца периода. Продолжить?';

  @override
  String get currentPlan => 'Текущий тариф';

  @override
  String validUntil(String date) {
    return 'Действует до: $date';
  }

  @override
  String get cancelAction => 'Отменить';

  @override
  String pricePerMonth(String price) {
    return '$price / мес';
  }

  @override
  String get choosePlan => 'Выбрать';

  @override
  String get quotaTitle => 'Дневное время разговора';

  @override
  String quotaMinutesLeft(int minutes) {
    return 'Осталось $minutes мин';
  }

  @override
  String quotaUsedOf(int used, int total) {
    return 'Использовано $used из $total мин';
  }

  @override
  String get quotaExhausted => 'Минуты на сегодня закончились';

  @override
  String get quotaUpgrade => 'Увеличить лимит';

  @override
  String get commProfileTitle => 'Профиль общения';

  @override
  String get commProfileEmpty =>
      'Проведите несколько бесед с ИИ-репетитором — профиль построится сам из вашей живой речи.';

  @override
  String get focusTagsTitle => 'Сейчас работаем над';

  @override
  String get paceLabel => 'Темп речи';

  @override
  String paceValue(int wpm) {
    return '$wpm слов/мин';
  }

  @override
  String paceTarget(int target) {
    return 'цель $target';
  }

  @override
  String get minutesSpoken => 'Минут говорения';

  @override
  String get wordsSpoken => 'Сказано слов';

  @override
  String basedOnSessions(int count) {
    return 'на основе $count бесед';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get paywallReportTitle => 'Откройте полный отчёт';

  @override
  String get paywallReportBody =>
      'Каждая ошибка, исправление и личный совет — с Premium.';

  @override
  String get paywallSeePlans => 'Смотреть тарифы';

  @override
  String get premiumBadge => 'Premium';

  @override
  String get planPopular => 'Самый популярный';

  @override
  String get premiumHeroTitle => 'EduGain Premium';

  @override
  String get premiumHeroBody =>
      'Говорите больше каждый день, откройте все треки и получайте полный анализ своей речи.';

  @override
  String get appTagline => 'Английский с искусственным интеллектом';

  @override
  String get welcomeChooseLanguage => 'Выберите язык';

  @override
  String get welcomeSkip => 'Пропустить';

  @override
  String get welcomeStart => 'Начать';

  @override
  String get welcomeSpeakTitle => 'Говорите с ИИ-репетитором';

  @override
  String get welcomeSpeakBody =>
      'Живые диалоги в любое время суток. Без осуждения и страха ошибиться — просто практика.';

  @override
  String get welcomeCoachTitle => 'Подсказки прямо в разговоре';

  @override
  String get welcomeCoachBody =>
      'Мягкие исправления после каждой фразы и понятный отчёт о грамматике, лексике и беглости.';

  @override
  String get welcomeGoalTitle => 'Путь к вашей цели';

  @override
  String get welcomeGoalBody =>
      'IELTS, карьера, путешествия или повседневная речь — трек подстраивается под ваши слабые места.';

  @override
  String get xpSourceDailyGoal => 'Дневная цель';

  @override
  String get xpSourceStreak => 'Бонус за серию';

  @override
  String get coachCorrection => 'Исправление';

  @override
  String get coachNatural => 'Естественный вариант';

  @override
  String get coachGrammar => 'Грамматика';

  @override
  String get coachVocabulary => 'Лексика';

  @override
  String get coachPronunciation => 'Произношение';

  @override
  String get statusSpeaking => 'Говорит…';

  @override
  String get statusListening => 'Слушает…';

  @override
  String get statusThinking => 'Думает…';

  @override
  String get scoreOverall => 'Итог';

  @override
  String get scoreGrammar => 'Грамматика';

  @override
  String get scoreVocabulary => 'Лексика';

  @override
  String get scoreFluency => 'Беглость';

  @override
  String get scorePronunciation => 'Произношение';

  @override
  String get scoresEstimatedNote =>
      'Беглость и произношение оценены по тексту.';

  @override
  String get voiceUnavailable => 'Голос временно недоступен.';

  @override
  String get listenModeOn => 'Режим аудирования — текст скрыт';

  @override
  String get listenModeOff => 'Показать текст';

  @override
  String get tapToReveal => 'Нажмите, чтобы показать';

  @override
  String get actionTranslate => 'Перевод';

  @override
  String get actionHint => 'Подсказка';

  @override
  String get hintTitle => 'Как ответить';

  @override
  String get hintTip =>
      'Ответьте полным предложением и задайте встречный вопрос, чтобы продолжить разговор.';
}
