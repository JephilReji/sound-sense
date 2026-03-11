import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SoundClass {
  horn,
  siren,
  safetyAlarm,
  heavyVehicle,
}

class SoundEvent {
  final SoundClass soundClass;
  final double confidence;
  final double decibels;
  final DateTime timestamp;
  final bool isPanic;

  const SoundEvent({
    required this.soundClass,
    required this.confidence,
    required this.decibels,
    required this.timestamp,
    this.isPanic = false,
  });

  String get label {
    switch (soundClass) {
      case SoundClass.horn:        return 'Vehicle Horn';
      case SoundClass.siren:       return 'Emergency Siren';
      case SoundClass.safetyAlarm: return 'Safety Alarm';
      case SoundClass.heavyVehicle:return 'Heavy Vehicle';
    }
  }

  String get emoji {
    switch (soundClass) {
      case SoundClass.horn:        return '📯';
      case SoundClass.siren:       return '🚨';
      case SoundClass.safetyAlarm: return '🔔';
      case SoundClass.heavyVehicle:return '🚛';
    }
  }

  String get description {
    switch (soundClass) {
      case SoundClass.horn:        return 'Vehicle nearby is honking';
      case SoundClass.siren:       return 'Emergency vehicle approaching';
      case SoundClass.safetyAlarm: return 'Fire alarm or danger alert detected';
      case SoundClass.heavyVehicle:return 'Truck or bus in vicinity';
    }
  }

  Color get alertColor {
    switch (soundClass) {
      case SoundClass.horn:        return AppTheme.alertHorn;        // Orange
      case SoundClass.siren:       return AppTheme.alertSiren;       // Blue
      case SoundClass.safetyAlarm: return AppTheme.alertSafetyAlarm; // Red
      case SoundClass.heavyVehicle:return AppTheme.alertHeavy;       // Green
    }
  }

  Color get screenColor {
    switch (soundClass) {
      case SoundClass.horn:        return const Color(0xFFCC4400);   // Deep Orange
      case SoundClass.siren:       return const Color(0xFF0A40CC);   // Deep Blue
      case SoundClass.safetyAlarm: return const Color(0xFFCC0022);   // Deep Red
      case SoundClass.heavyVehicle:return const Color(0xFF007744);   // Deep Green
    }
  }

  bool get isDangerous => confidence > 0.65;

  int get urgencyLevel {
    if (isPanic) return 3;
    if (soundClass == SoundClass.siren || soundClass == SoundClass.safetyAlarm) return 2;
    if (soundClass == SoundClass.horn || soundClass == SoundClass.heavyVehicle) return 1;
    return 0;
  }

  String get urgencyLabel {
    switch (urgencyLevel) {
      case 3:  return 'PANIC';
      case 2:  return 'HIGH';
      case 1:  return 'MEDIUM';
      default: return 'LOW';
    }
  }
}