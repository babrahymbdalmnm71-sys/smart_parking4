import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  static const String _historyKey = 'parking_history_list_v2'; // Changed key to reset old global data
  static const String _spotsKey = 'parking_spots_list';
  static const String _feedbackKey = 'user_feedback_list';

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    try {
      if (_database != null) return _database!;
      _database = await _initDB('smart_park.db');
      return _database!;
    } catch (e) {
      debugPrint('Database initialization error: $e');
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Upgraded for user-specific history
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parking_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userPhone TEXT NOT NULL,
        parkingName TEXT NOT NULL,
        date TEXT NOT NULL,
        durationMinutes REAL NOT NULL,
        cost REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE parking_spots (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        rating REAL NOT NULL,
        reviewsCount INTEGER NOT NULL,
        pricePerHour REAL NOT NULL,
        distanceKm REAL NOT NULL,
        availableSpots INTEGER NOT NULL,
        totalSpots INTEGER NOT NULL,
        openHours TEXT NOT NULL,
        amenities TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userName TEXT NOT NULL,
        userPhone TEXT NOT NULL,
        message TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Logic to migrate or reset history for user-specific support
      await db.execute('DROP TABLE IF EXISTS parking_history');
      await db.execute('''
        CREATE TABLE parking_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userPhone TEXT NOT NULL,
          parkingName TEXT NOT NULL,
          date TEXT NOT NULL,
          durationMinutes REAL NOT NULL,
          cost REAL NOT NULL
        )
      ''');
    }
    // Spots and Feedback table creation handled in onCreate or previous versions
    if (oldVersion < 3) {
       await db.execute('''
        CREATE TABLE IF NOT EXISTS parking_spots (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          rating REAL NOT NULL,
          reviewsCount INTEGER NOT NULL,
          pricePerHour REAL NOT NULL,
          distanceKm REAL NOT NULL,
          availableSpots INTEGER NOT NULL,
          totalSpots INTEGER NOT NULL,
          openHours TEXT NOT NULL,
          amenities TEXT NOT NULL,
          imageUrl TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_feedback (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userName TEXT NOT NULL,
          userPhone TEXT NOT NULL,
          message TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
  }

  // --- Parking History (User Specific) ---
  Future<int> insertHistory(Map<String, dynamic> row) async {
    await _saveToPrefs(_historyKey, row);
    if (kIsWeb) return 1;
    final db = await instance.database;
    if (db == null) return 0;
    return await db.insert('parking_history', row);
  }

  Future<List<Map<String, dynamic>>> queryUserHistory(String phone) async {
    if (kIsWeb) {
      final all = await _loadFromPrefs(_historyKey);
      return all.where((e) => e['userPhone'] == phone).toList();
    }
    final db = await instance.database;
    if (db == null) {
      final all = await _loadFromPrefs(_historyKey);
      return all.where((e) => e['userPhone'] == phone).toList();
    }
    return await db.query(
      'parking_history', 
      where: 'userPhone = ?', 
      whereArgs: [phone],
      orderBy: 'date DESC'
    );
  }

  // --- Parking Spots ---
  Future<int> insertSpot(Map<String, dynamic> row) async {
    await _saveOrUpdateInPrefs(_spotsKey, row);
    if (kIsWeb) return 1;
    final db = await instance.database;
    if (db == null) return 0;
    return await db.insert('parking_spots', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSpot(Map<String, dynamic> row) async {
    await _saveOrUpdateInPrefs(_spotsKey, row);
    if (kIsWeb) return 1;
    final db = await instance.database;
    if (db == null) return 0;
    return await db.update('parking_spots', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<List<Map<String, dynamic>>> queryAllSpots() async {
    if (kIsWeb) return await _loadFromPrefs(_spotsKey);
    final db = await instance.database;
    if (db == null) return await _loadFromPrefs(_spotsKey);
    return await db.query('parking_spots');
  }

  // --- User Feedback ---
  Future<int> insertFeedback(Map<String, dynamic> row) async {
    await _saveToPrefs(_feedbackKey, row);
    if (kIsWeb) return 1;
    final db = await instance.database;
    if (db == null) return 0;
    return await db.insert('user_feedback', row);
  }

  Future<List<Map<String, dynamic>>> queryAllFeedback() async {
    if (kIsWeb) return await _loadFromPrefs(_feedbackKey);
    final db = await instance.database;
    if (db == null) return await _loadFromPrefs(_feedbackKey);
    return await db.query('user_feedback', orderBy: 'date DESC');
  }

  Future<int> queryAllSpotsCount() async {
    final db = await instance.database;
    if (db == null) {
      final all = await _loadFromPrefs(_spotsKey);
      return all.length;
    }
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM parking_spots'));
    return count ?? 0;
  }

  Future<void> clearAllSpots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_spotsKey);
      if (!kIsWeb) {
        final db = await instance.database;
        if (db != null) {
          await db.delete('parking_spots');
        }
      }
    } catch (e) {
      debugPrint('Error clearing spots: $e');
    }
  }

  // --- Helpers ---
  Future<void> _saveToPrefs(String key, Map<String, dynamic> row) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString(key);
      List<dynamic> list = existingData != null ? jsonDecode(existingData) : [];
      list.insert(0, row);
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('Prefs save error: $e');
    }
  }

  Future<void> _saveOrUpdateInPrefs(String key, Map<String, dynamic> row) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString(key);
      List<dynamic> list = existingData != null ? jsonDecode(existingData) : [];
      int index = list.indexWhere((e) => e['id'] == row['id']);
      if (index != -1) {
        list[index] = row;
      } else {
        list.add(row);
      }
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('Prefs update error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadFromPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString(key);
      if (existingData == null) return [];
      final List<dynamic> list = jsonDecode(existingData);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Prefs load error: $e');
      return [];
    }
  }
}
