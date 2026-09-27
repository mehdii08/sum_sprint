import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Hand-written localization class for Sum Sprint.
///
/// All user-facing strings are defined here. Currently only English is provided.
/// To add a new language: add a new map in [_t] and a new entry
/// in [supportedLocales]. No code generation step required.
///
/// Parameterized strings use `{name}` placeholders so translations can
/// reorder them freely.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Get the localized instance from the widget tree.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('en')];

  // ── translations ──

  Map<String, String> _t(String lang) {
    return switch (lang) {
      // Future: add more languages by adding a new case here
      _ => _english,
    };
  }

  String _get(String key) => _t(locale.languageCode)[key] ?? key;

  String _fmt(String key, Map<String, Object> args) {
    var s = _get(key);
    args.forEach((name, value) => s = s.replaceAll('{$name}', '$value'));
    return s;
  }

  /// Looks up [key] dynamically. Unknown keys are returned unchanged, so raw
  /// server messages stored in provider error fields still display as-is.
  String tr(String key) => _get(key);

  static const Map<String, String> _english = {
    'appTitle': 'Sum Sprint',
    'appTagline': 'Sharpen your mind, beat the clock!',
    'splashTagline': 'Fast math, real competitions',
    'nicknameHint': 'Enter your nickname',
    'warmUp': 'Warm Up',
    'competitions': 'Competitions',
    'comingSoon': 'Coming Soon',
    'comingSoonMessage': 'Competition mode will be available in a future update!',
    'ok': 'OK',
    'cancel': 'Cancel',
    'warmUpChallenges': 'Warm Up Challenges',
    'noChallenges': 'No challenges available.',
    'retry': 'Retry',
    'best': 'Best',
    'bestScore': '{score} pts',
    'bestScoreNone': 'No attempts yet',
    'play': 'Play',
    'history': 'History',
    'historyTitle': '{name} - History',
    'clearHistory': 'Clear History',
    'clearHistoryConfirm': 'Are you sure you want to clear all history for this challenge? This cannot be undone.',
    'clear': 'Clear',
    'noGamesPlayed': 'No games played yet',
    'noGamesPlayedHint': 'Complete a challenge to see your history!',
    'justNow': 'Just now',
    'minAgo': '{n}m ago',
    'hourAgo': '{n}h ago',
    'dayAgo': '{n}d ago',
    'dateFormat': '{day}/{month}/{year}',
    'correctOutOf': '{correct}/10 correct',
    'avg': 'avg',
    'getReady': 'Get ready...',
    'timeUp': "Time's Up!",
    'correct': 'Correct!',
    'wrong': 'Wrong!',
    'answerWas': 'Answer: {answer}',
    'quitGame': 'Quit Game?',
    'quitGameConfirm': 'Are you sure you want to quit? Your progress will be lost.',
    'keepPlaying': 'Keep Playing',
    'quit': 'Quit',
    'challengeComplete': 'Challenge Complete!',
    'finalScore': 'Final Score',
    'points': 'points',
    'pointsShort': 'pts',
    'coins': 'coins',
    'coinsAmount': '{n} coins',
    'free': 'Free',
    'playerFallback': 'Player',
    'secondsShort': '{n}s',
    'secondsUnit': 's',
    'correctStat': 'Correct',
    'withinRangeStat': 'Within Range',
    'avgAccuracyStat': 'Avg Accuracy',
    'avgTimeStat': 'Avg Time (s)',
    'totalTimeStat': 'Total Time',
    'newHighScore': 'New High Score!',
    'playAgain': 'Play Again',
    'home': 'Home',

    // ── Shared game intro / controls ─────────────────────────────
    'startGame': 'Start Game',
    'startWithCost': 'Start · {cost}',
    'personalBestNone': 'Personal best: -- pts',
    'roundProgress': 'Round {current}/{total}',
    'roundShort': 'R {current}/{total}',
    'pillRounds': '{n} Rounds',
    'pillSecondsEach': '{n}s Each',
    'pillMaxPoints': '{n} Max Pts',
    'pillPlayers': '{n} Players',
    'pillBestOf': 'Best of {n}',
    'pillSecondsPerRound': '{n}s/Round',
    'pillBlocks': '{n} Blocks',
    'pillMax': '{n} Max',
    'mathIntroTitle': "Solve fast. Don't blink.",
    'mathIntroSubtitle': 'Select the correct answer before time runs out.\nConsecutive correct answers build your multiplier.',

    // ── Challenge entry ──────────────────────────────────────────
    'entryNeedCoins': 'Need {cost} coins (you have {balance})',
    'entryStartTitle': 'Start challenge?',
    'entryCostMessage': 'This costs {cost} coins. You have {balance}.',
    'entryPay': 'Pay {cost}',

    // ── Home ─────────────────────────────────────────────────────
    'homeChallenges': 'Challenges',
    'homeCategoryTiming': 'Timing',
    'homeCategoryMemory': 'Memory',
    'homeCategoryStrategy': 'Strategy',
    'homeCategoryMath': 'Math Speed',
    'homeRounds': '{n} Rounds',
    'homePairs': '{n} Pairs',
    'homeStops': '{n} Stops',
    'homeQuestions': '{n} Questions',
    'homeLeaderboards': 'Leaderboards',
    'homeLeaderboardsSubtitle': 'See global rankings and event boards',

    // ── Leaderboard ──────────────────────────────────────────────
    'leaderboardTitle': 'Leaderboard',
    'leaderboardGlobal': 'Global',
    'leaderboardEnded': 'Ended',
    'leaderboardActive': 'Active',
    'leaderboardRewardsHint': 'Top players win exclusive rewards',
    'leaderboardEmptyTitle': 'No Rankings Yet',
    'leaderboardEmptyMessage': 'Be the first player to compete and\nclaim the top spot.',
    'leaderboardPlayNow': 'Play Now',
    'durationDays': '{n}D',
    'durationHours': '{n}H',
    'durationMinutes': '{n}M',

    // ── Result ───────────────────────────────────────────────────
    'resultTitle': 'Results',
    'resultNewPersonalBest': 'New Personal Best!',
    'resultGoToHub': 'Go to Hub',
    'resultGrade': 'Grade: {grade}',
    'resultTotalPoints': 'Total Points Earned',
    'statTime': 'Time',
    'statOnRange': 'On Range',
    'statAccuracy': 'Accuracy',
    'statAvgTime': 'Avg Time',
    'statTotal': 'Total',

    // ── Login ────────────────────────────────────────────────────
    'loginEnterCode': 'Enter the code from your email',
    'loginCodeResent': 'Code resent. Check your inbox.',
    'loginSignIn': 'Sign In',
    'loginSignUp': 'Sign Up',
    'loginVerifyEmail': 'Verify Email',
    'loginCheckEmail': 'Check your email',
    'loginCodeSentTo': 'We sent a verification code to\n{email}',
    'loginDevCode': 'Dev: use {code}',
    'loginCodeLabel': 'Verification code',
    'loginVerifyContinue': 'Verify & continue',
    'loginResendCode': 'Resend code',
    'loginCreateAccount': 'Create Account',
    'loginWelcomeBack': 'Welcome Back',
    'loginSignUpSubtitle': 'Sign up, then enter the code we email you.',
    'loginSignInSubtitle': 'Sign in to continue where you left off.',
    'loginEmail': 'Email',
    'loginEmailRequired': 'Email is required',
    'loginEmailInvalid': 'Enter a valid email',
    'loginPassword': 'Password',
    'loginPasswordRequired': 'Password is required',
    'loginPasswordTooShort': 'At least 6 characters',
    'loginNicknameOptional': 'Nickname (optional)',
    'loginNicknameHint': 'How others see you on leaderboards',

    // ── Profile ──────────────────────────────────────────────────
    'profileTitle': 'Profile',
    'profileClearCacheTitle': 'Clear Cache & Reload',
    'profileClearCacheMessage': 'This will remove all cached app files and reload the latest version. Your account data stays on the server.\n\nUse this if the app looks outdated or broken.',
    'profileClearCacheSubtitle': 'Clears cached files and reloads the latest version',
    'profileClearAndReload': 'Clear & Reload',
    'profileLogoutTitle': 'Log out?',
    'profileLogoutMessage': 'You will need to sign in again with your email to play.',
    'profileLogout': 'Log out',
    'profileTelegramAccount': 'Telegram Account',
    'profileTelegramUser': 'Telegram User',
    'profileSignedInViaTelegram': 'Signed in via Telegram',
    'profileAccount': 'Account',
    'profileSignedIn': 'Signed in',
    'profileSignedInWithEmail': 'Signed in with email',
    'profileDisplayName': 'Display Name',
    'profileNewNickname': 'New nickname',
    'profileShownOnLeaderboards': 'Shown on leaderboards',
    'profileEdit': 'Edit',
    'profileCoins': 'Coins',
    'profileCoinsHint': 'Earn by playing challenges',
    'profileAppUpdate': 'App Update',
    'profileAdmin': 'Admin',
    'profileAdminSubtitle': 'Manage challenges and leaderboards',

    // ── Errors (keys stored by providers) ────────────────────────
    'errServerNoResponse': 'Server did not respond.',
    'errConnectionRetry': 'Connection error. Please try again.',
    'errInvalidCodeRetry': 'Invalid or expired code. Try again.',
    'errVerifyCodeFailed': 'Could not verify code. Please try again.',
    'errDevOtpNeedsPassword': 'Dev OTP needs the password from this sign-up. Start sign-up again.',
    'errDevConfirmFailed': 'Dev confirm failed. Apply migration 009_dev_confirm_signup.',
    'errResendFailed': 'Could not resend code. Please wait and try again.',
    'errSignInFailed': 'Sign in failed. Check your credentials.',
    'errInvalidCredentials': 'Invalid email or password.',
    'errEmailExists': 'An account with this email already exists.',
    'errInvalidCodeRequestNew': 'Invalid or expired code. Request a new one.',
    'errTooManyAttempts': 'Too many attempts. Please wait a moment.',
    'errNoInternet': 'Connection error. Check your internet.',
    'errLoadChallengesFailed': 'Failed to load challenges',
    'errNotEnoughCoins': 'Not enough coins',
    'errStartChallengeFailed': 'Could not start challenge',
    'errLoadProfileFailed': 'Failed to load profile',

    // ── Mind Timer ───────────────────────────────────────────────
    'mindTimerReadyPrompt': 'When you tap Start, count in your head and stop as close to the target as possible.',
    'mindTimerStart': 'Start',
    'mindTimerStop': 'Stop',
    'mindTimerCounting': 'Counting...',
    'mindTimerCountingHint': 'Count in your head. No visible timer.',
    'mindTimerSeeTarget': 'See target',
    'mindTimerHidesHint': 'Timer hides when you tap',
    'mindTimerCountInMind': 'Count in your mind.',
    'mindTimerStopWhenFeel': 'Stop when you feel the time.',
    'mindTimerPerfect': 'Perfect!',
    'mindTimerAmazing': 'Amazing!',
    'mindTimerGreat': 'Great!',
    'mindTimerClose': 'Close!',
    'mindTimerAlmost': 'Almost...',
    'mindTimerWayOff': 'Way off',
    'mindTimerOutsideRange': 'Outside range',
    'mindTimerPoints': 'points',
    'mindTimerOffBy': 'Off by {diff}s',
    'stopAtExactly': 'Stop at exactly',
    'submittingScore': 'Submitting score...',
    'scoreSubmitted': 'Score submitted!',
    'scoreSavedLocally': 'Score saved locally. Sync will retry later.',
    'backToCompetition': 'Back to Competition',

    // ── Admin ────────────────────────────────────────────────────
    'adminAccessDenied': 'Admin access denied',
    'adminAccessDeniedMsg': 'You do not have admin privileges.',
    'adminDashboard': 'Admin Dashboard',
    'adminCompetitions': 'Competitions',
    'adminCompetitionsSubtitle': 'Create, update, and delete competitions',
    'adminNewCompetition': 'New Competition',
    'adminEditCompetition': 'Edit Competition',
    'adminManageCompetitions': 'Manage Competitions',
    'adminDeleteCompetitionTitle': 'Delete Competition',
    'adminDeleteCompetitionMsg': 'This will also remove participants and results. Continue?',
    'adminCancel': 'Cancel',
    'adminDelete': 'Delete',
    'adminEdit': 'Edit',
    'adminCreate': 'Create',
    'adminUpdate': 'Update',
    'adminNameLabel': 'Name',
    'adminNameRequired': 'Required',
    'adminNameIsRequired': 'Name is required',
    'adminDescriptionLabel': 'Description',
    'adminEntryCoins': 'Entry Coins',
    'adminEntryCoinsFree': 'Entry Coins (0 = free)',
    'adminPrizePool': 'Prize Pool (coins)',
    'adminWinners': 'Winners',
    'adminWinnerShares': 'Winner Shares',
    'adminStatus': 'Status',
    'adminUpcoming': 'Upcoming',
    'adminActive': 'Active',
    'adminFinished': 'Finished',
    'adminEnded': 'Ended',
    'adminChallenges': 'Challenges',
    'adminChallengesSubtitle': 'Manage challenges shown on the home screen',
    'adminManageChallenges': 'Manage Challenges',
    'adminNewChallenge': 'New Challenge',
    'adminEditChallenge': 'Edit Challenge',
    'adminDeleteChallengeTitle': 'Delete Challenge',
    'adminDeleteChallengeMsg': 'Are you sure you want to delete this challenge?',
    'adminNoChallenges': 'No challenges yet',
    'adminTapToCreate': 'Tap + to create your first one',
    'adminChallengeType': 'Challenge Type',
    'adminAddChallenge': 'Add challenge',
    'adminRemoveChallenge': 'Remove challenge',
    'adminChallengeName': 'Challenge Name',
    'adminMin': 'Min',
    'adminMax': 'Max',
    'adminMinNumber': 'Min Number',
    'adminMaxNumber': 'Max Number',
    'adminTimeS': 'Time (s)',
    'adminTimePerQuestion': 'Time / Q (s)',
    'adminTimeLimitS': 'Time Limit (s)',
    'adminQuestions': 'Questions',
    'adminTargetS': 'Target (s)',
    'adminRangeS': 'Range (±s)',
    'adminMaxPoints': 'Max Points',
    'adminTypeMath': 'Math',
    'adminTypeMindTimer': 'Mind Timer',
    'adminTypeMathDesc': 'Addition, subtraction, etc.',
    'adminTypeMindTimerDesc': 'Stop the hidden timer at the right moment',
    'adminSelectType': 'Select Challenge Type',
    'adminSave': 'Save',
    'adminSaveFailed': 'Failed to save: {error}',
    'adminRetry': 'Retry',
    'adminPanel': 'Admin Panel',
    'adminCustomLeaderboards': 'Custom Leaderboards',
    'adminCustomLeaderboardsSubtitle': 'Manage time-based leaderboards with date ranges and rewards',
    'adminNewLeaderboard': 'New Leaderboard',
    'adminEditLeaderboard': 'Edit Leaderboard',
    'adminDeleteLeaderboardTitle': 'Delete Leaderboard',
    'adminDeleteLeaderboardMsg': 'Are you sure you want to delete this leaderboard? This cannot be undone.',
    'adminNoLeaderboards': 'No custom leaderboards yet',
    'adminTitleLabel': 'Title',
    'adminTitleHint': 'e.g. Weekly Challenge, Weekend Event',
    'adminTitleRequired': 'Title is required',
    'adminDateRange': 'Date Range',
    'adminStartDate': 'Start',
    'adminEndDate': 'End',
    'adminRewardsLabel': 'Rewards (optional)',
    'adminRewardsHint': 'e.g. Top 3 win 1000 coins each',
    'adminActiveLeaderboardHint': 'Only active leaderboards appear in the app',
    'signInSignUp': 'Sign In / Sign Up',
    'nicknameOfflineHint': 'Nickname for offline play',
    'connectingTelegram': 'Connecting to Telegram',

    // ── Challenge instruction overlay ────────────────────────────
    'challengeHowToPlay': 'How to Play',
    'challengeRuleAdd': 'Two numbers will appear on screen.',
    'challengeRuleAnswer': 'Add them together and tap the correct answer.',
    'challengeRuleTimer': 'You have {seconds} seconds per question — answer quickly!',
    'challengeRuleQuestions': 'There are {count} questions in total.',
    'challengeRuleScore': 'Faster correct answers earn more points.',
    'challengeStart': 'Start',

    // ── Pair Hunt ────────────────────────────────────────────────
    'pairHuntPairs': 'Pairs',
    'pairHuntPairsLabel': 'pairs',
    'pairHuntTimeLimit': 'Time Limit',
    'pairHuntTimeLimitValue': '{seconds}s',
    'pairHuntBlocks': 'Blocks',
    'pairHuntHowToPlay': 'How to Play',
    'pairHuntIntroBadge': 'Flip cards. Find matching pairs. Clear the board.',
    'pairHuntIntroTitle': 'Match the pairs. Beat the clock.',
    'pairHuntIntroSubtitle': 'Flip cards to find matching pairs.\nClear all pairs before time runs out!',
    'pairHuntNoMatch': 'No match — try again',
    'pairHuntRule1': 'Tap a block to reveal the emoji behind it.',
    'pairHuntRule2': 'Tap another block — if the emojis match, they stay face‑up!',
    'pairHuntRule3': "If they don't match, both flip back. Remember positions!",
    'pairHuntRule4': 'Find all pairs within {seconds} seconds to maximize your score.',
    'pairHuntStart': 'Start',
    'pairHuntProgress': '{found}/{total} pairs',
    'pairHuntTimeRemaining': '{seconds}s remaining',
    'pairHuntMismatches': 'misses',
    'pairHuntPairsFoundStat': 'Pairs',
    'pairHuntMismatchStat': 'Misses',
    'pairHuntTimeTakenStat': 'Time Taken',
    'pairHuntFinished': 'All pairs found!',
    'pairHuntTimeUp': "Time's Up!",
    'pairHuntTypePrefix': 'Pair Hunt',
    // ── Admin Pair Hunt ─────────────────────────────────────────
    'adminTypePairHunt': 'Pair Hunt',
    'adminTypePairHuntDesc': 'Memory card matching game',
    'adminBlockCount': 'Block Count',
    'adminBlocksEven': 'Blocks (even)',
    'adminPointsPerPair': 'Pts per Pair',
    'adminMaxTimeBonus': 'Max Bonus',
    'adminPenaltyPerMismatch': 'Penalty / Mismatch',

    // ── Tic Tac Toe ─────────────────────────────────────────────
    'ticTacToeRounds': 'Rounds',
    'ticTacToeRoundsValue': '3 (Easy → Medium → Hard)',
    'ticTacToeTimePerRound': 'Time per Round',
    'ticTacToeMaxPoints': 'Max Points',
    'ticTacToeHowToPlay': 'How to Play',
    'ticTacToeIntroBadge': 'Place 3 in a row to win!',
    'ticTacToeIntroTitle': 'Classic Rules. Neon Battle.',
    'ticTacToeIntroSubtitle': 'Outsmart your opponent in a glowing duel of wits.\nThe first to connect three marks wins the round.',
    'ticTacToeRule1': 'You are X and always move first. Tap any empty cell.',
    'ticTacToeRule2': 'The AI answers with O. Get three in a row to win!',
    'ticTacToeRule3': 'You play 3 rounds — the AI gets smarter each round: Easy, Medium, Hard.',
    'ticTacToeRule4': 'Win within {seconds} seconds — the faster you win, the more points you earn. Draws and losses score 0.',
    'ticTacToeRule5': 'Your final score is the average of the 3 rounds.',
    'ticTacToeStart': 'Start',
    'ticTacToeYourTurn': 'Your turn — you are X',
    'ticTacToeYourTurnShort': 'Your turn',
    'ticTacToeAiThinking': 'AI is thinking…',
    'ticTacToeYouWin': 'You Win!',
    'ticTacToeYouLose': 'You Lose',
    'ticTacToeDraw': 'Draw',
    'ticTacToeTimeUp': "Time's Up!",
    'ticTacToeNextRound': 'Next round starting…',
    'ticTacToeAllRoundsDone': 'Calculating final score…',
    'ticTacToeNoPoints': 'No points this round',
    'ticTacToeDifficultyEasy': 'Easy',
    'ticTacToeDifficultyMedium': 'Medium',
    'ticTacToeDifficultyHard': 'Hard',
    'ticTacToeWinsStat': 'Wins',
    'ticTacToeDrawsStat': 'Draws',
    'ticTacToeTimeStat': 'Total Time',
    'ticTacToeRound': 'Round {round}/{total}',
    'ticTacToeTimeRemaining': '{seconds}s remaining',
    'ticTacToeRoundPoints': '+{points} points',
    'ticTacToeWins': '{won}/{total} wins',
    // ── Admin Tic Tac Toe ───────────────────────────────────────
    'adminTypeTicTacToe': 'Tic-Tac-Toe',
    'adminTypeTicTacToeDesc': '3 rounds vs AI (Easy → Medium → Hard)',
    'adminTimePerRound': 'Time / Round (s)',
  };

  // ── getters and parameterized methods ──

  String get appTitle => _get('appTitle');
  String get appTagline => _get('appTagline');
  String get splashTagline => _get('splashTagline');
  String get nicknameHint => _get('nicknameHint');
  String get warmUp => _get('warmUp');
  String get competitions => _get('competitions');
  String get comingSoon => _get('comingSoon');
  String get comingSoonMessage => _get('comingSoonMessage');
  String get ok => _get('ok');
  String get cancel => _get('cancel');
  String get warmUpChallenges => _get('warmUpChallenges');
  String get noChallenges => _get('noChallenges');
  String get retry => _get('retry');
  String get best => _get('best');
  String bestScore(Object score) => _fmt('bestScore', {'score': score});
  String get bestScoreNone => _get('bestScoreNone');
  String get play => _get('play');
  String get history => _get('history');
  String historyTitle(Object name) => _fmt('historyTitle', {'name': name});
  String get clearHistory => _get('clearHistory');
  String get clearHistoryConfirm => _get('clearHistoryConfirm');
  String get clear => _get('clear');
  String get noGamesPlayed => _get('noGamesPlayed');
  String get noGamesPlayedHint => _get('noGamesPlayedHint');
  String get justNow => _get('justNow');
  String minAgo(Object n) => _fmt('minAgo', {'n': n});
  String hourAgo(Object n) => _fmt('hourAgo', {'n': n});
  String dayAgo(Object n) => _fmt('dayAgo', {'n': n});
  String dateFormat(Object day, Object month, Object year) =>
      _fmt('dateFormat', {'day': day, 'month': month, 'year': year});
  String correctOutOf(Object correct) => _fmt('correctOutOf', {'correct': correct});
  String get avg => _get('avg');
  String get getReady => _get('getReady');
  String get timeUp => _get('timeUp');
  String get correct => _get('correct');
  String get wrong => _get('wrong');
  String answerWas(Object answer) => _fmt('answerWas', {'answer': answer});
  String get quitGame => _get('quitGame');
  String get quitGameConfirm => _get('quitGameConfirm');
  String get keepPlaying => _get('keepPlaying');
  String get quit => _get('quit');
  String get challengeComplete => _get('challengeComplete');
  String get finalScore => _get('finalScore');
  String get points => _get('points');
  String get pointsShort => _get('pointsShort');
  String get coins => _get('coins');
  String coinsAmount(Object n) => _fmt('coinsAmount', {'n': n});
  String get free => _get('free');
  String get playerFallback => _get('playerFallback');
  String secondsShort(Object n) => _fmt('secondsShort', {'n': n});
  String get secondsUnit => _get('secondsUnit');
  String get correctStat => _get('correctStat');
  String get avgTimeStat => _get('avgTimeStat');
  String get totalTimeStat => _get('totalTimeStat');
  String get newHighScore => _get('newHighScore');
  String get playAgain => _get('playAgain');
  String get home => _get('home');
  String get withinRangeStat => _get('withinRangeStat');
  String get avgAccuracyStat => _get('avgAccuracyStat');

  // ── Shared game intro / controls ───────────────────────────────
  String get startGame => _get('startGame');
  String startWithCost(Object cost) => _fmt('startWithCost', {'cost': cost});
  String get personalBestNone => _get('personalBestNone');
  String roundProgress(Object current, Object total) =>
      _fmt('roundProgress', {'current': current, 'total': total});
  String roundShort(Object current, Object total) =>
      _fmt('roundShort', {'current': current, 'total': total});
  String pillRounds(Object n) => _fmt('pillRounds', {'n': n});
  String pillSecondsEach(Object n) => _fmt('pillSecondsEach', {'n': n});
  String pillMaxPoints(Object n) => _fmt('pillMaxPoints', {'n': n});
  String pillPlayers(Object n) => _fmt('pillPlayers', {'n': n});
  String pillBestOf(Object n) => _fmt('pillBestOf', {'n': n});
  String pillSecondsPerRound(Object n) => _fmt('pillSecondsPerRound', {'n': n});
  String pillBlocks(Object n) => _fmt('pillBlocks', {'n': n});
  String pillMax(Object n) => _fmt('pillMax', {'n': n});
  String get mathIntroTitle => _get('mathIntroTitle');
  String get mathIntroSubtitle => _get('mathIntroSubtitle');

  // ── Challenge entry ────────────────────────────────────────────
  String entryNeedCoins(Object cost, Object balance) =>
      _fmt('entryNeedCoins', {'cost': cost, 'balance': balance});
  String get entryStartTitle => _get('entryStartTitle');
  String entryCostMessage(Object cost, Object balance) =>
      _fmt('entryCostMessage', {'cost': cost, 'balance': balance});
  String entryPay(Object cost) => _fmt('entryPay', {'cost': cost});

  // ── Home ───────────────────────────────────────────────────────
  String get homeChallenges => _get('homeChallenges');
  String get homeCategoryTiming => _get('homeCategoryTiming');
  String get homeCategoryMemory => _get('homeCategoryMemory');
  String get homeCategoryStrategy => _get('homeCategoryStrategy');
  String get homeCategoryMath => _get('homeCategoryMath');
  String homeRounds(Object n) => _fmt('homeRounds', {'n': n});
  String homePairs(Object n) => _fmt('homePairs', {'n': n});
  String homeStops(Object n) => _fmt('homeStops', {'n': n});
  String homeQuestions(Object n) => _fmt('homeQuestions', {'n': n});
  String get homeLeaderboards => _get('homeLeaderboards');
  String get homeLeaderboardsSubtitle => _get('homeLeaderboardsSubtitle');

  // ── Leaderboard ────────────────────────────────────────────────
  String get leaderboardTitle => _get('leaderboardTitle');
  String get leaderboardGlobal => _get('leaderboardGlobal');
  String get leaderboardEnded => _get('leaderboardEnded');
  String get leaderboardActive => _get('leaderboardActive');
  String get leaderboardRewardsHint => _get('leaderboardRewardsHint');
  String get leaderboardEmptyTitle => _get('leaderboardEmptyTitle');
  String get leaderboardEmptyMessage => _get('leaderboardEmptyMessage');
  String get leaderboardPlayNow => _get('leaderboardPlayNow');
  String durationDays(Object n) => _fmt('durationDays', {'n': n});
  String durationHours(Object n) => _fmt('durationHours', {'n': n});
  String durationMinutes(Object n) => _fmt('durationMinutes', {'n': n});

  // ── Result ─────────────────────────────────────────────────────
  String get resultTitle => _get('resultTitle');
  String get resultNewPersonalBest => _get('resultNewPersonalBest');
  String get resultGoToHub => _get('resultGoToHub');
  String resultGrade(Object grade) => _fmt('resultGrade', {'grade': grade});
  String get resultTotalPoints => _get('resultTotalPoints');
  String get statTime => _get('statTime');
  String get statOnRange => _get('statOnRange');
  String get statAccuracy => _get('statAccuracy');
  String get statAvgTime => _get('statAvgTime');
  String get statTotal => _get('statTotal');

  // ── Login ──────────────────────────────────────────────────────
  String get loginEnterCode => _get('loginEnterCode');
  String get loginCodeResent => _get('loginCodeResent');
  String get loginSignIn => _get('loginSignIn');
  String get loginSignUp => _get('loginSignUp');
  String get loginVerifyEmail => _get('loginVerifyEmail');
  String get loginCheckEmail => _get('loginCheckEmail');
  String loginCodeSentTo(Object email) => _fmt('loginCodeSentTo', {'email': email});
  String loginDevCode(Object code) => _fmt('loginDevCode', {'code': code});
  String get loginCodeLabel => _get('loginCodeLabel');
  String get loginVerifyContinue => _get('loginVerifyContinue');
  String get loginResendCode => _get('loginResendCode');
  String get loginCreateAccount => _get('loginCreateAccount');
  String get loginWelcomeBack => _get('loginWelcomeBack');
  String get loginSignUpSubtitle => _get('loginSignUpSubtitle');
  String get loginSignInSubtitle => _get('loginSignInSubtitle');
  String get loginEmail => _get('loginEmail');
  String get loginEmailRequired => _get('loginEmailRequired');
  String get loginEmailInvalid => _get('loginEmailInvalid');
  String get loginPassword => _get('loginPassword');
  String get loginPasswordRequired => _get('loginPasswordRequired');
  String get loginPasswordTooShort => _get('loginPasswordTooShort');
  String get loginNicknameOptional => _get('loginNicknameOptional');
  String get loginNicknameHint => _get('loginNicknameHint');

  // ── Profile ────────────────────────────────────────────────────
  String get profileTitle => _get('profileTitle');
  String get profileClearCacheTitle => _get('profileClearCacheTitle');
  String get profileClearCacheMessage => _get('profileClearCacheMessage');
  String get profileClearCacheSubtitle => _get('profileClearCacheSubtitle');
  String get profileClearAndReload => _get('profileClearAndReload');
  String get profileLogoutTitle => _get('profileLogoutTitle');
  String get profileLogoutMessage => _get('profileLogoutMessage');
  String get profileLogout => _get('profileLogout');
  String get profileTelegramAccount => _get('profileTelegramAccount');
  String get profileTelegramUser => _get('profileTelegramUser');
  String get profileSignedInViaTelegram => _get('profileSignedInViaTelegram');
  String get profileAccount => _get('profileAccount');
  String get profileSignedIn => _get('profileSignedIn');
  String get profileSignedInWithEmail => _get('profileSignedInWithEmail');
  String get profileDisplayName => _get('profileDisplayName');
  String get profileNewNickname => _get('profileNewNickname');
  String get profileShownOnLeaderboards => _get('profileShownOnLeaderboards');
  String get profileEdit => _get('profileEdit');
  String get profileCoins => _get('profileCoins');
  String get profileCoinsHint => _get('profileCoinsHint');
  String get profileAppUpdate => _get('profileAppUpdate');
  String get profileAdmin => _get('profileAdmin');
  String get profileAdminSubtitle => _get('profileAdminSubtitle');

  // ── Mind Timer ──────────────────────────────────────────────────
  String get mindTimerReadyPrompt => _get('mindTimerReadyPrompt');
  String get mindTimerStart => _get('mindTimerStart');
  String get mindTimerStop => _get('mindTimerStop');
  String get mindTimerCounting => _get('mindTimerCounting');
  String get mindTimerCountingHint => _get('mindTimerCountingHint');
  String get mindTimerSeeTarget => _get('mindTimerSeeTarget');
  String get mindTimerHidesHint => _get('mindTimerHidesHint');
  String get mindTimerCountInMind => _get('mindTimerCountInMind');
  String get mindTimerStopWhenFeel => _get('mindTimerStopWhenFeel');
  String get mindTimerPerfect => _get('mindTimerPerfect');
  String get mindTimerAmazing => _get('mindTimerAmazing');
  String get mindTimerGreat => _get('mindTimerGreat');
  String get mindTimerClose => _get('mindTimerClose');
  String get mindTimerAlmost => _get('mindTimerAlmost');
  String get mindTimerWayOff => _get('mindTimerWayOff');
  String get mindTimerOutsideRange => _get('mindTimerOutsideRange');
  String get mindTimerPoints => _get('mindTimerPoints');
  String mindTimerOffBy(Object diff) => _fmt('mindTimerOffBy', {'diff': diff});

  // ── Result / submission ──────────────────────────────────────
  String get submittingScore => _get('submittingScore');
  String get scoreSubmitted => _get('scoreSubmitted');
  String get scoreSavedLocally => _get('scoreSavedLocally');
  String get backToCompetition => _get('backToCompetition');

  // ── Mind Timer extra ──────────────────────────────────────────
  String get stopAtExactly => _get('stopAtExactly');

  // ── Admin ──────────────────────────────────────────────────────
  String get adminAccessDenied => _get('adminAccessDenied');
  String get adminAccessDeniedMsg => _get('adminAccessDeniedMsg');
  String get adminDashboard => _get('adminDashboard');
  String get adminCompetitions => _get('adminCompetitions');
  String get adminCompetitionsSubtitle => _get('adminCompetitionsSubtitle');
  String get adminNewCompetition => _get('adminNewCompetition');
  String get adminEditCompetition => _get('adminEditCompetition');
  String get adminManageCompetitions => _get('adminManageCompetitions');
  String get adminDeleteCompetitionTitle => _get('adminDeleteCompetitionTitle');
  String get adminDeleteCompetitionMsg => _get('adminDeleteCompetitionMsg');
  String get adminCancel => _get('adminCancel');
  String get adminDelete => _get('adminDelete');
  String get adminEdit => _get('adminEdit');
  String get adminCreate => _get('adminCreate');
  String get adminUpdate => _get('adminUpdate');
  String get adminNameLabel => _get('adminNameLabel');
  String get adminNameRequired => _get('adminNameRequired');
  String get adminNameIsRequired => _get('adminNameIsRequired');
  String get adminDescriptionLabel => _get('adminDescriptionLabel');
  String get adminEntryCoins => _get('adminEntryCoins');
  String get adminEntryCoinsFree => _get('adminEntryCoinsFree');
  String get adminPrizePool => _get('adminPrizePool');
  String get adminWinners => _get('adminWinners');
  String get adminWinnerShares => _get('adminWinnerShares');
  String get adminStatus => _get('adminStatus');
  String get adminUpcoming => _get('adminUpcoming');
  String get adminActive => _get('adminActive');
  String get adminFinished => _get('adminFinished');
  String get adminEnded => _get('adminEnded');
  String get adminChallenges => _get('adminChallenges');
  String get adminChallengesSubtitle => _get('adminChallengesSubtitle');
  String get adminManageChallenges => _get('adminManageChallenges');
  String get adminNewChallenge => _get('adminNewChallenge');
  String get adminEditChallenge => _get('adminEditChallenge');
  String get adminDeleteChallengeTitle => _get('adminDeleteChallengeTitle');
  String get adminDeleteChallengeMsg => _get('adminDeleteChallengeMsg');
  String get adminNoChallenges => _get('adminNoChallenges');
  String get adminTapToCreate => _get('adminTapToCreate');
  String get adminChallengeType => _get('adminChallengeType');
  String get adminAddChallenge => _get('adminAddChallenge');
  String get adminRemoveChallenge => _get('adminRemoveChallenge');
  String get adminChallengeName => _get('adminChallengeName');
  String get adminMin => _get('adminMin');
  String get adminMax => _get('adminMax');
  String get adminMinNumber => _get('adminMinNumber');
  String get adminMaxNumber => _get('adminMaxNumber');
  String get adminTimeS => _get('adminTimeS');
  String get adminTimePerQuestion => _get('adminTimePerQuestion');
  String get adminTimeLimitS => _get('adminTimeLimitS');
  String get adminQuestions => _get('adminQuestions');
  String get adminTargetS => _get('adminTargetS');
  String get adminRangeS => _get('adminRangeS');
  String get adminMaxPoints => _get('adminMaxPoints');
  String get adminTypeMath => _get('adminTypeMath');
  String get adminTypeMindTimer => _get('adminTypeMindTimer');
  String get adminTypeMathDesc => _get('adminTypeMathDesc');
  String get adminTypeMindTimerDesc => _get('adminTypeMindTimerDesc');
  String get adminSelectType => _get('adminSelectType');
  String get adminSave => _get('adminSave');
  String adminSaveFailed(Object error) => _fmt('adminSaveFailed', {'error': error});
  String get adminRetry => _get('adminRetry');
  String get adminPanel => _get('adminPanel');
  String get adminCustomLeaderboards => _get('adminCustomLeaderboards');
  String get adminCustomLeaderboardsSubtitle => _get('adminCustomLeaderboardsSubtitle');
  String get adminNewLeaderboard => _get('adminNewLeaderboard');
  String get adminEditLeaderboard => _get('adminEditLeaderboard');
  String get adminDeleteLeaderboardTitle => _get('adminDeleteLeaderboardTitle');
  String get adminDeleteLeaderboardMsg => _get('adminDeleteLeaderboardMsg');
  String get adminNoLeaderboards => _get('adminNoLeaderboards');
  String get adminTitleLabel => _get('adminTitleLabel');
  String get adminTitleHint => _get('adminTitleHint');
  String get adminTitleRequired => _get('adminTitleRequired');
  String get adminDateRange => _get('adminDateRange');
  String get adminStartDate => _get('adminStartDate');
  String get adminEndDate => _get('adminEndDate');
  String get adminRewardsLabel => _get('adminRewardsLabel');
  String get adminRewardsHint => _get('adminRewardsHint');
  String get adminActiveLeaderboardHint => _get('adminActiveLeaderboardHint');
  String get signInSignUp => _get('signInSignUp');
  String get nicknameOfflineHint => _get('nicknameOfflineHint');
  String get connectingTelegram => _get('connectingTelegram');

  // ── Challenge instruction overlay ─────────────────────────────────
  String get challengeHowToPlay => _get('challengeHowToPlay');
  String get challengeRuleAdd => _get('challengeRuleAdd');
  String get challengeRuleAnswer => _get('challengeRuleAnswer');
  String challengeRuleTimer(Object seconds) =>
      _fmt('challengeRuleTimer', {'seconds': seconds});
  String challengeRuleQuestions(Object count) =>
      _fmt('challengeRuleQuestions', {'count': count});
  String get challengeRuleScore => _get('challengeRuleScore');
  String get challengeStart => _get('challengeStart');

  // ── Pair Hunt ──────────────────────────────────────────────────────
  String get pairHuntPairs => _get('pairHuntPairs');
  String get pairHuntPairsLabel => _get('pairHuntPairsLabel');
  String get pairHuntTimeLimit => _get('pairHuntTimeLimit');
  String pairHuntTimeLimitValue(Object seconds) =>
      _fmt('pairHuntTimeLimitValue', {'seconds': seconds});
  String get pairHuntBlocks => _get('pairHuntBlocks');
  String get pairHuntHowToPlay => _get('pairHuntHowToPlay');
  String get pairHuntIntroBadge => _get('pairHuntIntroBadge');
  String get pairHuntIntroTitle => _get('pairHuntIntroTitle');
  String get pairHuntIntroSubtitle => _get('pairHuntIntroSubtitle');
  String get pairHuntNoMatch => _get('pairHuntNoMatch');
  String get pairHuntRule1 => _get('pairHuntRule1');
  String get pairHuntRule2 => _get('pairHuntRule2');
  String get pairHuntRule3 => _get('pairHuntRule3');
  String pairHuntRule4(Object seconds) =>
      _fmt('pairHuntRule4', {'seconds': seconds});
  String get pairHuntStart => _get('pairHuntStart');
  String pairHuntProgress(Object found, Object total) =>
      _fmt('pairHuntProgress', {'found': found, 'total': total});
  String pairHuntTimeRemaining(Object seconds) =>
      _fmt('pairHuntTimeRemaining', {'seconds': seconds});
  String get pairHuntMismatches => _get('pairHuntMismatches');
  String get pairHuntPairsFoundStat => _get('pairHuntPairsFoundStat');
  String get pairHuntMismatchStat => _get('pairHuntMismatchStat');
  String get pairHuntTimeTakenStat => _get('pairHuntTimeTakenStat');
  String get pairHuntFinished => _get('pairHuntFinished');
  String get pairHuntTimeUp => _get('pairHuntTimeUp');
  String get pairHuntTypePrefix => _get('pairHuntTypePrefix');

  // ── Admin Pair Hunt ────────────────────────────────────────────────
  String get adminTypePairHunt => _get('adminTypePairHunt');
  String get adminTypePairHuntDesc => _get('adminTypePairHuntDesc');
  String get adminBlockCount => _get('adminBlockCount');
  String get adminBlocksEven => _get('adminBlocksEven');
  String get adminPointsPerPair => _get('adminPointsPerPair');
  String get adminMaxTimeBonus => _get('adminMaxTimeBonus');
  String get adminPenaltyPerMismatch => _get('adminPenaltyPerMismatch');

  // ── Tic Tac Toe ────────────────────────────────────────────────────
  String get ticTacToeRounds => _get('ticTacToeRounds');
  String get ticTacToeRoundsValue => _get('ticTacToeRoundsValue');
  String get ticTacToeTimePerRound => _get('ticTacToeTimePerRound');
  String get ticTacToeMaxPoints => _get('ticTacToeMaxPoints');
  String get ticTacToeHowToPlay => _get('ticTacToeHowToPlay');
  String get ticTacToeIntroBadge => _get('ticTacToeIntroBadge');
  String get ticTacToeIntroTitle => _get('ticTacToeIntroTitle');
  String get ticTacToeIntroSubtitle => _get('ticTacToeIntroSubtitle');
  String get ticTacToeRule1 => _get('ticTacToeRule1');
  String get ticTacToeRule2 => _get('ticTacToeRule2');
  String get ticTacToeRule3 => _get('ticTacToeRule3');
  String ticTacToeRule4(Object seconds) =>
      _fmt('ticTacToeRule4', {'seconds': seconds});
  String get ticTacToeRule5 => _get('ticTacToeRule5');
  String get ticTacToeStart => _get('ticTacToeStart');
  String get ticTacToeYourTurn => _get('ticTacToeYourTurn');
  String get ticTacToeYourTurnShort => _get('ticTacToeYourTurnShort');
  String get ticTacToeAiThinking => _get('ticTacToeAiThinking');
  String get ticTacToeYouWin => _get('ticTacToeYouWin');
  String get ticTacToeYouLose => _get('ticTacToeYouLose');
  String get ticTacToeDraw => _get('ticTacToeDraw');
  String get ticTacToeTimeUp => _get('ticTacToeTimeUp');
  String get ticTacToeNextRound => _get('ticTacToeNextRound');
  String get ticTacToeAllRoundsDone => _get('ticTacToeAllRoundsDone');
  String get ticTacToeNoPoints => _get('ticTacToeNoPoints');
  String get ticTacToeDifficultyEasy => _get('ticTacToeDifficultyEasy');
  String get ticTacToeDifficultyMedium => _get('ticTacToeDifficultyMedium');
  String get ticTacToeDifficultyHard => _get('ticTacToeDifficultyHard');
  String get ticTacToeWinsStat => _get('ticTacToeWinsStat');
  String get ticTacToeDrawsStat => _get('ticTacToeDrawsStat');
  String get ticTacToeTimeStat => _get('ticTacToeTimeStat');
  String ticTacToeRound(Object round, Object total) =>
      _fmt('ticTacToeRound', {'round': round, 'total': total});
  String ticTacToeTimeRemaining(Object seconds) =>
      _fmt('ticTacToeTimeRemaining', {'seconds': seconds});
  String ticTacToeRoundPoints(Object points) =>
      _fmt('ticTacToeRoundPoints', {'points': points});
  String ticTacToeWins(Object won, Object total) =>
      _fmt('ticTacToeWins', {'won': won, 'total': total});

  // ── Admin Tic Tac Toe ──────────────────────────────────────────────
  String get adminTypeTicTacToe => _get('adminTypeTicTacToe');
  String get adminTypeTicTacToeDesc => _get('adminTypeTicTacToeDesc');
  String get adminTimePerRound => _get('adminTimePerRound');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
