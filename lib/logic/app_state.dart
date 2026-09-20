import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database_helper.dart';
import '../core/prefs_helper.dart';
import '../data/models/parking_spot.dart';
import '../data/demo_data.dart';

class ActiveParkingSession {
  final ParkingSpot spot;
  final String slotLabel;
  final DateTime startTime;
  final double pricePerHour;

  ActiveParkingSession({
    required this.spot,
    required this.slotLabel,
    required this.startTime,
    required this.pricePerHour,
  });

  Map<String, dynamic> toJson() => {
        'spotId': spot.id,
        'slotLabel': slotLabel,
        'startTime': startTime.toIso8601String(),
        'pricePerHour': pricePerHour,
      };

  static ActiveParkingSession fromJson(Map<String, dynamic> json, List<ParkingSpot> allSpots) {
    try {
      final spot = allSpots.firstWhere((s) => s.id == json['spotId']);
      return ActiveParkingSession(
        spot: spot,
        slotLabel: json['slotLabel'],
        startTime: DateTime.parse(json['startTime']),
        pricePerHour: spot.pricePerHour, 
      );
    } catch (e) {
      rethrow;
    }
  }
}

class AppState extends ChangeNotifier {
  bool _isDarkMode = PrefsHelper.isDarkMode;
  bool _isArabic = PrefsHelper.isArabic;
  ActiveParkingSession? _activeSession;
  List<Map<String, dynamic>> _history = [];
  List<ParkingSpot> _parkingSpots = [];
  List<ParkingSpot>? _filteredSpots; 
  String _currentSearchQuery = '';
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _feedback = [];
  Position? _userPosition;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    await fetchSpots();
    await _loadPersistedData();
    await fetchNotifications();
  }

  Future<void> _loadPersistedData() async {
    final sessionData = PrefsHelper.activeSession;
    if (sessionData != null && _parkingSpots.isNotEmpty) {
      try {
        _activeSession = ActiveParkingSession.fromJson(sessionData, _parkingSpots);
      } catch (e) {
        PrefsHelper.clearActiveSession();
      }
    }
    await fetchHistory();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isArabic => _isArabic;
  ActiveParkingSession? get activeSession => _activeSession;
  List<Map<String, dynamic>> get history => _history;
  
  List<ParkingSpot> get parkingSpots => _filteredSpots ?? _parkingSpots;
  String get currentSearchQuery => _currentSearchQuery;
  
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotificationsCount => _notifications.where((n) => n['read'] == false).length;
  List<Map<String, dynamic>> get feedback => _feedback;
  Position? get userPosition => _userPosition;

  String get userName => PrefsHelper.userName;
  String get userPhone => PrefsHelper.userPhone;
  String? get profileImage => PrefsHelper.userImage;
  bool get isLoggedIn => PrefsHelper.isLoggedIn;
  bool get hasUsedCoupon => PrefsHelper.hasUsedCoupon;
  bool get isAdmin => PrefsHelper.isAdmin;

  void toggleDarkMode(bool value) async {
    _isDarkMode = value;
    await PrefsHelper.setDarkMode(value);
    notifyListeners();
  }

  void setUserPosition(Position pos) {
    _userPosition = pos;
    notifyListeners();
  }

  void toggleLanguage(bool arabic) async {
    _isArabic = arabic;
    await PrefsHelper.setLanguage(arabic);
    notifyListeners();
  }

  void login(String name, String phone) async {
    bool admin = (name.toLowerCase() == 'admin' && phone == '0000');
    await PrefsHelper.setLogin(name, phone, isAdmin: admin);
    _filteredSpots = null; 
    _currentSearchQuery = '';
    await fetchSpots();
    await fetchHistory(); 
    if (admin) await fetchAllFeedback();
    notifyListeners();
  }

  void logout() async {
    await PrefsHelper.logout();
    _activeSession = null;
    _history = []; 
    _notifications = [];
    _filteredSpots = null;
    _currentSearchQuery = '';
    notifyListeners();
  }

  void updateProfile({String? name, String? phone, String? image}) async {
    await PrefsHelper.updateProfile(name: name, phone: phone, image: image);
    notifyListeners();
  }

  void searchSpots(String query) {
    _currentSearchQuery = query;
    _applySearch();
  }

  void _applySearch() {
    if (_currentSearchQuery.trim().isEmpty) {
      _filteredSpots = null;
    } else {
      final q = _currentSearchQuery.toLowerCase();
      _filteredSpots = _parkingSpots
          .where((s) => s.name.toLowerCase().contains(q) || 
                       s.address.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }

  Future<void> markNotificationsRead() async {
    final prefs = await SharedPreferences.getInstance();
    for (var n in _notifications) {
      n['read'] = true;
    }
    await prefs.setString('user_notifications', jsonEncode(_notifications));
    notifyListeners();
  }

  Future<void> addNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString('user_notifications');
    List<dynamic> list = existingData != null ? jsonDecode(existingData) : [];
    
    final newNotif = {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
      'read': false,
    };
    
    list.insert(0, newNotif);
    await prefs.setString('user_notifications', jsonEncode(list));
    await fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_notifications');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      _notifications = list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    notifyListeners();
  }

  Future<void> sendFeedback(String message) async {
    await DatabaseHelper.instance.insertFeedback({
      'userName': userName,
      'userPhone': userPhone,
      'message': message,
      'date': DateTime.now().toIso8601String(),
    });
    if (isAdmin) await fetchAllFeedback();
  }

  Future<void> fetchAllFeedback() async {
    _feedback = await DatabaseHelper.instance.queryAllFeedback();
    notifyListeners();
  }

  Future<void> fetchSpots() async {
    final data = await DatabaseHelper.instance.queryAllSpots();
    if (data.isEmpty) {
      for (var spot in DemoData.parkingSpots) {
        await DatabaseHelper.instance.insertSpot(spot.toMap());
      }
      _parkingSpots = List.from(DemoData.parkingSpots);
    } else {
      _parkingSpots = data.map((e) => ParkingSpot.fromMap(e)).toList();
    }
    _applySearch(); 
    notifyListeners();
  }

  Future<void> addOrUpdateSpot(ParkingSpot spot) async {
    await DatabaseHelper.instance.insertSpot(spot.toMap());
    await fetchSpots(); 
  }

  Future<void> resetSpotsToDefault() async {
    await DatabaseHelper.instance.clearAllSpots();
    for (var spot in DemoData.parkingSpots) {
      await DatabaseHelper.instance.insertSpot(spot.toMap());
    }
    await fetchSpots();
  }

  void startParking(ActiveParkingSession session) async {
    _activeSession = session;
    await PrefsHelper.saveActiveSession(session.toJson());
    await addNotification('تم الحجز بنجاح', 'لقد قمت بحجز مكان في ${session.spot.name} - ${session.slotLabel}');
    notifyListeners();
  }

  Future<void> endParking({double discountFactor = 1.0, bool usedCoupon = false}) async {
    if (_activeSession != null) {
      try {
        final now = DateTime.now();
        final elapsed = now.difference(_activeSession!.startTime);
        
        final double durationInHours = elapsed.inSeconds / 3600.0;
        final double finalHours = durationInHours < 1.0 ? 1.0 : durationInHours;
        
        double cost = finalHours * _activeSession!.pricePerHour;
        cost = cost * discountFactor; 
        
        final finalCost = cost < 0.1 ? 0.5 : cost; 

        final historyItem = {
          'userPhone': userPhone, 
          'parkingName': _activeSession!.spot.name,
          'date': now.toIso8601String(),
          'durationMinutes': (finalHours * 60).toDouble(),
          'cost': finalCost,
        };

        await DatabaseHelper.instance.insertHistory(historyItem);

        if (usedCoupon) {
          await PrefsHelper.setUsedCoupon(true);
        }

        final spotName = _activeSession!.spot.name;
        _activeSession = null;
        await PrefsHelper.clearActiveSession();
        await fetchHistory();
        await addNotification('تم إنهاء الموقف', 'تم دفع الرسوم وإنهاء جلستك في $spotName بنجاح.');
      } catch (e) {
        debugPrint('Error ending parking: $e');
      }
    }
  }

  Future<void> fetchHistory() async {
    if (userPhone.isEmpty) return;
    try {
      _history = await DatabaseHelper.instance.queryUserHistory(userPhone);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }
}
