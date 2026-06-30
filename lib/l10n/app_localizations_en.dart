// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get continueAction => 'Continue';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUzbek => 'O‘zbekcha';

  @override
  String get welcomeTitle => 'Welcome 👋';

  @override
  String get phoneSubtitle => 'Enter your phone number to continue';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get sendCode => 'Send code';

  @override
  String get dividerOr => 'or';

  @override
  String get googleSignIn => 'Sign in with Google';

  @override
  String get termsNotice =>
      'By continuing you agree to the Terms of Use and Privacy Policy';

  @override
  String get phoneInvalid => 'Enter a valid phone number (+998XXXXXXXXX)';

  @override
  String get otpTitle => 'Verification code';

  @override
  String otpSentTo(String phone) {
    return 'Code sent to: $phone';
  }

  @override
  String get verify => 'Verify';

  @override
  String resendCountdown(String time) {
    return 'Resend in $time';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get otpEnter6 => 'Enter the 6-digit code';

  @override
  String get otpResent => 'A new code has been sent';

  @override
  String get nameTitle => 'Let’s get acquainted';

  @override
  String get nameSubtitle => 'What should we call you?';

  @override
  String get nameLabel => 'Your name';

  @override
  String get nameHint => 'e.g. Aziz';

  @override
  String get nameEmpty => 'Please enter your name';

  @override
  String greeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String levelLabel(String level) {
    return 'Level: $level';
  }

  @override
  String get letsLearnToday => 'Let’s learn something today!';

  @override
  String get modules => 'Modules';

  @override
  String get statXp => 'XP';

  @override
  String get statLevel => 'Level';

  @override
  String get statDay => 'Days';

  @override
  String get reviewTime => 'Time to review';

  @override
  String wordsWaiting(int count) {
    return '$count words are waiting for you';
  }

  @override
  String get featuredBadge => 'FEATURED';

  @override
  String get featuredTitle => 'Start a conversation with AI';

  @override
  String get featuredSubtitle => 'Practise in a real conversation';

  @override
  String get placementTitle => 'Find your level';

  @override
  String get placementSubtitle => 'A short test — the experience adapts to you';

  @override
  String get moduleSpeakingSubtitle => 'Live conversation with AI';

  @override
  String get moduleVocabSubtitle => 'Grow your vocabulary';

  @override
  String get moduleGrammarSubtitle => 'Practise your grammar';

  @override
  String get navHome => 'Home';

  @override
  String get navLessons => 'Lessons';

  @override
  String get navProfile => 'Profile';

  @override
  String get lessonsTitle => 'Lessons';

  @override
  String get lessonSpeakingSubtitle =>
      'Practise speaking through live conversation with AI';

  @override
  String get lessonVocabSubtitle => 'Grow your vocabulary with flashcards';

  @override
  String get lessonGrammarSubtitle =>
      'Reinforce grammar with rules and exercises';

  @override
  String get lessonPlacementTitle => 'Level test';

  @override
  String get lessonPlacementSubtitle => 'Determine your CEFR level';

  @override
  String get profileTitle => 'Profile';

  @override
  String get logout => 'Log out';

  @override
  String get subscription => 'Subscription';

  @override
  String get xpHistory => 'XP history';

  @override
  String get xpHistoryError => 'Couldn’t load history';

  @override
  String get noXpYet => 'No XP yet — start practising!';

  @override
  String get editNameTitle => 'Change name';

  @override
  String get dailyGoalTitle => 'Daily goal (XP)';

  @override
  String get dailyGoalHint => 'e.g. 50';

  @override
  String get dailyGoalLabel => 'Daily goal';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get loadFailed => 'Couldn’t load';

  @override
  String get check => 'Check';

  @override
  String get yourAnswer => 'Your answer';

  @override
  String get premiumContent => 'Premium content';

  @override
  String get paywallCtaDefault => 'Continue with Premium';

  @override
  String get premiumButton => 'Premium';

  @override
  String get freeTopic => 'Free topic';

  @override
  String get freeTopicHint => 'e.g. travel';

  @override
  String get freeTopicCardSubtitle => 'Have a conversation on any topic';

  @override
  String get scenarios => 'Scenarios';

  @override
  String get scenariosLoadError =>
      'Couldn’t load scenarios. Check your connection.';

  @override
  String get limitReachedTitle => 'Limit reached';

  @override
  String get startConversation => 'Start';

  @override
  String get feedbackTitle => 'Result';

  @override
  String get strengths => 'Strengths';

  @override
  String get mistakes => 'Mistakes';

  @override
  String get feedbackLocked =>
      'The full analysis (all mistakes and tips) unlocks with Premium.';

  @override
  String get micPermission =>
      'Microphone access needed — enable it in phone settings.';

  @override
  String get recordStartError => 'Couldn’t start recording.';

  @override
  String get audioCaptureError => 'Audio not captured.';

  @override
  String get aiUnavailable => 'AI is temporarily unavailable';

  @override
  String get turnLimitReached => 'Conversation limit reached. Get your result.';

  @override
  String get speechNotRecognized => 'Speech not recognised — please try again.';

  @override
  String chatTurnCounter(int turn, int max) {
    return 'Chat · $turn/$max turns';
  }

  @override
  String get finishSession => 'Finish';

  @override
  String get selectVoice => 'Choose voice';

  @override
  String get turnLimitBanner =>
      'Conversation limit reached — tap “Finish” for your result.';

  @override
  String get listening => 'listening…';

  @override
  String get tapToSpeak => 'Tap to speak';

  @override
  String get composerHint => 'Type a message or speak…';

  @override
  String get recordingLabel => 'Recording';

  @override
  String get tapToSend => 'Tap to send';

  @override
  String get chooseVoice => 'Choose a voice';

  @override
  String get voicesLoadError => 'Couldn’t load the voice list.';

  @override
  String get noVoices => 'No voices available yet.';

  @override
  String get voicePreview => 'Listen';

  @override
  String get voicePreviewError => 'Couldn’t play the voice.';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get noSets => 'No sets yet';

  @override
  String get noWords => 'No words';

  @override
  String get tapCardToFlip => 'Tap the card to see it';

  @override
  String get dontKnow => 'Didn’t know';

  @override
  String get know => 'Knew it';

  @override
  String get congrats => 'Congratulations! 🎉';

  @override
  String vocabResult(int learned, int total) {
    return 'You knew $learned of $total words.';
  }

  @override
  String get reviewTitle => 'Review';

  @override
  String get allReviewed => 'All reviewed! 🎉';

  @override
  String get noReviewWords =>
      'No words to review right now.\nKeep learning new words.';

  @override
  String get wordSets => 'Word sets';

  @override
  String get greatJob => 'Great job! 🎉';

  @override
  String reviewResult(int correct, int reviewed) {
    return 'You recalled $correct of $reviewed words.';
  }

  @override
  String get tapToSeeMeaning => 'Tap the card to see the meaning';

  @override
  String get couldntRecall => 'Didn’t recall';

  @override
  String get recalled => 'Recalled';

  @override
  String get noTopics => 'No topics yet';

  @override
  String get atLeastOneAnswer => 'Give at least one answer';

  @override
  String grammarScore(int score, int total) {
    return 'Result: $score / $total';
  }

  @override
  String get placementTestTitle => 'Level test';

  @override
  String get noQuestions => 'No questions found';

  @override
  String get resultReady => 'Result ready 🎯';

  @override
  String get yourEnglishLevel => 'Your English level';

  @override
  String get startAction => 'Start';

  @override
  String get finishAction => 'Finish';

  @override
  String get nextAction => 'Next';

  @override
  String get choosePayment => 'Choose a payment method';

  @override
  String get paymentPageError => 'Couldn’t open the payment page';

  @override
  String get finishPaymentTitle => 'Complete the payment';

  @override
  String get finishPaymentBody =>
      'Complete the payment in the browser, then check the status.';

  @override
  String get cancelSubscriptionTitle => 'Cancel subscription';

  @override
  String get cancelSubscriptionBody =>
      'Benefits stay until the period ends. Continue?';

  @override
  String get currentPlan => 'Current plan';

  @override
  String validUntil(String date) {
    return 'Valid until: $date';
  }

  @override
  String get cancelAction => 'Cancel';

  @override
  String pricePerMonth(String price) {
    return '$price / month';
  }

  @override
  String get choosePlan => 'Choose';

  @override
  String get appTagline => 'English with artificial intelligence';

  @override
  String get xpSourceDailyGoal => 'Daily goal';

  @override
  String get xpSourceStreak => 'Streak bonus';

  @override
  String get coachCorrection => 'Correction';

  @override
  String get coachNatural => 'Natural version';

  @override
  String get coachGrammar => 'Grammar';

  @override
  String get coachVocabulary => 'Vocabulary';

  @override
  String get coachPronunciation => 'Pronunciation';

  @override
  String get statusSpeaking => 'Speaking…';

  @override
  String get statusListening => 'Listening…';

  @override
  String get statusThinking => 'Thinking…';

  @override
  String get scoreOverall => 'Overall';

  @override
  String get scoreGrammar => 'Grammar';

  @override
  String get scoreVocabulary => 'Vocabulary';

  @override
  String get scoreFluency => 'Fluency';

  @override
  String get scorePronunciation => 'Pronunciation';

  @override
  String get scoresEstimatedNote =>
      'Fluency & pronunciation are estimated from your text.';

  @override
  String get voiceUnavailable => 'Voice is temporarily unavailable.';

  @override
  String get listenModeOn => 'Listening mode — text hidden';

  @override
  String get listenModeOff => 'Show text';

  @override
  String get tapToReveal => 'Tap to reveal';

  @override
  String get actionTranslate => 'Translate';

  @override
  String get actionHint => 'Hint';

  @override
  String get hintTitle => 'How to respond';

  @override
  String get hintTip =>
      'Answer in a full sentence and ask a question back to keep the conversation going.';
}
