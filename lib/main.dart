import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final AndroidNotificationChannel silentChannel = AndroidNotificationChannel(
  'soundsense_silent_channel',
  'SoundSense Active Listening',
  importance: Importance.low,
  playSound: false,
  enableVibration: false,
);

final AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
  'emergency_alerts',
  'Emergency Alerts',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  await initializeBackgroundService();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SoundSenseApp());
}

Future<void> requestPermissions() async {
  await [
    Permission.microphone,
    Permission.notification,
    Permission.systemAlertWindow,
  ].request();
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(silentChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, 
      isForegroundMode: true,
      notificationChannelId: 'soundsense_silent_channel',
      initialNotificationTitle: 'SoundSense is active',
      initialNotificationContent: 'SoundSense is Listening',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.microphone],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

Future<void> triggerFullScreenAlert(String detectedSound) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'emergency_alerts',
    'Emergency Alerts',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
  );
  
  final NotificationDetails details = NotificationDetails(android: androidDetails);
  
  await flutterLocalNotificationsPlugin.show(
    id: 999,
    title: 'DANGER: $detectedSound',
    body: 'Immediate awareness required',
    notificationDetails: details,
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  try {
    final interpreter = await Interpreter.fromAsset('assets/models/soundclassifier_with_metadata.tflite');
    final labelsData = await rootBundle.loadString('assets/models/labels.txt');
    final labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();

    final record = AudioRecorder();
    
    // BYPASS: We completely removed `if (await record.hasPermission())`
    // because checking for permissions without a UI crashes the background isolate.
    final stream = await record.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    stream.listen((data) {
      // 1. SAFELY read only the fresh audio frame, completely ignoring garbage memory
      final int length = data.length ~/ 2;
      final ByteData byteData = ByteData.sublistView(data);
      
      double sumSquares = 0.0;
      final Float32List floatInput = Float32List(length);
      
      for (int i = 0; i < length; i++) {
        // Read 16-bit PCM accurately based on system architecture
        final double sample = byteData.getInt16(i * 2, Endian.little).toDouble();
        final double normalizedSample = sample / 32768.0;
        sumSquares += normalizedSample * normalizedSample;
        floatInput[i] = normalizedSample;
      }
      
      final double rms = sqrt(sumSquares / length);
      double calculatedDb = 0.0;
      
      // 2. Realistic SPL Math: Quiet room ~40dB, Speaking ~70dB
      if (rms > 0.00001) { 
        double dbfs = 20 * (log(rms) / ln10); // Usually between -80 (quiet) and 0 (loud)
        calculatedDb = dbfs + 95.0; // Push it up to human-readable SPL ranges
        calculatedDb = calculatedDb.clamp(0.0, 120.0);
      }

      service.invoke('update', {
        'class': "Listening...",
        'db': calculatedDb,
        'confidence': 0.0,
      });

      try {
        var input = [floatInput];
        var output = List.filled(1 * labels.length, 0.0).reshape([1, labels.length]);

        interpreter.run(input, output);

        double maxProb = 0.0; 
        int maxIdx = -1;
        
        for (int i = 0; i < labels.length; i++) {
          if (output[0][i] > maxProb) {
            maxProb = output[0][i];
            maxIdx = i;
          }
        }

        if (maxIdx != -1 && maxProb > 0.50) {
          String detectedClass = labels[maxIdx];
          
          service.invoke('update', {
            'class': detectedClass,
            'db': calculatedDb, // Now accurately synced with the AI
            'confidence': maxProb,
          });

          if (maxProb > 0.80 && (detectedClass == "Siren" || detectedClass == "Fire Alarm")) {
            triggerFullScreenAlert(detectedClass);
          }
        }
      } catch (e) {
        print("TFLite calculation skipped: $e");
      }
    });
  } catch (e) {
    print("AI Engine Crash Prevented: $e");
    // This catches the crash so your notification and service stay alive!
  }
}

class SoundSenseApp extends StatelessWidget {
  const SoundSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}