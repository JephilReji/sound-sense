import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DetectionMode { normal, indoor }

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relation,
  }) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        relation: json['relation'],
      );
}

class AppState extends ChangeNotifier {
  String userName = 'Your Name';
  String userPhone = '';
  bool locationEnabled = false;
  String currentLocation = 'Chennai, Tamil Nadu';

  DetectionMode detectionMode = DetectionMode.normal;
  int alertDismissTimeout = 30;

  // New Sound Class Preference Flags
  bool hornEnabled = true;
  bool sirenEnabled = true;
  bool safetyAlarmEnabled = true;
  bool heavyEnabled = true;

  final List<EmergencyContact> emergencyContacts = [];

  AppState() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName') ?? 'Your Name';
    userPhone = prefs.getString('userPhone') ?? '';
    locationEnabled = prefs.getBool('locationEnabled') ?? false;
    alertDismissTimeout = prefs.getInt('alertDismissTimeout') ?? 30;

    // Load Sound Preferences
    hornEnabled = prefs.getBool('settings_horn') ?? true;
    sirenEnabled = prefs.getBool('settings_siren') ?? true;
    safetyAlarmEnabled = prefs.getBool('settings_safety') ?? true;
    heavyEnabled = prefs.getBool('settings_heavy') ?? true;

    final contactsStr = prefs.getStringList('emergencyContacts');
    if (contactsStr != null) {
      emergencyContacts.clear();
      for (var str in contactsStr) {
        emergencyContacts.add(EmergencyContact.fromJson(jsonDecode(str)));
      }
    }
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setString('userPhone', userPhone);
    await prefs.setBool('locationEnabled', locationEnabled);
    await prefs.setInt('alertDismissTimeout', alertDismissTimeout);

    // Save Sound Preferences
    await prefs.setBool('settings_horn', hornEnabled);
    await prefs.setBool('settings_siren', sirenEnabled);
    await prefs.setBool('settings_safety', safetyAlarmEnabled);
    await prefs.setBool('settings_heavy', heavyEnabled);

    final contactsStr =
        emergencyContacts.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('emergencyContacts', contactsStr);
  }

  void updateSoundPreference(String key, bool value) {
    switch (key) {
      case 'horn': hornEnabled = value; break;
      case 'siren': sirenEnabled = value; break;
      case 'safety': safetyAlarmEnabled = value; break;
      case 'heavy': heavyEnabled = value; break;
    }
    _savePrefs();
    notifyListeners();
  }

  void updateProfile({String? name, String? phone}) {
    if (name != null) userName = name;
    if (phone != null) userPhone = phone;
    _savePrefs();
    notifyListeners();
  }

  void toggleLocation() {
    locationEnabled = !locationEnabled;
    _savePrefs();
    notifyListeners();
  }

  void setDetectionMode(DetectionMode mode) {
    detectionMode = mode;
    notifyListeners();
  }

  void addContact(EmergencyContact contact) {
    emergencyContacts.add(contact);
    _savePrefs();
    notifyListeners();
  }

  void removeContact(String id) {
    emergencyContacts.removeWhere((c) => c.id == id);
    _savePrefs();
    notifyListeners();
  }

  void updateContact(EmergencyContact updated) {
    final idx = emergencyContacts.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      emergencyContacts[idx] = updated;
      _savePrefs();
      notifyListeners();
    }
  }

  void setAlertTimeout(int seconds) {
    alertDismissTimeout = seconds;
    _savePrefs();
    notifyListeners();
  }

  String get modeLabel =>
      detectionMode == DetectionMode.normal ? 'Normal Mode' : 'Indoor Mode';

  String get modeDescription => detectionMode == DetectionMode.normal
      ? 'Optimised for open roads & traffic'
      : 'Optimised for enclosed spaces & buildings';

  IconData get modeIcon => detectionMode == DetectionMode.normal
      ? Icons.traffic_rounded
      : Icons.home_rounded;
}