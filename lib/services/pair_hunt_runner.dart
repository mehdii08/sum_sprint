import 'dart:math';
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/player_data.dart';
import 'pair_hunt_scoring.dart';

/// Pool of 65 distinct emojis for Pair Hunt blocks.
const List<String> _emojiPool = [
  // Animals (15)
  '🐶', '🐱', '🐼', '🐨', '🦊', '🐸', '🐵', '🦁', '🐯', '🐮',
  '🐷', '🐰', '🐻', '🐔', '🐧',
  // Food (15)
  '🍎', '🍕', '🍔', '🌮', '🍩', '🍪', '🍓', '🍌', '🥑', '🍇',
  '🍉', '🍋', '🍒', '🥝', '🧁',
  // Objects (15)
  '⚽', '🎸', '🚀', '💡', '🔑', '🎩', '📱', '💎', '⌚', '🎁',
  '🚗', '✈️', '🏠', '🎵', '🔔',
  // Faces (10)
  '😀', '😂', '😍', '😎', '🤩', '😱', '🥳', '😴', '🤔', '😇',
  // Nature (10)
  '🌈', '⭐', '🔥', '🌊', '🌺', '🍀', '🌙', '☀️', '❄️', '🌸',
];

/// Orchestrates a single Pair‑Hunt challenge session.
///
/// Unlike the math ChallengeRunner (discrete questions) or MindTimerRunner
/// (discrete rounds), the Pair‑Hunt runner manages a single continuous
/// game — the player flips blocks to find matching emoji pairs until all
/// are found or the timer runs out.
class PairHuntRunner {
  final Random _random = Random();
  ChallengeDefinition? _challengeDefinition;

  /// All blocks in the grid.
  List<PairHuntBlock> _blocks = [];

  /// Number of pairs successfully found.
  int _pairsFound = 0;

  /// Number of mismatch attempts.
  int _mismatchCount = 0;

  /// Whether the game is active.
  bool _isStarted = false;

  /// Whether the game has finished.
  bool _isFinished = false;

  // ── Getters ──────────────────────────────────────────────────────

  bool get isStarted => _isStarted;
  bool get isFinished => _isFinished;
  List<PairHuntBlock> get blocks => _blocks;
  int get pairsFound => _pairsFound;
  int get totalPairs => _challengeDefinition?.pairCount ?? 0;
  int get mismatchCount => _mismatchCount;
  ChallengeDefinition? get challengeDefinition => _challengeDefinition;
  bool get allPairsFound => _pairsFound >= totalPairs;

  // ── Start game ───────────────────────────────────────────────────

  void startGame(ChallengeDefinition challenge) {
    if (!challenge.isPairHunt) {
      throw ArgumentError(
        'PairHuntRunner requires a pair_hunt challenge, '
        'got type="${challenge.challengeType.value}".',
      );
    }
    _challengeDefinition = challenge;
    _pairsFound = 0;
    _mismatchCount = 0;
    _isStarted = true;
    _isFinished = false;
    _generateGrid();
  }

  /// Generate a randomized grid of emoji pairs.
  void _generateGrid() {
    final blockCount = _challengeDefinition!.blockCount;
    final pairCount = blockCount ~/ 2;

    // Pick N unique emojis from the pool.
    final poolCopy = List<String>.from(_emojiPool);
    poolCopy.shuffle(_random);
    final selectedEmojis = poolCopy.take(pairCount).toList();

    // Create two blocks for each emoji.
    final emojiPairs = <String>[];
    for (final emoji in selectedEmojis) {
      emojiPairs.add(emoji);
      emojiPairs.add(emoji);
    }

    // Shuffle the combined list.
    emojiPairs.shuffle(_random);

    // Create blocks.
    _blocks = List.generate(blockCount, (i) {
      return PairHuntBlock(
        emoji: emojiPairs[i],
        index: i,
        isRevealed: false,
        isMatched: false,
      );
    });
  }

  // ── Block interaction ────────────────────────────────────────────

  /// Attempt to flip a block at [index].
  /// Returns true if the flip was accepted (block was face-down and unmatched).
  bool canFlip(int index) {
    if (index < 0 || index >= _blocks.length) return false;
    final block = _blocks[index];
    return !block.isMatched && !block.isRevealed;
  }

  /// Flip a block face-up.
  void flipBlock(int index) {
    if (!canFlip(index)) return;
    _blocks[index].isRevealed = true;
  }

  /// Check if the two currently face-up (non-matched) blocks form a match.
  /// Returns null if fewer than 2 non-matched blocks are face-up.
  bool? checkMatch() {
    final revealed = _blocks.where((b) => b.isRevealed && !b.isMatched).toList();
    if (revealed.length != 2) return null;
    return revealed[0].emoji == revealed[1].emoji;
  }

  /// Mark the two currently revealed blocks as matched.
  void markMatch() {
    final revealed = _blocks.where((b) => b.isRevealed && !b.isMatched).toList();
    for (final block in revealed) {
      block.isMatched = true;
    }
    _pairsFound++;
    if (allPairsFound) {
      _isFinished = true;
    }
  }

  /// Flip back the two currently revealed (non-matched) blocks.
  void resetMismatch() {
    final revealed = _blocks.where((b) => b.isRevealed && !b.isMatched).toList();
    for (final block in revealed) {
      block.isRevealed = false;
    }
    _mismatchCount++;
  }

  /// Get the indices of the currently revealed (non-matched) blocks.
  List<int> get revealedIndices =>
      _blocks
          .where((b) => b.isRevealed && !b.isMatched)
          .map((b) => b.index)
          .toList();

  // ── End game ─────────────────────────────────────────────────────

  /// End the game due to timer expiry.
  void endByTimeout() {
    _isFinished = true;
  }

  /// Build the final result.
  PairHuntGameResult getFinalGameResult(double timeTakenSeconds) {
    final c = _challengeDefinition;
    if (c == null) throw StateError('No challenge has been started');

    return PairHuntScoring.calculate(
      pairsFound: _pairsFound,
      totalPairs: c.pairCount,
      mismatchCount: _mismatchCount,
      timeTakenSeconds: timeTakenSeconds,
      timeLimitSeconds: c.timeLimitSeconds.toDouble(),
      pointsPerPair: c.pointsPerPair,
      maxTimeBonus: c.maxTimeBonus,
      penaltyPerMismatch: c.penaltyPerMismatch,
    );
  }

  /// Build the final Result for storage/submission.
  Result getFinalResult(PlayerData player, double timeTakenSeconds) {
    final c = _challengeDefinition;
    if (c == null) throw StateError('No challenge has been started');

    final gameResult = getFinalGameResult(timeTakenSeconds);

    return Result(
      challengeId: c.id,
      score: gameResult.score,
      correctCount: gameResult.pairsFound,
      totalResponseTimeMs: (gameResult.timeTakenSeconds * 1000).round(),
      date: DateTime.now(),
      playerName: player.nickname,
      isPairHunt: true,
      pairsFound: gameResult.pairsFound,
      totalPairs: gameResult.totalPairs,
      mismatchCount: gameResult.mismatchCount,
    );
  }
}
