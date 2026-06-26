import 'package:flutter/foundation.dart';
import '../models/competition.dart';
import '../models/result.dart';
import '../repositories/supabase_competition_repository.dart';

/// Manages competition state: listing competitions, joining, leaderboard,
/// and submitting competition challenge results.
///
/// Works with [SupabaseCompetitionRepository] for all Supabase operations.
/// Does NOT affect offline warm-up mode (that stays on LocalResultRepository).
class CompetitionProvider extends ChangeNotifier {
  final SupabaseCompetitionRepository _repository;

  List<Competition> _competitions = [];
  final Map<String, List<LeaderboardEntry>> _leaderboardCache = {};
  final Map<String, Participant?> _participationCache = {};
  final Map<String, bool> _joinedCache = {};
  final Map<String, Set<String>> _completedChallengesCache = {};
  bool _isLoadingCompetitions = false;
  bool _isLoadingLeaderboard = false;
  String? _errorMessage;
  Competition? _selectedCompetition;

  /// Prize notifications to show on the home screen.
  /// Cleared after being consumed by the UI.
  final List<WinnerNotification> _winnerNotifications = [];
  List<WinnerNotification> get winnerNotifications => List.unmodifiable(_winnerNotifications);

  CompetitionProvider({SupabaseCompetitionRepository? repository})
      : _repository = repository ?? SupabaseCompetitionRepository();

  // --- Getters ---
  List<Competition> get competitions => _competitions;
  Competition? get selectedCompetition => _selectedCompetition;
  bool get isLoadingCompetitions => _isLoadingCompetitions;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String? get errorMessage => _errorMessage;

