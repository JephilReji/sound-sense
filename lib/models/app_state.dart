import 'package:flutter/material.dart';

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
}

class AppState extends ChangeNotifier {
  // Profile
  String userName = 'Your Name';
  String userPhone = '';
  bool locationEnabled = false;
  String currentLocation = 'Chennai, Tamil Nadu';

  // Detection Mode
  DetectionMode detectionMode = DetectionMode.normal;

  // Alert dismiss timeout (seconds)
  int alertDismissTimeout = 30;

  // Emergency contacts
  final List<EmergencyContact> emergencyContacts = [];

  void updateProfile({String? name, String? phone}) {
    if (name != null) userName = name;
    if (phone != null) userPhone = phone;
    notifyListeners();
  }

  void toggleLocation() {
    locationEnabled = !locationEnabled;
    notifyListeners();
  }

  void setDetectionMode(DetectionMode mode) {
    detectionMode = mode;
    notifyListeners();
  }

  void addContact(EmergencyContact contact) {
    emergencyContacts.add(contact);
    notifyListeners();
  }

  void removeContact(String id) {
    emergencyContacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void updateContact(EmergencyContact updated) {
    final idx = emergencyContacts.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      emergencyContacts[idx] = updated;
      notifyListeners();
    }
  }

  void setAlertTimeout(int seconds) {
    alertDismissTimeout = seconds;
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