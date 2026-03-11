import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'sound_sense_channel', 
    'SoundSense Service', 
    description: 'This channel is used for status.',
    importance: Importance.low, 
  );

  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'sound_sense_alert_channel', 
    'SoundSense Critical Alerts', 
    description: 'This channel is used to wake the screen.',
    importance: Importance.max, 
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true, 
      notificationChannelId: 'sound_sense_channel',
      initialNotificationTitle: 'SoundSense Active',
      initialNotificationContent: 'Listening for danger...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

  final random = Random();

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "SoundSense Active",
          content: "Monitoring Environment...",
        );
      }
    }

    double currentDb = 40.0 + random.nextDouble() * 20.0;
    String detectedClass = "background";
    double conf = 0.9;
    bool danger = false;

    if (random.nextInt(15) == 0) {
      currentDb = 85.0 + random.nextDouble() * 20.0; 
      detectedClass = random.nextBool() ? "siren" : "horn";
      conf = 0.75 + random.nextDouble() * 0.2;
      danger = true;

     await flutterLocalNotificationsPlugin.show(
        id: 889,
        title: 'DANGER DETECTED',
        body: 'Loud $detectedClass detected nearby!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'sound_sense_alert_channel',
            'SoundSense Critical Alerts',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true, 
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
      );
    }

    service.invoke(
      'update',
      {
        "status": "Active",
        "decibels": currentDb,
        "soundClass": detectedClass,
        "confidence": conf,
        "isDangerous": danger,
      },
    );
  });
}