  /// Load all competitions from the server.
  ///
  /// Also finalizes any ended-but-not-yet-finished competitions
  /// (distributes prizes, marks status) so coins are paid out even
  /// if nobody opens the detail screen.
  /// If the current user won a prize, a [WinnerNotification] is
  /// stored so the home screen can show it.
  Future<void> loadCompetitions() async {
    _isLoadingCompetitions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _competitions = await _repository.getCompetitions();
      final userId = _repository.currentUserId;

      // Auto-finalize ended competitions that haven't been finished yet.
      bool anyFinalized = false;
      for (final c in _competitions) {
        if (c.hasEnded && c.status != CompetitionStatus.finished) {
          final winners = await _repository.finalizeCompetition(c.id);
          anyFinalized = true;

          // Check if current user is among the winners
          if (winners != null && userId != null) {
            for (final w in winners) {
              if (w['user_id'] == userId) {
                final prize = (w['prize'] as num).toInt();
                final rank = (w['rank'] as num).toInt();
                if (prize > 0) {
                  // Avoid duplicates if re-finalized
                  final alreadyNotified = _winnerNotifications.any(
                    (n) => n.competitionName == c.name,
                  );
                  if (!alreadyNotified) {
                    _winnerNotifications.add(WinnerNotification(
                      competitionName: c.name,
                      prize: prize,
                      rank: rank,
                    ));
                  }
                }
              }
            }
          }
        }
      }

      // Reload so status fields reflect the finalization
      if (anyFinalized) {
        _competitions = await _repository.getCompetitions();
      }
    } catch (e) {
      _errorMessage = 'Failed to load competitions. Check your connection.';
      debugPrint('Load competitions error: $e');
    } finally {
      _isLoadingCompetitions = false;
      notifyListeners();
    }
  }

  /// Select a competition for detail view and load its leaderboard.
  /// For finished competitions, also finalizes (distributes prizes, marks finished).
  Future<void> selectCompetition(Competition competition) async {
    _selectedCompetition = competition;
    notifyListeners();

    if (competition.hasEnded && competition.status != CompetitionStatus.finished) {
      await _repository.finalizeCompetition(competition.id);
      // Reload competitions so the list card reflects the new status
      await loadCompetitions();
    }

    if (competition.effectiveStatus == CompetitionStatus.finished) {
      await _loadFinalLeaderboard(competition.id);
    } else {
      await _loadLeaderboard(competition.id);
    }
  }

  /// Check whether the current user has joined a competition.
  Future<bool> hasJoinedCompetition(String competitionId) async {
    if (_joinedCache.containsKey(competitionId)) {
      return _joinedCache[competitionId]!;
    }
    final joined = await _repository.hasJoined(competitionId);
    _joinedCache[competitionId] = joined;
    return joined;
  }

  /// Join a competition and refresh the joined state.
  Future<void> joinCompetition(String competitionId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.joinCompetition(competitionId);
      _joinedCache[competitionId] = true;
      // Clear any stale completed-challenges cache after joining
      _completedChallengesCache.remove(competitionId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to join competition. Not enough coins?';
      debugPrint('Join competition error: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Get the leaderboard for a competition.
  /// Uses the prize-aware final leaderboard for finished competitions.
  /// Pass [forceRefresh: true] to skip the cache (e.g., realtime updates).
  Future<List<LeaderboardEntry>> getLeaderboard(String competitionId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _leaderboardCache.containsKey(competitionId)) {
      return _leaderboardCache[competitionId]!;
    }
    final comp = _selectedCompetition;
    if (comp != null && comp.id == competitionId && comp.hasEnded) {
      return _loadFinalLeaderboard(competitionId);
    }
    return _loadLeaderboard(competitionId);
  }

  /// Synchronous access to cached leaderboard entries.
  /// Returns empty list if not yet loaded. Does NOT trigger a network call.
  List<LeaderboardEntry> cachedLeaderboard(String competitionId) =>
      _leaderboardCache[competitionId] ?? [];

  Future<List<LeaderboardEntry>> _loadLeaderboard(
      String competitionId) async {
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final entries = await _repository.getLeaderboard(competitionId);
      _leaderboardCache[competitionId] = entries;
      return entries;
    } catch (e) {
      debugPrint('Load leaderboard error: $e');
      return [];
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<List<LeaderboardEntry>> _loadFinalLeaderboard(
      String competitionId) async {
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final entries = await _repository.getFinalLeaderboard(competitionId);
      _leaderboardCache[competitionId] = entries;
      return entries;
    } catch (e) {
      debugPrint('Load final leaderboard error: $e');
      return [];
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  /// Get my final rank and prize for a finished competition.
  /// Returns (rank, prize) or null if not participated.
  Future<(int, int)?> getMyFinalResult(String competitionId) async {
    final entries = _leaderboardCache[competitionId] ??
        await _loadFinalLeaderboard(competitionId);

    final userId = _repository.currentUserId;
    if (userId == null) return null;

    final me = entries.where((e) => e.userId == userId).firstOrNull;
    return me != null ? (me.rank, me.prize) : null;
  }

  /// Get my participation status for a competition.
  Future<Participant?> getMyParticipation(String competitionId) async {
    if (_participationCache.containsKey(competitionId)) {
      return _participationCache[competitionId];
    }
    final participant = await _repository.getMyParticipation(competitionId);
    _participationCache[competitionId] = participant;
    return participant;
  }

  /// Returns the set of challenge IDs the current user has already completed
  /// for a given competition. Cached so repeated calls don't hit the network.
  Future<Set<String>> getCompletedChallengeIds(String competitionId) async {
    if (_completedChallengesCache.containsKey(competitionId)) {
      return _completedChallengesCache[competitionId]!;
    }
    final ids = await _repository.getCompletedChallengeIds(competitionId);
    _completedChallengesCache[competitionId] = ids;
    return ids;
  }

  /// Submit a completed challenge result for the selected competition.
  /// Returns true on success, false on failure.
  Future<bool> submitChallengeResult(Result result) async {
    if (_selectedCompetition == null) return false;
    _errorMessage = null;

    try {
      await _repository.submitChallengeResult(
        competitionId: _selectedCompetition!.id,
        result: result,
      );

      // Invalidate caches so they refresh on next view
      _leaderboardCache.remove(_selectedCompetition!.id);
      _completedChallengesCache.remove(_selectedCompetition!.id);
      _participationCache.remove(_selectedCompetition!.id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit result. Please try again.';
      debugPrint('Submit result error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Clear any error state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear selected competition and cached leaderboard when leaving competition screen.
  void clearSelection() {
    _selectedCompetition = null;
    notifyListeners();
  }

  /// Remove a notification after it's been shown/dismissed by the UI.
  void dismissWinnerNotification(int index) {
    if (index < _winnerNotifications.length) {
      _winnerNotifications.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all winner notifications (e.g. on sign-out).
  void clearWinnerNotifications() {
    if (_winnerNotifications.isNotEmpty) {
      _winnerNotifications.clear();
      notifyListeners();
    }
  }
}

/// Represents a prize the user won when a competition was finalized.
class WinnerNotification {
  final String competitionName;
  final int prize;
  final int rank;
  const WinnerNotification({
    required this.competitionName,
    required this.prize,
    required this.rank,
  });
}
