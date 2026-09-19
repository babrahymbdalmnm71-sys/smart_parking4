import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  factory ActiveParkingSession.fromJson(Map<String, dynamic> json) {
    try {
      final spot = DemoData.parkingSpots.firstWhere((s) => s.id == json['spotId']);
      return ActiveParkingSession(
        spot: spot,
        slotLabel: json['slotLabel'],
        startTime: DateTime.parse(json['startTime']),
        pricePerHour: (json['pricePerHour'] as num).toDouble(),
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
  Position? _userPosition;

  AppState() {
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    final sessionData = PrefsHelper.activeSession;
    if (sessionData != null) {
      try {
        _activeSession = ActiveParkingSession.fromJson(sessionData);
      } catch (e) {
        debugPrint('Error loading persisted session: $e');
        PrefsHelper.clearActiveSession();
      }
    }
    await fetchHistory();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isArabic => _isArabic;
  ActiveParkingSession? get activeSession => _activeSession;
  List<Map<String, dynamic>> get history => _history;
  Position? get userPosition => _userPosition;

  String get userName => PrefsHelper.userName;
  String get userPhone => PrefsHelper.userPhone;
  String? get profileImage => PrefsHelper.userImage;
  bool get isLoggedIn => PrefsHelper.isLoggedIn;
  bool get hasUsedCoupon => PrefsHelper.hasUsedCoupon;

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
    await PrefsHelper.setLogin(name, phone);
    await fetchHistory(); // Fetch history for the new user
    notifyListeners();
  }

  void logout() async {
    await PrefsHelper.logout();
    _activeSession = null;
    _history = []; // Clear history on logout
    notifyListeners();
  }

  void updateProfile({String? name, String? phone, String? image}) async {
    await PrefsHelper.updateProfile(name: name, phone: phone, image: image);
    notifyListeners();
  }

  void startParking(ActiveParkingSession session) async {
    _activeSession = session;
    await PrefsHelper.saveActiveSession(session.toJson());
    notifyListeners();
  }

  Future<void> endParking({double discountFactor = 1.0, bool usedCoupon = false}) async {
    if (_activeSession != null) {
      try {
        final now = DateTime.now();
        final elapsed = now.difference(_activeSession!.startTime);
        
        final double durationInMinutes = elapsed.inSeconds / 60.0;
        final double storedMinutes = durationInMinutes < 0.01 ? 0.02 : durationInMinutes;
        
        double cost = (storedMinutes / 60.0) * _activeSession!.pricePerHour;
        cost = cost * discountFactor; // Apply discount
        
        final finalCost = cost < 0.1 ? 0.5 : cost; 
        
        final historyItem = {
          'parkingName': _activeSession!.spot.name,
          'date': now.toIso8601String(),
          'durationMinutes': storedMinutes,
          'cost': finalCost,
        };

        await DatabaseHelper.instance.insertHistory(historyItem);

        if (usedCoupon) {
          await PrefsHelper.setUsedCoupon(true);
        }

        _activeSession = null;
        await PrefsHelper.clearActiveSession();
        await fetchHistory();
      } catch (e) {
        debugPrint('Error ending parking: $e');
      }
    }
  }

  Future<void> fetchHistory() async {
    try {
      _history = await DatabaseHelper.instance.queryAllHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }
}
