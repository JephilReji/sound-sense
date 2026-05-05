import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sound_event.dart';

class AlertScreen extends StatefulWidget {
  final SoundEvent event;

  const AlertScreen({super.key, required this.event});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  Timer? _strobeTimer;
  Timer? _countdownTimer;
  bool _isTorchOn = false;
  
  int _secondsRemaining = 45;
  bool _emergencyTriggered = false;

  @override
  void initState() {
    super.initState();
    _triggerHardwareAlerts();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        if (!_emergencyTriggered) {
          _executeEmergencyProtocol();
        }
      }
    });
  }

  Future<void> _executeEmergencyProtocol() async {
    setState(() {
      _emergencyTriggered = true;
    });
    
    // Stop the intense hardware alerts so the user can focus on the SMS screen
    Vibration.cancel();
    _strobeTimer?.cancel();
    TorchLight.disableTorch().catchError((_) {});

    // The message that will be sent to contacts. 
    final String message = "EMERGENCY: SoundSense detected a critical danger (${widget.event.label}) near me. Please check on me immediately. Location: [GPS Link pending]";
    
    // Uses url_launcher to open the native SMS app safely
    final Uri smsUri = Uri.parse("sms:?body=${Uri.encodeComponent(message)}");
    
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      debugPrint("Could not launch SMS app");
    }
  }

  Future<void> _triggerHardwareAlerts() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    
    if (hasVibrator == true) {
      List<int> pattern = [];
      
      if (widget.event.isPanic) {
        _startStrobe();
        switch (widget.event.soundClass) {
          case SoundClass.horn:
            pattern = [0, 150, 50, 150, 50, 150, 50, 150];
            break;
          case SoundClass.siren:
            pattern = [0, 100, 50, 100, 50, 100, 50, 100, 50, 100];
            break;
          case SoundClass.safetyAlarm:
            pattern = [0, 800, 150, 800, 150, 800];
            break;
          case SoundClass.heavyVehicle:
            pattern = [0, 2000, 100, 2000];
            break;
        }
        Vibration.vibrate(pattern: pattern, repeat: 0);
      } else {
        switch (widget.event.soundClass) {
          case SoundClass.horn:
            pattern = [0, 400, 200, 400];
            break;
          case SoundClass.siren:
            pattern = [0, 500, 300, 500, 300, 500];
            break;
          case SoundClass.safetyAlarm:
            pattern = [0, 400, 400, 400, 400];
            break;
          case SoundClass.heavyVehicle:
            pattern = [0, 1000, 500, 1000];
            break;
        }
        Vibration.vibrate(pattern: pattern);
      }
    }
  }

  Future<void> _startStrobe() async {
    try {
      bool isTorchAvailable = await TorchLight.isTorchAvailable();
      if (isTorchAvailable) {
        _strobeTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
          try {
            if (_isTorchOn) {
              await TorchLight.disableTorch();
            } else {
              await TorchLight.enableTorch();
            }
            _isTorchOn = !_isTorchOn;
          } catch (e) {
            debugPrint(e.toString());
          }
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    Vibration.cancel();
    _strobeTimer?.cancel();
    _countdownTimer?.cancel(); 
    TorchLight.disableTorch().catchError((_) {}); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.event.alertColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Text(
                widget.event.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              widget.event.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.event.decibels.toStringAsFixed(0)} dB DETECTED',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            
            // --- UPDATED UX COUNTDOWN TIMER ---
            if (!_emergencyTriggered)
              Column(
                children: [
                  const Text(
                    'AUTO-NOTIFYING EMERGENCY CONTACTS IN',
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_secondsRemaining}s', // Cleaned up formatting here!
                    style: TextStyle(
                      color: _secondsRemaining <= 10 ? const Color.fromARGB(255, 255, 200, 200) : Colors.white, 
                      fontSize: 48, 
                      fontWeight: FontWeight.w900
                    ),
                  ),
                ],
              )
            else
              const Text(
                'EMERGENCY PROTOCOL ACTIVATED',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.w900
                ),
              ),
            // ------------------------------
            
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); 
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'DISMISS',
                      style: TextStyle(
                        color: widget.event.alertColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}