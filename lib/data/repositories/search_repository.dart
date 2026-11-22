import 'package:sqflite/sqflite.dart';

import '../../models/enums.dart';
import '../database.dart';

enum SearchFilter { tasks, events, habits, completed, overdue }

class SearchResult {
  SearchResult({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.matchedFragment,
    required this.score,
  });

  final EntityType entityType;
  final String entityId;
  final String title;
  final String matchedFragment;
  final double score;
}

class SearchRepository {
  SearchRepository(this._db);

  final Future<Database> _db;

  Future<List<SearchResult>> search(
    String query,
    String userId,
    Set<SearchFilter> filters,
  ) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final db = await _db;
    final pattern = '%$q%';
    final results = <SearchResult>[];

    if (filters.contains(SearchFilter.tasks) || filters.isEmpty) {
      final rows = await db.rawQuery('''
        SELECT id, title, description FROM tasks
        WHERE user_id = ? AND deleted_at IS NULL
          AND (title LIKE ? OR description LIKE ?)
      ''', [userId, pattern, pattern]);

      for (final row in rows) {
        results.add(
          SearchResult(
            entityType: EntityType.task,
            entityId: row['id'] as String,
            title: row['title'] as String,
            matchedFragment: _fragment(row['description'] as String?, q),
            score: _score(row['title'] as String, row['description'] as String?, q),
          ),
        );
      }
    }

    if (filters.contains(SearchFilter.events) || filters.isEmpty) {
      final rows = await db.rawQuery('''
        SELECT id, title, description FROM events
        WHERE user_id = ? AND deleted_at IS NULL
          AND (title LIKE ? OR description LIKE ?)
      ''', [userId, pattern, pattern]);

      for (final row in rows) {
        results.add(
          SearchResult(
            entityType: EntityType.event,
            entityId: row['id'] as String,
            title: row['title'] as String,
            matchedFragment: _fragment(row['description'] as String?, q),
            score: _score(row['title'] as String, row['description'] as String?, q),
          ),
        );
      }
    }

    if (filters.contains(SearchFilter.habits) || filters.isEmpty) {
      final rows = await db.rawQuery('''
        SELECT id, title, description FROM habits
        WHERE user_id = ? AND deleted_at IS NULL
          AND (title LIKE ? OR description LIKE ?)
      ''', [userId, pattern, pattern]);

      for (final row in rows) {
        results.add(
          SearchResult(
            entityType: EntityType.habit,
            entityId: row['id'] as String,
            title: row['title'] as String,
            matchedFragment: _fragment(row['description'] as String?, q),
            score: _score(row['title'] as String, row['description'] as String?, q),
          ),
        );
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  double _score(String title, String? description, String query) {
    final q = query.toLowerCase();
    var score = 0.0;

    if (title.toLowerCase().contains(q)) score += 2;
    if ((description ?? '').toLowerCase().contains(q)) score += 1;

    return score;
  }

  String _fragment(String? text, String query) {
    if (text == null || text.isEmpty) return '';
    final index = text.toLowerCase().indexOf(query.toLowerCase());
    if (index < 0) return text.length > 80 ? '${text.substring(0, 80)}…' : text;

    final start = index > 20 ? index - 20 : 0;
    final end = (index + query.length + 40).clamp(0, text.length);
    return text.substring(start, end);
  }
}