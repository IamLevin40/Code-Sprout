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
    // As requested, no fallback — assume schema provides the field
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
}
