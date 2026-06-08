import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/food_item.dart';
import '../models/user_profile.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();

  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('spisetavle.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    final dbFile = File(path);

    if (!await dbFile.exists()) {
      await _copyDatabaseFromAssets(path);
    }

    return await openDatabase(path, version: 1);
  }

  Future<void> _copyDatabaseFromAssets(String targetPath) async {
    final parentDir = Directory(dirname(targetPath));

    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final data = await rootBundle.load('assets/frida_data.db');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    await File(targetPath).writeAsBytes(bytes, flush: true);
  }

  Future<void> resetDatabaseFromAssets() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'spisetavle.db');

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    await _copyDatabaseFromAssets(path);
  }

  // ---------------------------------------------------------------------------
  // Brugere
  // ---------------------------------------------------------------------------

  Future<UserProfile?> getUserProfile(String brugerNr) async {
    final db = await instance.database;

    final result = await db.query(
      'brugere',
      where: 'bruger_nr = ?',
      whereArgs: [brugerNr],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return UserProfile.fromMap(result.first);
  }

  Future<List<UserProfile>> getAllUserProfiles() async {
    final db = await instance.database;

    final result = await db.query('brugere', orderBy: 'bruger_nr ASC');

    return result.map((row) => UserProfile.fromMap(row)).toList();
  }

  Future<void> saveUserProfile(UserProfile user) async {
    final db = await instance.database;

    await db.delete(
      'brugere',
      where: 'bruger_nr = ?',
      whereArgs: [user.brugerNr],
    );

    await db.insert('brugere', user.toMap());
  }

  // ---------------------------------------------------------------------------
  // Frida / frida_local
  // ---------------------------------------------------------------------------

  Future<List<String>> searchFoods(String text, {int limit = 50}) async {
    final db = await instance.database;
    final query = text.trim();

    if (query.isEmpty) return [];

    final forceFrida = query.startsWith('#');
    final searchText = forceFrida ? query.substring(1).trim() : query;

    if (searchText.isEmpty) return [];

    final likeArg = '%$searchText%';

    final List<Map<String, Object?>> result;

    if (forceFrida) {
      result = await db.rawQuery(
        '''
SELECT name
FROM frida
WHERE name LIKE ?
ORDER BY name COLLATE NOCASE
LIMIT ?
''',
        [likeArg, limit],
      );
    } else {
      result = await db.rawQuery(
        '''
SELECT name FROM (
  SELECT name, 0 AS sort_order
  FROM frida_local
  WHERE name LIKE ?

  UNION

  SELECT name, 1 AS sort_order
  FROM frida
  WHERE name LIKE ?
)
ORDER BY sort_order, name COLLATE NOCASE
LIMIT ?
''',
        [likeArg, likeArg, limit],
      );
    }

    return result.map((row) => row['name'].toString()).toList();
  }

  Future<FoodItem?> getFoodValues(String name) async {
    final db = await instance.database;
    final cleanName = name.trim();

    if (cleanName.isEmpty) return null;

    final forceFrida = cleanName.startsWith('#');
    final lookupName = forceFrida ? cleanName.substring(1).trim() : cleanName;

    if (lookupName.isEmpty) return null;

    final List<Map<String, Object?>> result;

    if (forceFrida) {
      result = await db.rawQuery(
        '''
SELECT _id, name, kcal, khyd, fedt, prot, alk
FROM frida
WHERE name = ?
LIMIT 1
''',
        [lookupName],
      );
    } else {
      result = await db.rawQuery(
        '''
SELECT _id, name, kcal, khyd, fedt, prot, alk
FROM frida_local
WHERE name = ?

UNION ALL

SELECT _id, name, kcal, khyd, fedt, prot, alk
FROM frida
WHERE name = ?
LIMIT 1
''',
        [lookupName, lookupName],
      );
    }

    if (result.isEmpty) return null;
    return FoodItem.fromMap(result.first);
  }

  Future<FoodItem?> getLocalFoodExact(String name) async {
    final db = await instance.database;
    final cleanName = name.trim();

    if (cleanName.isEmpty) return null;

    final result = await db.rawQuery(
      '''
SELECT _id, name, kcal, khyd, fedt, prot, alk
FROM frida_local
WHERE name = ?
LIMIT 1
''',
      [cleanName],
    );

    if (result.isEmpty) return null;
    return FoodItem.fromMap(result.first);
  }

  Future<List<FoodItem>> searchFridaFoodItems(
    String text, {
    int limit = 50,
  }) async {
    final db = await instance.database;
    final query = text.trim();

    if (query.isEmpty) return [];

    final searchText = query.startsWith('#')
        ? query.substring(1).trim()
        : query;

    if (searchText.isEmpty) return [];

    final result = await db.rawQuery(
      '''
SELECT _id, name, kcal, khyd, fedt, prot, alk
FROM frida
WHERE name LIKE ?
ORDER BY name COLLATE NOCASE
LIMIT ?
''',
      ['%$searchText%', limit],
    );

    return result.map((row) => FoodItem.fromMap(row)).toList();
  }

  Future<void> saveFoodToLocalAlias({
    required String alias,
    required FoodItem food,
  }) async {
    final db = await instance.database;
    final cleanAlias = alias.trim();

    if (cleanAlias.isEmpty) return;

    await db.insert('frida_local', {
      'name': cleanAlias,
      'kcal': _formatNumber(food.kcal),
      'khyd': _formatNumber(food.khyd),
      'fedt': _formatNumber(food.fedt),
      'prot': _formatNumber(food.prot),
      'alk': _formatNumber(food.alk),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertFoodItemLogEntry({
    required String date,
    required FoodItem food,
    required String displayName,
    required double amount,
    required String user,
    required String tid,
  }) async {
    final db = await instance.database;
    final factor = amount / 100.0;

    return await db.insert('spise_log', {
      'date': normalizeDate(date),
      'name': displayName.trim(),
      'amount': amount,
      'kcal': _formatNumber(food.kcal * factor),
      'khyd': _formatNumber(food.khyd * factor),
      'fedt': _formatNumber(food.fedt * factor),
      'prot': _formatNumber(food.prot * factor),
      'alk': _formatNumber(food.alk * factor),
      'user': user,
      'tid': tid,
    });
  }

  Future<List<FoodItem>> getAllLocalFoods() async {
    final db = await instance.database;

    final result = await db.rawQuery('''
SELECT _id, name, kcal, khyd, fedt, prot, alk
FROM frida_local
ORDER BY name COLLATE NOCASE
''');

    return result.map((row) => FoodItem.fromMap(row)).toList();
  }

  Future<void> updateLocalFood(FoodItem food) async {
    final db = await instance.database;

    await db.update(
      'frida_local',
      {
        'kcal': _formatNumber(food.kcal),
        'khyd': _formatNumber(food.khyd),
        'fedt': _formatNumber(food.fedt),
        'prot': _formatNumber(food.prot),
        'alk': _formatNumber(food.alk),
      },
      where: 'name = ?',
      whereArgs: [food.navn],
    );
  }

  Future<void> deleteLocalFood(String name) async {
    final db = await instance.database;

    await db.delete('frida_local', where: 'name = ?', whereArgs: [name]);
  }

  // ---------------------------------------------------------------------------
  // Spise_log
  // ---------------------------------------------------------------------------

  Future<int> insertCalculatedLogEntry({
    required String date,
    required String foodName,
    required double amount,
    required String user,
    required String tid,
  }) async {
    final food = await getFoodValues(foodName);

    if (food == null) {
      throw Exception('Fødevare ikke fundet: $foodName');
    }

    return insertFoodItemLogEntry(
      date: date,
      food: food,
      displayName: food.navn,
      amount: amount,
      user: user,
      tid: tid,
    );
  }

  Future<Map<String, double>> getDailyTotals(String user, String date) async {
    final db = await instance.database;
    final rows = await db.query(
      'spise_log',
      columns: ['kcal', 'khyd', 'fedt', 'prot', 'alk'],
      where: 'user = ? AND date = ?',
      whereArgs: [user, normalizeDate(date)],
    );

    double kcal = 0;
    double khyd = 0;
    double fedt = 0;
    double prot = 0;
    double alk = 0;

    for (final row in rows) {
      kcal += _toDouble(row['kcal']);
      khyd += _toDouble(row['khyd']);
      fedt += _toDouble(row['fedt']);
      prot += _toDouble(row['prot']);
      alk += _toDouble(row['alk']);
    }

    return {'kcal': kcal, 'khyd': khyd, 'fedt': fedt, 'prot': prot, 'alk': alk};
  }

  Future<List<Map<String, Object?>>> getLogForMealTime({
    required String user,
    required String date,
    required String tid,
    String? userName,
  }) async {
    final db = await instance.database;

    final args = userName == null || userName.trim().isEmpty
        ? [user, normalizeDate(date), tid]
        : [user, userName.trim(), normalizeDate(date), tid];

    final whereClause = userName == null || userName.trim().isEmpty
        ? 'user = ? AND date = ? AND tid = ?'
        : '(user = ? OR user = ?) AND date = ? AND tid = ?';

    return await db.query(
      'spise_log',
      where: whereClause,
      whereArgs: args,
      orderBy: '_id ASC',
    );
  }

  Future<int> deleteLogEntry(int id) async {
    final db = await instance.database;

    return await db.delete('spise_log', where: '_id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // Kopifunktioner
  // ---------------------------------------------------------------------------

  Future<int> copyFromYesterday({
    required String user,
    required String targetDate,
    String? tid,
  }) async {
    final db = await instance.database;

    final target = parseDate(targetDate);
    final sourceDate = formatDate(target.subtract(const Duration(days: 1)));
    final normalizedTarget = normalizeDate(targetDate);

    final whereTid = tid == null ? '' : 'AND tid = ?';
    final args = tid == null
        ? [normalizedTarget, user, user, sourceDate]
        : [normalizedTarget, user, user, sourceDate, tid];

    return await db.rawInsert('''
INSERT INTO spise_log (
  date, name, amount, kcal, khyd, fedt, prot, alk, user, tid
)
SELECT
  ?, name, amount, kcal, khyd, fedt, prot, alk, ?, tid
FROM spise_log
WHERE user = ?
AND date = ?
$whereTid
''', args);
  }

  Future<int> copyFromOtherUser({
    required String fromUser,
    required String toUser,
    required String date,
    String? tid,
  }) async {
    final db = await instance.database;
    final normalizedDate = normalizeDate(date);

    final whereTid = tid == null ? '' : 'AND tid = ?';
    final args = tid == null
        ? [normalizedDate, toUser, fromUser, normalizedDate]
        : [normalizedDate, toUser, fromUser, normalizedDate, tid];

    return await db.rawInsert('''
INSERT INTO spise_log (
  date, name, amount, kcal, khyd, fedt, prot, alk, user, tid
)
SELECT
  ?, name, amount, kcal, khyd, fedt, prot, alk, ?, tid
FROM spise_log
WHERE user = ?
AND date = ?
$whereTid
''', args);
  }

  // ---------------------------------------------------------------------------
  // Historik
  // ---------------------------------------------------------------------------

  Future<List<Map<String, Object?>>> getHistoryTotals(
    String user, {
    String? userName,
  }) async {
    final db = await instance.database;

    final whereArgs = userName == null || userName.trim().isEmpty
        ? [user]
        : [user, userName.trim()];

    final whereClause = userName == null || userName.trim().isEmpty
        ? 'user = ?'
        : '(user = ? OR user = ?)';

    return await db.rawQuery('''
SELECT
  date,
  SUM(CAST(REPLACE(khyd, ',', '.') AS REAL)) AS khyd,
  SUM(CAST(REPLACE(fedt, ',', '.') AS REAL)) AS fedt,
  SUM(CAST(REPLACE(prot, ',', '.') AS REAL)) AS prot,
  SUM(CAST(REPLACE(kcal, ',', '.') AS REAL)) AS kcal
FROM spise_log
WHERE $whereClause
GROUP BY date
ORDER BY
  substr(date,7,4) DESC,
  substr(date,4,2) DESC,
  substr(date,1,2) DESC
''', whereArgs);
  }

  // ---------------------------------------------------------------------------
  // Måltider
  // ---------------------------------------------------------------------------

  Future<List<String>> searchMeals(String text, {int limit = 50}) async {
    final db = await instance.database;
    final query = text.trim();

    if (query.isEmpty) return [];

    final result = await db.rawQuery(
      '''
SELECT DISTINCT maaltid
FROM maaltid
WHERE maaltid LIKE ?
ORDER BY maaltid COLLATE NOCASE
LIMIT ?
''',
      ['%$query%', limit],
    );

    return result.map((row) => row['maaltid'].toString()).toList();
  }

  Future<int> insertMealIntoLog({
    required String mealName,
    required String date,
    required String user,
    required String tid,
  }) async {
    final db = await instance.database;

    return await db.rawInsert(
      '''
INSERT INTO spise_log (
  date, name, amount, kcal, khyd, fedt, prot, alk, user, tid
)
SELECT
  ?, name, amount, kcal, khyd, fedt, prot, '0', ?, ?
FROM maaltid
WHERE maaltid = ?
''',
      [normalizeDate(date), user, tid, mealName],
    );
  }

  Future<List<String>> getAllMeals() async {
    final db = await instance.database;

    final result = await db.rawQuery('''
SELECT DISTINCT maaltid
FROM maaltid
ORDER BY maaltid COLLATE NOCASE
''');

    return result.map((row) => row['maaltid'].toString()).toList();
  }

  Future<List<Map<String, Object?>>> getMealItems(String mealName) async {
    final db = await instance.database;

    return await db.rawQuery(
      '''
SELECT rowid, name, amount, kcal, khyd, fedt, prot, maaltid
FROM maaltid
WHERE maaltid = ?
ORDER BY rowid ASC
''',
      [mealName],
    );
  }

  Future<void> deleteMeal(String mealName) async {
    final db = await instance.database;

    await db.delete('maaltid', where: 'maaltid = ?', whereArgs: [mealName]);
  }

  Future<void> deleteMealItem(int rowid) async {
    final db = await instance.database;

    await db.delete('maaltid', where: 'rowid = ?', whereArgs: [rowid]);
  }

  Future<void> insertMealItem({
    required String mealName,
    required String displayName,
    required double amount,
    required FoodItem food,
  }) async {
    final db = await instance.database;
    final factor = amount / 100.0;

    await db.insert('maaltid', {
      'maaltid': mealName,
      'name': displayName,
      'amount': _formatNumber(amount),
      'kcal': _formatNumber(food.kcal * factor),
      'khyd': _formatNumber(food.khyd * factor),
      'fedt': _formatNumber(food.fedt * factor),
      'prot': _formatNumber(food.prot * factor),
    });
  }

  Future<void> createMealFromLogEntries({
    required String mealName,
    required String user,
    required String date,
    required String tid,
  }) async {
    final db = await instance.database;

    await db.rawInsert(
      '''
INSERT INTO maaltid (
  name, amount, kcal, khyd, fedt, prot, maaltid
)
SELECT
  name, amount, kcal, khyd, fedt, prot, ?
FROM spise_log
WHERE user = ?
AND date = ?
AND tid = ?
''',
      [mealName, user, normalizeDate(date), tid],
    );
  }

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  Future<bool> hasLogForDate({
    required String user,
    required String date,
  }) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      '''
SELECT COUNT(*) AS count
FROM spise_log
WHERE user = ?
AND date = ?
''',
      [user, normalizeDate(date)],
    );

    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<int> getStreakForDate(String user, String date) async {
    var streak = 0;
    var currentDate = parseDate(date);

    while (true) {
      final hasLog = await hasLogForDate(
        user: user,
        date: formatDate(currentDate),
      );

      if (!hasLog) break;

      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<int> getStreak(String user) async {
    var streak = 0;
    var date = DateTime.now();

    while (true) {
      final dateString = formatDate(date);

      final hasLog = await hasLogForDate(user: user, date: dateString);

      if (!hasLog) break;

      streak++;
      date = date.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<int> countRows(String tableName) async {
    final db = await instance.database;

    final allowedTables = {
      'frida',
      'frida_local',
      'maaltid',
      'brugere',
      'spise_log',
    };

    if (!allowedTables.contains(tableName)) {
      throw ArgumentError('Ukendt tabel: $tableName');
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $tableName',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> databaseStatus() async {
    return {
      'frida': await countRows('frida'),
      'frida_local': await countRows('frida_local'),
      'maaltid': await countRows('maaltid'),
      'brugere': await countRows('brugere'),
      'spise_log': await countRows('spise_log'),
    };
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  // ---------------------------------------------------------------------------
  // Hjælpefunktioner
  // ---------------------------------------------------------------------------

  double _toDouble(Object? value) {
    if (value == null) return 0;
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  String normalizeDate(String date) {
    final trimmed = date.trim();

    if (trimmed.contains(' ')) {
      final parts = trimmed.split(' ');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$day $month $year';
      }
    }

    if (trimmed.contains('.')) {
      final parts = trimmed.split('.');
      if (parts.length >= 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$day $month $year';
      }
    }

    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return '${parts[2].padLeft(2, '0')} ${parts[1].padLeft(2, '0')} ${parts[0]}';
        }

        return '${parts[0].padLeft(2, '0')} ${parts[1].padLeft(2, '0')} ${parts[2]}';
      }
    }

    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');
      if (parts.length == 3) {
        return '${parts[0].padLeft(2, '0')} ${parts[1].padLeft(2, '0')} ${parts[2]}';
      }
    }

    return trimmed;
  }

  DateTime parseDate(String date) {
    final normalized = normalizeDate(date);
    final parts = normalized.split(' ');

    if (parts.length != 3) {
      throw FormatException('Ugyldig dato: $date');
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day $month $year';
  }
}
