import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // Storage key for history on Web/Fallback
  static const String _historyKey = 'parking_history_list';

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parking_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parkingName TEXT NOT NULL,
        date TEXT NOT NULL,
        durationMinutes REAL NOT NULL,
        cost REAL NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS parking_history');
      await _createDB(db, newVersion);
    }
  }

  Future<int> insertHistory(Map<String, dynamic> row) async {
    // Always try to save to SharedPreferences as well (for cross-platform reliability)
    await _saveToPrefs(row);

    if (kIsWeb) return 1;
    
    final db = await instance.database;
    if (db == null) return 0;
    
    try {
      return await db.insert('parking_history', row);
    } catch (e) {
      debugPrint('Error inserting to SQLite: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllHistory() async {
    if (kIsWeb) {
      return await _loadFromPrefs();
    }
    
    final db = await instance.database;
    if (db == null) {
      return await _loadFromPrefs();
    }
    
    try {
      return await db.query('parking_history', orderBy: 'date DESC');
    } catch (e) {
      debugPrint('Error querying SQLite: $e');
      return await _loadFromPrefs();
    }
  }

  // Helper to save history to SharedPreferences (Works on Web/Windows/Android)
  Future<void> _saveToPrefs(Map<String, dynamic> row) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString(_historyKey);
      List<dynamic> list = existingData != null ? jsonDecode(existingData) : [];
      list.insert(0, row); // Add new at the top
      await prefs.setString(_historyKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Prefs save error: $e');
    }
  }

  // Helper to load history from SharedPreferences
  Future<List<Map<String, dynamic>>> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString(_historyKey);
      if (existingData == null) return [];
      final List<dynamic> list = jsonDecode(existingData);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Prefs load error: $e');
      return [];
    }
  }
}
