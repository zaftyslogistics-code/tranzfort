// ignore: depend_on_referenced_packages
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

import '../models/mutation_queue.dart';

class MutationQueueDatabase {
  static const String _databaseName = 'mutation_queue.db';
  static const String _tableName = 'mutations';
  static const int _databaseVersion = 1;

  static final MutationQueueDatabase _instance = MutationQueueDatabase._internal();
  factory MutationQueueDatabase() => _instance;
  MutationQueueDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        target TEXT NOT NULL,
        payload TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        max_retries INTEGER NOT NULL DEFAULT 5,
        status TEXT NOT NULL,
        last_error TEXT,
        user_id TEXT NOT NULL
      )
    ''');

    // Create indexes for efficient queries
    await db.execute('''
      CREATE INDEX idx_user_id ON $_tableName(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_status ON $_tableName(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON $_tableName(timestamp)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here if needed
    // For now, we'll just recreate the table on version changes
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS $_tableName');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // CRUD Operations

  Future<void> enqueue(QueuedMutation mutation) async {
    final db = await database;
    await db.insert(
      _tableName,
      mutation.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<QueuedMutation?> dequeue() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return QueuedMutation.fromJson(maps.first);
  }

  Future<void> updateStatus(String id, MutationStatus status) async {
    final db = await database;
    await db.update(
      _tableName,
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementRetryCount(String id) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE $_tableName
      SET retry_count = retry_count + 1
      WHERE id = ?
    ''', [id]);
  }

  Future<void> setLastError(String id, String? error) async {
    final db = await database;
    await db.update(
      _tableName,
      {'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<QueuedMutation>> getPending() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'status = ? OR status = ?',
      whereArgs: ['pending', 'retrying'],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => QueuedMutation.fromJson(map)).toList();
  }

  Future<List<QueuedMutation>> getByUserId(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => QueuedMutation.fromJson(map)).toList();
  }

  Future<QueuedMutation?> getById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return QueuedMutation.fromJson(maps.first);
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCompleted() async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'status = ?',
      whereArgs: ['completed'],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM $_tableName
      WHERE status = ? OR status = ?
    ''', ['pending', 'retrying']);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFailedCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM $_tableName
      WHERE status = ?
    ''', ['failed']);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getRetryingCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM $_tableName
      WHERE status = ?
    ''', ['retrying']);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getExhaustedCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM $_tableName
      WHERE status = ? AND retry_count >= max_retries
    ''', ['failed']);

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
