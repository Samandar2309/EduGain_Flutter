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
  String get peerQuotaTitle => 'Today\'s live conversation time is used up';

  @override
  String get peerQuotaBody =>
      'Upgrade for unlimited live conversations with other learners.';

  @override
  String get resumeTitle => 'Unfinished conversation';

  @override
  String resumeSubtitle(int turns) {
    return '$turns turns in — pick up where you left off';
  }

  @override
  String get resumeAction => 'Continue';

  @override
  String get networkError => 'Connection problem. Please try again.';

  @override
  String get feedbackNotReadyTitle => 'Report isn\'t ready';

  @override
  String get feedbackNotReadyBody =>
      'Your conversation is saved. The scoring service didn\'t answer just now — you can build the report again.';

  @override
  String get continueAction => 'Continue';

  @override
  String minutesShort(int count) {
    return '${count}m';
  }

  @override
  String groupRoomHoldsUpTo(int count) {
    return 'The room holds up to $count people';
  }

  @override
  String get cannotHearYou => 'We can\'t hear you — speak up, or type instead';

  @override
  String get micBlockedTapToAllow => 'Microphone blocked — tap to allow';

  @override
  String minutesLeft(int count) {
    return '$count min left';
  }

  @override
  String get actionEnd => 'End';

  @override
  String get questionsTitle => 'Questions';

  @override
  String get workedTitle => 'How to answer this';

  @override
  String get workedWeak => 'What most people say';

  @override
  String get workedStrong => 'What works better';

  @override
  String get workedMoves => 'What changed';

  @override
  String get workedLocked => 'Answer breakdowns are in Premium';

  @override
  String get workedLockedWhy =>
      'The questions are free for everyone. The breakdown — a weak and a strong answer side by side, with the difference marked — is in Premium.';

  @override
  String get workedOpen => 'Open the breakdown';

  @override
  String questionsFollows(String title) {
    return 'Follows the card: $title';
  }

  @override
  String get questionsPart3Hint =>
      'These are not about you but about people in general. Give a view and a reason for it — a sentence or two will not be enough.';

  @override
  String get cueCardLabel => 'Cue card';

  @override
  String get cueCardYouShouldSay => 'You should say:';

  @override
  String get cueCardHint =>
      'Prepare for one minute, then speak for two without stopping. Practising in a pair: one reads the card and keeps time, then you swap.';

  @override
  String cueCardPrep(int count) {
    return '$count min to prepare';
  }

  @override
  String cueCardTalk(int count) {
    return '$count min to talk';
  }

  @override
  String get questionsModeSubtitle => 'Ready-made questions to talk about';

  @override
  String get questionsIntro =>
      'Ask each other in a live conversation, or prepare on your own.';

  @override
  String get questionsUseHint =>
      'Pick one and ask your partner — then answer it yourself.';

  @override
  String get questionsSaved => 'Saved';

  @override
  String get questionsNoneSaved =>
      'Nothing saved yet.\nBookmark the questions you like.';

  @override
  String get questionsNew => 'NEW';

  @override
  String get questionsError => 'Could not load the questions.';

  @override
  String get speakingSectionPrepare => 'Prepare';

  @override
  String questionsCount(int count) {
    return '$count questions';
  }

  @override
  String questionsTopicCount(int count) {
    return '$count topics';
  }

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
  String get learnLangComingSoon => 'Coming soon';

  @override
  String get learnLangNotifyMe => 'We\'ll tell you';

  @override
  String learnLangInterestSaved(String language) {
    return 'Noted. You\'ll be the first to hear when $language opens.';
  }

  @override
  String get feedbackSendTitle => 'Send feedback';

  @override
  String get feedbackSendSubtitle =>
      'What broke, what\'s missing — tell us. We read every one.';

  @override
  String get feedbackHint => 'Describe the problem or your suggestion…';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackEmpty => 'Please write something first';

  @override
  String get feedbackThanks => 'Thank you — we\'ve got it.';

  @override
  String get feedbackTooMany =>
      'That\'s enough messages for today. Let\'s carry on tomorrow.';

  @override
  String get rateSessionQuestion => 'How was that conversation?';

  @override
  String get rateSessionCommentHint =>
      'Anything you\'d like to add? (optional)';

  @override
  String get rateSessionCommentSent => 'Comment sent. Thank you!';

  @override
  String get rateSessionThanks => 'Thanks — that helps.';

  @override
  String get channelTitle => 'Join our channel';

  @override
  String get channelSubtitle =>
      'New lessons, tips and announcements all land there. Subscribe once and we\'ll carry on.';

  @override
  String get channelOpenAction => 'Open the channel';

  @override
  String get channelJoinedAction => 'I\'ve subscribed';

  @override
  String get channelNotYet =>
      'We can\'t see your subscription yet. Join the channel and try again.';

  @override
  String greeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String levelLabel(String level) {
    return 'English: $level';
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
  String get details => 'Details';

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
  String get gamesTitle => 'Games';

  @override
  String get gamesVocabTitle => 'Word games';

  @override
  String get gamesVocabSubtitle => 'Alone, against Gainsy, or a live opponent';

  @override
  String get gamesGrammarTitle => 'Grammar';

  @override
  String get gamesGrammarSubtitle => 'Learn the rule, then drill it';

  @override
  String get gamesBrowseTitle => 'Browse words';

  @override
  String get gamesBrowseSubtitle => 'With translation and an example';

  @override
  String get gamesReviewSubtitle => 'Words you are about to forget';

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
  String get placementResultBody =>
      'Your tutor will speak at this level from now on, and it moves as you improve.';

  @override
  String get placementLastResultTitle => 'Your last result';

  @override
  String get placementTakenToday => 'Taken today';

  @override
  String get placementTakenYesterday => 'Taken yesterday';

  @override
  String placementTakenDaysAgo(int days) {
    return 'Taken $days days ago';
  }

  @override
  String get placementRetakeQuestion => 'Do you want to take the test again?';

  @override
  String get placementRetakeReplaces =>
      'Your new result will replace this level.';

  @override
  String get placementRetakeAction => 'Yes, start again';

  @override
  String get placementKeepAction => 'No, keep my level';

  @override
  String get levelInviteTitle => 'First, let\'s find your level';

  @override
  String get levelInviteBody =>
      'A few quick questions. After that your tutor speaks at a level you can follow, instead of guessing.';

  @override
  String get levelInviteMeta => '18 questions · about 2 minutes';

  @override
  String get levelInviteStart => 'Find my level';

  @override
  String get levelInviteSkip => 'Not now';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get navLeaderboard => 'Leaderboard';

  @override
  String get leaderboardThisWeek => 'This week';

  @override
  String get leaderboardLastWeek => 'Last week';

  @override
  String get leaderboardEmpty => 'Nobody has earned XP this week yet.';

  @override
  String get leaderboardEmptyLastWeek => 'Nobody earned XP last week.';

  @override
  String get leaderboardFirstPlaceOpen => 'First conversation, first place.';

  @override
  String get leaderboardNotRankedYet =>
      'Finish one lesson to join this week\'s board.';

  @override
  String get leaderboardYou => 'You';

  @override
  String get leaderboardYouAreFirst => 'You are first — hold it.';

  @override
  String get leaderboardPlaceSuffix => 'th place —';

  @override
  String leaderboardStreakDays(int days) {
    return '$days days';
  }

  @override
  String get leaderboardResetsMonday => 'The board starts again every Monday.';

  @override
  String get tierFree => 'Free';

  @override
  String get homeLevelUnknown => 'Level: not set';

  @override
  String get statStreak => 'Day streak';

  @override
  String get statGoal => 'Goal';

  @override
  String get homeAiKicker => 'Recommended';

  @override
  String get homeAiTitle => 'Start a conversation with AI';

  @override
  String get homeAiSubtitle => 'Sharpen your speaking';

  @override
  String get homeAiLocked => 'Opens once your level is set';

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
  String get quotaTitle => 'Daily speaking time';

  @override
  String quotaMinutesLeft(int minutes) {
    return '$minutes min left';
  }

  @override
  String quotaUsedOf(int used, int total) {
    return '$used of $total min used';
  }

  @override
  String get quotaExhausted => 'Today\'s minutes are used up';

  @override
  String get quotaUpgrade => 'Increase limit';

  @override
  String get commProfileTitle => 'Communication Profile';

  @override
  String get commProfileEmpty =>
      'Have a few conversations with the AI tutor — your profile builds itself from your real speech.';

  @override
  String get focusTagsTitle => 'Working on now';

  @override
  String get paceLabel => 'Speaking pace';

  @override
  String paceValue(int wpm) {
    return '$wpm words/min';
  }

  @override
  String paceTarget(int target) {
    return 'goal $target';
  }

  @override
  String get minutesSpoken => 'Minutes spoken';

  @override
  String get wordsSpoken => 'Words spoken';

  @override
  String basedOnSessions(int count) {
    return 'based on $count sessions';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get paywallReportTitle => 'Unlock your full report';

  @override
  String get paywallReportBody =>
      'Every mistake, correction and personal tip — with Premium.';

  @override
  String get paywallSeePlans => 'See plans';

  @override
  String get premiumBadge => 'Premium';

  @override
  String get planPopular => 'Most popular';

  @override
  String get premiumHeroTitle => 'EduGain Premium';

  @override
  String get premiumHeroBody =>
      'Speak more every day, open every track and get the full analysis of your speech.';

  @override
  String get appTagline => 'English with artificial intelligence';

  @override
  String get welcomeChooseLanguage => 'Choose your language';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomeSpeakTitle => 'Speak with an AI tutor';

  @override
  String get welcomeSpeakBody =>
      'Real conversations any time of day. No judgement, no fear of mistakes — just practice.';

  @override
  String get welcomeCoachTitle => 'Live coaching as you talk';

  @override
  String get welcomeCoachBody =>
      'Gentle corrections after every sentence and a clear report on your grammar, vocabulary and fluency.';

  @override
  String get welcomeGoalTitle => 'A path to your goal';

  @override
  String get welcomeGoalBody =>
      'IELTS, career, travel or everyday talk — follow a track that adapts to your weak spots.';

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

  @override
  String get groupChatTitle => 'Group chat';

  @override
  String get groupCreateRoom => 'Create room';

  @override
  String get groupNewRoom => 'New group chat';

  @override
  String get groupTopicLabel => 'Topic';

  @override
  String get groupVisibilityLabel => 'Visibility';

  @override
  String get groupPublicOption => 'Public';

  @override
  String get groupPrivateOption => 'Private';

  @override
  String get groupPublicHint => 'Anyone can join from the lobby';

  @override
  String get groupPrivateHint => 'Join only by code or link';

  @override
  String groupParticipantsCount(int count) {
    return 'Participants: $count';
  }

  @override
  String get groupCreateAndStart => 'Create and start';

  @override
  String get groupCreateFailed => 'Couldn’t create the room';

  @override
  String get groupEmptyTitle => 'No open chats yet';

  @override
  String get groupEmptySubtitle => 'Be the first to create a room!';

  @override
  String get groupJoinByCode => 'Join by code';

  @override
  String get groupCodeHint => 'e.g. ABC123';

  @override
  String get groupInviteFriends => 'Invite your friends';

  @override
  String get groupShareTelegram => 'Share on Telegram';

  @override
  String get groupCopyCode => 'Copy code';

  @override
  String get groupCodeCopied => 'Code copied';

  @override
  String get inviteCopied => 'Invite copied — paste it to a friend';

  @override
  String get groupInvite => 'Invite';

  @override
  String groupInviteShareText(String code) {
    return 'Join our group speaking room on EduGain! 🎙\n\nRoom code: $code\n\nOpen @edugain_bot → Speaking → Group room → “Join by code”';
  }

  @override
  String get groupConnected => 'Connected';

  @override
  String get groupConnectingStatus => 'Connecting…';

  @override
  String get groupYou => 'You';

  @override
  String get groupMicOff => 'Mic off';

  @override
  String get groupRemove => 'Remove';

  @override
  String get groupRoomNotFound => 'Room not found';

  @override
  String get groupFull => 'Full';

  @override
  String get groupJoin => 'Join';

  @override
  String get groupKickedMsg => 'You were removed from the room';

  @override
  String get groupConnectErrorMsg => 'Connection error';

  @override
  String get groupChatEmpty => 'No messages yet — be the first to write';

  @override
  String get groupModeratorNote => 'The AI moderator keeps the topic on track';

  @override
  String get groupRule4b => 'Follow the AI moderator';

  @override
  String get groupCallTime => 'Call time';

  @override
  String get groupLeaveRoom => 'Leave the room';

  @override
  String get groupOthers => 'Others';

  @override
  String get groupWriteMessage => 'Write a message…';

  @override
  String get groupParticipants => 'Participants';

  @override
  String get groupSeeAll => 'See all';

  @override
  String get groupRulesTitle => 'Room rules';

  @override
  String get groupRule1 => 'Listen to each other';

  @override
  String get groupRule2 => 'Be respectful';

  @override
  String get groupRule3 => 'Speak in English';

  @override
  String get groupRule4 => 'No spam';

  @override
  String get groupSettingsTitle => 'Call settings';

  @override
  String get groupSettingMic => 'Microphone';

  @override
  String get groupSettingNotify => 'Alerts';

  @override
  String get groupSettingRules => 'Rules';

  @override
  String get groupSpeakNow => 'Speak';

  @override
  String get groupMuteMic => 'Turn microphone off';

  @override
  String get groupSpeakingNow => 'SPEAKING NOW';

  @override
  String get groupNobodySpeaking => 'Nobody is speaking';

  @override
  String get groupInRoom => 'IN THE ROOM';

  @override
  String get groupMuteMember => 'Mute';

  @override
  String get groupMakeHost => 'Make host';

  @override
  String get groupMuteEveryone => 'Mute everyone';

  @override
  String get groupMutedByHost => 'The host muted you';

  @override
  String get groupMicBlocked => 'Microphone not allowed';

  @override
  String get groupHostBadge => 'Host';

  @override
  String get groupMore => 'more';

  @override
  String get grammarTitle => 'Grammar';

  @override
  String get grammarChooseLevel => 'Choose your level';

  @override
  String get grammarLevelsSubtitle => 'From A1 to C2 — step-by-step grammar';

  @override
  String grammarTopicCount(int count) {
    return '$count topics';
  }

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get grammarLevelA1 => 'Beginner';

  @override
  String get grammarLevelA2 => 'Elementary';

  @override
  String get grammarLevelB1 => 'Intermediate';

  @override
  String get grammarLevelB2 => 'Upper-intermediate';

  @override
  String get grammarLevelC1 => 'Advanced';

  @override
  String get grammarLevelC2 => 'Proficient';

  @override
  String get grammarRulePlusPractice => 'Rule + practice';

  @override
  String get grammarLearnRule => 'Learn the rule';

  @override
  String get grammarRuleExamplesPattern => 'Rule, examples and pattern';

  @override
  String get grammarPractice => 'Practice';

  @override
  String get grammarPracticeSubtitle =>
      'Fill-in-the-blank + sentence-building games';

  @override
  String get grammarStartPractice => 'Start practice';

  @override
  String get grammarRuleLabel => 'Rule';

  @override
  String get grammarRuleReadySpeaking =>
      'Now try using this rule in your Speaking practice 🎯';

  @override
  String get grammarNotEnoughExercises =>
      'Not enough exercises for this topic.';

  @override
  String get grammarChooseForm => 'CHOOSE THE CORRECT FORM';

  @override
  String get grammarBuildSentence => 'BUILD THE SENTENCE';

  @override
  String get answerCorrectExcl => 'Correct!';

  @override
  String get answerWrongLabel => 'Wrong';

  @override
  String correctAnswerLabel(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get vocabWhatToDo => 'What shall we do?';

  @override
  String get vocabLearnTitle => 'Learn words';

  @override
  String get vocabLearnSubtitle =>
      'See new words with translations and examples';

  @override
  String get vocabTestKnowledge => 'Test your knowledge';

  @override
  String get vocabTestSubtitle => 'Check what you’ve learned through games';

  @override
  String get vocabDailyReview => 'Daily review';

  @override
  String vocabDueReady(int count) {
    return '$count words are ready to review — reinforce them.';
  }

  @override
  String get vocabStartReview => 'Start review';

  @override
  String get vocabNotEnoughReview => 'Not enough words to review';

  @override
  String vocabWordCount(int count) {
    return '$count words';
  }

  @override
  String get vocabWordSet => 'Word set';

  @override
  String get vocabHowToPlay => 'How shall we play?';

  @override
  String get vocabSoloTitle => 'Solo play';

  @override
  String get vocabSoloSubtitle => 'Learn words at your own pace';

  @override
  String get vocabSpellTitle => 'Spell it';

  @override
  String get vocabSpellSubtitle => 'Spell the word from memory';

  @override
  String get vocabDuelBotTitle => 'Duel with Gainsy';

  @override
  String get vocabDuelBotSubtitle => 'A speed race against the bot';

  @override
  String get vocabDuelOnlineTitle => 'Play with a person';

  @override
  String get vocabDuelOnlineSubtitle => 'A speed race against a live opponent';

  @override
  String get vocabNotEnoughWords => 'Not enough words in this set to play.';

  @override
  String get loadRetryError => 'Loading error. Please try again.';

  @override
  String get vocabGainsyAnswering => 'Gainsy is answering…';

  @override
  String get vocabFindingOpponent => 'Finding an opponent…';

  @override
  String get vocabDuelWaitHint =>
      'You’ll be matched automatically when another learner picks this game';

  @override
  String get vocabNoOpponent => 'No online opponent right now.';

  @override
  String get vocabPlayWithGainsy => 'Play with Gainsy';

  @override
  String vocabPartnerAnswering(String name) {
    return '$name is answering…';
  }

  @override
  String get vocabConnLostPlayBot =>
      'Connection problem. Play with Gainsy instead?';

  @override
  String get backAction => 'Back';

  @override
  String get vocabSpellInstruction => 'SPELL THE WORD';

  @override
  String get vocabNoSpellWords => 'No suitable words in this set to spell.';

  @override
  String get gameChooseTranslation => 'Choose the translation';

  @override
  String get gameChooseWord => 'Choose the word';

  @override
  String get gameWordsReadySpeaking =>
      'These words are now ready for your Speaking practice 🎯';

  @override
  String get gameYouWon => 'You won!';

  @override
  String gameOpponentAhead(String name) {
    return '$name is ahead this time';
  }

  @override
  String get gameNiceWork => 'Nice work!';

  @override
  String get youLabel => 'You';

  @override
  String get gameCorrectAnswers => 'Correct';

  @override
  String get gameCombo => 'Combo';

  @override
  String get gameAccuracy => 'Accuracy';

  @override
  String get gamePlayAgain => 'Play again';

  @override
  String get vocabTitle => 'Vocabulary';

  @override
  String get speakingSectionAi => 'With the AI tutor · always available';

  @override
  String get speakingSectionLive => 'With people · live';

  @override
  String get speakingFreeTitle => 'Free talk';

  @override
  String get speakingFreeSubtitle => 'With the AI, any topic';

  @override
  String get speakingTopicsTitle => 'Ready lessons';

  @override
  String get speakingTopicsSubtitle => 'With the AI, at your level';

  @override
  String get speakingGroupSubtitle => 'Join an open room or create your own';

  @override
  String get speakingOneToOneTitle => '1:1 live chat';

  @override
  String get speakingOneToOneSubtitle =>
      'Face-to-face practice with one person';

  @override
  String get peerLiveChat => 'Live conversation';

  @override
  String get micPrimerTitle => 'Turn on your microphone';

  @override
  String get micPrimerBody =>
      'Your partner needs to hear you. Your browser will now ask for permission — please choose “Allow”.';

  @override
  String get micPrimerAllowWord => 'Allow';

  @override
  String get micPrimerBlockWord => 'Block';

  @override
  String get micPrimerContinue => 'Continue';

  @override
  String get micBlockedTelegramBody =>
      'Microphone access was refused. Close Telegram completely, open EduGain again, and choose “Allow” this time.';

  @override
  String get micBlockedBrowserBody =>
      'Microphone access is blocked for this site. Tap the lock icon next to the address bar → Microphone → Allow, then reload.';

  @override
  String get peerPartnerMicOff =>
      'Your partner’s microphone is off — they can hear you, but you cannot hear them.';

  @override
  String get peerNoMicRejoin =>
      'Your microphone isn\'t on. End the call and start again — you\'ll be asked for it first.';

  @override
  String get micPreparing => 'Preparing microphone…';

  @override
  String get micNeededTitle => 'Microphone needed';

  @override
  String get micDeniedBody =>
      'Microphone permission is required to talk with your partner.';

  @override
  String get micBlockedBody =>
      'Microphone access is blocked. Please allow microphone access in your browser or Telegram settings, then try again.';

  @override
  String get micNotFoundBody => 'No microphone was found on this device.';

  @override
  String get micBusyBody =>
      'Your microphone is being used by another app. Close it and try again.';

  @override
  String get micInsecureBody =>
      'The microphone only works over a secure connection. Please reopen the app from the bot.';

  @override
  String get micConstraintsBody =>
      'Your microphone does not support the settings a call needs.';

  @override
  String get micUnknownBody =>
      'The microphone could not be turned on. Please try again.';

  @override
  String get micRetry => 'Try again';

  @override
  String get peerFriendRoom => 'Room with a friend';

  @override
  String get peerJoinByCode => 'Join by code';

  @override
  String get peerHistory => 'Conversation history';

  @override
  String peerConvCount(int count) {
    return '$count conversations';
  }

  @override
  String get peerRoomCode => 'Room code';

  @override
  String get peerEnter => 'Enter';

  @override
  String peerOnlineCount(int count) {
    return '$count people online';
  }

  @override
  String get peerFindPartner => 'Find a partner';

  @override
  String get peerFindPartnerSubtitle =>
      'Connect randomly with a learner online\nand have a live English conversation';

  @override
  String get peerNoHistoryTitle => 'No conversations yet';

  @override
  String get peerNoHistorySubtitle =>
      'Find your first partner — every conversation\nis saved here.';

  @override
  String get peerToday => 'Today';

  @override
  String get peerYesterday => 'Yesterday';

  @override
  String peerDurMinSec(int m, int s) {
    return '$m min $s s';
  }

  @override
  String peerDurSec(int s) {
    return '$s s';
  }

  @override
  String get peerStatusConnecting => 'Connecting…';

  @override
  String get peerStatusSearching => 'Looking for a partner…';

  @override
  String get peerStatusWaitingFriend => 'Waiting for your friend';

  @override
  String get peerStatusConnectingVoice => 'Connecting audio…';

  @override
  String peerStatusLiveChat(String time) {
    return 'Live conversation · $time';
  }

  @override
  String get peerStatusEnded => 'Conversation ended';

  @override
  String get peerSearchingTitle => 'Looking for a suitable partner…';

  @override
  String get peerSearchingSubtitle =>
      'You’ll connect automatically once another\nlearner starts searching';

  @override
  String get peerYourPartner => 'Your conversation partner';

  @override
  String get peerInviteTelegram => 'Invite via Telegram';

  @override
  String peerInviteShareText(String code) {
    return 'Join me for a live English conversation on EduGain! Enter this code in the app’s “Live conversation” section: $code';
  }

  @override
  String get peerYourRole => 'Your role';

  @override
  String get peerPartnerRole => 'Partner’s role';

  @override
  String get peerStopSearching => 'Stop searching';

  @override
  String get peerEndedPartnerLeft => 'Your partner left the conversation.';

  @override
  String get peerEndedYouEnded => 'Conversation ended. Good practice! 👏';

  @override
  String get peerEndedFailed =>
      'A connection problem occurred. Please try again.';

  @override
  String get peerEndedDefault => 'Conversation ended.';

  @override
  String get speakingDailyMission => 'Daily mission';

  @override
  String get speakingRecommended => 'Recommended for you';

  @override
  String get seeAll => 'See all';

  @override
  String get tracksSectionTitle => 'Tracks';

  @override
  String lessonsOf(int done, int total) {
    return '$done of $total lessons';
  }

  @override
  String get speakingExploreByGoal => 'Explore by goal';

  @override
  String get speakingLessonPremium => 'This lesson is part of Premium.';

  @override
  String speakingReachToUnlock(String level) {
    return 'Reach $level to unlock this lesson.';
  }

  @override
  String get speakingStartFirstLesson => 'Start your first lesson';

  @override
  String get speakingPickGoal => 'Pick a goal and begin speaking in seconds.';

  @override
  String get speakingStartNow => 'Start now';

  @override
  String get speakingContinueLearning => 'Continue learning';

  @override
  String get speakingPracticeAgain => 'Practice again';

  @override
  String get speakingTodaysMission => 'Today’s Speaking Mission';

  @override
  String get speakingLoadError => 'Couldn’t load Speaking.';

  @override
  String get speakingLastToday => 'Last opened today';

  @override
  String get speakingLastYesterday => 'Last opened yesterday';

  @override
  String speakingLastDaysAgo(int days) {
    return 'Last opened $days days ago';
  }

  @override
  String speakingMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String speakingLessonsShort(int done, int total) {
    return '$done/$total lessons';
  }

  @override
  String speakingLessonsCompleted(int done, int total) {
    return '$done of $total lessons completed';
  }

  @override
  String get turnFailedRetry => 'Your answer wasn’t sent';

  @override
  String get assistTooFast => 'One moment — try again in a second.';

  @override
  String get sayAgain => 'Say again';

  @override
  String get saySlower => 'Slower';

  @override
  String get youSaidLabel => 'You said';

  @override
  String get sttMisheardHint => 'Not what you said? Tap the mic and try again.';

  @override
  String get switchToTyping => 'Type instead';

  @override
  String get switchToSpeaking => 'Speak instead';

  @override
  String get sendAction => 'Send';

  @override
  String get sendingLabel => 'Sending';

  @override
  String get speakingHistoryTitle => 'Past conversations';

  @override
  String get speakingHistoryEmpty => 'No conversations yet';

  @override
  String get speakingHistoryEmptyBody =>
      'Finish a speaking session and it will be saved here with its report.';

  @override
  String speakingTurnsCount(int count) {
    return '$count turns';
  }

  @override
  String get speakingUnfinished => 'Unfinished';

  @override
  String get speakingNoReport => 'No report for this conversation';

  @override
  String get speakingFreeTopicLabel => 'Free topic';

  @override
  String get a11yMicReady => 'Microphone. Tap to start speaking';

  @override
  String get a11yMicRecording => 'Recording. Tap to send your answer';

  @override
  String get a11yMicBusy => 'Please wait — the tutor is answering';

  @override
  String get speakingUnclearAudio =>
      'Hard to hear — try saying it again a bit clearer';

  @override
  String get tapToHide => 'Tap to hide the text';

  @override
  String get groupReply => 'Reply';

  @override
  String get questionsDraw => 'Random question';

  @override
  String get questionsDrawHint =>
      'Run out of things to say? Tap Random question for one you have not answered yet.';

  @override
  String get questionsAllSeen => 'All answered — starting over';

  @override
  String get courseUnitLocked =>
      'This unit is not open yet — finish the one before it';

  @override
  String courseUnitsDone(int done, int total) {
    return '$done of $total units done';
  }

  @override
  String get courseStart => 'Start';

  @override
  String get courseLessons => 'Lessons';

  @override
  String get courseRule => 'The rule';

  @override
  String get courseYouWillLearn => 'THIS UNIT TEACHES';

  @override
  String get courseStartLesson => 'Start';

  @override
  String courseContinueLesson(int n) {
    return 'Continue lesson $n';
  }

  @override
  String courseNextUnit(String title) {
    return 'Next topic: $title';
  }

  @override
  String courseLessonN(int n) {
    return 'Lesson $n';
  }

  @override
  String courseItemCount(int n) {
    return '$n exercises';
  }

  @override
  String courseMastery(int level, int max) {
    return 'Mastery $level of $max';
  }

  @override
  String get drillPickMeaning => 'Choose the meaning of the word';

  @override
  String get drillPickWord => 'Choose the English word';

  @override
  String get drillMatchPairs => 'Tap on the left, then its pair on the right';

  @override
  String get drillPickAnswer => 'Choose the correct answer';

  @override
  String get drillOrderWords => 'Tap the words to build the sentence';

  @override
  String get drillTypeMissing => 'Type the missing word';

  @override
  String get drillRewrite => 'Rewrite the sentence';

  @override
  String get courseCheck => 'Check';

  @override
  String get courseContinue => 'Continue';

  @override
  String get courseCorrect => 'Correct!';

  @override
  String get courseNotQuite => 'Not this time';

  @override
  String courseTheAnswerWas(String answer) {
    return 'The answer: $answer';
  }

  @override
  String get courseLessonDone => 'Lesson complete!';

  @override
  String get courseUnitDone => 'Unit complete!';

  @override
  String get courseCorrectCount => 'Correct';

  @override
  String get courseBackToPath => 'Back to the path';

  @override
  String get courseQuitTitle => 'Leave the lesson?';

  @override
  String get courseQuitBody => 'Your answers so far will not be saved.';

  @override
  String get courseQuitStay => 'Keep going';

  @override
  String get courseQuitLeave => 'Leave';

  @override
  String get lessonCourseTitle => 'Words & Rules';

  @override
  String get lessonCourseSubtitle => 'Learn the rules, memorise the words';

  @override
  String get lessonPracticeTitle => 'Practice';

  @override
  String get lessonPracticeSubtitle => 'What you got wrong';

  @override
  String get courseWillReturn => 'This one comes back at the end';

  @override
  String get courseTestFinish => 'Finish';

  @override
  String courseTestPassed(int n) {
    return '$n units unlocked!';
  }

  @override
  String get courseTestFailed => 'Not yet — start from the lessons';

  @override
  String get courseTestNoXp =>
      'Jumping ahead earns no XP. Do the lessons and they pay normally.';

  @override
  String get courseJumpTitle => 'Already know this?';

  @override
  String courseJumpBody(int n, int pass) {
    return 'Answer $n questions from the earlier units. Score above $pass% and they open — but they earn no XP.';
  }

  @override
  String get courseJumpStart => 'Take the test';

  @override
  String get courseJumpCancel => 'No, I will go in order';

  @override
  String get courseReview => 'REVIEW';

  @override
  String get courseQuitBodyKept =>
      'What you answered is kept, but the lesson stays unfinished.';

  @override
  String get homeSpeakLive => 'Speak live';

  @override
  String get homeGroupTitle => 'Group room';

  @override
  String get homeGroupSubtitle => 'Talk in an open room of up to 50';

  @override
  String get homePeerTitle => 'Talk to a partner';

  @override
  String get homePeerSubtitle => 'One to one, with a real person';

  @override
  String get peerFindTap => 'Find a partner';

  @override
  String get profilePhotoTitle => 'Profile picture';

  @override
  String get profilePhotoPick => 'Choose from gallery';

  @override
  String get profilePhotoCamera => 'Take a photo';

  @override
  String get profilePhotoReset => 'Use my Telegram picture';

  @override
  String get profilePhotoSaved => 'Picture updated';

  @override
  String get profilePhotoTooLarge => 'That picture is too large — 2 MB at most';

  @override
  String get commProfileIntro =>
      'From your recent conversations. Each score is out of 100.';

  @override
  String get bandStrong => 'Strong';

  @override
  String get bandGood => 'Good';

  @override
  String get bandMiddle => 'Getting there';

  @override
  String get bandStarting => 'Just starting';

  @override
  String get trendUp => 'improving';

  @override
  String get trendDown => 'slipping';

  @override
  String get trendSteady => 'steady';

  @override
  String get paceExplain =>
      'Fluent conversation usually runs 120–160 words a minute. Speed is not the goal on its own — being clear matters more.';

  @override
  String get focusTagsHint =>
      'Your tutor will watch for these in your next conversations.';

  @override
  String get tagVerbTense => 'Verb tenses';

  @override
  String get tagWordChoice => 'Word choice';

  @override
  String get tagWordOrder => 'Word order';

  @override
  String get tagArticles => 'Articles (a / the)';

  @override
  String get tagPreposition => 'Prepositions';

  @override
  String get tagPlural => 'Plurals';

  @override
  String get tagAgreement => 'Subject–verb agreement';

  @override
  String get tagPronoun => 'Pronouns';

  @override
  String get tagComparative => 'Comparatives';

  @override
  String get tagConditional => 'Conditionals';

  @override
  String get tagQuestionForm => 'Question forms';

  @override
  String get tagCollocation => 'Word pairings';

  @override
  String get accountTitle => 'Account';

  @override
  String get xpSourceCourse => 'Course lesson';

  @override
  String get developerTitle => 'Support';

  @override
  String get developerCopied => 'Telegram handle copied';

  @override
  String get speakingTopicsTag => 'CEFR · IELTS';

  @override
  String get peerWhoTitle => 'Who would you like to talk to?';

  @override
  String get peerWhoFemale => 'Women';

  @override
  String get peerWhoMale => 'Men';

  @override
  String get peerWhoAny => 'Anyone';

  @override
  String get peerWhoFemaleSub => 'You will only be matched with women';

  @override
  String get peerWhoMaleSub => 'You will only be matched with men';

  @override
  String get peerWhoAnySub => 'Matches fastest';

  @override
  String get peerWhoStart => 'Find a partner';

  @override
  String get peerWhoNarrowHint =>
      'Narrowing the search can mean a longer wait.';

  @override
  String peerWhoOnline(int count) {
    return '$count online now';
  }

  @override
  String get accountName => 'Name';

  @override
  String get accountUsername => 'Telegram';

  @override
  String get accountPhone => 'Phone';

  @override
  String get accountGender => 'Gender';

  @override
  String get accountGenderUnset => 'Not set';

  @override
  String get accountGenderFemale => 'Female';

  @override
  String get accountGenderMale => 'Male';

  @override
  String get accountGenderWhy =>
      'Used to find you a suitable partner in live conversation.';

  @override
  String get accountNoUsername => 'None';

  @override
  String get accountSaved => 'Saved';

  @override
  String get quizTitle => 'Live quiz';

  @override
  String get quizHubTitle => 'Live quiz';

  @override
  String get quizHubSubtitle => 'Join any time — a new match every 3 minutes';

  @override
  String quizPlaying(int count) {
    return '$count playing';
  }

  @override
  String get quizAlone => 'Be the first in';

  @override
  String quizQuestionOf(int index, int total) {
    return '$index of $total';
  }

  @override
  String get quizPickMeaning => 'Choose the meaning';

  @override
  String get quizPickWord => 'Choose the word';

  @override
  String get quizFillGap => 'Fill the gap';

  @override
  String get quizGrammar => 'Grammar';

  @override
  String get quizCorrect => 'Correct';

  @override
  String get quizWrong => 'Not this time';

  @override
  String get quizTimeUp => 'Time up';

  @override
  String quizPoints(int points) {
    return '+$points';
  }

  @override
  String get quizMatchBoard => 'This match';

  @override
  String quizNextMatch(int seconds) {
    return 'Next match in ${seconds}s';
  }

  @override
  String get quizMatchOver => 'Match over';

  @override
  String get quizYouPlaceholder => 'You';

  @override
  String get quizNoScoreYet => 'Answer one to get on the board';

  @override
  String get quizEmpty => 'The quiz is warming up. Try again in a moment.';

  @override
  String get quizJoinedMidMatch =>
      'You joined mid-match — a new one starts soon';

  @override
  String get quizStart => 'Start a quiz';

  @override
  String get quizStartHint =>
      'Nobody is playing yet — open a game and everyone gets a nudge';

  @override
  String get quizLobbyTitle => 'Waiting to start';

  @override
  String quizWaitingFor(int count) {
    return '$count more to begin';
  }

  @override
  String get quizStartingNow => 'Starting…';

  @override
  String get quizImReady => 'I\'m ready';

  @override
  String get quizYouAreReady => 'You\'re in';

  @override
  String get quizInLobby => 'In the lobby';

  @override
  String quizHostedBy(String name) {
    return '$name opened this game';
  }

  @override
  String get quizLeave => 'Leave';

  @override
  String get peerNoMicBody => 'Microphone is off — tap to try again';

  @override
  String get peerListening => 'Tap the mic when you want to speak';

  @override
  String get homeLiveOpen => 'Open now';

  @override
  String get homeLiveQuiet => 'Nobody yet';

  @override
  String homeOnlineN(int count) {
    return '$count online';
  }

  @override
  String get homeJoinChat => 'Join the chat';

  @override
  String get homeSeeAll => 'See all';

  @override
  String homeLessonsN(int count) {
    return '$count lessons';
  }

  @override
  String homeGamesN(int count) {
    return '$count games';
  }

  @override
  String get homeWordsTitle => 'Words & Rules';

  @override
  String get homeWordsSub => 'New words, rules and practice';

  @override
  String get homeGamesSub => 'Play and sharpen your English';

  @override
  String homeLessonsAt(int done, int total) {
    return '$done of $total';
  }
}
