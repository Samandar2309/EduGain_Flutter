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

  /// No description provided for @peerQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s live conversation time is used up'**
  String get peerQuotaTitle;

  /// No description provided for @peerQuotaBody.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for unlimited live conversations with other learners.'**
  String get peerQuotaBody;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfinished conversation'**
  String get resumeTitle;

  /// No description provided for @resumeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{turns} turns in — pick up where you left off'**
  String resumeSubtitle(int turns);

  /// No description provided for @resumeAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get resumeAction;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection problem. Please try again.'**
  String get networkError;

  /// No description provided for @feedbackNotReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Report isn\'t ready'**
  String get feedbackNotReadyTitle;

  /// No description provided for @feedbackNotReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your conversation is saved. The scoring service didn\'t answer just now — you can build the report again.'**
  String get feedbackNotReadyBody;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String minutesShort(int count);

  /// No description provided for @groupRoomHoldsUpTo.
  ///
  /// In en, this message translates to:
  /// **'The room holds up to {count} people'**
  String groupRoomHoldsUpTo(int count);

  /// No description provided for @cannotHearYou.
  ///
  /// In en, this message translates to:
  /// **'We can\'t hear you — speak up, or type instead'**
  String get cannotHearYou;

  /// No description provided for @micBlockedTapToAllow.
  ///
  /// In en, this message translates to:
  /// **'Microphone blocked — tap to allow'**
  String get micBlockedTapToAllow;

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} min left'**
  String minutesLeft(int count);

  /// No description provided for @actionEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get actionEnd;

  /// No description provided for @questionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questionsTitle;

  /// No description provided for @workedTitle.
  ///
  /// In en, this message translates to:
  /// **'How to answer this'**
  String get workedTitle;

  /// No description provided for @workedWeak.
  ///
  /// In en, this message translates to:
  /// **'What most people say'**
  String get workedWeak;

  /// No description provided for @workedStrong.
  ///
  /// In en, this message translates to:
  /// **'What works better'**
  String get workedStrong;

  /// No description provided for @workedMoves.
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get workedMoves;

  /// No description provided for @workedLocked.
  ///
  /// In en, this message translates to:
  /// **'Answer breakdowns are in Premium'**
  String get workedLocked;

  /// No description provided for @workedLockedWhy.
  ///
  /// In en, this message translates to:
  /// **'The questions are free for everyone. The breakdown — a weak and a strong answer side by side, with the difference marked — is in Premium.'**
  String get workedLockedWhy;

  /// No description provided for @workedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the breakdown'**
  String get workedOpen;

  /// No description provided for @questionsFollows.
  ///
  /// In en, this message translates to:
  /// **'Follows the card: {title}'**
  String questionsFollows(String title);

  /// No description provided for @questionsPart3Hint.
  ///
  /// In en, this message translates to:
  /// **'These are not about you but about people in general. Give a view and a reason for it — a sentence or two will not be enough.'**
  String get questionsPart3Hint;

  /// No description provided for @cueCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Cue card'**
  String get cueCardLabel;

  /// No description provided for @cueCardYouShouldSay.
  ///
  /// In en, this message translates to:
  /// **'You should say:'**
  String get cueCardYouShouldSay;

  /// No description provided for @cueCardHint.
  ///
  /// In en, this message translates to:
  /// **'Prepare for one minute, then speak for two without stopping. Practising in a pair: one reads the card and keeps time, then you swap.'**
  String get cueCardHint;

  /// No description provided for @cueCardPrep.
  ///
  /// In en, this message translates to:
  /// **'{count} min to prepare'**
  String cueCardPrep(int count);

  /// No description provided for @cueCardTalk.
  ///
  /// In en, this message translates to:
  /// **'{count} min to talk'**
  String cueCardTalk(int count);

  /// No description provided for @questionsModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready-made questions to talk about'**
  String get questionsModeSubtitle;

  /// No description provided for @questionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Ask each other in a live conversation, or prepare on your own.'**
  String get questionsIntro;

  /// No description provided for @questionsUseHint.
  ///
  /// In en, this message translates to:
  /// **'Pick one and ask your partner — then answer it yourself.'**
  String get questionsUseHint;

  /// No description provided for @questionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get questionsSaved;

  /// No description provided for @questionsNoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet.\nBookmark the questions you like.'**
  String get questionsNoneSaved;

  /// No description provided for @questionsNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get questionsNew;

  /// No description provided for @questionsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the questions.'**
  String get questionsError;

  /// No description provided for @speakingSectionPrepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get speakingSectionPrepare;

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String questionsCount(int count);

  /// No description provided for @questionsTopicCount.
  ///
  /// In en, this message translates to:
  /// **'{count} topics'**
  String questionsTopicCount(int count);

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

  /// No description provided for @learnLangComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get learnLangComingSoon;

  /// No description provided for @learnLangNotifyMe.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tell you'**
  String get learnLangNotifyMe;

  /// No description provided for @learnLangInterestSaved.
  ///
  /// In en, this message translates to:
  /// **'Noted. You\'ll be the first to hear when {language} opens.'**
  String learnLangInterestSaved(String language);

  /// No description provided for @feedbackSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackSendTitle;

  /// No description provided for @feedbackSendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What broke, what\'s missing — tell us. We read every one.'**
  String get feedbackSendSubtitle;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem or your suggestion…'**
  String get feedbackHint;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSend;

  /// No description provided for @feedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please write something first'**
  String get feedbackEmpty;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you — we\'ve got it.'**
  String get feedbackThanks;

  /// No description provided for @feedbackTooMany.
  ///
  /// In en, this message translates to:
  /// **'That\'s enough messages for today. Let\'s carry on tomorrow.'**
  String get feedbackTooMany;

  /// No description provided for @rateSessionQuestion.
  ///
  /// In en, this message translates to:
  /// **'How was that conversation?'**
  String get rateSessionQuestion;

  /// No description provided for @rateSessionCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Anything you\'d like to add? (optional)'**
  String get rateSessionCommentHint;

  /// No description provided for @rateSessionCommentSent.
  ///
  /// In en, this message translates to:
  /// **'Comment sent. Thank you!'**
  String get rateSessionCommentSent;

  /// No description provided for @rateSessionThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — that helps.'**
  String get rateSessionThanks;

  /// No description provided for @channelTitle.
  ///
  /// In en, this message translates to:
  /// **'Join our channel'**
  String get channelTitle;

  /// No description provided for @channelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New lessons, tips and announcements all land there. Subscribe once and we\'ll carry on.'**
  String get channelSubtitle;

  /// No description provided for @channelOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open the channel'**
  String get channelOpenAction;

  /// No description provided for @channelJoinedAction.
  ///
  /// In en, this message translates to:
  /// **'I\'ve subscribed'**
  String get channelJoinedAction;

  /// No description provided for @channelNotYet.
  ///
  /// In en, this message translates to:
  /// **'We can\'t see your subscription yet. Join the channel and try again.'**
  String get channelNotYet;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String greeting(String name);

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'English: {level}'**
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

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

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

  /// No description provided for @gamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesTitle;

  /// No description provided for @gamesVocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Word games'**
  String get gamesVocabTitle;

  /// No description provided for @gamesVocabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alone, against Gainsy, or a live opponent'**
  String get gamesVocabSubtitle;

  /// No description provided for @gamesGrammarTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get gamesGrammarTitle;

  /// No description provided for @gamesGrammarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn the rule, then drill it'**
  String get gamesGrammarSubtitle;

  /// No description provided for @gamesBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse words'**
  String get gamesBrowseTitle;

  /// No description provided for @gamesBrowseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'With translation and an example'**
  String get gamesBrowseSubtitle;

  /// No description provided for @gamesReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Words you are about to forget'**
  String get gamesReviewSubtitle;

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

  /// No description provided for @placementResultBody.
  ///
  /// In en, this message translates to:
  /// **'Your tutor will speak at this level from now on, and it moves as you improve.'**
  String get placementResultBody;

  /// No description provided for @placementLastResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your last result'**
  String get placementLastResultTitle;

  /// No description provided for @placementTakenToday.
  ///
  /// In en, this message translates to:
  /// **'Taken today'**
  String get placementTakenToday;

  /// No description provided for @placementTakenYesterday.
  ///
  /// In en, this message translates to:
  /// **'Taken yesterday'**
  String get placementTakenYesterday;

  /// No description provided for @placementTakenDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Taken {days} days ago'**
  String placementTakenDaysAgo(int days);

  /// No description provided for @placementRetakeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to take the test again?'**
  String get placementRetakeQuestion;

  /// No description provided for @placementRetakeReplaces.
  ///
  /// In en, this message translates to:
  /// **'Your new result will replace this level.'**
  String get placementRetakeReplaces;

  /// No description provided for @placementRetakeAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, start again'**
  String get placementRetakeAction;

  /// No description provided for @placementKeepAction.
  ///
  /// In en, this message translates to:
  /// **'No, keep my level'**
  String get placementKeepAction;

  /// No description provided for @levelInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'First, let\'s find your level'**
  String get levelInviteTitle;

  /// No description provided for @levelInviteBody.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions. After that your tutor speaks at a level you can follow, instead of guessing.'**
  String get levelInviteBody;

  /// No description provided for @levelInviteMeta.
  ///
  /// In en, this message translates to:
  /// **'18 questions · about 2 minutes'**
  String get levelInviteMeta;

  /// No description provided for @levelInviteStart.
  ///
  /// In en, this message translates to:
  /// **'Find my level'**
  String get levelInviteStart;

  /// No description provided for @levelInviteSkip.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get levelInviteSkip;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @navLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get navLeaderboard;

  /// No description provided for @leaderboardThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get leaderboardThisWeek;

  /// No description provided for @leaderboardLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get leaderboardLastWeek;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody has earned XP this week yet.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardEmptyLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Nobody earned XP last week.'**
  String get leaderboardEmptyLastWeek;

  /// No description provided for @leaderboardFirstPlaceOpen.
  ///
  /// In en, this message translates to:
  /// **'First conversation, first place.'**
  String get leaderboardFirstPlaceOpen;

  /// No description provided for @leaderboardNotRankedYet.
  ///
  /// In en, this message translates to:
  /// **'Finish one lesson to join this week\'s board.'**
  String get leaderboardNotRankedYet;

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYou;

  /// No description provided for @leaderboardYouAreFirst.
  ///
  /// In en, this message translates to:
  /// **'You are first — hold it.'**
  String get leaderboardYouAreFirst;

  /// No description provided for @leaderboardPlaceSuffix.
  ///
  /// In en, this message translates to:
  /// **'th place —'**
  String get leaderboardPlaceSuffix;

  /// No description provided for @leaderboardStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String leaderboardStreakDays(int days);

  /// No description provided for @leaderboardResetsMonday.
  ///
  /// In en, this message translates to:
  /// **'The board starts again every Monday.'**
  String get leaderboardResetsMonday;

  /// No description provided for @tierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tierFree;

  /// No description provided for @homeLevelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Level: not set'**
  String get homeLevelUnknown;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get statStreak;

  /// No description provided for @statGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get statGoal;

  /// No description provided for @homeAiKicker.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get homeAiKicker;

  /// No description provided for @homeAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with AI'**
  String get homeAiTitle;

  /// No description provided for @homeAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sharpen your speaking'**
  String get homeAiSubtitle;

  /// No description provided for @homeAiLocked.
  ///
  /// In en, this message translates to:
  /// **'Opens once your level is set'**
  String get homeAiLocked;

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

  /// No description provided for @quotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily speaking time'**
  String get quotaTitle;

  /// No description provided for @quotaMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String quotaMinutesLeft(int minutes);

  /// No description provided for @quotaUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} min used'**
  String quotaUsedOf(int used, int total);

  /// No description provided for @quotaExhausted.
  ///
  /// In en, this message translates to:
  /// **'Today\'s minutes are used up'**
  String get quotaExhausted;

  /// No description provided for @quotaUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Increase limit'**
  String get quotaUpgrade;

  /// No description provided for @commProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication Profile'**
  String get commProfileTitle;

  /// No description provided for @commProfileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Have a few conversations with the AI tutor — your profile builds itself from your real speech.'**
  String get commProfileEmpty;

  /// No description provided for @focusTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Working on now'**
  String get focusTagsTitle;

  /// No description provided for @paceLabel.
  ///
  /// In en, this message translates to:
  /// **'Speaking pace'**
  String get paceLabel;

  /// No description provided for @paceValue.
  ///
  /// In en, this message translates to:
  /// **'{wpm} words/min'**
  String paceValue(int wpm);

  /// No description provided for @paceTarget.
  ///
  /// In en, this message translates to:
  /// **'goal {target}'**
  String paceTarget(int target);

  /// No description provided for @minutesSpoken.
  ///
  /// In en, this message translates to:
  /// **'Minutes spoken'**
  String get minutesSpoken;

  /// No description provided for @wordsSpoken.
  ///
  /// In en, this message translates to:
  /// **'Words spoken'**
  String get wordsSpoken;

  /// No description provided for @basedOnSessions.
  ///
  /// In en, this message translates to:
  /// **'based on {count} sessions'**
  String basedOnSessions(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @paywallReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your full report'**
  String get paywallReportTitle;

  /// No description provided for @paywallReportBody.
  ///
  /// In en, this message translates to:
  /// **'Every mistake, correction and personal tip — with Premium.'**
  String get paywallReportBody;

  /// No description provided for @paywallSeePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get paywallSeePlans;

  /// No description provided for @premiumBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumBadge;

  /// No description provided for @planPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get planPopular;

  /// No description provided for @premiumHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'EduGain Premium'**
  String get premiumHeroTitle;

  /// No description provided for @premiumHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Speak more every day, open every track and get the full analysis of your speech.'**
  String get premiumHeroBody;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'English with artificial intelligence'**
  String get appTagline;

  /// No description provided for @welcomeChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get welcomeChooseLanguage;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeSkip;

  /// No description provided for @welcomeStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeStart;

  /// No description provided for @welcomeSpeakTitle.
  ///
  /// In en, this message translates to:
  /// **'Speak with an AI tutor'**
  String get welcomeSpeakTitle;

  /// No description provided for @welcomeSpeakBody.
  ///
  /// In en, this message translates to:
  /// **'Real conversations any time of day. No judgement, no fear of mistakes — just practice.'**
  String get welcomeSpeakBody;

  /// No description provided for @welcomeCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Live coaching as you talk'**
  String get welcomeCoachTitle;

  /// No description provided for @welcomeCoachBody.
  ///
  /// In en, this message translates to:
  /// **'Gentle corrections after every sentence and a clear report on your grammar, vocabulary and fluency.'**
  String get welcomeCoachBody;

  /// No description provided for @welcomeGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'A path to your goal'**
  String get welcomeGoalTitle;

  /// No description provided for @welcomeGoalBody.
  ///
  /// In en, this message translates to:
  /// **'IELTS, career, travel or everyday talk — follow a track that adapts to your weak spots.'**
  String get welcomeGoalBody;

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

  /// No description provided for @groupChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get groupChatTitle;

  /// No description provided for @groupCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get groupCreateRoom;

  /// No description provided for @groupNewRoom.
  ///
  /// In en, this message translates to:
  /// **'New group chat'**
  String get groupNewRoom;

  /// No description provided for @groupTopicLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get groupTopicLabel;

  /// No description provided for @groupVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get groupVisibilityLabel;

  /// No description provided for @groupPublicOption.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get groupPublicOption;

  /// No description provided for @groupPrivateOption.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get groupPrivateOption;

  /// No description provided for @groupPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone can join from the lobby'**
  String get groupPublicHint;

  /// No description provided for @groupPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Join only by code or link'**
  String get groupPrivateHint;

  /// No description provided for @groupParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'Participants: {count}'**
  String groupParticipantsCount(int count);

  /// No description provided for @groupCreateAndStart.
  ///
  /// In en, this message translates to:
  /// **'Create and start'**
  String get groupCreateAndStart;

  /// No description provided for @groupCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t create the room'**
  String get groupCreateFailed;

  /// No description provided for @groupEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No open chats yet'**
  String get groupEmptyTitle;

  /// No description provided for @groupEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to create a room!'**
  String get groupEmptySubtitle;

  /// No description provided for @groupJoinByCode.
  ///
  /// In en, this message translates to:
  /// **'Join by code'**
  String get groupJoinByCode;

  /// No description provided for @groupCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABC123'**
  String get groupCodeHint;

  /// No description provided for @groupInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite your friends'**
  String get groupInviteFriends;

  /// No description provided for @groupShareTelegram.
  ///
  /// In en, this message translates to:
  /// **'Share on Telegram'**
  String get groupShareTelegram;

  /// No description provided for @groupCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get groupCopyCode;

  /// No description provided for @groupCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get groupCodeCopied;

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite copied — paste it to a friend'**
  String get inviteCopied;

  /// No description provided for @groupInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get groupInvite;

  /// No description provided for @groupInviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join our group speaking room on EduGain! 🎙\n\nRoom code: {code}\n\nOpen @edugain_bot → Speaking → Group room → “Join by code”'**
  String groupInviteShareText(String code);

  /// No description provided for @groupConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get groupConnected;

  /// No description provided for @groupConnectingStatus.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get groupConnectingStatus;

  /// No description provided for @groupYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get groupYou;

  /// No description provided for @groupMicOff.
  ///
  /// In en, this message translates to:
  /// **'Mic off'**
  String get groupMicOff;

  /// No description provided for @groupRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupRemove;

  /// No description provided for @groupRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found'**
  String get groupRoomNotFound;

  /// No description provided for @groupFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get groupFull;

  /// No description provided for @groupJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get groupJoin;

  /// No description provided for @groupKickedMsg.
  ///
  /// In en, this message translates to:
  /// **'You were removed from the room'**
  String get groupKickedMsg;

  /// No description provided for @groupConnectErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get groupConnectErrorMsg;

  /// No description provided for @groupChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet — be the first to write'**
  String get groupChatEmpty;

  /// No description provided for @groupModeratorNote.
  ///
  /// In en, this message translates to:
  /// **'The AI moderator keeps the topic on track'**
  String get groupModeratorNote;

  /// No description provided for @groupRule4b.
  ///
  /// In en, this message translates to:
  /// **'Follow the AI moderator'**
  String get groupRule4b;

  /// No description provided for @groupCallTime.
  ///
  /// In en, this message translates to:
  /// **'Call time'**
  String get groupCallTime;

  /// No description provided for @groupLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave the room'**
  String get groupLeaveRoom;

  /// No description provided for @groupOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get groupOthers;

  /// No description provided for @groupWriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get groupWriteMessage;

  /// No description provided for @groupParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get groupParticipants;

  /// No description provided for @groupSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get groupSeeAll;

  /// No description provided for @groupRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Room rules'**
  String get groupRulesTitle;

  /// No description provided for @groupRule1.
  ///
  /// In en, this message translates to:
  /// **'Listen to each other'**
  String get groupRule1;

  /// No description provided for @groupRule2.
  ///
  /// In en, this message translates to:
  /// **'Be respectful'**
  String get groupRule2;

  /// No description provided for @groupRule3.
  ///
  /// In en, this message translates to:
  /// **'Speak in English'**
  String get groupRule3;

  /// No description provided for @groupRule4.
  ///
  /// In en, this message translates to:
  /// **'No spam'**
  String get groupRule4;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Call settings'**
  String get groupSettingsTitle;

  /// No description provided for @groupSettingMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get groupSettingMic;

  /// No description provided for @groupSettingNotify.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get groupSettingNotify;

  /// No description provided for @groupSettingRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get groupSettingRules;

  /// No description provided for @groupSpeakNow.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get groupSpeakNow;

  /// No description provided for @groupMuteMic.
  ///
  /// In en, this message translates to:
  /// **'Turn microphone off'**
  String get groupMuteMic;

  /// No description provided for @groupSpeakingNow.
  ///
  /// In en, this message translates to:
  /// **'SPEAKING NOW'**
  String get groupSpeakingNow;

  /// No description provided for @groupNobodySpeaking.
  ///
  /// In en, this message translates to:
  /// **'Nobody is speaking'**
  String get groupNobodySpeaking;

  /// No description provided for @groupInRoom.
  ///
  /// In en, this message translates to:
  /// **'IN THE ROOM'**
  String get groupInRoom;

  /// No description provided for @groupMuteMember.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get groupMuteMember;

  /// No description provided for @groupMakeHost.
  ///
  /// In en, this message translates to:
  /// **'Make host'**
  String get groupMakeHost;

  /// No description provided for @groupMuteEveryone.
  ///
  /// In en, this message translates to:
  /// **'Mute everyone'**
  String get groupMuteEveryone;

  /// No description provided for @groupMutedByHost.
  ///
  /// In en, this message translates to:
  /// **'The host muted you'**
  String get groupMutedByHost;

  /// No description provided for @groupMicBlocked.
  ///
  /// In en, this message translates to:
  /// **'Microphone not allowed'**
  String get groupMicBlocked;

  /// No description provided for @groupHostBadge.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get groupHostBadge;

  /// No description provided for @groupMore.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get groupMore;

  /// No description provided for @grammarTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammarTitle;

  /// No description provided for @grammarChooseLevel.
  ///
  /// In en, this message translates to:
  /// **'Choose your level'**
  String get grammarChooseLevel;

  /// No description provided for @grammarLevelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From A1 to C2 — step-by-step grammar'**
  String get grammarLevelsSubtitle;

  /// No description provided for @grammarTopicCount.
  ///
  /// In en, this message translates to:
  /// **'{count} topics'**
  String grammarTopicCount(int count);

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @grammarLevelA1.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get grammarLevelA1;

  /// No description provided for @grammarLevelA2.
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get grammarLevelA2;

  /// No description provided for @grammarLevelB1.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get grammarLevelB1;

  /// No description provided for @grammarLevelB2.
  ///
  /// In en, this message translates to:
  /// **'Upper-intermediate'**
  String get grammarLevelB2;

  /// No description provided for @grammarLevelC1.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get grammarLevelC1;

  /// No description provided for @grammarLevelC2.
  ///
  /// In en, this message translates to:
  /// **'Proficient'**
  String get grammarLevelC2;

  /// No description provided for @grammarRulePlusPractice.
  ///
  /// In en, this message translates to:
  /// **'Rule + practice'**
  String get grammarRulePlusPractice;

  /// No description provided for @grammarLearnRule.
  ///
  /// In en, this message translates to:
  /// **'Learn the rule'**
  String get grammarLearnRule;

  /// No description provided for @grammarRuleExamplesPattern.
  ///
  /// In en, this message translates to:
  /// **'Rule, examples and pattern'**
  String get grammarRuleExamplesPattern;

  /// No description provided for @grammarPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get grammarPractice;

  /// No description provided for @grammarPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill-in-the-blank + sentence-building games'**
  String get grammarPracticeSubtitle;

  /// No description provided for @grammarStartPractice.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get grammarStartPractice;

  /// No description provided for @grammarRuleLabel.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get grammarRuleLabel;

  /// No description provided for @grammarRuleReadySpeaking.
  ///
  /// In en, this message translates to:
  /// **'Now try using this rule in your Speaking practice 🎯'**
  String get grammarRuleReadySpeaking;

  /// No description provided for @grammarNotEnoughExercises.
  ///
  /// In en, this message translates to:
  /// **'Not enough exercises for this topic.'**
  String get grammarNotEnoughExercises;

  /// No description provided for @grammarChooseForm.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE THE CORRECT FORM'**
  String get grammarChooseForm;

  /// No description provided for @grammarBuildSentence.
  ///
  /// In en, this message translates to:
  /// **'BUILD THE SENTENCE'**
  String get grammarBuildSentence;

  /// No description provided for @answerCorrectExcl.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get answerCorrectExcl;

  /// No description provided for @answerWrongLabel.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get answerWrongLabel;

  /// No description provided for @correctAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String correctAnswerLabel(String answer);

  /// No description provided for @vocabWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What shall we do?'**
  String get vocabWhatToDo;

  /// No description provided for @vocabLearnTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn words'**
  String get vocabLearnTitle;

  /// No description provided for @vocabLearnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See new words with translations and examples'**
  String get vocabLearnSubtitle;

  /// No description provided for @vocabTestKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge'**
  String get vocabTestKnowledge;

  /// No description provided for @vocabTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check what you’ve learned through games'**
  String get vocabTestSubtitle;

  /// No description provided for @vocabDailyReview.
  ///
  /// In en, this message translates to:
  /// **'Daily review'**
  String get vocabDailyReview;

  /// No description provided for @vocabDueReady.
  ///
  /// In en, this message translates to:
  /// **'{count} words are ready to review — reinforce them.'**
  String vocabDueReady(int count);

  /// No description provided for @vocabStartReview.
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get vocabStartReview;

  /// No description provided for @vocabNotEnoughReview.
  ///
  /// In en, this message translates to:
  /// **'Not enough words to review'**
  String get vocabNotEnoughReview;

  /// No description provided for @vocabWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String vocabWordCount(int count);

  /// No description provided for @vocabWordSet.
  ///
  /// In en, this message translates to:
  /// **'Word set'**
  String get vocabWordSet;

  /// No description provided for @vocabHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'How shall we play?'**
  String get vocabHowToPlay;

  /// No description provided for @vocabSoloTitle.
  ///
  /// In en, this message translates to:
  /// **'Solo play'**
  String get vocabSoloTitle;

  /// No description provided for @vocabSoloSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn words at your own pace'**
  String get vocabSoloSubtitle;

  /// No description provided for @vocabSpellTitle.
  ///
  /// In en, this message translates to:
  /// **'Spell it'**
  String get vocabSpellTitle;

  /// No description provided for @vocabSpellSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spell the word from memory'**
  String get vocabSpellSubtitle;

  /// No description provided for @vocabDuelBotTitle.
  ///
  /// In en, this message translates to:
  /// **'Duel with Gainsy'**
  String get vocabDuelBotTitle;

  /// No description provided for @vocabDuelBotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A speed race against the bot'**
  String get vocabDuelBotSubtitle;

  /// No description provided for @vocabDuelOnlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Play with a person'**
  String get vocabDuelOnlineTitle;

  /// No description provided for @vocabDuelOnlineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A speed race against a live opponent'**
  String get vocabDuelOnlineSubtitle;

  /// No description provided for @vocabNotEnoughWords.
  ///
  /// In en, this message translates to:
  /// **'Not enough words in this set to play.'**
  String get vocabNotEnoughWords;

  /// No description provided for @loadRetryError.
  ///
  /// In en, this message translates to:
  /// **'Loading error. Please try again.'**
  String get loadRetryError;

  /// No description provided for @vocabGainsyAnswering.
  ///
  /// In en, this message translates to:
  /// **'Gainsy is answering…'**
  String get vocabGainsyAnswering;

  /// No description provided for @vocabFindingOpponent.
  ///
  /// In en, this message translates to:
  /// **'Finding an opponent…'**
  String get vocabFindingOpponent;

  /// No description provided for @vocabDuelWaitHint.
  ///
  /// In en, this message translates to:
  /// **'You’ll be matched automatically when another learner picks this game'**
  String get vocabDuelWaitHint;

  /// No description provided for @vocabNoOpponent.
  ///
  /// In en, this message translates to:
  /// **'No online opponent right now.'**
  String get vocabNoOpponent;

  /// No description provided for @vocabPlayWithGainsy.
  ///
  /// In en, this message translates to:
  /// **'Play with Gainsy'**
  String get vocabPlayWithGainsy;

  /// No description provided for @vocabPartnerAnswering.
  ///
  /// In en, this message translates to:
  /// **'{name} is answering…'**
  String vocabPartnerAnswering(String name);

  /// No description provided for @vocabConnLostPlayBot.
  ///
  /// In en, this message translates to:
  /// **'Connection problem. Play with Gainsy instead?'**
  String get vocabConnLostPlayBot;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @vocabSpellInstruction.
  ///
  /// In en, this message translates to:
  /// **'SPELL THE WORD'**
  String get vocabSpellInstruction;

  /// No description provided for @vocabNoSpellWords.
  ///
  /// In en, this message translates to:
  /// **'No suitable words in this set to spell.'**
  String get vocabNoSpellWords;

  /// No description provided for @gameChooseTranslation.
  ///
  /// In en, this message translates to:
  /// **'Choose the translation'**
  String get gameChooseTranslation;

  /// No description provided for @gameChooseWord.
  ///
  /// In en, this message translates to:
  /// **'Choose the word'**
  String get gameChooseWord;

  /// No description provided for @gameWordsReadySpeaking.
  ///
  /// In en, this message translates to:
  /// **'These words are now ready for your Speaking practice 🎯'**
  String get gameWordsReadySpeaking;

  /// No description provided for @gameYouWon.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get gameYouWon;

  /// No description provided for @gameOpponentAhead.
  ///
  /// In en, this message translates to:
  /// **'{name} is ahead this time'**
  String gameOpponentAhead(String name);

  /// No description provided for @gameNiceWork.
  ///
  /// In en, this message translates to:
  /// **'Nice work!'**
  String get gameNiceWork;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @gameCorrectAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get gameCorrectAnswers;

  /// No description provided for @gameCombo.
  ///
  /// In en, this message translates to:
  /// **'Combo'**
  String get gameCombo;

  /// No description provided for @gameAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get gameAccuracy;

  /// No description provided for @gamePlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get gamePlayAgain;

  /// No description provided for @vocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabTitle;

  /// No description provided for @speakingSectionAi.
  ///
  /// In en, this message translates to:
  /// **'With the AI tutor · always available'**
  String get speakingSectionAi;

  /// No description provided for @speakingSectionLive.
  ///
  /// In en, this message translates to:
  /// **'With people · live'**
  String get speakingSectionLive;

  /// No description provided for @speakingFreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Free talk'**
  String get speakingFreeTitle;

  /// No description provided for @speakingFreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'With the AI, any topic'**
  String get speakingFreeSubtitle;

  /// No description provided for @speakingTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready lessons'**
  String get speakingTopicsTitle;

  /// No description provided for @speakingTopicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'With the AI, at your level'**
  String get speakingTopicsSubtitle;

  /// No description provided for @speakingGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join an open room or create your own'**
  String get speakingGroupSubtitle;

  /// No description provided for @speakingOneToOneTitle.
  ///
  /// In en, this message translates to:
  /// **'1:1 live chat'**
  String get speakingOneToOneTitle;

  /// No description provided for @speakingOneToOneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Face-to-face practice with one person'**
  String get speakingOneToOneSubtitle;

  /// No description provided for @peerLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Live conversation'**
  String get peerLiveChat;

  /// No description provided for @peerFriendRoom.
  ///
  /// In en, this message translates to:
  /// **'Room with a friend'**
  String get peerFriendRoom;

  /// No description provided for @peerJoinByCode.
  ///
  /// In en, this message translates to:
  /// **'Join by code'**
  String get peerJoinByCode;

  /// No description provided for @peerHistory.
  ///
  /// In en, this message translates to:
  /// **'Conversation history'**
  String get peerHistory;

  /// No description provided for @peerConvCount.
  ///
  /// In en, this message translates to:
  /// **'{count} conversations'**
  String peerConvCount(int count);

  /// No description provided for @peerRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get peerRoomCode;

  /// No description provided for @peerEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get peerEnter;

  /// No description provided for @peerOnlineCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people online'**
  String peerOnlineCount(int count);

  /// No description provided for @peerFindPartner.
  ///
  /// In en, this message translates to:
  /// **'Find a partner'**
  String get peerFindPartner;

  /// No description provided for @peerFindPartnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect randomly with a learner online\nand have a live English conversation'**
  String get peerFindPartnerSubtitle;

  /// No description provided for @peerNoHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get peerNoHistoryTitle;

  /// No description provided for @peerNoHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find your first partner — every conversation\nis saved here.'**
  String get peerNoHistorySubtitle;

  /// No description provided for @peerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get peerToday;

  /// No description provided for @peerYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get peerYesterday;

  /// No description provided for @peerDurMinSec.
  ///
  /// In en, this message translates to:
  /// **'{m} min {s} s'**
  String peerDurMinSec(int m, int s);

  /// No description provided for @peerDurSec.
  ///
  /// In en, this message translates to:
  /// **'{s} s'**
  String peerDurSec(int s);

  /// No description provided for @peerStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get peerStatusConnecting;

  /// No description provided for @peerStatusSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for a partner…'**
  String get peerStatusSearching;

  /// No description provided for @peerStatusWaitingFriend.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your friend'**
  String get peerStatusWaitingFriend;

  /// No description provided for @peerStatusConnectingVoice.
  ///
  /// In en, this message translates to:
  /// **'Connecting audio…'**
  String get peerStatusConnectingVoice;

  /// No description provided for @peerStatusLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Live conversation · {time}'**
  String peerStatusLiveChat(String time);

  /// No description provided for @peerStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Conversation ended'**
  String get peerStatusEnded;

  /// No description provided for @peerSearchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Looking for a suitable partner…'**
  String get peerSearchingTitle;

  /// No description provided for @peerSearchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You’ll connect automatically once another\nlearner starts searching'**
  String get peerSearchingSubtitle;

  /// No description provided for @peerYourPartner.
  ///
  /// In en, this message translates to:
  /// **'Your conversation partner'**
  String get peerYourPartner;

  /// No description provided for @peerInviteTelegram.
  ///
  /// In en, this message translates to:
  /// **'Invite via Telegram'**
  String get peerInviteTelegram;

  /// No description provided for @peerInviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join me for a live English conversation on EduGain! Enter this code in the app’s “Live conversation” section: {code}'**
  String peerInviteShareText(String code);

  /// No description provided for @peerYourRole.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get peerYourRole;

  /// No description provided for @peerPartnerRole.
  ///
  /// In en, this message translates to:
  /// **'Partner’s role'**
  String get peerPartnerRole;

  /// No description provided for @peerStopSearching.
  ///
  /// In en, this message translates to:
  /// **'Stop searching'**
  String get peerStopSearching;

  /// No description provided for @peerEndedPartnerLeft.
  ///
  /// In en, this message translates to:
  /// **'Your partner left the conversation.'**
  String get peerEndedPartnerLeft;

  /// No description provided for @peerEndedYouEnded.
  ///
  /// In en, this message translates to:
  /// **'Conversation ended. Good practice! 👏'**
  String get peerEndedYouEnded;

  /// No description provided for @peerEndedFailed.
  ///
  /// In en, this message translates to:
  /// **'A connection problem occurred. Please try again.'**
  String get peerEndedFailed;

  /// No description provided for @peerEndedDefault.
  ///
  /// In en, this message translates to:
  /// **'Conversation ended.'**
  String get peerEndedDefault;

  /// No description provided for @speakingDailyMission.
  ///
  /// In en, this message translates to:
  /// **'Daily mission'**
  String get speakingDailyMission;

  /// No description provided for @speakingRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get speakingRecommended;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @tracksSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracksSectionTitle;

  /// No description provided for @lessonsOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} lessons'**
  String lessonsOf(int done, int total);

  /// No description provided for @speakingExploreByGoal.
  ///
  /// In en, this message translates to:
  /// **'Explore by goal'**
  String get speakingExploreByGoal;

  /// No description provided for @speakingLessonPremium.
  ///
  /// In en, this message translates to:
  /// **'This lesson is part of Premium.'**
  String get speakingLessonPremium;

  /// No description provided for @speakingReachToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Reach {level} to unlock this lesson.'**
  String speakingReachToUnlock(String level);

  /// No description provided for @speakingStartFirstLesson.
  ///
  /// In en, this message translates to:
  /// **'Start your first lesson'**
  String get speakingStartFirstLesson;

  /// No description provided for @speakingPickGoal.
  ///
  /// In en, this message translates to:
  /// **'Pick a goal and begin speaking in seconds.'**
  String get speakingPickGoal;

  /// No description provided for @speakingStartNow.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get speakingStartNow;

  /// No description provided for @speakingContinueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get speakingContinueLearning;

  /// No description provided for @speakingPracticeAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice again'**
  String get speakingPracticeAgain;

  /// No description provided for @speakingTodaysMission.
  ///
  /// In en, this message translates to:
  /// **'Today’s Speaking Mission'**
  String get speakingTodaysMission;

  /// No description provided for @speakingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load Speaking.'**
  String get speakingLoadError;

  /// No description provided for @speakingLastToday.
  ///
  /// In en, this message translates to:
  /// **'Last opened today'**
  String get speakingLastToday;

  /// No description provided for @speakingLastYesterday.
  ///
  /// In en, this message translates to:
  /// **'Last opened yesterday'**
  String get speakingLastYesterday;

  /// No description provided for @speakingLastDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last opened {days} days ago'**
  String speakingLastDaysAgo(int days);

  /// No description provided for @speakingMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String speakingMinutesShort(int minutes);

  /// No description provided for @speakingLessonsShort.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} lessons'**
  String speakingLessonsShort(int done, int total);

  /// No description provided for @speakingLessonsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} lessons completed'**
  String speakingLessonsCompleted(int done, int total);

  /// No description provided for @turnFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Your answer wasn’t sent'**
  String get turnFailedRetry;

  /// No description provided for @assistTooFast.
  ///
  /// In en, this message translates to:
  /// **'One moment — try again in a second.'**
  String get assistTooFast;

  /// No description provided for @sayAgain.
  ///
  /// In en, this message translates to:
  /// **'Say again'**
  String get sayAgain;

  /// No description provided for @saySlower.
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get saySlower;

  /// No description provided for @youSaidLabel.
  ///
  /// In en, this message translates to:
  /// **'You said'**
  String get youSaidLabel;

  /// No description provided for @sttMisheardHint.
  ///
  /// In en, this message translates to:
  /// **'Not what you said? Tap the mic and try again.'**
  String get sttMisheardHint;

  /// No description provided for @switchToTyping.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get switchToTyping;

  /// No description provided for @switchToSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speak instead'**
  String get switchToSpeaking;

  /// No description provided for @sendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendAction;

  /// No description provided for @sendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sendingLabel;

  /// No description provided for @speakingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Past conversations'**
  String get speakingHistoryTitle;

  /// No description provided for @speakingHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get speakingHistoryEmpty;

  /// No description provided for @speakingHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Finish a speaking session and it will be saved here with its report.'**
  String get speakingHistoryEmptyBody;

  /// No description provided for @speakingTurnsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} turns'**
  String speakingTurnsCount(int count);

  /// No description provided for @speakingUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Unfinished'**
  String get speakingUnfinished;

  /// No description provided for @speakingNoReport.
  ///
  /// In en, this message translates to:
  /// **'No report for this conversation'**
  String get speakingNoReport;

  /// No description provided for @speakingFreeTopicLabel.
  ///
  /// In en, this message translates to:
  /// **'Free topic'**
  String get speakingFreeTopicLabel;

  /// No description provided for @a11yMicReady.
  ///
  /// In en, this message translates to:
  /// **'Microphone. Tap to start speaking'**
  String get a11yMicReady;

  /// No description provided for @a11yMicRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording. Tap to send your answer'**
  String get a11yMicRecording;

  /// No description provided for @a11yMicBusy.
  ///
  /// In en, this message translates to:
  /// **'Please wait — the tutor is answering'**
  String get a11yMicBusy;

  /// No description provided for @speakingUnclearAudio.
  ///
  /// In en, this message translates to:
  /// **'Hard to hear — try saying it again a bit clearer'**
  String get speakingUnclearAudio;

  /// No description provided for @tapToHide.
  ///
  /// In en, this message translates to:
  /// **'Tap to hide the text'**
  String get tapToHide;

  /// No description provided for @groupReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get groupReply;

  /// No description provided for @questionsDraw.
  ///
  /// In en, this message translates to:
  /// **'Random question'**
  String get questionsDraw;

  /// No description provided for @questionsDrawHint.
  ///
  /// In en, this message translates to:
  /// **'Run out of things to say? Tap Random question for one you have not answered yet.'**
  String get questionsDrawHint;

  /// No description provided for @questionsAllSeen.
  ///
  /// In en, this message translates to:
  /// **'All answered — starting over'**
  String get questionsAllSeen;

  /// No description provided for @courseUnitLocked.
  ///
  /// In en, this message translates to:
  /// **'This unit is not open yet — finish the one before it'**
  String get courseUnitLocked;

  /// No description provided for @courseUnitsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} units done'**
  String courseUnitsDone(int done, int total);

  /// No description provided for @courseStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get courseStart;

  /// No description provided for @courseLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get courseLessons;

  /// No description provided for @courseRule.
  ///
  /// In en, this message translates to:
  /// **'The rule'**
  String get courseRule;

  /// No description provided for @courseYouWillLearn.
  ///
  /// In en, this message translates to:
  /// **'THIS UNIT TEACHES'**
  String get courseYouWillLearn;

  /// No description provided for @courseStartLesson.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get courseStartLesson;

  /// No description provided for @courseContinueLesson.
  ///
  /// In en, this message translates to:
  /// **'Continue lesson {n}'**
  String courseContinueLesson(int n);

  /// No description provided for @courseLessonN.
  ///
  /// In en, this message translates to:
  /// **'Lesson {n}'**
  String courseLessonN(int n);

  /// No description provided for @courseItemCount.
  ///
  /// In en, this message translates to:
  /// **'{n} exercises'**
  String courseItemCount(int n);

  /// No description provided for @courseMastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery {level} of {max}'**
  String courseMastery(int level, int max);

  /// No description provided for @drillPickMeaning.
  ///
  /// In en, this message translates to:
  /// **'Choose the meaning of the word'**
  String get drillPickMeaning;

  /// No description provided for @drillPickWord.
  ///
  /// In en, this message translates to:
  /// **'Choose the English word'**
  String get drillPickWord;

  /// No description provided for @drillMatchPairs.
  ///
  /// In en, this message translates to:
  /// **'Tap on the left, then its pair on the right'**
  String get drillMatchPairs;

  /// No description provided for @drillPickAnswer.
  ///
  /// In en, this message translates to:
  /// **'Choose the correct answer'**
  String get drillPickAnswer;

  /// No description provided for @drillOrderWords.
  ///
  /// In en, this message translates to:
  /// **'Tap the words to build the sentence'**
  String get drillOrderWords;

  /// No description provided for @drillTypeMissing.
  ///
  /// In en, this message translates to:
  /// **'Type the missing word'**
  String get drillTypeMissing;

  /// No description provided for @drillRewrite.
  ///
  /// In en, this message translates to:
  /// **'Rewrite the sentence'**
  String get drillRewrite;

  /// No description provided for @courseCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get courseCheck;

  /// No description provided for @courseContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get courseContinue;

  /// No description provided for @courseCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get courseCorrect;

  /// No description provided for @courseNotQuite.
  ///
  /// In en, this message translates to:
  /// **'Not this time'**
  String get courseNotQuite;

  /// No description provided for @courseTheAnswerWas.
  ///
  /// In en, this message translates to:
  /// **'The answer: {answer}'**
  String courseTheAnswerWas(String answer);

  /// No description provided for @courseLessonDone.
  ///
  /// In en, this message translates to:
  /// **'Lesson complete!'**
  String get courseLessonDone;

  /// No description provided for @courseUnitDone.
  ///
  /// In en, this message translates to:
  /// **'Unit complete!'**
  String get courseUnitDone;

  /// No description provided for @courseCorrectCount.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get courseCorrectCount;

  /// No description provided for @courseBackToPath.
  ///
  /// In en, this message translates to:
  /// **'Back to the path'**
  String get courseBackToPath;

  /// No description provided for @courseQuitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the lesson?'**
  String get courseQuitTitle;

  /// No description provided for @courseQuitBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers so far will not be saved.'**
  String get courseQuitBody;

  /// No description provided for @courseQuitStay.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get courseQuitStay;

  /// No description provided for @courseQuitLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get courseQuitLeave;

  /// No description provided for @lessonCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Words & Rules'**
  String get lessonCourseTitle;

  /// No description provided for @lessonCourseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn the rules, memorise the words'**
  String get lessonCourseSubtitle;

  /// No description provided for @lessonPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get lessonPracticeTitle;

  /// No description provided for @lessonPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What you got wrong'**
  String get lessonPracticeSubtitle;

  /// No description provided for @courseWillReturn.
  ///
  /// In en, this message translates to:
  /// **'This one comes back at the end'**
  String get courseWillReturn;

  /// No description provided for @courseTestFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get courseTestFinish;

  /// No description provided for @courseTestPassed.
  ///
  /// In en, this message translates to:
  /// **'{n} units unlocked!'**
  String courseTestPassed(int n);

  /// No description provided for @courseTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Not yet — start from the lessons'**
  String get courseTestFailed;

  /// No description provided for @courseTestNoXp.
  ///
  /// In en, this message translates to:
  /// **'Jumping ahead earns no XP. Do the lessons and they pay normally.'**
  String get courseTestNoXp;

  /// No description provided for @courseJumpTitle.
  ///
  /// In en, this message translates to:
  /// **'Already know this?'**
  String get courseJumpTitle;

  /// No description provided for @courseJumpBody.
  ///
  /// In en, this message translates to:
  /// **'Answer {n} questions from the earlier units. Score above {pass}% and they open — but they earn no XP.'**
  String courseJumpBody(int n, int pass);

  /// No description provided for @courseJumpStart.
  ///
  /// In en, this message translates to:
  /// **'Take the test'**
  String get courseJumpStart;

  /// No description provided for @courseJumpCancel.
  ///
  /// In en, this message translates to:
  /// **'No, I will go in order'**
  String get courseJumpCancel;

  /// No description provided for @courseReview.
  ///
  /// In en, this message translates to:
  /// **'REVIEW'**
  String get courseReview;

  /// No description provided for @courseQuitBodyKept.
  ///
  /// In en, this message translates to:
  /// **'What you answered is kept, but the lesson stays unfinished.'**
  String get courseQuitBodyKept;

  /// No description provided for @homeSpeakLive.
  ///
  /// In en, this message translates to:
  /// **'Speak live'**
  String get homeSpeakLive;

  /// No description provided for @homeGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Group room'**
  String get homeGroupTitle;

  /// No description provided for @homeGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Talk in an open room of up to 50'**
  String get homeGroupSubtitle;

  /// No description provided for @homePeerTitle.
  ///
  /// In en, this message translates to:
  /// **'Talk to a partner'**
  String get homePeerTitle;

  /// No description provided for @homePeerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One to one, with a real person'**
  String get homePeerSubtitle;

  /// No description provided for @peerFindTap.
  ///
  /// In en, this message translates to:
  /// **'Find a partner'**
  String get peerFindTap;

  /// No description provided for @profilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get profilePhotoTitle;

  /// No description provided for @profilePhotoPick.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profilePhotoPick;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoReset.
  ///
  /// In en, this message translates to:
  /// **'Use my Telegram picture'**
  String get profilePhotoReset;

  /// No description provided for @profilePhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Picture updated'**
  String get profilePhotoSaved;

  /// No description provided for @profilePhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That picture is too large — 2 MB at most'**
  String get profilePhotoTooLarge;

  /// No description provided for @commProfileIntro.
  ///
  /// In en, this message translates to:
  /// **'From your recent conversations. Each score is out of 100.'**
  String get commProfileIntro;

  /// No description provided for @bandStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get bandStrong;

  /// No description provided for @bandGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get bandGood;

  /// No description provided for @bandMiddle.
  ///
  /// In en, this message translates to:
  /// **'Getting there'**
  String get bandMiddle;

  /// No description provided for @bandStarting.
  ///
  /// In en, this message translates to:
  /// **'Just starting'**
  String get bandStarting;

  /// No description provided for @trendUp.
  ///
  /// In en, this message translates to:
  /// **'improving'**
  String get trendUp;

  /// No description provided for @trendDown.
  ///
  /// In en, this message translates to:
  /// **'slipping'**
  String get trendDown;

  /// No description provided for @trendSteady.
  ///
  /// In en, this message translates to:
  /// **'steady'**
  String get trendSteady;

  /// No description provided for @paceExplain.
  ///
  /// In en, this message translates to:
  /// **'Fluent conversation usually runs 120–160 words a minute. Speed is not the goal on its own — being clear matters more.'**
  String get paceExplain;

  /// No description provided for @focusTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Your tutor will watch for these in your next conversations.'**
  String get focusTagsHint;

  /// No description provided for @tagVerbTense.
  ///
  /// In en, this message translates to:
  /// **'Verb tenses'**
  String get tagVerbTense;

  /// No description provided for @tagWordChoice.
  ///
  /// In en, this message translates to:
  /// **'Word choice'**
  String get tagWordChoice;

  /// No description provided for @tagWordOrder.
  ///
  /// In en, this message translates to:
  /// **'Word order'**
  String get tagWordOrder;

  /// No description provided for @tagArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles (a / the)'**
  String get tagArticles;

  /// No description provided for @tagPreposition.
  ///
  /// In en, this message translates to:
  /// **'Prepositions'**
  String get tagPreposition;

  /// No description provided for @tagPlural.
  ///
  /// In en, this message translates to:
  /// **'Plurals'**
  String get tagPlural;

  /// No description provided for @tagAgreement.
  ///
  /// In en, this message translates to:
  /// **'Subject–verb agreement'**
  String get tagAgreement;

  /// No description provided for @tagPronoun.
  ///
  /// In en, this message translates to:
  /// **'Pronouns'**
  String get tagPronoun;

  /// No description provided for @tagComparative.
  ///
  /// In en, this message translates to:
  /// **'Comparatives'**
  String get tagComparative;

  /// No description provided for @tagConditional.
  ///
  /// In en, this message translates to:
  /// **'Conditionals'**
  String get tagConditional;

  /// No description provided for @tagQuestionForm.
  ///
  /// In en, this message translates to:
  /// **'Question forms'**
  String get tagQuestionForm;

  /// No description provided for @tagCollocation.
  ///
  /// In en, this message translates to:
  /// **'Word pairings'**
  String get tagCollocation;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @xpSourceCourse.
  ///
  /// In en, this message translates to:
  /// **'Course lesson'**
  String get xpSourceCourse;

  /// No description provided for @developerTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get developerTitle;

  /// No description provided for @developerCopied.
  ///
  /// In en, this message translates to:
  /// **'Telegram handle copied'**
  String get developerCopied;

  /// No description provided for @speakingTopicsTag.
  ///
  /// In en, this message translates to:
  /// **'CEFR · IELTS'**
  String get speakingTopicsTag;

  /// No description provided for @peerWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who would you like to talk to?'**
  String get peerWhoTitle;

  /// No description provided for @peerWhoFemale.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get peerWhoFemale;

  /// No description provided for @peerWhoMale.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get peerWhoMale;

  /// No description provided for @peerWhoAny.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get peerWhoAny;

  /// No description provided for @peerWhoFemaleSub.
  ///
  /// In en, this message translates to:
  /// **'You will only be matched with women'**
  String get peerWhoFemaleSub;

  /// No description provided for @peerWhoMaleSub.
  ///
  /// In en, this message translates to:
  /// **'You will only be matched with men'**
  String get peerWhoMaleSub;

  /// No description provided for @peerWhoAnySub.
  ///
  /// In en, this message translates to:
  /// **'Matches fastest'**
  String get peerWhoAnySub;

  /// No description provided for @peerWhoStart.
  ///
  /// In en, this message translates to:
  /// **'Find a partner'**
  String get peerWhoStart;

  /// No description provided for @peerWhoNarrowHint.
  ///
  /// In en, this message translates to:
  /// **'Narrowing the search can mean a longer wait.'**
  String get peerWhoNarrowHint;

  /// No description provided for @peerWhoOnline.
  ///
  /// In en, this message translates to:
  /// **'{count} online now'**
  String peerWhoOnline(int count);

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountName;

  /// No description provided for @accountUsername.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get accountUsername;

  /// No description provided for @accountPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get accountPhone;

  /// No description provided for @accountGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get accountGender;

  /// No description provided for @accountGenderUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get accountGenderUnset;

  /// No description provided for @accountGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get accountGenderFemale;

  /// No description provided for @accountGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get accountGenderMale;

  /// No description provided for @accountGenderWhy.
  ///
  /// In en, this message translates to:
  /// **'Used to find you a suitable partner in live conversation.'**
  String get accountGenderWhy;

  /// No description provided for @accountNoUsername.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get accountNoUsername;

  /// No description provided for @accountSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get accountSaved;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Live quiz'**
  String get quizTitle;

  /// No description provided for @quizHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Live quiz'**
  String get quizHubTitle;

  /// No description provided for @quizHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join any time — a new match every 3 minutes'**
  String get quizHubSubtitle;

  /// No description provided for @quizPlaying.
  ///
  /// In en, this message translates to:
  /// **'{count} playing'**
  String quizPlaying(int count);

  /// No description provided for @quizAlone.
  ///
  /// In en, this message translates to:
  /// **'Be the first in'**
  String get quizAlone;

  /// No description provided for @quizQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String quizQuestionOf(int index, int total);

  /// No description provided for @quizPickMeaning.
  ///
  /// In en, this message translates to:
  /// **'Choose the meaning'**
  String get quizPickMeaning;

  /// No description provided for @quizPickWord.
  ///
  /// In en, this message translates to:
  /// **'Choose the word'**
  String get quizPickWord;

  /// No description provided for @quizFillGap.
  ///
  /// In en, this message translates to:
  /// **'Fill the gap'**
  String get quizFillGap;

  /// No description provided for @quizGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get quizGrammar;

  /// No description provided for @quizCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get quizCorrect;

  /// No description provided for @quizWrong.
  ///
  /// In en, this message translates to:
  /// **'Not this time'**
  String get quizWrong;

  /// No description provided for @quizTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time up'**
  String get quizTimeUp;

  /// No description provided for @quizPoints.
  ///
  /// In en, this message translates to:
  /// **'+{points}'**
  String quizPoints(int points);

  /// No description provided for @quizMatchBoard.
  ///
  /// In en, this message translates to:
  /// **'This match'**
  String get quizMatchBoard;

  /// No description provided for @quizNextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match in {seconds}s'**
  String quizNextMatch(int seconds);

  /// No description provided for @quizMatchOver.
  ///
  /// In en, this message translates to:
  /// **'Match over'**
  String get quizMatchOver;

  /// No description provided for @quizYouPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get quizYouPlaceholder;

  /// No description provided for @quizNoScoreYet.
  ///
  /// In en, this message translates to:
  /// **'Answer one to get on the board'**
  String get quizNoScoreYet;

  /// No description provided for @quizEmpty.
  ///
  /// In en, this message translates to:
  /// **'The quiz is warming up. Try again in a moment.'**
  String get quizEmpty;

  /// No description provided for @quizJoinedMidMatch.
  ///
  /// In en, this message translates to:
  /// **'You joined mid-match — a new one starts soon'**
  String get quizJoinedMidMatch;

  /// No description provided for @quizStart.
  ///
  /// In en, this message translates to:
  /// **'Start a quiz'**
  String get quizStart;

  /// No description provided for @quizStartHint.
  ///
  /// In en, this message translates to:
  /// **'Nobody is playing yet — open a game and everyone gets a nudge'**
  String get quizStartHint;

  /// No description provided for @quizLobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting to start'**
  String get quizLobbyTitle;

  /// No description provided for @quizWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'{count} more to begin'**
  String quizWaitingFor(int count);

  /// No description provided for @quizStartingNow.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get quizStartingNow;

  /// No description provided for @quizImReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get quizImReady;

  /// No description provided for @quizYouAreReady.
  ///
  /// In en, this message translates to:
  /// **'You\'re in'**
  String get quizYouAreReady;

  /// No description provided for @quizInLobby.
  ///
  /// In en, this message translates to:
  /// **'In the lobby'**
  String get quizInLobby;

  /// No description provided for @quizHostedBy.
  ///
  /// In en, this message translates to:
  /// **'{name} opened this game'**
  String quizHostedBy(String name);

  /// No description provided for @quizLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get quizLeave;

  /// No description provided for @peerNoMicBody.
  ///
  /// In en, this message translates to:
  /// **'Microphone is off — tap to try again'**
  String get peerNoMicBody;

  /// No description provided for @peerListening.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic when you want to speak'**
  String get peerListening;
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
