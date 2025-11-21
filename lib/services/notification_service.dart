import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final String? reportId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.reportId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'reportId': reportId,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      reportId: json['reportId'],
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      // 1. Request Permission
      await _requestPermission();

      // 4. Listen for Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 5. Handle Background Message Open
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification opened app: ${message.data}');
        _addNotificationFromMessage(message);
      });
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
      // Continue without Firebase
    }

    // 2. Initialize Local Notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
        if (response.payload != null) {
          print('Notification tapped with payload: ${response.payload}');
        }
      },
    );

    // 3. Load saved notifications
    await _loadNotifications();

    _isInitialized = true;
  }

  Future<void> _requestPermission() async {
    if (_firebaseMessaging != null) {
      NotificationSettings settings = await _firebaseMessaging!
          .requestPermission(alert: true, badge: true, sound: true);
      print('User granted permission: ${settings.authorizationStatus}');
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<String?> getToken() async {
    if (_firebaseMessaging == null) return null;
    return await _firebaseMessaging!.getToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      // Show local notification
      _showLocalNotification(message);

      // Add to list
      _addNotificationFromMessage(message);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!await getNotificationsEnabled()) return;

    const androidDetails = AndroidNotificationDetails(
      'chiclayo_reporte_channel',
      'Notificaciones de Reportes',
      channelDescription: 'Canal para actualizaciones de estado de reportes',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data['reportId'],
    );
  }

  Future<void> _addNotificationFromMessage(RemoteMessage message) async {
    final newNotification = NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      title: message.notification?.title ?? 'Nueva notificación',
      body: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      reportId: message.data['reportId'],
    );

    _notifications.insert(0, newNotification);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('notifications');
    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      _notifications = jsonList
          .map((e) => NotificationModel.fromJson(e))
          .toList();
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(
      _notifications.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('notifications', data);
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    if (_firebaseMessaging != null) {
      if (!enabled) {
        await _firebaseMessaging!.deleteToken();
      } else {
        await _firebaseMessaging!.getToken();
      }
    }
    notifyListeners();
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
}
