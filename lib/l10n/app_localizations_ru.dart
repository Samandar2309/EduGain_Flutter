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
  String get peerQuotaTitle => 'Время живого общения на сегодня закончилось';

  @override
  String get peerQuotaBody =>
      'Оформите подписку — живое общение без ограничений.';

  @override
  String get resumeTitle => 'Незавершённый разговор';

  @override
  String resumeSubtitle(int turns) {
    return 'Пройдено реплик: $turns — продолжите с того же места';
  }

  @override
  String get resumeAction => 'Продолжить';

  @override
  String get networkError => 'Проблема с подключением. Попробуйте ещё раз.';

  @override
  String get feedbackNotReadyTitle => 'Отчёт не готов';

  @override
  String get feedbackNotReadyBody =>
      'Ваш разговор сохранён. Сервис оценки сейчас не ответил — отчёт можно собрать заново.';

  @override
  String get continueAction => 'Продолжить';

  @override
  String minutesShort(int count) {
    return '$count мин';
  }

  @override
  String groupRoomHoldsUpTo(int count) {
    return 'В комнату поместится до $count человек';
  }

  @override
  String get cannotHearYou => 'Мы вас не слышим — говорите громче или напишите';

  @override
  String get micBlockedTapToAllow =>
      'Микрофон закрыт — нажмите, чтобы разрешить';

  @override
  String minutesLeft(int count) {
    return 'осталось $count мин';
  }

  @override
  String get actionEnd => 'Завершить';

  @override
  String get questionsTitle => 'Вопросы';

  @override
  String get workedTitle => 'Как отвечать';

  @override
  String get workedWeak => 'Так отвечает большинство';

  @override
  String get workedStrong => 'А так — лучше';

  @override
  String get workedMoves => 'Что изменилось';

  @override
  String get workedLocked => 'Разбор ответа — в Premium';

  @override
  String get workedLockedWhy =>
      'Вопросы открыты для всех. Разбор — слабый и сильный ответ рядом, с отмеченной разницей — в Premium.';

  @override
  String get workedOpen => 'Открыть разбор';

  @override
  String questionsFollows(String title) {
    return 'После карточки «$title»';
  }

  @override
  String get questionsPart3Hint =>
      'Эти вопросы не о вас лично, а об обществе. Высказывайте мнение и обосновывайте его, не ограничивайтесь парой фраз.';

  @override
  String get cueCardLabel => 'Карточка';

  @override
  String get cueCardYouShouldSay => 'Вы должны рассказать:';

  @override
  String get cueCardHint =>
      'Готовьтесь 1 минуту, затем говорите 2 минуты без остановки. В паре: один читает карточку и следит за временем, потом меняетесь.';

  @override
  String cueCardPrep(int count) {
    return '$count мин на подготовку';
  }

  @override
  String cueCardTalk(int count) {
    return '$count мин говорить';
  }

  @override
  String get questionsModeSubtitle => 'Готовые вопросы для разговора';

  @override
  String get questionsIntro =>
      'Задавайте их друг другу в живом разговоре или готовьтесь заранее.';

  @override
  String get questionsUseHint =>
      'Выберите вопрос и задайте партнёру — потом ответьте сами.';

  @override
  String get questionsSaved => 'Сохранённые';

  @override
  String get questionsNoneSaved =>
      'Вы пока ничего не сохранили.\nОтмечайте вопросы закладкой.';

  @override
  String get questionsNew => 'НОВОЕ';

  @override
  String get questionsError => 'Не удалось загрузить вопросы.';

  @override
  String get speakingSectionPrepare => 'Подготовка';

  @override
  String questionsCount(int count) {
    return '$count вопр.';
  }

  @override
  String questionsTopicCount(int count) {
    return '$count тем';
  }

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
  String get learnLangComingSoon => 'Скоро';

  @override
  String get learnLangNotifyMe => 'Сообщим';

  @override
  String learnLangInterestSaved(String language) {
    return 'Записали. Расскажем вам первым, когда откроется $language.';
  }

  @override
  String get feedbackSendTitle => 'Оставить отзыв';

  @override
  String get feedbackSendSubtitle =>
      'Что не сработало, чего не хватает — напишите. Мы читаем всё.';

  @override
  String get feedbackHint => 'Опишите проблему или предложение…';

  @override
  String get feedbackSend => 'Отправить';

  @override
  String get feedbackEmpty => 'Пожалуйста, сначала напишите отзыв';

  @override
  String get feedbackThanks => 'Спасибо! Мы получили ваше сообщение.';

  @override
  String get feedbackTooMany =>
      'На сегодня сообщений достаточно. Продолжим завтра.';

  @override
  String get rateSessionQuestion => 'Как прошёл этот разговор?';

  @override
  String get rateSessionCommentHint =>
      'Хотите добавить комментарий? (необязательно)';

  @override
  String get rateSessionCommentSent => 'Комментарий отправлен. Спасибо!';

  @override
  String get rateSessionThanks => 'Спасибо — это нам поможет.';

  @override
  String get channelTitle => 'Подпишитесь на наш канал';

  @override
  String get channelSubtitle =>
      'Новые уроки, полезные советы и новости — всё там. Подпишитесь один раз, и продолжим.';

  @override
  String get channelOpenAction => 'Перейти в канал';

  @override
  String get channelJoinedAction => 'Я подписался';

  @override
  String get channelNotYet =>
      'Подписку пока не видно. Присоединитесь к каналу и попробуйте ещё раз.';

  @override
  String greeting(String name) {
    return 'Привет, $name 👋';
  }

  @override
  String levelLabel(String level) {
    return 'Английский: $level';
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
  String get details => 'Подробнее';

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
  String get voiceAddMore => 'Добавить голоса';

  @override
  String get voiceAddMoreIntro =>
      'Приложение может использовать только те голоса, которые уже есть на устройстве. Установите новые в настройках устройства, затем вернитесь и обновите список.';

  @override
  String get voiceStepsAndroid =>
      'Настройки → Система → Языки и ввод → Синтез речи → Google Text-to-Speech → Установить голосовые данные → English. Выбирайте голоса «Enhanced» — они звучат гораздо естественнее.';

  @override
  String get voiceStepsIos =>
      'Настройки → Универсальный доступ → Устный контент → Голоса → English. Загрузите голос «Premium» или «Enhanced», например Evan или Nathan.';

  @override
  String get voiceStepsWindows =>
      'Параметры → Время и язык → Речь → Управление голосами → Добавить голоса → English (United States).';

  @override
  String get voiceStepsMac =>
      'Системные настройки → Универсальный доступ → Устный контент → Системный голос → Управление голосами → English.';

  @override
  String get voiceStepsGeneric =>
      'Откройте настройки устройства, найдите синтез речи или устный контент и установите английский голос.';

  @override
  String get voiceRefresh => 'Обновить список';

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
  String get gamesTitle => 'Игры';

  @override
  String get gamesVocabTitle => 'Игры со словами';

  @override
  String get gamesVocabSubtitle =>
      'Одному, против Gainsy или с живым соперником';

  @override
  String get gamesGrammarTitle => 'Грамматика';

  @override
  String get gamesGrammarSubtitle => 'Выучите правило и потренируйтесь';

  @override
  String get gamesBrowseTitle => 'Посмотреть слова';

  @override
  String get gamesBrowseSubtitle => 'С переводом и примером';

  @override
  String get gamesReviewSubtitle => 'Слова, которые вот-вот забудутся';

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
  String get placementResultBody =>
      'Теперь преподаватель будет говорить на этом уровне — он изменится по мере вашего прогресса.';

  @override
  String get placementLastResultTitle => 'Ваш последний результат';

  @override
  String get placementTakenToday => 'Пройден сегодня';

  @override
  String get placementTakenYesterday => 'Пройден вчера';

  @override
  String placementTakenDaysAgo(int days) {
    return 'Пройден $days дн. назад';
  }

  @override
  String get placementRetakeQuestion => 'Хотите пройти тест заново?';

  @override
  String get placementRetakeReplaces =>
      'Новый результат заменит текущий уровень.';

  @override
  String get placementRetakeAction => 'Да, начать заново';

  @override
  String get placementKeepAction => 'Нет, оставить уровень';

  @override
  String get levelInviteTitle => 'Сначала определим ваш уровень';

  @override
  String get levelInviteBody =>
      'Несколько коротких вопросов. После этого преподаватель будет говорить на понятном вам уровне, а не наугад.';

  @override
  String get levelInviteMeta => '18 вопросов · около 2 минут';

  @override
  String get levelInviteStart => 'Определить уровень';

  @override
  String get levelInviteSkip => 'Не сейчас';

  @override
  String get leaderboardTitle => 'Рейтинг';

  @override
  String get navLeaderboard => 'Рейтинг';

  @override
  String get leaderboardThisWeek => 'Эта неделя';

  @override
  String get leaderboardLastWeek => 'Прошлая';

  @override
  String get leaderboardEmpty => 'На этой неделе ещё никто не набрал XP.';

  @override
  String get leaderboardEmptyLastWeek =>
      'На прошлой неделе никто не набрал XP.';

  @override
  String get leaderboardFirstPlaceOpen => 'Первый разговор — первое место.';

  @override
  String get leaderboardNotRankedYet =>
      'Пройдите один урок, чтобы попасть в рейтинг.';

  @override
  String get leaderboardYou => 'Вы';

  @override
  String get leaderboardYouAreFirst => 'Вы первый — удержите место.';

  @override
  String get leaderboardPlaceSuffix => '-е место —';

  @override
  String leaderboardStreakDays(int days) {
    return '$days дн.';
  }

  @override
  String get leaderboardResetsMonday =>
      'Рейтинг обновляется каждый понедельник.';

  @override
  String get tierFree => 'Бесплатно';

  @override
  String get homeLevelUnknown => 'Уровень: не определён';

  @override
  String get statStreak => 'Дней подряд';

  @override
  String get statGoal => 'Цель';

  @override
  String get homeAiKicker => 'Рекомендуем';

  @override
  String get homeAiTitle => 'Начните разговор с AI';

  @override
  String get homeAiSubtitle => 'Развивайте разговорную речь';

  @override
  String get homeAiLocked => 'Откроется после определения уровня';

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
  String get coachWhy => 'Почему';

  @override
  String get coachMore => 'Почему и естественный вариант';

  @override
  String get coachLess => 'Скрыть пояснение';

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

  @override
  String get groupChatTitle => 'Групповой разговор';

  @override
  String get groupCreateRoom => 'Создать комнату';

  @override
  String get groupNewRoom => 'Новый групповой разговор';

  @override
  String get groupTopicLabel => 'Тема';

  @override
  String get groupVisibilityLabel => 'Видимость';

  @override
  String get groupPublicOption => 'Открытая';

  @override
  String get groupPrivateOption => 'Закрытая';

  @override
  String get groupPublicHint => 'Любой может зайти из лобби';

  @override
  String get groupPrivateHint => 'Войти можно только по коду или ссылке';

  @override
  String groupParticipantsCount(int count) {
    return 'Участники: $count';
  }

  @override
  String get groupCreateAndStart => 'Создать и начать';

  @override
  String get groupCreateFailed => 'Не удалось создать комнату';

  @override
  String get groupEmptyTitle => 'Пока нет открытых разговоров';

  @override
  String get groupEmptySubtitle => 'Создайте первую комнату!';

  @override
  String get groupJoinByCode => 'Войти по коду';

  @override
  String get groupCodeHint => 'например: ABC123';

  @override
  String get groupInviteFriends => 'Пригласите друзей';

  @override
  String get groupShareTelegram => 'Поделиться в Telegram';

  @override
  String get groupCopyCode => 'Копировать код';

  @override
  String get groupCodeCopied => 'Код скопирован';

  @override
  String get inviteCopied => 'Приглашение скопировано — отправьте его другу';

  @override
  String get groupInvite => 'Пригласить';

  @override
  String groupInviteShareText(String code) {
    return 'Присоединяйтесь к разговорной комнате в EduGain! 🎙\n\nКод комнаты: $code\n\nОткройте @edugain_bot → Speaking → Групповая комната → «Войти по коду»';
  }

  @override
  String get groupConnected => 'Подключён';

  @override
  String get groupConnectingStatus => 'Подключение…';

  @override
  String get groupYou => 'Вы';

  @override
  String get groupMicOff => 'Микрофон выключен';

  @override
  String get groupRemove => 'Удалить';

  @override
  String get groupRoomNotFound => 'Комната не найдена';

  @override
  String get groupFull => 'Заполнено';

  @override
  String get groupJoin => 'Присоединиться';

  @override
  String get groupKickedMsg => 'Вас удалили из комнаты';

  @override
  String get groupConnectErrorMsg => 'Ошибка подключения';

  @override
  String get groupChatEmpty => 'Сообщений пока нет — напишите первым';

  @override
  String get groupModeratorNote => 'AI-модератор ведёт тему';

  @override
  String get groupRule4b => 'Следуйте указаниям AI-модератора';

  @override
  String get groupCallTime => 'Время разговора';

  @override
  String get groupLeaveRoom => 'Покинуть комнату';

  @override
  String get groupOthers => 'Другие';

  @override
  String get groupWriteMessage => 'Напишите сообщение…';

  @override
  String get groupParticipants => 'Участники';

  @override
  String get groupSeeAll => 'Показать всех';

  @override
  String get groupRulesTitle => 'Правила комнаты';

  @override
  String get groupRule1 => 'Слушайте друг друга';

  @override
  String get groupRule2 => 'Будьте вежливы';

  @override
  String get groupRule3 => 'Говорите по-английски';

  @override
  String get groupRule4 => 'Без спама';

  @override
  String get groupSettingsTitle => 'Настройки разговора';

  @override
  String get groupSettingMic => 'Микрофон';

  @override
  String get groupSettingNotify => 'Уведомления';

  @override
  String get groupSettingRules => 'Правила';

  @override
  String get groupSpeakNow => 'Говорить';

  @override
  String get groupMuteMic => 'Выключить микрофон';

  @override
  String get groupSpeakingNow => 'СЕЙЧАС ГОВОРЯТ';

  @override
  String get groupNobodySpeaking => 'Никто не говорит';

  @override
  String get groupInRoom => 'В КОМНАТЕ';

  @override
  String get groupMuteMember => 'Выключить микрофон';

  @override
  String get groupMakeHost => 'Передать роль хоста';

  @override
  String get groupMuteEveryone => 'Выключить всем микрофон';

  @override
  String get groupMutedByHost => 'Хост выключил ваш микрофон';

  @override
  String get groupMicBlocked => 'Нет доступа к микрофону';

  @override
  String get groupHostBadge => 'Хост';

  @override
  String get groupMore => 'ещё';

  @override
  String get grammarTitle => 'Грамматика';

  @override
  String get grammarChooseLevel => 'Выберите свой уровень';

  @override
  String get grammarLevelsSubtitle => 'От A1 до C2 — грамматика шаг за шагом';

  @override
  String grammarTopicCount(int count) {
    return '$count тем';
  }

  @override
  String get comingSoon => 'Скоро';

  @override
  String get grammarLevelA1 => 'Начальный';

  @override
  String get grammarLevelA2 => 'Элементарный';

  @override
  String get grammarLevelB1 => 'Средний';

  @override
  String get grammarLevelB2 => 'Выше среднего';

  @override
  String get grammarLevelC1 => 'Продвинутый';

  @override
  String get grammarLevelC2 => 'Профессиональный';

  @override
  String get grammarRulePlusPractice => 'Правило + практика';

  @override
  String get grammarLearnRule => 'Изучить правило';

  @override
  String get grammarRuleExamplesPattern => 'Правило, примеры и шаблон';

  @override
  String get grammarPractice => 'Практика';

  @override
  String get grammarPracticeSubtitle =>
      'Игры «заполни пропуск» и «составь предложение»';

  @override
  String get grammarStartPractice => 'Начать практику';

  @override
  String get grammarRuleLabel => 'Правило';

  @override
  String get grammarRuleReadySpeaking =>
      'Теперь попробуйте применить это правило в практике Speaking 🎯';

  @override
  String get grammarNotEnoughExercises => 'Недостаточно заданий по этой теме.';

  @override
  String get grammarChooseForm => 'ВЫБЕРИТЕ ПРАВИЛЬНУЮ ФОРМУ';

  @override
  String get grammarBuildSentence => 'СОСТАВЬТЕ ПРЕДЛОЖЕНИЕ';

  @override
  String get answerCorrectExcl => 'Правильно!';

  @override
  String get answerWrongLabel => 'Неправильно';

  @override
  String correctAnswerLabel(String answer) {
    return 'Правильный ответ: $answer';
  }

  @override
  String get vocabWhatToDo => 'Что будем делать?';

  @override
  String get vocabLearnTitle => 'Учить слова';

  @override
  String get vocabLearnSubtitle =>
      'Смотрите новые слова с переводом и примерами';

  @override
  String get vocabTestKnowledge => 'Проверить знания';

  @override
  String get vocabTestSubtitle => 'Проверьте выученное в играх';

  @override
  String get vocabDailyReview => 'Ежедневное повторение';

  @override
  String vocabDueReady(int count) {
    return '$count слов готовы к повторению — закрепите их.';
  }

  @override
  String get vocabStartReview => 'Начать повторение';

  @override
  String get vocabNotEnoughReview => 'Недостаточно слов для повторения';

  @override
  String vocabWordCount(int count) {
    return '$count слов';
  }

  @override
  String get vocabWordSet => 'Набор слов';

  @override
  String get vocabHowToPlay => 'Как играем?';

  @override
  String get vocabSoloTitle => 'Соло-игра';

  @override
  String get vocabSoloSubtitle => 'Учите слова в своём темпе';

  @override
  String get vocabSpellTitle => 'Собери слово';

  @override
  String get vocabSpellSubtitle => 'Соберите слово по памяти';

  @override
  String get vocabDuelBotTitle => 'Дуэль с Gainsy';

  @override
  String get vocabDuelBotSubtitle => 'Гонка на скорость против бота';

  @override
  String get vocabDuelOnlineTitle => 'Игра с человеком';

  @override
  String get vocabDuelOnlineSubtitle => 'Гонка на скорость с живым соперником';

  @override
  String get vocabNotEnoughWords => 'В этом наборе недостаточно слов для игры.';

  @override
  String get loadRetryError => 'Ошибка загрузки. Повторите попытку.';

  @override
  String get vocabGainsyAnswering => 'Gainsy отвечает…';

  @override
  String get vocabFindingOpponent => 'Ищем соперника…';

  @override
  String get vocabDuelWaitHint =>
      'Вы подключитесь автоматически, когда другой ученик выберет эту игру';

  @override
  String get vocabNoOpponent => 'Сейчас нет соперников онлайн.';

  @override
  String get vocabPlayWithGainsy => 'Играть с Gainsy';

  @override
  String vocabPartnerAnswering(String name) {
    return '$name отвечает…';
  }

  @override
  String get vocabConnLostPlayBot =>
      'Проблема с подключением. Сыграть с Gainsy?';

  @override
  String get backAction => 'Назад';

  @override
  String get vocabSpellInstruction => 'СОБЕРИТЕ СЛОВО ПО БУКВАМ';

  @override
  String get vocabNoSpellWords =>
      'В этом наборе нет подходящих слов для сборки.';

  @override
  String get gameChooseTranslation => 'Выберите перевод';

  @override
  String get gameChooseWord => 'Выберите слово';

  @override
  String get gameWordsReadySpeaking =>
      'Эти слова теперь готовы к практике Speaking 🎯';

  @override
  String get gameYouWon => 'Вы победили!';

  @override
  String gameOpponentAhead(String name) {
    return '$name впереди на этот раз';
  }

  @override
  String get gameNiceWork => 'Отличная работа!';

  @override
  String get youLabel => 'Вы';

  @override
  String get gameCorrectAnswers => 'Верно';

  @override
  String get gameCombo => 'Комбо';

  @override
  String get gameAccuracy => 'Точность';

  @override
  String get gamePlayAgain => 'Играть снова';

  @override
  String get vocabTitle => 'Словарь';

  @override
  String get speakingSectionAi => 'С ИИ-репетитором · всегда доступно';

  @override
  String get speakingSectionLive => 'С людьми · вживую';

  @override
  String get speakingFreeTitle => 'Свободный разговор';

  @override
  String get speakingFreeSubtitle => 'С ИИ на любую тему';

  @override
  String get speakingTopicsTitle => 'Готовые уроки';

  @override
  String get speakingTopicsSubtitle => 'С ИИ по вашему уровню';

  @override
  String get speakingGroupSubtitle =>
      'Зайдите в открытую комнату или создайте свою';

  @override
  String get speakingOneToOneTitle => 'Разговор 1:1';

  @override
  String get speakingOneToOneSubtitle => 'Практика один на один';

  @override
  String get peerLiveChat => 'Живой разговор';

  @override
  String get micPrimerTitle => 'Включите микрофон';

  @override
  String get micPrimerBody =>
      'Собеседник должен вас слышать. Сейчас браузер запросит доступ — нажмите «Allow» (Разрешить).';

  @override
  String get micPrimerAllowWord => 'Allow';

  @override
  String get micPrimerBlockWord => 'Block';

  @override
  String get micPrimerContinue => 'Продолжить';

  @override
  String get micBlockedTelegramBody =>
      'Доступ к микрофону был отклонён. Полностью закройте Telegram, откройте EduGain заново и на этот раз нажмите «Allow».';

  @override
  String get micBlockedBrowserBody =>
      'Микрофон заблокирован для этого сайта. Нажмите на замок рядом с адресом → Микрофон → Разрешить, затем обновите страницу.';

  @override
  String get peerPartnerMicOff =>
      'У собеседника выключен микрофон — он слышит вас, а вы его нет.';

  @override
  String get peerNoMicRejoin =>
      'Микрофон не включён. Завершите звонок и начните заново — доступ спросят сразу.';

  @override
  String get micPreparing => 'Готовим микрофон…';

  @override
  String get micNeededTitle => 'Нужен микрофон';

  @override
  String get micDeniedBody =>
      'Чтобы говорить с собеседником, нужен доступ к микрофону.';

  @override
  String get micBlockedBody =>
      'Доступ к микрофону заблокирован. Разрешите его в настройках браузера или Telegram и попробуйте снова.';

  @override
  String get micNotFoundBody => 'Микрофон на этом устройстве не найден.';

  @override
  String get micBusyBody =>
      'Микрофон занят другим приложением. Закройте его и попробуйте снова.';

  @override
  String get micInsecureBody =>
      'Микрофон работает только по защищённому соединению. Откройте приложение заново из бота.';

  @override
  String get micConstraintsBody =>
      'Ваш микрофон не поддерживает настройки, нужные для звонка.';

  @override
  String get micUnknownBody =>
      'Не удалось включить микрофон. Попробуйте ещё раз.';

  @override
  String get micRetry => 'Попробовать снова';

  @override
  String get peerFriendRoom => 'Комната с другом';

  @override
  String get peerJoinByCode => 'Войти по коду';

  @override
  String get peerHistory => 'История разговоров';

  @override
  String peerConvCount(int count) {
    return '$count разговоров';
  }

  @override
  String get peerRoomCode => 'Код комнаты';

  @override
  String get peerEnter => 'Войти';

  @override
  String peerOnlineCount(int count) {
    return '$count человек онлайн';
  }

  @override
  String get peerFindPartner => 'Найти собеседника';

  @override
  String get peerFindPartnerSubtitle =>
      'Случайно подключитесь к ученику онлайн\nи проведите живой разговор на английском';

  @override
  String get peerNoHistoryTitle => 'Разговоров пока нет';

  @override
  String get peerNoHistorySubtitle =>
      'Найдите первого собеседника — каждый разговор\nсохраняется здесь.';

  @override
  String get peerToday => 'Сегодня';

  @override
  String get peerYesterday => 'Вчера';

  @override
  String peerDurMinSec(int m, int s) {
    return '$m мин $s с';
  }

  @override
  String peerDurSec(int s) {
    return '$s с';
  }

  @override
  String get peerStatusConnecting => 'Подключение…';

  @override
  String get peerStatusSearching => 'Ищем собеседника…';

  @override
  String get peerStatusWaitingFriend => 'Ждём вашего друга';

  @override
  String get peerStatusConnectingVoice => 'Подключаем звук…';

  @override
  String peerStatusLiveChat(String time) {
    return 'Живой разговор · $time';
  }

  @override
  String get peerStatusEnded => 'Разговор завершён';

  @override
  String get peerSearchingTitle => 'Ищем подходящего собеседника…';

  @override
  String get peerSearchingSubtitle =>
      'Вы подключитесь автоматически, как только другой\nученик начнёт поиск';

  @override
  String get peerYourPartner => 'Ваш собеседник';

  @override
  String get peerInviteTelegram => 'Пригласить через Telegram';

  @override
  String peerInviteShareText(String code) {
    return 'Присоединяйтесь ко мне на живой разговор на английском в EduGain! Введите этот код в разделе «Живой разговор»: $code';
  }

  @override
  String get peerYourRole => 'Ваша роль';

  @override
  String get peerPartnerRole => 'Роль собеседника';

  @override
  String get peerStopSearching => 'Остановить поиск';

  @override
  String get peerEndedPartnerLeft => 'Собеседник покинул разговор.';

  @override
  String get peerEndedYouEnded => 'Разговор завершён. Хорошая практика! 👏';

  @override
  String get peerEndedFailed =>
      'Возникла проблема с подключением. Повторите попытку.';

  @override
  String get peerEndedDefault => 'Разговор завершён.';

  @override
  String get speakingDailyMission => 'Ежедневная миссия';

  @override
  String get speakingRecommended => 'Рекомендуем вам';

  @override
  String get seeAll => 'Все';

  @override
  String get tracksSectionTitle => 'Направления';

  @override
  String lessonsOf(int done, int total) {
    return '$done из $total уроков';
  }

  @override
  String get speakingExploreByGoal => 'По целям';

  @override
  String get speakingLessonPremium => 'Этот урок входит в Premium.';

  @override
  String speakingReachToUnlock(String level) {
    return 'Достигните $level, чтобы открыть этот урок.';
  }

  @override
  String get speakingStartFirstLesson => 'Начните первый урок';

  @override
  String get speakingPickGoal => 'Выберите цель и начните говорить за секунды.';

  @override
  String get speakingStartNow => 'Начать сейчас';

  @override
  String get speakingContinueLearning => 'Продолжить обучение';

  @override
  String get speakingPracticeAgain => 'Повторить';

  @override
  String get speakingTodaysMission => 'Сегодняшняя миссия Speaking';

  @override
  String get speakingLoadError => 'Не удалось загрузить Speaking.';

  @override
  String get speakingLastToday => 'Открыто сегодня';

  @override
  String get speakingLastYesterday => 'Открыто вчера';

  @override
  String speakingLastDaysAgo(int days) {
    return 'Открыто $days дн. назад';
  }

  @override
  String speakingMinutesShort(int minutes) {
    return '$minutes мин';
  }

  @override
  String speakingLessonsShort(int done, int total) {
    return '$done/$total уроков';
  }

  @override
  String speakingLessonsCompleted(int done, int total) {
    return '$done из $total уроков пройдено';
  }

  @override
  String get turnFailedRetry => 'Ваш ответ не отправлен';

  @override
  String get assistTooFast => 'Секунду — попробуйте ещё раз.';

  @override
  String get sayAgain => 'Повторить';

  @override
  String get saySlower => 'Медленнее';

  @override
  String get youSaidLabel => 'Вы сказали';

  @override
  String get sttMisheardHint =>
      'Не то, что вы сказали? Нажмите микрофон и повторите.';

  @override
  String get switchToTyping => 'Написать текстом';

  @override
  String get switchToSpeaking => 'Говорить';

  @override
  String get sendAction => 'Отправить';

  @override
  String get sendingLabel => 'Отправка';

  @override
  String get speakingHistoryTitle => 'Прошлые разговоры';

  @override
  String get speakingHistoryEmpty => 'Разговоров пока нет';

  @override
  String get speakingHistoryEmptyBody =>
      'Завершите разговор — он сохранится здесь вместе с отчётом.';

  @override
  String speakingTurnsCount(int count) {
    return '$count реплик';
  }

  @override
  String get speakingUnfinished => 'Не завершён';

  @override
  String get speakingNoReport => 'Для этого разговора нет отчёта';

  @override
  String get speakingFreeTopicLabel => 'Свободная тема';

  @override
  String get a11yMicReady => 'Микрофон. Нажмите, чтобы говорить';

  @override
  String get a11yMicRecording => 'Идёт запись. Нажмите, чтобы отправить';

  @override
  String get a11yMicBusy => 'Подождите — репетитор отвечает';

  @override
  String get speakingUnclearAudio =>
      'Плохо слышно — попробуйте сказать чуть чётче';

  @override
  String get tapToHide => 'Нажмите, чтобы скрыть текст';

  @override
  String get groupReply => 'Ответить';

  @override
  String get questionsDraw => 'Случайный вопрос';

  @override
  String get questionsDrawHint =>
      'Не о чем говорить? Нажмите «Случайный вопрос» — придёт тот, на который вы ещё не отвечали.';

  @override
  String get questionsAllSeen => 'Все пройдены — начинаем заново';

  @override
  String get courseUnitLocked =>
      'Этот раздел ещё закрыт — завершите предыдущий';

  @override
  String courseUnitsDone(int done, int total) {
    return '$done из $total разделов завершено';
  }

  @override
  String get courseStart => 'Начать';

  @override
  String get courseLessons => 'Уроки';

  @override
  String get courseRule => 'Правило';

  @override
  String get courseYouWillLearn => 'В ЭТОМ РАЗДЕЛЕ ВЫ ИЗУЧИТЕ';

  @override
  String get courseStartLesson => 'Начать';

  @override
  String courseContinueLesson(int n) {
    return 'Продолжить урок $n';
  }

  @override
  String courseNextUnit(String title) {
    return 'Следующая тема: $title';
  }

  @override
  String courseLessonN(int n) {
    return 'Урок $n';
  }

  @override
  String courseItemCount(int n) {
    return '$n упражнений';
  }

  @override
  String courseMastery(int level, int max) {
    return 'Мастерство $level из $max';
  }

  @override
  String get drillPickMeaning => 'Выберите значение слова';

  @override
  String get drillPickWord => 'Выберите английское слово';

  @override
  String get drillMatchPairs => 'Нажмите слева, затем пару справа';

  @override
  String get drillPickAnswer => 'Выберите правильный ответ';

  @override
  String get drillOrderWords =>
      'Нажимайте на слова, чтобы составить предложение';

  @override
  String get drillTypeMissing => 'Впишите пропущенное слово';

  @override
  String get drillRewrite => 'Перепишите предложение';

  @override
  String get courseCheck => 'Проверить';

  @override
  String get courseContinue => 'Продолжить';

  @override
  String get courseCorrect => 'Верно!';

  @override
  String get courseNotQuite => 'Не в этот раз';

  @override
  String courseTheAnswerWas(String answer) {
    return 'Правильный ответ: $answer';
  }

  @override
  String get courseLessonDone => 'Урок завершён!';

  @override
  String get courseUnitDone => 'Раздел завершён!';

  @override
  String get courseCorrectCount => 'Верных';

  @override
  String get courseBackToPath => 'Вернуться к пути';

  @override
  String get courseQuitTitle => 'Выйти из урока?';

  @override
  String get courseQuitBody => 'Ваши ответы не сохранятся.';

  @override
  String get courseQuitStay => 'Продолжить';

  @override
  String get courseQuitLeave => 'Выйти';

  @override
  String get lessonCourseTitle => 'Words & Rules';

  @override
  String get lessonCourseSubtitle => 'Учите правила, запоминайте слова';

  @override
  String get lessonPracticeTitle => 'Практика';

  @override
  String get lessonPracticeSubtitle => 'Ваши ошибки';

  @override
  String get courseWillReturn => 'Этот вопрос вернётся в конце';

  @override
  String get courseTestFinish => 'Завершить';

  @override
  String courseTestPassed(int n) {
    return 'Открыто разделов: $n!';
  }

  @override
  String get courseTestFailed => 'Пока рано — начните с уроков';

  @override
  String get courseTestNoXp =>
      'Пропуск не даёт XP. За уроки XP начисляется как обычно.';

  @override
  String get courseJumpTitle => 'Уже знаете это?';

  @override
  String courseJumpBody(int n, int pass) {
    return 'Ответьте на $n вопросов из предыдущих разделов. Больше $pass% верных — они откроются, но без XP.';
  }

  @override
  String get courseJumpStart => 'Пройти тест';

  @override
  String get courseJumpCancel => 'Нет, пойду по порядку';

  @override
  String get courseReview => 'ПОВТОРЕНИЕ';

  @override
  String get courseQuitBodyKept =>
      'Ваши ответы сохранятся, но урок останется незавершённым.';

  @override
  String get homeSpeakLive => 'Живое общение';

  @override
  String get homeGroupTitle => 'Групповая комната';

  @override
  String get homeGroupSubtitle => 'Говорите в открытой комнате до 50 человек';

  @override
  String get homePeerTitle => 'Разговор с партнёром';

  @override
  String get homePeerSubtitle => 'Один на один, с живым человеком';

  @override
  String get peerFindTap => 'Найти партнёра';

  @override
  String get profilePhotoTitle => 'Фото профиля';

  @override
  String get profilePhotoPick => 'Выбрать из галереи';

  @override
  String get profilePhotoCamera => 'Сделать фото';

  @override
  String get profilePhotoReset => 'Вернуть фото из Telegram';

  @override
  String get profilePhotoSaved => 'Фото обновлено';

  @override
  String get profilePhotoTooLarge => 'Фото слишком большое — не более 2 МБ';

  @override
  String get commProfileIntro =>
      'По вашим последним разговорам. Каждая оценка — из 100.';

  @override
  String get bandStrong => 'Уверенно';

  @override
  String get bandGood => 'Хорошо';

  @override
  String get bandMiddle => 'В процессе';

  @override
  String get bandStarting => 'Только начало';

  @override
  String get trendUp => 'растёт';

  @override
  String get trendDown => 'снижается';

  @override
  String get trendSteady => 'стабильно';

  @override
  String get paceExplain =>
      'Свободная речь обычно 120–160 слов в минуту. Скорость сама по себе не цель — важнее говорить понятно.';

  @override
  String get focusTagsHint =>
      'Преподаватель будет следить за этим в следующих разговорах.';

  @override
  String get tagVerbTense => 'Времена глаголов';

  @override
  String get tagWordChoice => 'Выбор слов';

  @override
  String get tagWordOrder => 'Порядок слов';

  @override
  String get tagArticles => 'Артикли (a / the)';

  @override
  String get tagPreposition => 'Предлоги';

  @override
  String get tagPlural => 'Множественное число';

  @override
  String get tagAgreement => 'Согласование подлежащего и сказуемого';

  @override
  String get tagPronoun => 'Местоимения';

  @override
  String get tagComparative => 'Сравнительная степень';

  @override
  String get tagConditional => 'Условные предложения';

  @override
  String get tagQuestionForm => 'Построение вопросов';

  @override
  String get tagCollocation => 'Сочетаемость слов';

  @override
  String get accountTitle => 'Аккаунт';

  @override
  String get xpSourceCourse => 'Урок курса';

  @override
  String get developerTitle => 'Поддержка';

  @override
  String get developerCopied => 'Telegram скопирован';

  @override
  String get speakingTopicsTag => 'CEFR · IELTS';

  @override
  String get peerWhoTitle => 'С кем хотите поговорить?';

  @override
  String get peerWhoFemale => 'Женщины';

  @override
  String get peerWhoMale => 'Мужчины';

  @override
  String get peerWhoAny => 'Не важно';

  @override
  String get peerWhoFemaleSub => 'Вас соединят только с женщинами';

  @override
  String get peerWhoMaleSub => 'Вас соединят только с мужчинами';

  @override
  String get peerWhoAnySub => 'Быстрее всего';

  @override
  String get peerWhoStart => 'Найти собеседника';

  @override
  String get peerWhoNarrowHint => 'С фильтром ожидание может быть дольше.';

  @override
  String peerWhoOnline(int count) {
    return '$count сейчас онлайн';
  }

  @override
  String get accountName => 'Имя';

  @override
  String get accountUsername => 'Telegram';

  @override
  String get accountPhone => 'Телефон';

  @override
  String get accountGender => 'Пол';

  @override
  String get accountGenderUnset => 'Не указан';

  @override
  String get accountGenderFemale => 'Женский';

  @override
  String get accountGenderMale => 'Мужской';

  @override
  String get accountGenderWhy =>
      'Используется для подбора собеседника в живом разговоре.';

  @override
  String get accountNoUsername => 'Нет';

  @override
  String get accountSaved => 'Сохранено';

  @override
  String get quizTitle => 'Живая викторина';

  @override
  String get quizHubTitle => 'Живая викторина';

  @override
  String get quizHubSubtitle =>
      'Заходите когда угодно — новый матч каждые 3 минуты';

  @override
  String quizPlaying(int count) {
    return '$count играют';
  }

  @override
  String get quizAlone => 'Заходите первым';

  @override
  String quizQuestionOf(int index, int total) {
    return '$index из $total';
  }

  @override
  String get quizPickMeaning => 'Выберите значение';

  @override
  String get quizPickWord => 'Выберите слово';

  @override
  String get quizFillGap => 'Заполните пропуск';

  @override
  String get quizGrammar => 'Грамматика';

  @override
  String get quizCorrect => 'Верно';

  @override
  String get quizWrong => 'Не в этот раз';

  @override
  String get quizTimeUp => 'Время вышло';

  @override
  String quizPoints(int points) {
    return '+$points';
  }

  @override
  String get quizMatchBoard => 'Этот матч';

  @override
  String quizNextMatch(int seconds) {
    return 'Новый матч через $seconds с';
  }

  @override
  String get quizMatchOver => 'Матч окончен';

  @override
  String get quizYouPlaceholder => 'Вы';

  @override
  String get quizNoScoreYet => 'Ответьте, чтобы попасть в таблицу';

  @override
  String get quizEmpty => 'Викторина готовится. Попробуйте через минуту.';

  @override
  String get quizJoinedMidMatch =>
      'Вы вошли в середине матча — скоро начнётся новый';

  @override
  String get quizStart => 'Начать викторину';

  @override
  String get quizStartHint =>
      'Сейчас никто не играет — откройте игру, и всем придёт приглашение';

  @override
  String get quizLobbyTitle => 'Ждём начала';

  @override
  String quizWaitingFor(int count) {
    return 'Ещё $count, и начинаем';
  }

  @override
  String get quizStartingNow => 'Начинаем…';

  @override
  String get quizImReady => 'Я готов';

  @override
  String get quizYouAreReady => 'Вы в игре';

  @override
  String get quizInLobby => 'В лобби';

  @override
  String quizHostedBy(String name) {
    return '$name открыл игру';
  }

  @override
  String get quizLeave => 'Выйти';

  @override
  String get peerNoMicBody => 'Микрофон выключен — нажмите ещё раз';

  @override
  String get peerListening => 'Нажмите на микрофон, чтобы говорить';

  @override
  String get homeLiveOpen => 'Открыто';

  @override
  String get homeLiveQuiet => 'Пока никого';

  @override
  String homeOnlineN(int count) {
    return '$count онлайн';
  }

  @override
  String get homeJoinChat => 'Войти в чат';

  @override
  String get homeSeeAll => 'Все';

  @override
  String homeLessonsN(int count) {
    return '$count урока';
  }

  @override
  String homeGamesN(int count) {
    return '$count игр';
  }

  @override
  String get homeWordsTitle => 'Слова и правила';

  @override
  String get homeWordsSub => 'Новые слова, правила и упражнения';

  @override
  String get homeGamesSub => 'Играйте и улучшайте английский';

  @override
  String homeLessonsAt(int done, int total) {
    return '$done из $total';
  }

  @override
  String get referralTitle => 'Пригласите друга';

  @override
  String referralBody(int minutes) {
    return '$minutes минут разговора за каждого друга. Эти минуты не сгорают.';
  }

  @override
  String get referralCta => 'Пригласить друга';

  @override
  String referralFriends(int count) {
    return 'Друзей присоединилось: $count';
  }

  @override
  String referralShareText(String link) {
    return 'Практикуйте разговорный английский в EduGain — общайтесь с ИИ-собеседником и ведите живые разговоры с другими учениками.\n\n$link';
  }

  @override
  String referralEarned(int minutes) {
    return 'Всего $minutes минут';
  }

  @override
  String referralLeft(int minutes) {
    return 'Осталось $minutes минут';
  }
}
