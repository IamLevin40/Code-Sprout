import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class RankEntry {
  final String id;
  final String title;
  final int experiencePointsRequirement;

  RankEntry({required this.id, required this.title, required this.experiencePointsRequirement});
}

class RankDataSchema {
  final Map<String, RankEntry> ranks;
  RankDataSchema._(this.ranks);

  static RankDataSchema? _cached;

  static Future<RankDataSchema> load() async {
    if (_cached != null) return _cached!;

    final content = await rootBundle.loadString('schemas/rank_schema.txt');
    final jsonStart = content.indexOf('{');
    final jsonContent = content.substring(jsonStart);
    final Map<String, dynamic> map = json.decode(jsonContent) as Map<String, dynamic>;

    final ranks = <String, RankEntry>{};
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final title = value['title'] as String? ?? '';
        final req = value['experience_points_requirement'];
        final reqNum = (req is num) ? req.toInt() : int.tryParse(req?.toString() ?? '') ?? 0;
        ranks[key] = RankEntry(id: key, title: title, experiencePointsRequirement: reqNum);
      }
    });

    _cached = RankDataSchema._(ranks);
    return _cached!;
  }

  /// Returns ranks in order of their keys (assumes rank_1, rank_2...)
  List<RankEntry> getOrderedRanks() {
    final entries = ranks.entries.toList();
    entries.sort((a, b) {
      final aNum = _extractRankNumber(a.key);
      final bNum = _extractRankNumber(b.key);
      return aNum.compareTo(bNum);
    });
    return entries.map((e) => e.value).toList();
  }

  int _extractRankNumber(String key) {
    final m = RegExp(r'rank_(\d+)').firstMatch(key);
    if (m == null) return 0;
    return int.tryParse(m.group(1) ?? '') ?? 0;
  }
}
