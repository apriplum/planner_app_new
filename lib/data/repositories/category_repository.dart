import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/category.dart';
import '../database.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final Future<Database> _db;
  final _uuid = const Uuid();

  Future<List<Category>> getAll(String userId) async {
    final db = await _db;

    final rows = await db.query(
      'categories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(String id) async {
    final db = await _db;

    final rows = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isEmpty ? null : Category.fromMap(rows.first);
  }

  Future<Category?> getByName(String userId, String name) async {
    final db = await _db;

    final rows = await db.query(
      'categories',
      where: 'user_id = ? AND LOWER(name) = ?',
      whereArgs: [userId, name.trim().toLowerCase()],
      limit: 1,
    );

    return rows.isEmpty ? null : Category.fromMap(rows.first);
  }

  Future<Category> create({
    required String userId,
    required String name,
    String? color,
  }) async {
    final db = await _db;

    final category = Category(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
    );

    await db.insert('categories', category.toMap());
    return category;
  }

  Future<Category> getOrCreate({
    required String userId,
    required String name,
    String? color,
  }) async {
    final existing = await getByName(userId, name);

    if (existing != null) {
      return existing;
    }

    return create(userId: userId, name: name, color: color);
  }

  Future<void> update(Category category) async {
    final db = await _db;

    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;

    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countTasks(String categoryId) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM tasks
      WHERE category_id = ? AND deleted_at IS NULL
      ''',
      [categoryId],
    );

    return result.first['count'] as int? ?? 0;
  }

  String newId() => _uuid.v4();
}