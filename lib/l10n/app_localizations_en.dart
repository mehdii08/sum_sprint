// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sum Sprint';

  @override
  String get appTagline => 'Sharpen your mind, beat the clock!';

  @override
  String get nicknameHint => 'Enter your nickname';

  @override
  String get warmUp => 'Warm Up';

  @override
  String get competitions => 'Competitions';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get comingSoonMessage =>
      'Competition mode will be available in a future update!';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get warmUpChallenges => 'Warm Up Challenges';

  @override
  String get noChallenges => 'No challenges available.';

  @override
  String get retry => 'Retry';

  @override
  String get best => 'Best';

  @override
  String bestScore(Object score) {
    return '$score pts';
  }

  @override
  String get bestScoreNone => 'No attempts yet';

  @override
  String get play => 'Play';

  @override
  String get history => 'History';

  @override
  String historyTitle(Object name) {
    return '$name - History';
  }

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to clear all history for this challenge? This cannot be undone.';

  @override
  String get clear => 'Clear';

  @override
  String get noGamesPlayed => 'No games played yet';

  @override
  String get noGamesPlayedHint => 'Complete a challenge to see your history!';

  @override
  String get justNow => 'Just now';

  @override
  String minAgo(Object n) {
    return '${n}m ago';
  }

  @override
  String hourAgo(Object n) {
    return '${n}h ago';
  }

  @override
  String dayAgo(Object n) {
    return '${n}d ago';
  }

  @override
  String dateFormat(Object day, Object month, Object year) {
    return '$day/$month/$year';
  }

  @override
  String correctOutOf(Object correct) {
    return '$correct/10 correct';
  }

  @override
  String get avg => 'avg';

  @override
  String get getReady => 'Get ready...';

  @override
  String get timeUp => 'Time\'s Up!';

  @override
  String get correct => 'Correct!';

  @override
  String get wrong => 'Wrong!';

  @override
  String answerWas(Object answer) {
    return 'Answer: $answer';
  }

  @override
  String get quitGame => 'Quit Game?';

  @override
  String get quitGameConfirm =>
      'Are you sure you want to quit? Your progress will be lost.';

  @override
  String get keepPlaying => 'Keep Playing';

  @override
  String get quit => 'Quit';

  @override
  String get challengeComplete => 'Challenge Complete!';

  @override
  String get finalScore => 'Final Score';

  @override
  String get points => 'points';

  @override
  String get correctStat => 'Correct';

  @override
  String get avgTimeStat => 'Avg Time (s)';

  @override
  String get totalTimeStat => 'Total Time';

  @override
  String get newHighScore => 'New High Score!';

  @override
  String get playAgain => 'Play Again';

  @override
  String get home => 'Home';
}
