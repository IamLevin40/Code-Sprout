import 'dart:math';
import 'rank_data_schema.dart';

class RankData {
  final List<RankEntry> _ranks;

  RankData(this._ranks);

  static Future<RankData> load() async {
    final schema = await RankDataSchema.load();
    final ordered = schema.getOrderedRanks();
    return RankData(ordered);
  }

  /// Get user's total experience points
  static int getCurrentTotalExperiencePoints(Map<String, dynamic> userData) {
    final rp = userData['rankProgress'];
    if (rp is Map<String, dynamic>) {
      final val = rp['experiencePoints'];
      if (val is num) return val.toInt();
    }
    return 0;
  }

  /// Returns the current rank index (0-based) and RankEntry
  Map<String, dynamic> getCurrentRank(Map<String, dynamic> userData) {
    final total = getCurrentTotalExperiencePoints(userData);
    int accumulated = 0;
    int currentIndex = 0;

    for (int i = 0; i < _ranks.length; i++) {
      final r = _ranks[i];
      accumulated += r.experiencePointsRequirement;
      if (total >= accumulated) {
        currentIndex = i;
        continue;
      } else {
        // total < accumulated -> current rank is i (but if i==0 and req==0, handled)
        break;
      }
    }

    // If total exceeds all accumulations, set to last rank
    if (total >= _ranks.fold<int>(0, (p, e) => p + e.experiencePointsRequirement)) {
      currentIndex = _ranks.length - 1;
    }

    final current = _ranks[min(currentIndex, _ranks.length - 1)];
    return {'index': currentIndex, 'entry': current};
  }

  /// Get the title of the current rank
  String getCurrentRankTitle(Map<String, dynamic> userData) {
    return getCurrentRank(userData)['entry'].title as String;
  }

  /// Returns user's current XP within the current rank (not total)
  int getCurrentXPInRank(Map<String, dynamic> userData) {
    final total = getCurrentTotalExperiencePoints(userData);
    int acc = 0;
    for (int i = 0; i < _ranks.length; i++) {
      final r = _ranks[i];
      final nextAcc = acc + r.experiencePointsRequirement;
      if (total < nextAcc) {
        return total - acc;
      }
      acc = nextAcc;
    }
    // If at max rank return remainder over previous
    final lastReq = _ranks.last.experiencePointsRequirement;
    return total - (acc - lastReq);
  }

  /// Returns the XP requirement to reach the next rank from current rank (i.e., the requirement value of next rank)
  int getNextRankRequirement(Map<String, dynamic> userData) {
    final crt = getCurrentRank(userData);
    final idx = crt['index'] as int;
    if (idx >= _ranks.length - 1) return 0;
    return _ranks[idx + 1].experiencePointsRequirement;
  }

  /// Returns the total XP required to reach the next rank from start (accumulated)
  int getTotalXPForNextRank(Map<String, dynamic> userData) {
    final crt = getCurrentRank(userData);
    final idx = crt['index'] as int;
    int acc = 0;
    for (int i = 0; i <= idx + 1 && i < _ranks.length; i++) {
      acc += _ranks[i].experiencePointsRequirement;
    }
    return acc;
  }

  /// Returns progress as (currentInRank, nextRankRequirement)
  Map<String, int> getProgressForDisplay(Map<String, dynamic> userData) {
    final inRank = getCurrentXPInRank(userData);
    final nextReq = getNextRankRequirement(userData);
    return {'current': inRank, 'nextRequirement': nextReq};
  }

  /// Returns a display-friendly map containing:
  /// - title: String current rank title
  /// - progressValue: double between 0.0 and 1.0 for progress bar
  /// - displayText: String to display (e.g., "10 / 50 XP" or "Max")
  /// - current: int current in-rank XP or max total when at max
  /// - nextRequirement: int next rank requirement (or maxTotal when at max)
  /// - isMax: bool whether user is at max rank
  Map<String, dynamic> getDisplayData(Map<String, dynamic> userData) {
    final title = getCurrentRankTitle(userData);
    final maxTotal = getMaxTotalXP();
    final bool isMax = isAtMaxRank(userData);

    if (isMax) {
      // At max rank: show full bar and "Max" label
      return {
        'title': title,
        'progressValue': 1.0,
        'displayText': 'Max',
        'current': maxTotal,
        'nextRequirement': maxTotal,
        'isMax': true,
      };
    }

    final progress = getProgressForDisplay(userData);
    final int current = progress['current'] ?? 0;
    final int nextReq = progress['nextRequirement'] ?? 0;
    final double progressValue = (nextReq <= 0) ? 1.0 : (current / max(1, nextReq));

    return {
      'title': title,
      'progressValue': progressValue.clamp(0.0, 1.0),
      'displayText': '$current / $nextReq XP',
      'current': current,
      'nextRequirement': nextReq,
      'isMax': false,
    };
  }

  /// Get the maximum total XP across all ranks (accumulative)
  int getMaxTotalXP() {
    return _ranks.fold<int>(0, (prev, e) => prev + e.experiencePointsRequirement);
  }

  /// Check if the user is at (or beyond) the last rank
  bool isAtMaxRank(Map<String, dynamic> userData) {
    final total = getCurrentTotalExperiencePoints(userData);
    return total >= getMaxTotalXP();
  }

  /// Return a new copy of the userData map with updated rankProgress.experiencePoints
  Map<String, dynamic> _withUpdatedTotalXP(Map<String, dynamic> userData, int newTotal) {
    final newData = Map<String, dynamic>.from(userData);
    final rp = (userData['rankProgress'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(userData['rankProgress'] as Map<String, dynamic>)
        : <String, dynamic>{};
    rp['experiencePoints'] = newTotal;
    newData['rankProgress'] = rp;
    return newData;
  }

  /// Apply a delta to the user's total experience points (positive to add, negative to subtract).
  /// Behavior:
  /// - If adding (delta>0) while user is already at max rank, no change is applied (adding is disabled).
  /// - The resulting total is clamped to [0, maxTotal].
  /// Returns the updated userData map.
  Map<String, dynamic> applyExperienceDelta(Map<String, dynamic> userData, int delta) {
    final currentTotal = getCurrentTotalExperiencePoints(userData);
    final maxTotal = getMaxTotalXP();

    if (delta > 0 && currentTotal >= maxTotal) {
      // Adding is disabled at max rank — return original unchanged
      return userData;
    }

    int newTotal = currentTotal + delta;
    if (newTotal > maxTotal) newTotal = maxTotal;
    if (newTotal < 0) newTotal = 0;

    return _withUpdatedTotalXP(userData, newTotal);
  }

  /// Convenience helpers for add/subtract
  Map<String, dynamic> addExperiencePoints(Map<String, dynamic> userData, int amount) {
    if (amount <= 0) return userData;
    return applyExperienceDelta(userData, amount);
  }

  Map<String, dynamic> subtractExperiencePoints(Map<String, dynamic> userData, int amount) {
    if (amount <= 0) return userData;
    return applyExperienceDelta(userData, -amount);
  }
}
