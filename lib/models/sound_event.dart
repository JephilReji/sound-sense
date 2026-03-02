import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SoundClass {
  horn,
  siren,
  engine,
  heavyVehicle,
  background,
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
      case SoundClass.horn:
        return 'Vehicle Horn';
      case SoundClass.siren:
        return 'Emergency Siren';
      case SoundClass.engine:
        return 'Engine Rev';
      case SoundClass.heavyVehicle:
        return 'Heavy Vehicle';
      case SoundClass.background:
        return 'Background Noise';
    }
  }

  String get emoji {
    switch (soundClass) {
      case SoundClass.horn:
        return '📯';
      case SoundClass.siren:
        return '🚨';
      case SoundClass.engine:
        return '⚙️';
      case SoundClass.heavyVehicle:
        return '🚛';
      case SoundClass.background:
        return '🔈';
    }
  }

  String get description {
    switch (soundClass) {
      case SoundClass.horn:
        return 'Vehicle nearby is honking';
      case SoundClass.siren:
        return 'Emergency vehicle approaching';
      case SoundClass.engine:
        return 'High-rev engine detected';
      case SoundClass.heavyVehicle:
        return 'Truck or bus in vicinity';
      case SoundClass.background:
        return 'Normal traffic noise';
    }
  }

  Color get alertColor {
    switch (soundClass) {
      case SoundClass.horn:
        return AppTheme.alertHorn;
      case SoundClass.siren:
        return AppTheme.alertSiren;
      case SoundClass.engine:
        return AppTheme.alertEngine;
      case SoundClass.heavyVehicle:
        return AppTheme.alertHeavy;
      case SoundClass.background:
        return AppTheme.alertBackground;
    }
  }

  Color get screenColor {
    switch (soundClass) {
      case SoundClass.horn:
        return const Color(0xFFFF6B00);
      case SoundClass.siren:
        return const Color(0xFFCC0022);
      case SoundClass.engine:
        return const Color(0xFFCC8800);
      case SoundClass.heavyVehicle:
        return const Color(0xFFCC3300);
      case SoundClass.background:
        return const Color(0xFF006633);
    }
  }

  bool get isDangerous =>
      soundClass != SoundClass.background && confidence > 0.65;

  int get urgencyLevel {
    if (isPanic) return 3;
    if (soundClass == SoundClass.siren) return 2;
    if (soundClass == SoundClass.horn || soundClass == SoundClass.heavyVehicle) return 1;
    return 0;
  }

  String get urgencyLabel {
    switch (urgencyLevel) {
      case 3:
        return 'PANIC';
      case 2:
        return 'HIGH';
      case 1:
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }
}