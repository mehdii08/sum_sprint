import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Hand-written localization class for Sum Sprint.
///
/// All user-facing strings are defined here. Currently only English is provided.
/// To add a new language: add a new map in [localizedStrings] and a new entry
/// in [supportedLocales]. No code generation step required.
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

  static const Map<String, String> _english = {
    'appTitle': 'Sum Sprint',
    'appTagline': 'Sharpen your mind, beat the clock!',
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
    'coins': 'coins',
    'correctStat': 'Correct',
    'withinRangeStat': 'Within Range',
    'avgAccuracyStat': 'Avg Accuracy',
    'avgTimeStat': 'Avg Time (s)',
    'totalTimeStat': 'Total Time',
    'newHighScore': 'New High Score!',
    'playAgain': 'Play Again',
    'home': 'Home',
    // ── Mind Timer ───────────────────────────────────────────────
    'mindTimerReadyPrompt': 'When you tap Start, count in your head and stop as close to the target as possible.',
    'mindTimerStart': 'Start',
    'mindTimerStop': 'Stop',
    'mindTimerCounting': 'Counting...',
    'mindTimerCountingHint': 'Count in your head. No visible timer.',
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
    'adminNameLabel': 'Name',
    'adminNameRequired': 'Required',
    'adminDescriptionLabel': 'Description',
    'adminEntryCoins': 'Entry Coins',
    'adminPrizePool': 'Prize Pool (coins)',
    'adminWinners': 'Winners',
    'adminWinnerShares': 'Winner Shares',
    'adminStatus': 'Status',
    'adminUpcoming': 'Upcoming',
    'adminActive': 'Active',
    'adminFinished': 'Finished',
    'adminChallenges': 'Challenges',
    'adminAddChallenge': 'Add challenge',
    'adminRemoveChallenge': 'Remove challenge',
    'adminChallengeName': 'Challenge Name',
    'adminMin': 'Min',
    'adminMax': 'Max',
    'adminTimeS': 'Time (s)',
    'adminQuestions': 'Questions',
    'adminTargetS': 'Target (s)',
    'adminRangeS': 'Range (s)',
    'adminMaxPoints': 'Max Points',
    'adminTypeMath': 'Math',
    'adminTypeMindTimer': 'Mind Timer',
    'adminTypeMathDesc': 'Addition, subtraction, etc.',
    'adminTypeMindTimerDesc': 'Stop a hidden timer at the target',
    'adminSelectType': 'Select Challenge Type',
    'adminSave': 'Save',
    'adminRetry': 'Retry',
    'adminPanel': 'Admin Panel',
    'signInSignUp': 'Sign In / Sign Up',
    'nicknameOfflineHint': 'Nickname for offline play',
    'connectingTelegram': 'Connecting to Telegram',
  };

  // ── getters and parameterized methods ──

  String get appTitle => _get('appTitle');
  String get appTagline => _get('appTagline');
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
  String bestScore(Object score) => '$score pts';
  String get bestScoreNone => _get('bestScoreNone');
  String get play => _get('play');
  String get history => _get('history');
  String historyTitle(Object name) => '$name - History';
  String get clearHistory => _get('clearHistory');
  String get clearHistoryConfirm => _get('clearHistoryConfirm');
  String get clear => _get('clear');
  String get noGamesPlayed => _get('noGamesPlayed');
  String get noGamesPlayedHint => _get('noGamesPlayedHint');
  String get justNow => _get('justNow');
  String minAgo(Object n) => '${n}m ago';
  String hourAgo(Object n) => '${n}h ago';
  String dayAgo(Object n) => '${n}d ago';
  String dateFormat(Object day, Object month, Object year) =>
      '$day/$month/$year';
  String correctOutOf(Object correct) => '$correct/10 correct';
  String get avg => _get('avg');
  String get getReady => _get('getReady');
  String get timeUp => _get('timeUp');
  String get correct => _get('correct');
  String get wrong => _get('wrong');
  String answerWas(Object answer) => 'Answer: $answer';
  String get quitGame => _get('quitGame');
  String get quitGameConfirm => _get('quitGameConfirm');
  String get keepPlaying => _get('keepPlaying');
  String get quit => _get('quit');
  String get challengeComplete => _get('challengeComplete');
  String get finalScore => _get('finalScore');
  String get points => _get('points');
  String get coins => _get('coins');
  String get correctStat => _get('correctStat');
  String get avgTimeStat => _get('avgTimeStat');
  String get totalTimeStat => _get('totalTimeStat');
  String get newHighScore => _get('newHighScore');
  String get playAgain => _get('playAgain');
  String get home => _get('home');
  String get withinRangeStat => _get('withinRangeStat');
  String get avgAccuracyStat => _get('avgAccuracyStat');

  // ── Mind Timer ──────────────────────────────────────────────────
  String get mindTimerReadyPrompt => _get('mindTimerReadyPrompt');
  String get mindTimerStart => _get('mindTimerStart');
  String get mindTimerStop => _get('mindTimerStop');
  String get mindTimerCounting => _get('mindTimerCounting');
  String get mindTimerCountingHint => _get('mindTimerCountingHint');
  String get mindTimerPerfect => _get('mindTimerPerfect');
  String get mindTimerAmazing => _get('mindTimerAmazing');
  String get mindTimerGreat => _get('mindTimerGreat');
  String get mindTimerClose => _get('mindTimerClose');
  String get mindTimerAlmost => _get('mindTimerAlmost');
  String get mindTimerWayOff => _get('mindTimerWayOff');
  String get mindTimerOutsideRange => _get('mindTimerOutsideRange');
  String get mindTimerPoints => _get('mindTimerPoints');
  String mindTimerOffBy(Object diff) => 'Off by ${diff}s';

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
  String get adminNameLabel => _get('adminNameLabel');
  String get adminNameRequired => _get('adminNameRequired');
  String get adminDescriptionLabel => _get('adminDescriptionLabel');
  String get adminEntryCoins => _get('adminEntryCoins');
  String get adminPrizePool => _get('adminPrizePool');
  String get adminWinners => _get('adminWinners');
  String get adminWinnerShares => _get('adminWinnerShares');
  String get adminStatus => _get('adminStatus');
  String get adminUpcoming => _get('adminUpcoming');
  String get adminActive => _get('adminActive');
  String get adminFinished => _get('adminFinished');
  String get adminChallenges => _get('adminChallenges');
  String get adminAddChallenge => _get('adminAddChallenge');
  String get adminRemoveChallenge => _get('adminRemoveChallenge');
  String get adminChallengeName => _get('adminChallengeName');
  String get adminMin => _get('adminMin');
  String get adminMax => _get('adminMax');
  String get adminTimeS => _get('adminTimeS');
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
  String get adminRetry => _get('adminRetry');
  String get adminPanel => _get('adminPanel');
  String get signInSignUp => _get('signInSignUp');
  String get nicknameOfflineHint => _get('nicknameOfflineHint');
  String get connectingTelegram => _get('connectingTelegram');
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
