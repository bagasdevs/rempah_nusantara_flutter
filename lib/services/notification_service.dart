import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// Conditional imports for Firebase
// These will only work after running flutter pub get and configuring Firebase
bool _firebaseAvailable = false;

class NotificationService {
  static String? _fcmToken;
  static String? _pendingNavigation;

  /// Initialize notification service
  static Future<void> init() async {
    try {
      // Skip on web for now
      if (kIsWeb) {
        print('⚠️ [FCM] Web platform - skipping FCM init');
        return;
      }

      // Try to initialize Firebase
      await _initFirebase();

      if (_firebaseAvailable) {
        print('✅ [FCM] Notification service initialized');
      } else {
        print('⚠️ [FCM] Firebase not available - push notifications disabled');
      }
    } catch (e) {
      print('❌ [FCM] Init error: $e');
      _firebaseAvailable = false;
    }
  }

  /// Try to initialize Firebase - separated to handle import errors gracefully
  static Future<void> _initFirebase() async {
    try {
      // Dynamic import to avoid compile errors when Firebase is not configured
      final firebase = await _tryImportFirebase();
      if (firebase != null) {
        _firebaseAvailable = true;
        await _setupFirebaseMessaging();
      }
    } catch (e) {
      print('⚠️ [FCM] Firebase not configured: $e');
      _firebaseAvailable = false;
    }
  }

  /// Try to import Firebase dynamically
  static Future<dynamic> _tryImportFirebase() async {
    // This will be replaced with actual Firebase initialization
    // when Firebase is properly configured in the project
    // For now, return null to indicate Firebase is not available
    return null;
  }

  /// Setup Firebase Messaging listeners
  static Future<void> _setupFirebaseMessaging() async {
    // Will be implemented when Firebase is configured
  }

  /// Request notification permission
  static Future<bool> requestPermission() async {
    if (!_firebaseAvailable) {
      print('⚠️ [FCM] Firebase not available');
      return false;
    }

    try {
      // Permission request will be implemented with Firebase
      return true;
    } catch (e) {
      print('❌ [FCM] Permission request error: $e');
      return false;
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    if (!_firebaseAvailable) {
      return null;
    }

    try {
      // Token retrieval will be implemented with Firebase
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);

        if (ApiService.isAuthenticated) {
          await saveTokenToServer(_fcmToken!);
        }
      }

      return _fcmToken;
    } catch (e) {
      print('❌ [FCM] Get token error: $e');
      return null;
    }
  }

  /// Get current FCM token
  static String? get currentToken => _fcmToken;

  /// Check if Firebase is available
  static bool get isAvailable => _firebaseAvailable;

  /// Save FCM token to server
  static Future<void> saveTokenToServer(String token) async {
    try {
      if (!ApiService.isAuthenticated) return;

      String platform = 'android';
      if (!kIsWeb) {
        platform = Platform.isAndroid ? 'android' : 'ios';
      }

      await ApiService.post('/api/notifications/token', {
        'fcm_token': token,
        'platform': platform,
      });

      print('✅ [FCM] Token saved to server');
    } catch (e) {
      print('❌ [FCM] Save token error: $e');
    }
  }

  /// Navigate to route (to be connected with GoRouter)
  static void navigateTo(String route) {
    print('🧭 [FCM] Navigate to: $route');
    _pendingNavigation = route;
  }

  /// Get and clear pending navigation
  static String? consumePendingNavigation() {
    final route = _pendingNavigation;
    _pendingNavigation = null;
    return route;
  }

  // Listeners for foreground messages
  static final List<void Function(Map<String, dynamic>)> _listeners = [];

  /// Add listener for foreground messages
  static void addListener(void Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  static void removeListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  static void notifyListeners(Map<String, dynamic> message) {
    for (final listener in _listeners) {
      listener(message);
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    if (!_firebaseAvailable) return;

    try {
      // Will be implemented with Firebase
      print('✅ [FCM] Subscribed to topic: $topic');
    } catch (e) {
      print('❌ [FCM] Subscribe error: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (!_firebaseAvailable) return;

    try {
      // Will be implemented with Firebase
      print('✅ [FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ [FCM] Unsubscribe error: $e');
    }
  }

  /// Delete token (for logout)
  static Future<void> deleteToken() async {
    try {
      // Delete from server first
      if (ApiService.isAuthenticated && _fcmToken != null) {
        try {
          await ApiService.delete(
            '/api/notifications/token?fcm_token=$_fcmToken',
          );
        } catch (e) {
          print('⚠️ [FCM] Server token delete error: $e');
        }
      }

      // Clear local token
      _fcmToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      print('✅ [FCM] Token deleted');
    } catch (e) {
      print('❌ [FCM] Delete token error: $e');
    }
  }
}
