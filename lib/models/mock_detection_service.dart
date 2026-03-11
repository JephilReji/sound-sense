import 'dart:async';
import 'dart:math';
import '../models/sound_event.dart';

class MockDetectionService {
  final _random = Random();
  StreamController<SoundEvent>? _controller;
  Timer? _timer;
  bool _isRunning = false;

  Stream<SoundEvent> get eventStream {
    _controller ??= StreamController<SoundEvent>.broadcast();
    return _controller!.stream;
  }

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _controller ??= StreamController<SoundEvent>.broadcast();
    _scheduleNext();
  }

  void _scheduleNext() {
    if (!_isRunning) return;
    final delay = Duration(milliseconds: 2000 + _random.nextInt(4000));
    _timer = Timer(delay, _emitEvent);
  }

  void _emitEvent() {
    if (!_isRunning) return;

    final roll = _random.nextDouble();
    SoundClass sc;
    double confidence;
    double db;

    // Weighted probability for Indian roads (4 classes now)
    if (roll < 0.40) {
      sc = SoundClass.horn;
      confidence = 0.72 + _random.nextDouble() * 0.25;
      db = 80 + _random.nextDouble() * 20;
    } else if (roll < 0.65) {
      sc = SoundClass.heavyVehicle;
      confidence = 0.70 + _random.nextDouble() * 0.25;
      db = 85 + _random.nextDouble() * 15;
    } else if (roll < 0.85) {
      sc = SoundClass.siren;
      confidence = 0.85 + _random.nextDouble() * 0.14;
      db = 90 + _random.nextDouble() * 15;
    } else {
      sc = SoundClass.safetyAlarm;
      confidence = 0.80 + _random.nextDouble() * 0.18;
      db = 88 + _random.nextDouble() * 15;
    }

    final isPanic = db > 100;

    final event = SoundEvent(
      soundClass: sc,
      confidence: confidence,
      decibels: db,
      timestamp: DateTime.now(),
      isPanic: isPanic,
    );

    _controller?.add(event);
    _scheduleNext();
  }

  void triggerManual(SoundClass sc, {bool panic = false}) {
    final db = panic ? 105.0 : 85.0;
    final event = SoundEvent(
      soundClass: sc,
      confidence: 0.95,
      decibels: db,
      timestamp: DateTime.now(),
      isPanic: panic,
    );
    _controller?.add(event);
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _controller?.close();
    _controller = null;
  }
}