import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
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

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  
  if (isFirstLaunch) {
    await prefs.setBool('isFirstLaunch', false);
  }

  runApp(SoundSenseApp(isFirstLaunch: isFirstLaunch));
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
    service.on('setAsForeground').listen((event) => service.setAsForegroundService());
    service.on('setAsBackground').listen((event) => service.setAsBackgroundService());
  }

  service.on('stopService').listen((event) => service.stopSelf());

  double currentSensitivity = 0.65;
  double currentPanicDb = 100.0;
  bool isNormalMode = true;

  Timer.periodic(const Duration(seconds: 2), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    currentSensitivity = prefs.getDouble('settings_sensitivity') ?? 0.65;
    currentPanicDb = prefs.getDouble('settings_panicThreshold') ?? 100.0;
    isNormalMode = prefs.getBool('isNormalMode') ?? true;
  });

  try {
    final interpreter = await Interpreter.fromAsset('assets/models/soundclassifier_with_metadata.tflite');
    final labelsData = await rootBundle.loadString('assets/models/labels.txt');
    final labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();

    final inputShape = interpreter.getInputTensor(0).shape;
    final requiredInputSize = inputShape.length > 1 ? inputShape[1] : 15600;

    final record = AudioRecorder();
    final stream = await record.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    List<double> audioBuffer = [];

    stream.listen((data) {
      final int length = data.length ~/ 2;
      final ByteData byteData = ByteData.sublistView(data);
      
      double sumSquares = 0.0;
      
      for (int i = 0; i < length; i++) {
        final double sample = byteData.getInt16(i * 2, Endian.little).toDouble();
        final double normalizedSample = sample / 32768.0;
        sumSquares += normalizedSample * normalizedSample;
        audioBuffer.add(normalizedSample);
      }
      
      final double rms = sqrt(sumSquares / length);
      double calculatedDb = 0.0;
      
      if (rms > 0.00001) { 
        double dbfs = 20 * (log(rms) / ln10);
        calculatedDb = dbfs + 95.0; 
        calculatedDb = calculatedDb.clamp(0.0, 120.0);
      }

      service.invoke('update', {
        'class': "Listening...",
        'db': calculatedDb,
        'confidence': 0.0,
      });

      if (audioBuffer.length >= requiredInputSize) {
        var inputList = audioBuffer.sublist(audioBuffer.length - requiredInputSize);
        var input = [inputList];
        
        try {
          var output = List.filled(labels.length, 0.0).reshape([1, labels.length]);
          interpreter.run(input, output);

          double maxProb = 0.0; 
          int maxIdx = -1;
          for (int i = 0; i < labels.length; i++) {
            if (output[0][i] > maxProb) {
              maxProb = output[0][i];
              maxIdx = i;
            }
          }

          if (maxIdx != -1 && maxProb >= currentSensitivity) {
            String detectedLabel = labels[maxIdx];
            
            service.invoke('update', {
              'class': detectedLabel,
              'db': calculatedDb,
              'confidence': maxProb,
            });

            String labelLower = detectedLabel.toLowerCase();
            bool isEmergency = labelLower.contains("siren") || 
                               labelLower.contains("alarm") || 
                               labelLower.contains("horn");
                               
            bool isPanic = calculatedDb >= currentPanicDb || (!isNormalMode && labelLower.contains("alarm"));
            
            if (isEmergency && calculatedDb > 70.0) {
              service.invoke('emergency_alert', {
                'class': detectedLabel,
                'db': calculatedDb,
                'confidence': maxProb,
                'isPanic': isPanic,
              });
              
              if (maxProb > 0.75) {
                triggerFullScreenAlert(detectedLabel);
              }
            }
          }
        } catch (e) {
          debugPrint(e.toString());
        }

        audioBuffer.removeRange(0, audioBuffer.length - (requiredInputSize ~/ 2));
      }
    });
  } catch (e) {
    debugPrint(e.toString());
  }
}

class SoundSenseApp extends StatelessWidget {
  final bool isFirstLaunch;
  
  const SoundSenseApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isFirstLaunch ? const SplashScreen() : const MainShell(),   
       );
  }
}