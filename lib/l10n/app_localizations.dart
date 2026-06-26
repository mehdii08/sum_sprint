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
    'avgTimeStat': 'Avg Time (s)',
    'totalTimeStat': 'Total Time',
    'newHighScore': 'New High Score!',
    'playAgain': 'Play Again',
    'home': 'Home',
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
