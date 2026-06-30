import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

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
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageUzbek.
  ///
  /// In en, this message translates to:
  /// **'O‘zbekcha'**
  String get languageUzbek;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome 👋'**
  String get welcomeTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue'**
  String get phoneSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @dividerOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get dividerOr;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get googleSignIn;

  /// No description provided for @termsNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the Terms of Use and Privacy Policy'**
  String get termsNotice;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number (+998XXXXXXXXX)'**
  String get phoneInvalid;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to: {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String resendCountdown(String time);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @otpEnter6.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get otpEnter6;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent'**
  String get otpResent;

  /// No description provided for @nameTitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s get acquainted'**
  String get nameTitle;

  /// No description provided for @nameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get nameSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Aziz'**
  String get nameHint;

  /// No description provided for @nameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameEmpty;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String greeting(String name);

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level: {level}'**
  String levelLabel(String level);

  /// No description provided for @letsLearnToday.
  ///
  /// In en, this message translates to:
  /// **'Let’s learn something today!'**
  String get letsLearnToday;

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @statXp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get statXp;

  /// No description provided for @statLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get statLevel;

  /// No description provided for @statDay.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get statDay;

  /// No description provided for @reviewTime.
  ///
  /// In en, this message translates to:
  /// **'Time to review'**
  String get reviewTime;

  /// No description provided for @wordsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} words are waiting for you'**
  String wordsWaiting(int count);

  /// No description provided for @featuredBadge.
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get featuredBadge;

  /// No description provided for @featuredTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with AI'**
  String get featuredTitle;

  /// No description provided for @featuredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practise in a real conversation'**
  String get featuredSubtitle;

  /// No description provided for @placementTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your level'**
  String get placementTitle;

  /// No description provided for @placementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A short test — the experience adapts to you'**
  String get placementSubtitle;

  /// No description provided for @moduleSpeakingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live conversation with AI'**
  String get moduleSpeakingSubtitle;

  /// No description provided for @moduleVocabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grow your vocabulary'**
  String get moduleVocabSubtitle;

  /// No description provided for @moduleGrammarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practise your grammar'**
  String get moduleGrammarSubtitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get navLessons;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @lessonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessonsTitle;

  /// No description provided for @lessonSpeakingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practise speaking through live conversation with AI'**
  String get lessonSpeakingSubtitle;

  /// No description provided for @lessonVocabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grow your vocabulary with flashcards'**
  String get lessonVocabSubtitle;

  /// No description provided for @lessonGrammarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reinforce grammar with rules and exercises'**
  String get lessonGrammarSubtitle;

  /// No description provided for @lessonPlacementTitle.
  ///
  /// In en, this message translates to:
  /// **'Level test'**
  String get lessonPlacementTitle;

  /// No description provided for @lessonPlacementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Determine your CEFR level'**
  String get lessonPlacementSubtitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @xpHistory.
  ///
  /// In en, this message translates to:
  /// **'XP history'**
  String get xpHistory;

  /// No description provided for @xpHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load history'**
  String get xpHistoryError;

  /// No description provided for @noXpYet.
  ///
  /// In en, this message translates to:
  /// **'No XP yet — start practising!'**
  String get noXpYet;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get editNameTitle;

  /// No description provided for @dailyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goal (XP)'**
  String get dailyGoalTitle;

  /// No description provided for @dailyGoalHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get dailyGoalHint;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoalLabel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load'**
  String get loadFailed;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get yourAnswer;

  /// No description provided for @premiumContent.
  ///
  /// In en, this message translates to:
  /// **'Premium content'**
  String get premiumContent;

  /// No description provided for @paywallCtaDefault.
  ///
  /// In en, this message translates to:
  /// **'Continue with Premium'**
  String get paywallCtaDefault;

  /// No description provided for @premiumButton.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumButton;

  /// No description provided for @freeTopic.
  ///
  /// In en, this message translates to:
  /// **'Free topic'**
  String get freeTopic;

  /// No description provided for @freeTopicHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. travel'**
  String get freeTopicHint;

  /// No description provided for @freeTopicCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Have a conversation on any topic'**
  String get freeTopicCardSubtitle;

  /// No description provided for @scenarios.
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get scenarios;

  /// No description provided for @scenariosLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load scenarios. Check your connection.'**
  String get scenariosLoadError;

  /// No description provided for @limitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Limit reached'**
  String get limitReachedTitle;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startConversation;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get feedbackTitle;

  /// No description provided for @strengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get strengths;

  /// No description provided for @mistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get mistakes;

  /// No description provided for @feedbackLocked.
  ///
  /// In en, this message translates to:
  /// **'The full analysis (all mistakes and tips) unlocks with Premium.'**
  String get feedbackLocked;

  /// No description provided for @micPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone access needed — enable it in phone settings.'**
  String get micPermission;

  /// No description provided for @recordStartError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start recording.'**
  String get recordStartError;

  /// No description provided for @audioCaptureError.
  ///
  /// In en, this message translates to:
  /// **'Audio not captured.'**
  String get audioCaptureError;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI is temporarily unavailable'**
  String get aiUnavailable;

  /// No description provided for @turnLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Conversation limit reached. Get your result.'**
  String get turnLimitReached;

  /// No description provided for @speechNotRecognized.
  ///
  /// In en, this message translates to:
  /// **'Speech not recognised — please try again.'**
  String get speechNotRecognized;

  /// No description provided for @chatTurnCounter.
  ///
  /// In en, this message translates to:
  /// **'Chat · {turn}/{max} turns'**
  String chatTurnCounter(int turn, int max);

  /// No description provided for @finishSession.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishSession;

  /// No description provided for @selectVoice.
  ///
  /// In en, this message translates to:
  /// **'Choose voice'**
  String get selectVoice;

  /// No description provided for @turnLimitBanner.
  ///
  /// In en, this message translates to:
  /// **'Conversation limit reached — tap “Finish” for your result.'**
  String get turnLimitBanner;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'listening…'**
  String get listening;

  /// No description provided for @tapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get tapToSpeak;

  /// No description provided for @composerHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message or speak…'**
  String get composerHint;

  /// No description provided for @recordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingLabel;

  /// No description provided for @tapToSend.
  ///
  /// In en, this message translates to:
  /// **'Tap to send'**
  String get tapToSend;

  /// No description provided for @chooseVoice.
  ///
  /// In en, this message translates to:
  /// **'Choose a voice'**
  String get chooseVoice;

  /// No description provided for @voicesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the voice list.'**
  String get voicesLoadError;

  /// No description provided for @noVoices.
  ///
  /// In en, this message translates to:
  /// **'No voices available yet.'**
  String get noVoices;

  /// No description provided for @voicePreview.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get voicePreview;

  /// No description provided for @voicePreviewError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t play the voice.'**
  String get voicePreviewError;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @noSets.
  ///
  /// In en, this message translates to:
  /// **'No sets yet'**
  String get noSets;

  /// No description provided for @noWords.
  ///
  /// In en, this message translates to:
  /// **'No words'**
  String get noWords;

  /// No description provided for @tapCardToFlip.
  ///
  /// In en, this message translates to:
  /// **'Tap the card to see it'**
  String get tapCardToFlip;

  /// No description provided for @dontKnow.
  ///
  /// In en, this message translates to:
  /// **'Didn’t know'**
  String get dontKnow;

  /// No description provided for @know.
  ///
  /// In en, this message translates to:
  /// **'Knew it'**
  String get know;

  /// No description provided for @congrats.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! 🎉'**
  String get congrats;

  /// No description provided for @vocabResult.
  ///
  /// In en, this message translates to:
  /// **'You knew {learned} of {total} words.'**
  String vocabResult(int learned, int total);

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// No description provided for @allReviewed.
  ///
  /// In en, this message translates to:
  /// **'All reviewed! 🎉'**
  String get allReviewed;

  /// No description provided for @noReviewWords.
  ///
  /// In en, this message translates to:
  /// **'No words to review right now.\nKeep learning new words.'**
  String get noReviewWords;

  /// No description provided for @wordSets.
  ///
  /// In en, this message translates to:
  /// **'Word sets'**
  String get wordSets;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job! 🎉'**
  String get greatJob;

  /// No description provided for @reviewResult.
  ///
  /// In en, this message translates to:
  /// **'You recalled {correct} of {reviewed} words.'**
  String reviewResult(int correct, int reviewed);

  /// No description provided for @tapToSeeMeaning.
  ///
  /// In en, this message translates to:
  /// **'Tap the card to see the meaning'**
  String get tapToSeeMeaning;

  /// No description provided for @couldntRecall.
  ///
  /// In en, this message translates to:
  /// **'Didn’t recall'**
  String get couldntRecall;

  /// No description provided for @recalled.
  ///
  /// In en, this message translates to:
  /// **'Recalled'**
  String get recalled;

  /// No description provided for @noTopics.
  ///
  /// In en, this message translates to:
  /// **'No topics yet'**
  String get noTopics;

  /// No description provided for @atLeastOneAnswer.
  ///
  /// In en, this message translates to:
  /// **'Give at least one answer'**
  String get atLeastOneAnswer;

  /// No description provided for @grammarScore.
  ///
  /// In en, this message translates to:
  /// **'Result: {score} / {total}'**
  String grammarScore(int score, int total);

  /// No description provided for @placementTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Level test'**
  String get placementTestTitle;

  /// No description provided for @noQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions found'**
  String get noQuestions;

  /// No description provided for @resultReady.
  ///
  /// In en, this message translates to:
  /// **'Result ready 🎯'**
  String get resultReady;

  /// No description provided for @yourEnglishLevel.
  ///
  /// In en, this message translates to:
  /// **'Your English level'**
  String get yourEnglishLevel;

  /// No description provided for @startAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startAction;

  /// No description provided for @finishAction.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishAction;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextAction;

  /// No description provided for @choosePayment.
  ///
  /// In en, this message translates to:
  /// **'Choose a payment method'**
  String get choosePayment;

  /// No description provided for @paymentPageError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the payment page'**
  String get paymentPageError;

  /// No description provided for @finishPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete the payment'**
  String get finishPaymentTitle;

  /// No description provided for @finishPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'Complete the payment in the browser, then check the status.'**
  String get finishPaymentBody;

  /// No description provided for @cancelSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelSubscriptionTitle;

  /// No description provided for @cancelSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'Benefits stay until the period ends. Continue?'**
  String get cancelSubscriptionBody;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until: {date}'**
  String validUntil(String date);

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String pricePerMonth(String price);

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choosePlan;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'English with artificial intelligence'**
  String get appTagline;

  /// No description provided for @xpSourceDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get xpSourceDailyGoal;

  /// No description provided for @xpSourceStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak bonus'**
  String get xpSourceStreak;

  /// No description provided for @coachCorrection.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get coachCorrection;

  /// No description provided for @coachNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural version'**
  String get coachNatural;

  /// No description provided for @coachGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get coachGrammar;

  /// No description provided for @coachVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get coachVocabulary;

  /// No description provided for @coachPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get coachPronunciation;

  /// No description provided for @statusSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking…'**
  String get statusSpeaking;

  /// No description provided for @statusListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get statusListening;

  /// No description provided for @statusThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get statusThinking;

  /// No description provided for @scoreOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get scoreOverall;

  /// No description provided for @scoreGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get scoreGrammar;

  /// No description provided for @scoreVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get scoreVocabulary;

  /// No description provided for @scoreFluency.
  ///
  /// In en, this message translates to:
  /// **'Fluency'**
  String get scoreFluency;

  /// No description provided for @scorePronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get scorePronunciation;

  /// No description provided for @scoresEstimatedNote.
  ///
  /// In en, this message translates to:
  /// **'Fluency & pronunciation are estimated from your text.'**
  String get scoresEstimatedNote;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice is temporarily unavailable.'**
  String get voiceUnavailable;

  /// No description provided for @listenModeOn.
  ///
  /// In en, this message translates to:
  /// **'Listening mode — text hidden'**
  String get listenModeOn;

  /// No description provided for @listenModeOff.
  ///
  /// In en, this message translates to:
  /// **'Show text'**
  String get listenModeOff;

  /// No description provided for @tapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get tapToReveal;

  /// No description provided for @actionTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get actionTranslate;

  /// No description provided for @actionHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get actionHint;

  /// No description provided for @hintTitle.
  ///
  /// In en, this message translates to:
  /// **'How to respond'**
  String get hintTitle;

  /// No description provided for @hintTip.
  ///
  /// In en, this message translates to:
  /// **'Answer in a full sentence and ask a question back to keep the conversation going.'**
  String get hintTip;
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
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
